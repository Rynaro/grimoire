use crate::app::{App, InputMode, Panel, StatusLevel};
use crate::storage;
use ratatui::layout::{Alignment, Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span, Text};
use ratatui::widgets::{Block, Borders, Clear, List, ListItem, ListState, Paragraph, Wrap};
use ratatui::Frame;
use unicode_width::UnicodeWidthStr;

pub fn draw(f: &mut Frame, app: &mut App) {
    let size = f.size();
    let layout = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(5), Constraint::Length(2)])
        .split(size);

    let main_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([
            Constraint::Length(24),
            Constraint::Length(34),
            Constraint::Min(20),
        ])
        .split(layout[0]);

    draw_sidebar(f, main_chunks[0], app);

    if matches!(app.mode, InputMode::Search) {
        draw_search_results(f, main_chunks[1], app);
    } else {
        draw_notes_list(f, main_chunks[1], app);
    }

    draw_viewer(f, main_chunks[2], app);
    draw_status_bar(f, layout[1], app);

    match app.mode {
        InputMode::Command => draw_prompt(f, size, "Command", &app.command_prompt()),
        InputMode::Search => draw_prompt(f, size, "Search", &app.search_prompt()),
        _ => {}
    }

    if app.show_help {
        draw_help(f, size);
    }
}

fn draw_sidebar(f: &mut Frame, area: Rect, app: &App) {
    let items: Vec<ListItem> = app
        .folders
        .iter()
        .map(|folder| {
            ListItem::new(Line::from(vec![
                Span::styled(
                    format!("{} ", folder.name),
                    Style::default().fg(Color::LightCyan),
                ),
                Span::styled(
                    format!("({})", folder.note_count),
                    Style::default().fg(Color::DarkGray),
                ),
            ]))
        })
        .collect();

    let mut state = ListState::default();
    if !app.folders.is_empty() {
        state.select(Some(app.folder_idx));
    }

    let block = themed_block("Notebooks".to_string(), app.panel == Panel::Sidebar);
    let list = List::new(items)
        .highlight_style(
            Style::default()
                .fg(Color::Magenta)
                .add_modifier(Modifier::BOLD),
        )
        .block(block);

    f.render_stateful_widget(list, area, &mut state);
}

fn draw_notes_list(f: &mut Frame, area: Rect, app: &App) {
    let items: Vec<ListItem> = if app.notes.is_empty() {
        vec![ListItem::new("No notes in this folder yet")]
    } else {
        app.notes
            .iter()
            .map(|note| {
                let timestamp = storage::format_timestamp(note.modified);
                ListItem::new(vec![
                    Line::from(Span::styled(
                        note.title.clone(),
                        Style::default()
                            .fg(Color::White)
                            .add_modifier(Modifier::BOLD),
                    )),
                    Line::from(vec![
                        Span::styled(timestamp, Style::default().fg(Color::DarkGray)),
                        Span::raw("  "),
                        Span::styled(note.preview.clone(), Style::default().fg(Color::Gray)),
                    ]),
                ])
            })
            .collect()
    };

    let mut state = ListState::default();
    if !app.notes.is_empty() {
        state.select(Some(app.note_idx));
    }

    let heading = format!("Notes · {}", app.active_folder_name());
    let block = themed_block(heading, app.panel == Panel::Notes);
    let list = List::new(items)
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD),
        )
        .block(block);

    f.render_stateful_widget(list, area, &mut state);
}

fn draw_search_results(f: &mut Frame, area: Rect, app: &App) {
    let items: Vec<ListItem> = if app.search_results.is_empty() {
        vec![ListItem::new("Start typing to search across all notes…")]
    } else {
        app.search_results
            .iter()
            .map(|result| {
                let icon = match result.kind {
                    storage::SearchKind::Title => "📁",
                    storage::SearchKind::Content => "🔎",
                };
                ListItem::new(vec![
                    Line::from(vec![
                        Span::styled(icon, Style::default().fg(Color::LightYellow)),
                        Span::raw(" "),
                        Span::styled(
                            result.title.clone(),
                            Style::default()
                                .fg(Color::White)
                                .add_modifier(Modifier::BOLD),
                        ),
                    ]),
                    Line::from(Span::styled(
                        result.preview.clone(),
                        Style::default().fg(Color::Gray),
                    )),
                ])
            })
            .collect()
    };

    let mut state = ListState::default();
    if !app.search_results.is_empty() {
        state.select(Some(app.search_idx));
    }

    let block = themed_block("Search Results".to_string(), true);
    let list = List::new(items)
        .highlight_style(
            Style::default()
                .fg(Color::Yellow)
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD),
        )
        .block(block);

    f.render_stateful_widget(list, area, &mut state);
}

fn draw_viewer(f: &mut Frame, area: Rect, app: &mut App) {
    app.set_last_viewport_height(area.height);

    let note_title = format!("Note · {}", app.active_note_title());
    let block = themed_block(note_title, app.panel == Panel::Viewer);

    if matches!(app.mode, InputMode::Editing) {
        let lines: Vec<Line> = app
            .editor
            .as_ref()
            .map(|editor| {
                editor
                    .lines
                    .iter()
                    .map(|line| Line::from(line.clone()))
                    .collect()
            })
            .unwrap_or_default();
        let paragraph = Paragraph::new(lines)
            .block(block.clone())
            .scroll((app.viewer_scroll, 0))
            .wrap(Wrap { trim: false });
        f.render_widget(paragraph, area);

        if let Some(editor) = &app.editor {
            let cursor_y = area.y + 1 + editor.cursor_line as u16 - app.viewer_scroll;
            let cursor_x = area.x + 1 + editor.cursor_display_col();
            if cursor_y < area.y + area.height && cursor_x < area.x + area.width {
                f.set_cursor(cursor_x, cursor_y);
            }
        }
    } else {
        let paragraph = Paragraph::new(app.rendered_note.lines.clone())
            .block(block.clone())
            .scroll((app.viewer_scroll, 0))
            .wrap(Wrap { trim: false });
        f.render_widget(paragraph, area);
    }
}

fn draw_status_bar(f: &mut Frame, area: Rect, app: &App) {
    let default_line = Line::from(vec![
        Span::styled(
            format!("Folder: {}", app.active_folder_name()),
            Style::default().fg(Color::LightCyan),
        ),
        Span::raw("  "),
        Span::styled(
            format!("Note: {}", app.active_note_title()),
            Style::default().fg(Color::Yellow),
        ),
        Span::raw("  "),
        Span::styled(
            format!("Mode: {:?}", app.mode),
            Style::default().fg(Color::Gray),
        ),
    ]);

    let status_line = if let Some(status) = &app.status {
        let color = match status.level {
            StatusLevel::Info => Color::LightGreen,
            StatusLevel::Warn => Color::Yellow,
            StatusLevel::Error => Color::Red,
        };
        Line::from(Span::styled(
            status.text.clone(),
            Style::default().fg(color),
        ))
    } else {
        default_line
    };

    let paragraph = Paragraph::new(status_line)
        .alignment(Alignment::Left)
        .block(Block::default().borders(Borders::TOP));
    f.render_widget(paragraph, area);
}

fn draw_prompt(f: &mut Frame, size: Rect, title: &str, content: &str) {
    let width = size.width.saturating_sub(4);
    let area = Rect {
        x: size.x + 2,
        y: size.y + size.height.saturating_sub(3),
        width,
        height: 3,
    };
    let block = Block::default()
        .title(Line::from(vec![Span::styled(
            title,
            Style::default().fg(Color::Yellow),
        )]))
        .borders(Borders::ALL);
    let paragraph = Paragraph::new(content.to_string()).block(block);
    f.render_widget(Clear, area);
    f.render_widget(paragraph, area);
    let content_width = UnicodeWidthStr::width(content) as u16;
    let cursor_x = (area.x + 1 + content_width).min(area.x + area.width.saturating_sub(2));
    f.set_cursor(cursor_x, area.y + 1);
}

fn draw_help(f: &mut Frame, size: Rect) {
    let width = size.width.saturating_sub(10).min(80);
    let height = size.height.saturating_sub(6).min(18);
    let area = Rect {
        x: size.x + (size.width - width) / 2,
        y: size.y + (size.height - height) / 2,
        width,
        height,
    };

    let help_text = Text::from(vec![
        Line::from("Grimoire — quick reference"),
        Line::from(""),
        Line::from("Navigation: ↑/↓ to move, Tab to switch panes"),
        Line::from(": — open command palette"),
        Line::from("/ — global search (name + content)"),
        Line::from("e — edit note, Ctrl+S to save, Esc to cancel"),
        Line::from("[ / ] — cycle note links, Enter to follow"),
        Line::from("r — refresh filesystem state"),
        Line::from("q — quit"),
    ]);

    let block = Block::default()
        .title("Help")
        .borders(Borders::ALL)
        .border_style(Style::default().fg(Color::LightMagenta));

    let paragraph = Paragraph::new(help_text)
        .block(block)
        .wrap(Wrap { trim: true });
    f.render_widget(Clear, area);
    f.render_widget(paragraph, area);
}

fn themed_block(title: String, active: bool) -> Block<'static> {
    let style = if active {
        Style::default()
            .fg(Color::Magenta)
            .add_modifier(Modifier::BOLD)
    } else {
        Style::default().fg(Color::DarkGray)
    };
    Block::default()
        .title(Span::styled(title, style))
        .borders(Borders::ALL)
        .border_style(style)
}

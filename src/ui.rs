use crate::app::{App, Focus, Mode, SidebarItem};
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, Paragraph, Wrap},
    Frame,
};

pub fn draw(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(25), Constraint::Percentage(75)].as_ref())
        .split(f.size());

    draw_sidebar(f, app, chunks[0]);
    draw_editor(f, app, chunks[1]);
}

fn draw_sidebar(f: &mut Frame, app: &App, area: Rect) {
    let title = if matches!(app.mode, Mode::Searching) {
        format!("Search: {}", app.search_query)
    } else {
        "Grimoire".to_string()
    };

    let items: Vec<ListItem> = app
        .sidebar_items
        .iter()
        .enumerate()
        .map(|(i, item)| {
            let (icon, name) = match item {
                SidebarItem::Folder(path) => {
                    ("📁 ", path.file_name().unwrap_or_default().to_string_lossy())
                }
                SidebarItem::Note(path) => {
                    ("📄 ", path.file_name().unwrap_or_default().to_string_lossy())
                }
            };

            let style = if i == app.sidebar_selected {
                Style::default()
                    .fg(Color::Cyan)
                    .add_modifier(Modifier::BOLD | Modifier::REVERSED)
            } else {
                Style::default().fg(Color::White)
            };

            ListItem::new(Line::from(vec![
                Span::styled(icon, style),
                Span::styled(name.to_string(), style),
            ]))
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .border_style(if matches!(app.focus, Focus::Sidebar) {
                    Style::default().fg(Color::Cyan)
                } else {
                    Style::default().fg(Color::White)
                })
                .title(title),
        )
        .highlight_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD));

    let mut state = ratatui::widgets::ListState::default();
    state.select(Some(app.sidebar_selected));

    f.render_stateful_widget(list, area, &mut state);
}

fn draw_editor(f: &mut Frame, app: &App, area: Rect) {
    let title = match &app.current_note {
        Some(path) => path.file_name().unwrap_or_default().to_string_lossy().to_string(),
        None => "No note selected".to_string(),
    };

    let mode_text = match app.mode {
        Mode::Viewing => "VIEW",
        Mode::Editing => "EDIT",
        Mode::Searching => "SEARCH",
    };

    let block = Block::default()
        .borders(Borders::ALL)
        .border_style(if matches!(app.focus, Focus::Editor) {
            Style::default().fg(Color::Cyan)
        } else {
            Style::default().fg(Color::White)
        })
        .title(format!("{} [{}]", title, mode_text));

    match app.mode {
        Mode::Viewing => {
            let lines = app.markdown_renderer.render(&app.note_content);
            let paragraph = Paragraph::new(lines)
                .block(block)
                .wrap(Wrap { trim: true })
                .scroll((0, 0));
            f.render_widget(paragraph, area);
        }
        Mode::Editing => {
            let lines: Vec<Line> = app
                .note_content
                .lines()
                .map(|l| Line::from(Span::styled(l.to_string(), Style::default())))
                .collect();

            let paragraph = Paragraph::new(if lines.is_empty() {
                vec![Line::from(Span::styled(
                    "Start typing...",
                    Style::default().fg(Color::DarkGray),
                ))]
            } else {
                lines
            })
            .block(block)
            .wrap(Wrap { trim: true });

            f.render_widget(paragraph, area);
        }
        Mode::Searching => {
            let paragraph = Paragraph::new(vec![Line::from(Span::styled(
                format!("Search query: {}", app.search_query),
                Style::default(),
            ))])
            .block(block);
            f.render_widget(paragraph, area);
        }
    }

    // Draw help text at the bottom
    let help_text = match app.mode {
        Mode::Viewing => "q: quit | e: edit | n: new | d: delete | /: search | Tab: switch focus",
        Mode::Editing => "Esc: save & view | Tab: switch focus",
        Mode::Searching => "Esc: cancel | Type to search",
    };

    let help_area = Rect {
        x: area.x,
        y: area.y + area.height.saturating_sub(1),
        width: area.width,
        height: 1,
    };

    let help = Paragraph::new(Line::from(Span::styled(
        help_text,
        Style::default().fg(Color::DarkGray),
    )));
    f.render_widget(help, help_area);
}

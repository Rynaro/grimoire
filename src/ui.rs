use crate::app::{App, Mode};
use crate::markdown::MarkdownRenderer;
use ratatui::{
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
    Frame,
};

pub fn ui(f: &mut Frame, app: &App) {
    let chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(25), Constraint::Percentage(75)].as_ref())
        .split(f.size());

    render_sidebar(f, app, chunks[0]);
    render_note_area(f, app, chunks[1]);
}

fn render_sidebar(f: &mut Frame, app: &App, area: Rect) {
    let items = app.file_manager.list_items().unwrap_or_default();
    let list_items: Vec<ListItem> = items
        .iter()
        .map(|item| {
            let icon = if item.is_folder() { "📁 " } else { "📄 " };
            let name = item.name();
            ListItem::new(format!("{}{}", icon, name))
        })
        .collect();

    let mut list_state = ListState::default();
    list_state.select(Some(app.sidebar_selected));

    let list = List::new(list_items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Grimoire")
                .style(Style::default().fg(Color::White)),
        )
        .highlight_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .highlight_symbol("> ");

    f.render_stateful_widget(list, area, &mut list_state);
}

fn render_note_area(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(1), Constraint::Length(1)].as_ref())
        .split(area);

    match app.mode {
        Mode::View => render_note_view(f, app, chunks[0]),
        Mode::Edit => render_note_edit(f, app, chunks[0]),
        Mode::Command => render_command_mode(f, app, chunks[0]),
        Mode::Search => render_search_mode(f, app, chunks[0]),
    }

    render_status_bar(f, app, chunks[1]);
}

fn render_note_view(f: &mut Frame, app: &App, area: Rect) {
    let title = if let Some(ref path) = app.current_note {
        path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("Untitled")
            .to_string()
    } else {
        "No note selected".to_string()
    };

    let content = if app.current_note.is_some() {
        app.get_current_note_content().unwrap_or_default()
    } else {
        String::new()
    };

    let renderer = MarkdownRenderer::new();
    let lines = renderer.render(&content, (area.width as usize).saturating_sub(4));

    let paragraph = Paragraph::new(lines)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(title)
                .style(Style::default().fg(Color::White)),
        )
        .wrap(Wrap { trim: true })
        .scroll((0, 0));

    f.render_widget(paragraph, area);
}

fn render_note_edit(f: &mut Frame, app: &App, area: Rect) {
    let title = if let Some(ref path) = app.current_note {
        format!(
            "{} (EDITING)",
            path.file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("Untitled")
        )
    } else {
        "No note selected".to_string()
    };

    let content = &app.edit_content;
    let lines: Vec<Line> = content
        .lines()
        .map(|line| Line::from(line.to_string()))
        .collect();

    let paragraph = Paragraph::new(lines)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(title)
                .style(Style::default().fg(Color::Yellow)),
        )
        .wrap(Wrap { trim: true });

    f.render_widget(paragraph, area);

    // Render cursor
    if !content.is_empty() && app.edit_cursor <= content.len() {
        let before_cursor = &content[..app.edit_cursor];
        let cursor_y = before_cursor.chars().filter(|&c| c == '\n').count();
        let cursor_x = before_cursor
            .lines()
            .last()
            .map(|line| {
                // Count display width, handling multi-byte characters
                line.chars()
                    .map(|c| unicode_width::UnicodeWidthChar::width(c).unwrap_or(1))
                    .sum::<usize>()
            })
            .unwrap_or(0);

        // Calculate inner area (accounting for borders)
        let inner = Rect {
            x: area.x + 1,
            y: area.y + 1,
            width: area.width.saturating_sub(2),
            height: area.height.saturating_sub(2),
        };
        if cursor_y < inner.height as usize && cursor_x < inner.width as usize {
            f.set_cursor(
                inner.x + cursor_x as u16,
                inner.y + cursor_y as u16,
            );
        }
    } else {
        // Cursor at start
        let inner = Rect {
            x: area.x + 1,
            y: area.y + 1,
            width: area.width.saturating_sub(2),
            height: area.height.saturating_sub(2),
        };
        f.set_cursor(inner.x, inner.y);
    }
}

fn render_command_mode(f: &mut Frame, app: &App, area: Rect) {
    let paragraph = Paragraph::new(app.command_input.as_str())
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Command")
                .style(Style::default().fg(Color::Green)),
        )
        .style(Style::default().fg(Color::White));

    f.render_widget(paragraph, area);
}

fn render_search_mode(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Length(3), Constraint::Min(1)].as_ref())
        .split(area);

    // Search input
    let search_prompt = format!("Search: {}", app.search_query);
    let search_paragraph = Paragraph::new(search_prompt.as_str())
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title("Search")
                .style(Style::default().fg(Color::Green)),
        )
        .style(Style::default().fg(Color::White));

    f.render_widget(search_paragraph, chunks[0]);

    // Search results
    let result_items: Vec<ListItem> = app
        .search_results
        .iter()
        .map(|path| {
            let name = path
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("Unknown");
            ListItem::new(format!("📄 {}", name))
        })
        .collect();

    let mut list_state = ListState::default();
    list_state.select(Some(app.search_selected));

    let list = List::new(result_items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(format!("Results ({})", app.search_results.len()))
                .style(Style::default().fg(Color::White)),
        )
        .highlight_style(Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD))
        .highlight_symbol("> ");

    f.render_stateful_widget(list, chunks[1], &mut list_state);
}

fn render_status_bar(f: &mut Frame, app: &App, area: Rect) {
    let mode_text = match app.mode {
        Mode::View => "VIEW",
        Mode::Edit => "EDIT",
        Mode::Command => "COMMAND",
        Mode::Search => "SEARCH",
    };

    let help_text = match app.mode {
        Mode::View => "q: quit | e: edit | n: new | d: delete | /: search | ↑↓: navigate | Enter: open",
        Mode::Edit => "Esc: cancel | Ctrl+S: save | Arrow keys: navigate",
        Mode::Command => "Enter: execute | Esc: cancel",
        Mode::Search => "Enter: open | Esc: cancel | ↑↓: navigate",
    };

    let error_text = app.error_message.as_ref().map(|e| e.as_str()).unwrap_or("");

    let status = format!("{} | {}", mode_text, help_text);
    let status_line = if error_text.is_empty() {
        Line::from(Span::styled(
            status,
            Style::default().fg(Color::White).bg(Color::DarkGray),
        ))
    } else {
        Line::from(vec![
            Span::styled(
                format!("{} | ", status),
                Style::default().fg(Color::White).bg(Color::DarkGray),
            ),
            Span::styled(
                error_text,
                Style::default().fg(Color::Red).bg(Color::DarkGray),
            ),
        ])
    };

    let paragraph = Paragraph::new(status_line)
        .block(Block::default().borders(Borders::ALL));

    f.render_widget(paragraph, area);
}

mod components;
mod layout;

use crate::app::App;
use ratatui::{
    Frame,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph, Wrap},
};

// Components and layout modules for future expansion

#[derive(Clone, Copy, PartialEq)]
pub enum AppMode {
    Normal,
    Insert,
    Search,
    Command,
}

pub struct UIState {
    pub selected_index: usize,
    pub mode: AppMode,
    pub sidebar_visible: bool,
    pub command_buffer: String,
    pub list_state: ListState,
}

impl UIState {
    pub fn new() -> Self {
        let mut list_state = ListState::default();
        list_state.select(Some(0));
        Self {
            selected_index: 0,
            mode: AppMode::Normal,
            sidebar_visible: true,
            command_buffer: String::new(),
            list_state,
        }
    }

    pub fn select_next(&mut self) {
        self.selected_index = self.selected_index.saturating_add(1);
        self.list_state.select(Some(self.selected_index));
    }

    pub fn select_previous(&mut self) {
        self.selected_index = self.selected_index.saturating_sub(1);
        self.list_state.select(Some(self.selected_index));
    }

    pub fn toggle_sidebar(&mut self) {
        self.sidebar_visible = !self.sidebar_visible;
    }
}

pub fn render(f: &mut Frame, app: &mut App) {
    // Reserve space for status bar
    let main_area = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(1)].as_ref())
        .split(f.size());

    let chunks = if app.ui_state.sidebar_visible {
        Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(25), Constraint::Percentage(75)].as_ref())
            .split(main_area[0])
    } else {
        Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(100)].as_ref())
            .split(main_area[0])
    };

    if app.ui_state.sidebar_visible {
        render_sidebar(f, app, chunks[0]);
    }

    let note_area = if app.ui_state.sidebar_visible {
        chunks[1]
    } else {
        main_area[0]
    };

    render_note_area(f, app, note_area);
    render_status_bar(f, app, main_area[1]);
}

fn render_sidebar(f: &mut Frame, app: &mut App, area: Rect) {
    let items: Vec<ListItem> = app
        .file_manager
        .items()
        .iter()
        .enumerate()
        .map(|(idx, item)| {
            let icon = if item.is_file { "📄" } else { "📁" };
            let style = if idx == app.ui_state.selected_index {
                Style::default()
                    .fg(Color::Yellow)
                    .add_modifier(Modifier::BOLD)
            } else {
                Style::default()
            };
            ListItem::new(format!("{} {}", icon, item.name)).style(style)
        })
        .collect();

    let list = List::new(items)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(" Notes ")
                .style(Style::default().fg(Color::White)),
        )
        .highlight_style(
            Style::default()
                .bg(Color::DarkGray)
                .add_modifier(Modifier::BOLD),
        );

    f.render_stateful_widget(list, area, &mut app.ui_state.list_state);
}

fn render_note_area(f: &mut Frame, app: &App, area: Rect) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(1)].as_ref())
        .split(area);

    let content = if let Some(ref note) = app.current_note {
        if app.ui_state.mode == AppMode::Insert {
            note.content.clone()
        } else {
            note.render_markdown()
        }
    } else {
        "No note selected. Press 'n' to create a new note.".to_string()
    };

    let paragraph = Paragraph::new(content)
        .block(
            Block::default()
                .borders(Borders::ALL)
                .title(if let Some(ref note) = app.current_note {
                    format!(" {} ", note.title)
                } else {
                    " Note ".to_string()
                }),
        )
        .wrap(Wrap { trim: true })
        .style(if app.ui_state.mode == AppMode::Insert {
            Style::default().fg(Color::Green)
        } else {
            Style::default()
        });

    f.render_widget(paragraph, chunks[0]);

    // Mode indicator
    let mode_text = match app.ui_state.mode {
        AppMode::Normal => "NORMAL",
        AppMode::Insert => "INSERT",
        AppMode::Search => "SEARCH",
        AppMode::Command => "COMMAND",
    };

    let mode_style = match app.ui_state.mode {
        AppMode::Normal => Style::default().fg(Color::Blue),
        AppMode::Insert => Style::default().fg(Color::Green),
        AppMode::Search => Style::default().fg(Color::Yellow),
        AppMode::Command => Style::default().fg(Color::Magenta),
    };

    let status_text = if app.ui_state.mode == AppMode::Search {
        format!("{} {}", mode_text, app.search.query)
    } else if app.ui_state.mode == AppMode::Command {
        format!("{} {}", mode_text, app.ui_state.command_buffer)
    } else {
        mode_text.to_string()
    };

    let status = Paragraph::new(status_text)
        .block(Block::default().borders(Borders::ALL))
        .style(mode_style);

    f.render_widget(status, chunks[1]);
}

fn render_status_bar(f: &mut Frame, app: &App, area: Rect) {
    let help_text = match app.ui_state.mode {
        AppMode::Normal => "q:quit n:new d:delete e:edit /:search ::command Tab:toggle",
        AppMode::Insert => "Esc:save and exit",
        AppMode::Search => "Enter:search Esc:cancel",
        AppMode::Command => "Enter:execute Esc:cancel",
    };

    let status = Paragraph::new(help_text)
        .block(Block::default().borders(Borders::ALL))
        .style(Style::default().fg(Color::DarkGray));

    f.render_widget(status, area);
}

use crate::state::{AppState, Item, Focus};
use ratatui::{
    layout::Rect,
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Borders, List, ListItem},
    Frame,
};

pub struct Sidebar;

impl Sidebar {
    pub fn new() -> Self {
        Self
    }

    pub fn render(&self, f: &mut Frame, area: Rect, state: &mut AppState) {
        let items: Vec<ListItem> = state
            .items
            .iter()
            .map(|item| {
                let (icon, name) = match item {
                    Item::Folder(path) => {
                        let name = path
                            .file_name()
                            .and_then(|s| s.to_str())
                            .unwrap_or("Unknown");
                        ("📁 ", name)
                    }
                    Item::Note(path) => {
                        let name = path
                            .file_stem()
                            .and_then(|s| s.to_str())
                            .unwrap_or("Untitled");
                        ("📄 ", name)
                    }
                };

                ListItem::new(Line::from(vec![
                    Span::styled(icon, Style::default().fg(Color::Cyan)),
                    Span::styled(name, Style::default().fg(Color::White)),
                ]))
            })
            .collect();

        let list = List::new(items)
            .block(
                Block::default()
                    .borders(Borders::ALL)
                    .title("Grimoire")
                    .border_style(if state.focus == Focus::Sidebar {
                        Style::default().fg(Color::Yellow)
                    } else {
                        Style::default().fg(Color::White)
                    }),
            )
            .highlight_style(
                Style::default()
                    .fg(Color::Yellow)
                    .add_modifier(Modifier::BOLD | Modifier::REVERSED),
            );

        f.render_stateful_widget(list, area, &mut state.list_state);
    }
}

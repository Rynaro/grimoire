use crate::markdown::render_markdown;
use crate::state::{AppState, Mode, Focus};
use ratatui::{
    layout::Rect,
    style::{Color, Style},
    text::{Line, Span},
    widgets::{Block, Borders, Paragraph, Wrap},
    Frame,
};

pub struct NoteView;

impl NoteView {
    pub fn new() -> Self {
        Self
    }

    pub fn render(&self, f: &mut Frame, area: Rect, state: &mut AppState) {
        let block = Block::default()
            .borders(Borders::ALL)
            .title(if let Some(ref note) = state.current_note {
                &note.title
            } else {
                "No note selected"
            })
            .border_style(if state.focus == Focus::Note {
                Style::default().fg(Color::Yellow)
            } else {
                Style::default().fg(Color::White)
            });

        let content = if let Some(ref note) = state.current_note {
            if state.mode == Mode::Insert {
                // Show raw content in insert mode
                let lines: Vec<Line> = note
                    .content
                    .lines()
                    .map(|line| Line::from(Span::raw(line)))
                    .collect();
                Paragraph::new(lines)
                    .block(block)
                    .wrap(Wrap { trim: true })
            } else {
                // Render markdown in view mode
                render_markdown(&note.content, block.clone())
            }
        } else {
            Paragraph::new("Press 'Enter' to open a note or 'Ctrl+N' to create a new one")
                .block(block)
                .style(Style::default().fg(Color::DarkGray))
        };

        f.render_widget(content, area);

        // Show mode indicator
        if state.focus == Focus::Note {
            let mode_text = match state.mode {
                Mode::Normal => "NORMAL",
                Mode::Insert => "INSERT",
                Mode::Command => "COMMAND",
            };
            let mode_style = match state.mode {
                Mode::Normal => Style::default().fg(Color::Blue),
                Mode::Insert => Style::default().fg(Color::Green),
                Mode::Command => Style::default().fg(Color::Yellow),
            };

            let mode_line = Line::from(Span::styled(mode_text, mode_style));
            let mode_area = Rect {
                x: area.x + 1,
                y: area.y + area.height.saturating_sub(1),
                width: mode_text.len() as u16,
                height: 1,
            };
            f.render_widget(Paragraph::new(mode_line), mode_area);
        }

        // Show command line
        if state.mode == Mode::Command {
            let cmd_text = format!(":{}", state.command);
            let cmd_line = Line::from(Span::styled(
                cmd_text,
                Style::default().fg(Color::Yellow),
            ));
            let cmd_area = Rect {
                x: area.x + 1,
                y: area.y + area.height.saturating_sub(1),
                width: area.width.saturating_sub(2),
                height: 1,
            };
            f.render_widget(Paragraph::new(cmd_line), cmd_area);
        }
    }
}

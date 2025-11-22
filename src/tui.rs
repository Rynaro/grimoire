use crate::app::{App, Mode};
use crate::ui;
use anyhow::Result;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyEventKind};
use ratatui::Terminal;
use std::io;

pub struct Tui {
    should_quit: bool,
}

impl Tui {
    pub fn new() -> Self {
        Self { should_quit: false }
    }

    pub fn run(
        &mut self,
        terminal: &mut Terminal<ratatui::backend::CrosstermBackend<io::Stdout>>,
        app: &mut App,
    ) -> Result<()> {
        while !self.should_quit {
            terminal.draw(|f| ui::ui(f, app))?;

            if let Event::Key(key) = event::read()? {
                if key.kind == KeyEventKind::Press {
                    self.handle_key(key, app)?;
                }
            }
        }

        Ok(())
    }

    fn handle_key(&mut self, key: KeyEvent, app: &mut App) -> Result<()> {
        match app.mode {
            Mode::View => self.handle_view_mode(key, app),
            Mode::Edit => self.handle_edit_mode(key, app),
            Mode::Command => self.handle_command_mode(key, app),
            Mode::Search => self.handle_search_mode(key, app),
        }
    }

    fn handle_search_mode(&mut self, key: KeyEvent, app: &mut App) -> Result<()> {
        match key.code {
            KeyCode::Enter => {
                if let Some(path) = app.search_results.get(app.search_selected) {
                    let path = path.clone();
                    if let Err(e) = app.open_note(&path) {
                        app.set_error(format!("Failed to open: {}", e));
                    } else {
                        app.mode = Mode::View;
                    }
                }
            }
            KeyCode::Esc => {
                app.mode = Mode::View;
                app.search_query.clear();
                app.search_results.clear();
            }
            KeyCode::Up => {
                if app.search_selected > 0 {
                    app.search_selected -= 1;
                }
            }
            KeyCode::Down => {
                if app.search_selected < app.search_results.len().saturating_sub(1) {
                    app.search_selected += 1;
                }
            }
            KeyCode::Char(c) => {
                app.search_query.push(c);
                if let Err(e) = app.perform_search() {
                    app.set_error(format!("Search error: {}", e));
                }
            }
            KeyCode::Backspace => {
                app.search_query.pop();
                if let Err(e) = app.perform_search() {
                    app.set_error(format!("Search error: {}", e));
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_view_mode(&mut self, key: KeyEvent, app: &mut App) -> Result<()> {
        match key.code {
            KeyCode::Char('q') => {
                self.should_quit = true;
            }
            KeyCode::Char('e') => {
                if app.current_note.is_some() {
                    app.edit_content = app.get_current_note_content().unwrap_or_default();
                    app.edit_cursor = app.edit_content.len();
                    app.mode = Mode::Edit;
                }
            }
            KeyCode::Char('n') => {
                app.mode = Mode::Command;
                app.command_input = String::from(":new ");
            }
            KeyCode::Char('d') => {
                if let Some(ref path) = app.current_note {
                    let path = path.clone();
                    if let Err(e) = app.delete_note(&path) {
                        app.set_error(format!("Failed to delete: {}", e));
                    }
                }
            }
            KeyCode::Char('/') => {
                app.mode = Mode::Search;
                app.search_query.clear();
                app.search_results.clear();
            }
            KeyCode::Up => {
                if app.sidebar_selected > 0 {
                    app.sidebar_selected -= 1;
                }
            }
            KeyCode::Down => {
                let items = app.file_manager.list_items().unwrap_or_default();
                if app.sidebar_selected < items.len().saturating_sub(1) {
                    app.sidebar_selected += 1;
                }
            }
            KeyCode::Enter => {
                let items = app.file_manager.list_items().unwrap_or_default();
                if let Some(item) = items.get(app.sidebar_selected) {
                    if let Err(e) = app.open_note(item.path()) {
                        app.set_error(format!("Failed to open: {}", e));
                    }
                }
            }
            KeyCode::Esc => {
                app.search_mode = false;
                app.search_query.clear();
                app.search_results.clear();
                app.clear_error();
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_edit_mode(&mut self, key: KeyEvent, app: &mut App) -> Result<()> {
        match key.code {
            KeyCode::Esc => {
                // Reload content from disk to discard changes
                if let Some(ref path) = app.current_note {
                    app.edit_content = app.file_manager.read_note(path).unwrap_or_default();
                    app.edit_cursor = app.edit_content.len();
                }
                app.mode = Mode::View;
            }
            KeyCode::Char('s') if key.modifiers == crossterm::event::KeyModifiers::CONTROL => {
                // Save (Ctrl+S)
                if let Err(e) = app.save_current_note() {
                    app.set_error(format!("Failed to save: {}", e));
                } else {
                    app.mode = Mode::View;
                }
            }
            KeyCode::Left => {
                if app.edit_cursor > 0 {
                    app.edit_cursor -= 1;
                }
            }
            KeyCode::Right => {
                if app.edit_cursor < app.edit_content.len() {
                    app.edit_cursor += 1;
                }
            }
            KeyCode::Home => {
                app.edit_cursor = 0;
            }
            KeyCode::End => {
                app.edit_cursor = app.edit_content.len();
            }
            KeyCode::Backspace => {
                if app.edit_cursor > 0 {
                    app.edit_content.remove(app.edit_cursor - 1);
                    app.edit_cursor -= 1;
                }
            }
            KeyCode::Delete => {
                if app.edit_cursor < app.edit_content.len() {
                    app.edit_content.remove(app.edit_cursor);
                }
            }
            KeyCode::Enter => {
                app.edit_content.insert(app.edit_cursor, '\n');
                app.edit_cursor += 1;
            }
            KeyCode::Char(c) => {
                app.edit_content.insert(app.edit_cursor, c);
                app.edit_cursor += 1;
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_command_mode(&mut self, key: KeyEvent, app: &mut App) -> Result<()> {
        match key.code {
            KeyCode::Enter => {
                let cmd = app.command_input.trim().to_string();
                app.command_input.clear();
                if cmd.starts_with(":new ") {
                    let name = cmd.strip_prefix(":new ").unwrap_or("");
                    if !name.is_empty() {
                        if let Err(e) = app.create_note(name) {
                            app.set_error(format!("Failed to create note: {}", e));
                        }
                    }
                } else if cmd.starts_with(":delete ") {
                    let name = cmd.strip_prefix(":delete ").unwrap_or("");
                    if !name.is_empty() {
                        let notes_dir = app.file_manager.get_notes_dir().to_path_buf();
                        let path = notes_dir.join(name);
                        if let Err(e) = app.delete_note(&path) {
                            app.set_error(format!("Failed to delete: {}", e));
                        }
                    }
                }
                app.mode = Mode::View;
            }
            KeyCode::Esc => {
                app.command_input.clear();
                app.mode = Mode::View;
            }
            KeyCode::Char(c) => {
                app.command_input.push(c);
            }
            KeyCode::Backspace => {
                app.command_input.pop();
            }
            _ => {}
        }
        Ok(())
    }
}

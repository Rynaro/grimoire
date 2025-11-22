use crate::file_manager::FileManager;
use crate::notes::Note;
use crate::search::Search;
use crate::ui::{render, AppMode, UIState};
use anyhow::Result;
use crossterm::event::KeyCode;
use ratatui::Frame;
use std::path::{Path, PathBuf};

pub struct App {
    pub file_manager: FileManager,
    pub current_note: Option<Note>,
    pub ui_state: UIState,
    pub search: Search,
    pub notes_dir: PathBuf,
}

impl App {
    pub fn new() -> Result<Self> {
        let notes_dir = Path::new("notes").to_path_buf();
        let file_manager = FileManager::new(&notes_dir)?;
        let ui_state = UIState::new();
        let search = Search::new();

        Ok(Self {
            file_manager,
            current_note: None,
            ui_state,
            search,
            notes_dir,
        })
    }

    pub fn render(&mut self, f: &mut Frame) {
        render(f, self);
    }

    pub fn handle_key_event(&mut self, key: KeyCode) -> bool {
        match self.ui_state.mode {
            AppMode::Normal => self.handle_normal_mode(key),
            AppMode::Search => self.handle_search_mode(key),
            AppMode::Command => self.handle_command_mode(key),
            AppMode::Insert => self.handle_insert_mode(key),
        }
    }

    fn handle_normal_mode(&mut self, key: KeyCode) -> bool {
        match key {
            KeyCode::Char('q') => return true,
            KeyCode::Char('j') | KeyCode::Down => {
                let max_items = self.file_manager.items().len().saturating_sub(1);
                if self.ui_state.selected_index < max_items {
                    self.ui_state.select_next();
                    self.load_selected_note();
                }
            }
            KeyCode::Char('k') | KeyCode::Up => {
                if self.ui_state.selected_index > 0 {
                    self.ui_state.select_previous();
                    self.load_selected_note();
                }
            }
            KeyCode::Char('n') => {
                self.create_new_note();
            }
            KeyCode::Char('d') => {
                self.delete_selected_item();
            }
            KeyCode::Char('e') => {
                self.ui_state.mode = AppMode::Insert;
            }
            KeyCode::Char('/') => {
                self.ui_state.mode = AppMode::Search;
                self.search.reset();
            }
            KeyCode::Char(':') => {
                self.ui_state.mode = AppMode::Command;
                self.ui_state.command_buffer.clear();
            }
            KeyCode::Enter => {
                if self.ui_state.selected_index < self.file_manager.items().len() {
                    self.load_selected_note();
                }
            }
            KeyCode::Tab => {
                self.ui_state.toggle_sidebar();
            }
            KeyCode::Esc => {
                self.current_note = None;
            }
            _ => {}
        }
        false
    }

    fn handle_search_mode(&mut self, key: KeyCode) -> bool {
        match key {
            KeyCode::Esc => {
                self.ui_state.mode = AppMode::Normal;
                self.search.reset();
            }
            KeyCode::Enter => {
                self.perform_search();
                self.ui_state.mode = AppMode::Normal;
            }
            KeyCode::Backspace => {
                self.search.query.pop();
            }
            KeyCode::Char(c) => {
                self.search.query.push(c);
            }
            _ => {}
        }
        false
    }

    fn handle_command_mode(&mut self, key: KeyCode) -> bool {
        match key {
            KeyCode::Esc => {
                self.ui_state.mode = AppMode::Normal;
                self.ui_state.command_buffer.clear();
            }
            KeyCode::Enter => {
                self.execute_command();
                self.ui_state.mode = AppMode::Normal;
            }
            KeyCode::Backspace => {
                self.ui_state.command_buffer.pop();
            }
            KeyCode::Char(c) => {
                self.ui_state.command_buffer.push(c);
            }
            _ => {}
        }
        false
    }

    fn handle_insert_mode(&mut self, key: KeyCode) -> bool {
        match key {
            KeyCode::Esc => {
                self.save_current_note();
                self.ui_state.mode = AppMode::Normal;
            }
            KeyCode::Char(c) => {
                if let Some(ref mut note) = self.current_note {
                    note.content.push(c);
                }
            }
            KeyCode::Backspace => {
                if let Some(ref mut note) = self.current_note {
                    note.content.pop();
                }
            }
            KeyCode::Enter => {
                if let Some(ref mut note) = self.current_note {
                    note.content.push('\n');
                }
            }
            _ => {}
        }
        false
    }

    fn load_selected_note(&mut self) {
        if let Some(item) = self.file_manager.items().get(self.ui_state.selected_index) {
            if item.is_file {
                if let Ok(note) = Note::load(&item.path) {
                    self.current_note = Some(note);
                }
            }
        }
    }

    fn create_new_note(&mut self) {
        if let Ok(note_path) = self.file_manager.create_new_note() {
            if let Ok(note) = Note::load(&note_path) {
                self.current_note = Some(note);
                self.ui_state.mode = AppMode::Insert;
                if let Err(_) = self.file_manager.refresh() {
                    // Ignore refresh errors
                }
                // Select the new note
                if let Some(idx) = self.file_manager.items().iter().position(|item| item.path == note_path) {
                    self.ui_state.selected_index = idx;
                    self.ui_state.list_state.select(Some(idx));
                }
            }
        }
    }

    fn delete_selected_item(&mut self) {
        if let Some(item) = self.file_manager.items().get(self.ui_state.selected_index) {
            if self.file_manager.delete_item(&item.path).is_ok() {
                if let Err(_) = self.file_manager.refresh() {
                    // Ignore refresh errors
                }
                let new_len = self.file_manager.items().len();
                if self.ui_state.selected_index >= new_len && new_len > 0 {
                    self.ui_state.selected_index = new_len.saturating_sub(1);
                    self.ui_state.list_state.select(Some(self.ui_state.selected_index));
                } else if new_len == 0 {
                    self.ui_state.selected_index = 0;
                    self.ui_state.list_state.select(None);
                }
                self.current_note = None;
            }
        }
    }

    fn save_current_note(&mut self) {
        if let Some(ref note) = self.current_note {
            if let Err(_) = note.save() {
                // Error saving - could show in UI later
            }
            if let Err(_) = self.file_manager.refresh() {
                // Ignore refresh errors
            }
        }
    }

    fn perform_search(&mut self) {
        self.file_manager.search(&self.search.query);
    }

    fn execute_command(&mut self) {
        let cmd = self.ui_state.command_buffer.trim();
        match cmd {
            "w" | "write" => self.save_current_note(),
            "q" | "quit" => {}
            _ => {}
        }
    }
}

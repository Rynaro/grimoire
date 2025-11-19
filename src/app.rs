use crate::components::{note_view::NoteView, sidebar::Sidebar};
use crate::state::AppState;
use crate::file_manager::FileManager;
use anyhow::Result;
use crossterm::event::KeyEvent;
use ratatui::{
    layout::{Constraint, Direction, Layout},
    Frame,
};

pub struct App {
    state: AppState,
    file_manager: FileManager,
    sidebar: Sidebar,
    note_view: NoteView,
}

impl App {
    pub fn new() -> Result<Self> {
        let file_manager = FileManager::new()?;
        let state = AppState::new(&file_manager)?;
        let sidebar = Sidebar::new();
        let note_view = NoteView::new();

        Ok(Self {
            state,
            file_manager,
            sidebar,
            note_view,
        })
    }

    pub fn ui(&mut self, f: &mut Frame) {
        let chunks = Layout::default()
            .direction(Direction::Horizontal)
            .constraints([Constraint::Percentage(25), Constraint::Percentage(75)].as_ref())
            .split(f.size());

        self.sidebar.render(f, chunks[0], &mut self.state);
        self.note_view.render(f, chunks[1], &mut self.state);
    }

    pub fn handle_input(&mut self, key: KeyEvent) -> bool {
        match self.state.mode {
            crate::state::Mode::Normal => self.handle_normal_mode(key),
            crate::state::Mode::Insert => self.handle_insert_mode(key),
            crate::state::Mode::Command => self.handle_command_mode(key),
        }
    }

    fn handle_normal_mode(&mut self, key: KeyEvent) -> bool {
        use crossterm::event::{KeyCode, KeyModifiers};
        
        match key.code {
            KeyCode::Char('q') if key.modifiers.contains(KeyModifiers::CONTROL) => return true,
            KeyCode::Char('j') | KeyCode::Down => self.state.move_down(),
            KeyCode::Char('k') | KeyCode::Up => self.state.move_up(),
            KeyCode::Char('h') | KeyCode::Left => self.state.focus_sidebar(),
            KeyCode::Char('l') | KeyCode::Right => self.state.focus_note(),
            KeyCode::Enter => self.state.select_item(),
            KeyCode::Char('i') => self.state.set_mode(crate::state::Mode::Insert),
            KeyCode::Char(':') => self.state.set_mode(crate::state::Mode::Command),
            KeyCode::Char('n') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.state.create_new_note();
            }
            KeyCode::Char('d') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                self.state.delete_current_item();
            }
            KeyCode::Char('/') => {
                self.state.start_search();
                self.state.set_mode(crate::state::Mode::Command);
                self.state.command = "/".to_string();
            }
            KeyCode::Esc => self.state.clear_selection(),
            KeyCode::Char('f') if key.modifiers.contains(KeyModifiers::CONTROL) => {
                // Follow wiki-link under cursor (simplified - just search for links)
                if let Some(ref note) = self.state.current_note {
                    let links = crate::utils::extract_wiki_links(&note.content);
                    if let Some(link) = links.first() {
                        self.state.navigate_to_wiki_link(link);
                    }
                }
            }
            _ => {}
        }
        false
    }

    fn handle_insert_mode(&mut self, key: KeyEvent) -> bool {
        use crossterm::event::KeyCode;
        
        match key.code {
            KeyCode::Esc => {
                self.state.set_mode(crate::state::Mode::Normal);
                self.state.save_current_note(&self.file_manager);
            }
            KeyCode::Char(c) => {
                self.state.insert_char(c);
            }
            KeyCode::Backspace => {
                self.state.delete_char();
            }
            KeyCode::Enter => {
                self.state.insert_newline();
            }
            _ => {}
        }
        false
    }

    fn handle_command_mode(&mut self, key: KeyEvent) -> bool {
        use crossterm::event::KeyCode;
        
        match key.code {
            KeyCode::Esc => {
                self.state.set_mode(crate::state::Mode::Normal);
                self.state.clear_command();
                self.state.is_searching = false;
            }
            KeyCode::Enter => {
                if self.state.is_searching {
                    // Handle search
                    let query = if self.state.command.starts_with("/") {
                        &self.state.command[1..]
                    } else {
                        &self.state.command
                    };
                    if let Ok(results) = self.file_manager.search_content(query) {
                        if let Some((path, _)) = results.first() {
                            if let Ok(content) = std::fs::read_to_string(path) {
                                self.state.current_note = Some(crate::state::Note::new(path.clone(), content));
                                self.state.focus = crate::state::Focus::Note;
                            }
                        }
                    }
                    self.state.is_searching = false;
                } else {
                    self.state.execute_command(&mut self.file_manager);
                }
                self.state.set_mode(crate::state::Mode::Normal);
                self.state.clear_command();
            }
            KeyCode::Char(c) => {
                self.state.append_to_command(c);
            }
            KeyCode::Backspace => {
                self.state.delete_command_char();
            }
            _ => {}
        }
        false
    }
}

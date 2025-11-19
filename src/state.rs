use crate::file_manager::FileManager;
use std::path::PathBuf;
use std::fs;
use anyhow::Result;
use ratatui::widgets::ListState;

#[derive(Clone, Copy, PartialEq)]
pub enum Mode {
    Normal,
    Insert,
    Command,
}

#[derive(Clone)]
pub struct Note {
    pub path: PathBuf,
    pub content: String,
    pub title: String,
}

impl Note {
    pub fn new(path: PathBuf, content: String) -> Self {
        let title = path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("Untitled")
            .to_string();
        Self {
            path,
            content,
            title,
        }
    }
}

pub struct AppState {
    pub mode: Mode,
    pub notes_dir: PathBuf,
    pub items: Vec<Item>,
    pub list_state: ListState,
    pub current_note: Option<Note>,
    pub focus: Focus,
    pub command: String,
    pub search_query: String,
    pub is_searching: bool,
}

#[derive(Clone)]
pub enum Item {
    Folder(PathBuf),
    Note(PathBuf),
}

#[derive(Clone, Copy, PartialEq)]
pub enum Focus {
    Sidebar,
    Note,
}

impl AppState {
    pub fn new(file_manager: &FileManager) -> Result<Self> {
        let notes_dir = file_manager.get_notes_dir();
        let items = file_manager.list_items(&notes_dir)?;

        let mut list_state = ListState::default();
        list_state.select(Some(0));
        
        Ok(Self {
            mode: Mode::Normal,
            notes_dir,
            items,
            list_state,
            current_note: None,
            focus: Focus::Sidebar,
            command: String::new(),
            search_query: String::new(),
            is_searching: false,
        })
    }

    pub fn move_up(&mut self) {
        if self.focus == Focus::Sidebar {
            let i = self.list_state.selected().unwrap_or(0);
            if i > 0 {
                self.list_state.select(Some(i - 1));
            }
        }
    }

    pub fn move_down(&mut self) {
        if self.focus == Focus::Sidebar {
            let i = self.list_state.selected().unwrap_or(0);
            if i < self.items.len().saturating_sub(1) {
                self.list_state.select(Some(i + 1));
            }
        }
    }

    pub fn focus_sidebar(&mut self) {
        self.focus = Focus::Sidebar;
    }

    pub fn focus_note(&mut self) {
        self.focus = Focus::Note;
    }

    pub fn select_item(&mut self) {
        if self.focus == Focus::Sidebar {
            if let Some(selected) = self.list_state.selected() {
                if selected < self.items.len() {
                    let item = &self.items[selected];
                    match item {
                        Item::Note(path) => {
                            if let Ok(content) = fs::read_to_string(path) {
                                self.current_note = Some(Note::new(path.clone(), content));
                                self.focus = Focus::Note;
                            }
                        }
                        Item::Folder(path) => {
                            // Navigate into folder
                            if let Ok(new_items) = FileManager::new().and_then(|fm| fm.list_items(path)) {
                                self.items = new_items;
                                self.list_state.select(Some(0));
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn set_mode(&mut self, mode: Mode) {
        self.mode = mode;
    }

    pub fn create_new_note(&mut self) {
        // Create a new note with timestamp
        use chrono::Local;
        let timestamp = Local::now().format("%Y%m%d_%H%M%S");
        let filename = format!("note_{}.md", timestamp);
        let path = self.notes_dir.join(&filename);
        
        if let Ok(_) = fs::write(&path, "# New Note\n\n") {
            if let Ok(items) = FileManager::new().and_then(|fm| fm.list_items(&self.notes_dir)) {
                self.items = items;
                // Find and select the new note
                if let Some(pos) = self.items.iter().position(|item| {
                    matches!(item, Item::Note(p) if p == &path)
                }) {
                    self.list_state.select(Some(pos));
                    self.current_note = Some(Note::new(path, "# New Note\n\n".to_string()));
                    self.focus = Focus::Note;
                    self.mode = Mode::Insert;
                }
            }
        }
    }

    pub fn delete_current_item(&mut self) {
        if self.focus == Focus::Sidebar {
            if let Some(selected) = self.list_state.selected() {
                if selected < self.items.len() {
                    let item = &self.items[selected];
                    match item {
                        Item::Note(path) | Item::Folder(path) => {
                            if let Ok(_) = fs::remove_file(path).or_else(|_| fs::remove_dir_all(path)) {
                                if let Ok(items) = FileManager::new().and_then(|fm| fm.list_items(&self.notes_dir)) {
                                    self.items = items;
                                    let new_selected = if selected >= self.items.len() && selected > 0 {
                                        Some(selected - 1)
                                    } else if !self.items.is_empty() {
                                        Some(selected.min(self.items.len() - 1))
                                    } else {
                                        None
                                    };
                                    self.list_state.select(new_selected);
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    pub fn start_search(&mut self) {
        self.is_searching = true;
        self.search_query.clear();
    }

    pub fn clear_selection(&mut self) {
        self.current_note = None;
        self.focus = Focus::Sidebar;
    }

    pub fn insert_char(&mut self, c: char) {
        if let Some(ref mut note) = self.current_note {
            note.content.push(c);
        }
    }

    pub fn delete_char(&mut self) {
        if let Some(ref mut note) = self.current_note {
            note.content.pop();
        }
    }

    pub fn insert_newline(&mut self) {
        if let Some(ref mut note) = self.current_note {
            note.content.push('\n');
        }
    }

    pub fn save_current_note(&mut self, _file_manager: &FileManager) {
        if let Some(ref note) = self.current_note {
            if let Err(e) = fs::write(&note.path, &note.content) {
                eprintln!("Error saving note: {}", e);
            }
        }
    }

    pub fn append_to_command(&mut self, c: char) {
        self.command.push(c);
    }

    pub fn delete_command_char(&mut self) {
        self.command.pop();
    }

    pub fn clear_command(&mut self) {
        self.command.clear();
    }

    pub fn execute_command(&mut self, file_manager: &FileManager) {
        let cmd = self.command.trim();
        if cmd.starts_with(":") {
            let cmd = &cmd[1..];
            match cmd {
                "q" | "quit" => {
                    // Quit handled in main
                }
                "w" | "write" => {
                    self.save_current_note(file_manager);
                }
                _ if cmd.starts_with("search ") => {
                    let query = &cmd[7..];
                    if let Ok(results) = file_manager.search_content(query) {
                        // For now, just open the first result
                        if let Some((path, _)) = results.first() {
                            if let Ok(content) = std::fs::read_to_string(path) {
                                self.current_note = Some(Note::new(path.clone(), content));
                                self.focus = Focus::Note;
                            }
                        }
                    }
                }
                _ => {}
            }
        }
        self.command.clear();
    }
    
    pub fn navigate_to_wiki_link(&mut self, link: &str) {
        if let Some(ref note) = self.current_note {
            if let Some(path) = crate::utils::resolve_wiki_link(link, &note.path) {
                if let Ok(content) = std::fs::read_to_string(&path) {
                    self.current_note = Some(Note::new(path, content));
                }
            }
        }
    }
}

use crate::file_manager::FileManager;
use crate::markdown::MarkdownRenderer;
use std::io;
use std::path::PathBuf;

#[derive(PartialEq)]
pub enum Mode {
    Viewing,
    Editing,
    Searching,
}

pub struct App {
    pub mode: Mode,
    pub file_manager: FileManager,
    pub current_note: Option<PathBuf>,
    pub note_content: String,
    pub sidebar_selected: usize,
    pub sidebar_items: Vec<SidebarItem>,
    pub search_query: String,
    pub focus: Focus,
    pub markdown_renderer: MarkdownRenderer,
}

pub enum Focus {
    Sidebar,
    Editor,
}

#[derive(Clone, PartialEq)]
pub enum SidebarItem {
    Folder(PathBuf),
    Note(PathBuf),
}

impl App {
    pub fn new() -> io::Result<Self> {
        let notes_dir = Self::get_notes_directory()?;
        let mut file_manager = FileManager::new(&notes_dir);
        file_manager.scan_directory()?;

        let sidebar_items = file_manager.get_sidebar_items();
        let markdown_renderer = MarkdownRenderer::new();

        Ok(Self {
            mode: Mode::Viewing,
            file_manager,
            current_note: None,
            note_content: String::new(),
            sidebar_selected: 0,
            sidebar_items,
            search_query: String::new(),
            focus: Focus::Sidebar,
            markdown_renderer,
        })
    }

    fn get_notes_directory() -> io::Result<PathBuf> {
        let home = std::env::var("HOME").map_err(|_| {
            io::Error::new(io::ErrorKind::NotFound, "HOME environment variable not set")
        })?;
        let notes_dir = PathBuf::from(home).join(".grimoire");
        
        if !notes_dir.exists() {
            std::fs::create_dir_all(&notes_dir)?;
        }
        
        Ok(notes_dir)
    }

    pub fn navigate_up(&mut self) {
        match self.focus {
            Focus::Sidebar => {
                if self.sidebar_selected > 0 {
                    self.sidebar_selected -= 1;
                }
            }
            Focus::Editor => {
                // Editor navigation handled separately
            }
        }
    }

    pub fn navigate_down(&mut self) {
        match self.focus {
            Focus::Sidebar => {
                if self.sidebar_selected < self.sidebar_items.len().saturating_sub(1) {
                    self.sidebar_selected += 1;
                }
            }
            Focus::Editor => {
                // Editor navigation handled separately
            }
        }
    }

    pub fn select_item(&mut self) {
        if let Some(item) = self.sidebar_items.get(self.sidebar_selected) {
            match item {
                SidebarItem::Note(path) => {
                    self.load_note(path.clone());
                    self.focus = Focus::Editor;
                }
                SidebarItem::Folder(_) => {
                    // Could implement folder expansion here
                }
            }
        }
    }

    pub fn load_note(&mut self, path: PathBuf) {
        if let Ok(content) = std::fs::read_to_string(&path) {
            self.current_note = Some(path);
            self.note_content = content;
            self.mode = Mode::Viewing;
        }
    }

    pub fn create_new_note(&mut self) -> io::Result<()> {
        let timestamp = chrono::Local::now().format("%Y%m%d_%H%M%S");
        let filename = format!("note_{}.md", timestamp);
        let path = self.file_manager.notes_dir.join(&filename);
        
        std::fs::write(&path, "# New Note\n\n")?;
        self.file_manager.scan_directory()?;
        self.sidebar_items = self.file_manager.get_sidebar_items();
        
        // Find and select the new note
        if let Some(pos) = self.sidebar_items.iter().position(|item| {
            matches!(item, SidebarItem::Note(p) if p == &path)
        }) {
            self.sidebar_selected = pos;
            self.load_note(path);
        }
        
        Ok(())
    }

    pub fn delete_current_note(&mut self) -> io::Result<()> {
        if let Some(ref path) = self.current_note {
            std::fs::remove_file(path)?;
            self.current_note = None;
            self.note_content.clear();
            self.file_manager.scan_directory()?;
            self.sidebar_items = self.file_manager.get_sidebar_items();
            if self.sidebar_selected >= self.sidebar_items.len() {
                self.sidebar_selected = self.sidebar_items.len().saturating_sub(1);
            }
        }
        Ok(())
    }

    pub fn toggle_focus(&mut self) {
        self.focus = match self.focus {
            Focus::Sidebar => Focus::Editor,
            Focus::Editor => Focus::Sidebar,
        };
    }

    pub fn handle_backspace(&mut self) {
        match self.mode {
            Mode::Searching => {
                self.search_query.pop();
            }
            Mode::Editing => {
                // Editor backspace handled by input handling
            }
            _ => {}
        }
    }

    pub fn handle_input(&mut self, key: crossterm::event::KeyEvent) {
        match self.mode {
            Mode::Editing => {
                match key.code {
                    crossterm::event::KeyCode::Char(c) => {
                        self.note_content.push(c);
                    }
                    crossterm::event::KeyCode::Backspace => {
                        self.note_content.pop();
                    }
                    crossterm::event::KeyCode::Enter => {
                        self.note_content.push('\n');
                    }
                    _ => {}
                }
                
                // Auto-save
                if let Some(ref path) = self.current_note {
                    let _ = std::fs::write(path, &self.note_content);
                }
            }
            Mode::Searching => {
                match key.code {
                    crossterm::event::KeyCode::Char(c) => {
                        self.search_query.push(c);
                        self.perform_search();
                    }
                    _ => {}
                }
            }
            Mode::Viewing => {
                // Handle link navigation with 'l' key or Enter on links
                if let crossterm::event::KeyCode::Char('l') = key.code {
                    self.navigate_to_linked_note();
                }
            }
        }
    }

    pub fn navigate_to_linked_note(&mut self) {
        // Extract wiki-style links [[note_name]] or markdown links
        let links = self.markdown_renderer.extract_note_links(&self.note_content, &self.file_manager.notes_dir);
        
        if let Some(first_link) = links.first() {
            // Try to find the note by name
            for item in &self.file_manager.get_sidebar_items() {
                if let SidebarItem::Note(path) = item {
                    let note_name = path.file_stem()
                        .and_then(|n| n.to_str())
                        .unwrap_or("");
                    
                    if note_name.contains(first_link) || first_link.contains(note_name) {
                        self.load_note(path.clone());
                        return;
                    }
                }
            }
        }
    }

    pub fn perform_search(&mut self) {
        if self.search_query.is_empty() {
            self.sidebar_items = self.file_manager.get_sidebar_items();
            return;
        }

        let query = self.search_query.to_lowercase();
        let mut results = Vec::new();

        // Search in filenames
        for item in &self.file_manager.get_sidebar_items() {
            if let SidebarItem::Note(path) = item {
                if path.file_name()
                    .and_then(|n| n.to_str())
                    .map(|s| s.to_lowercase().contains(&query))
                    .unwrap_or(false)
                {
                    results.push(item.clone());
                }
            }
        }

        // Search in content
        for item in &self.file_manager.get_sidebar_items() {
            if let SidebarItem::Note(path) = item {
                if let Ok(content) = std::fs::read_to_string(path) {
                    if content.to_lowercase().contains(&query) {
                        if !results.contains(item) {
                            results.push(item.clone());
                        }
                    }
                }
            }
        }

        self.sidebar_items = results;
        if !self.sidebar_items.is_empty() && self.sidebar_selected >= self.sidebar_items.len() {
            self.sidebar_selected = 0;
        }
    }
}

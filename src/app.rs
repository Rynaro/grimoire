use crate::file_manager::FileManager;
use anyhow::Result;
use std::path::{Path, PathBuf};

#[derive(PartialEq)]
pub enum Mode {
    View,
    Edit,
    Command,
    Search,
}

pub struct App {
    pub file_manager: FileManager,
    pub current_note: Option<PathBuf>,
    pub mode: Mode,
    pub sidebar_selected: usize,
    pub command_input: String,
    pub error_message: Option<String>,
    pub search_query: String,
    pub search_mode: bool,
    pub edit_content: String,
    pub edit_cursor: usize,
    pub search_results: Vec<PathBuf>,
    pub search_selected: usize,
}

impl App {
    pub fn new() -> Result<Self> {
        let file_manager = FileManager::new()?;
        Ok(Self {
            file_manager,
            current_note: None,
            mode: Mode::View,
            sidebar_selected: 0,
            command_input: String::new(),
            error_message: None,
            search_query: String::new(),
            search_mode: false,
            edit_content: String::new(),
            edit_cursor: 0,
            search_results: Vec::new(),
            search_selected: 0,
        })
    }

    pub fn open_note(&mut self, path: &Path) -> Result<()> {
        self.current_note = Some(path.to_path_buf());
        self.edit_content = self.get_current_note_content().unwrap_or_default();
        self.edit_cursor = self.edit_content.len();
        self.mode = Mode::View;
        Ok(())
    }

    pub fn create_note(&mut self, name: &str) -> Result<()> {
        let path = self.file_manager.create_note(name)?;
        self.current_note = Some(path);
        self.edit_content = String::new();
        self.edit_cursor = 0;
        self.mode = Mode::Edit;
        Ok(())
    }

    pub fn delete_note(&mut self, path: &Path) -> Result<()> {
        self.file_manager.delete_note(path)?;
        if self.current_note.as_ref().map(|p| p.as_path()) == Some(path) {
            self.current_note = None;
        }
        Ok(())
    }

    pub fn get_current_note_content(&self) -> Result<String> {
        if let Some(ref path) = self.current_note {
            self.file_manager.read_note(path)
        } else {
            Ok(String::new())
        }
    }

    pub fn save_current_note(&mut self) -> Result<()> {
        if let Some(ref path) = self.current_note {
            self.file_manager.write_note(path, &self.edit_content)?;
        }
        Ok(())
    }

    pub fn perform_search(&mut self) -> Result<()> {
        if self.search_query.is_empty() {
            self.search_results = Vec::new();
            return Ok(());
        }
        self.search_results = self.file_manager.search_content(&self.search_query)?;
        self.search_selected = 0;
        Ok(())
    }

    pub fn set_error(&mut self, error: String) {
        self.error_message = Some(error);
    }

    pub fn clear_error(&mut self) {
        self.error_message = None;
    }
}

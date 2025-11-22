use crate::commands::{self, Command};
use crate::editor::EditorState;
use crate::markdown::{self, RenderedNote};
use crate::storage::{
    create_folder, create_note, delete_folder, delete_note, ensure_workspace, list_folders,
    list_notes, read_note, search_notes, write_note, FolderEntry, NoteEntry, SearchResult,
};
use anyhow::{Context, Result};
use crossterm::event::{KeyCode, KeyEvent, KeyEventKind, KeyModifiers};
use std::path::{Path, PathBuf};
use std::time::{Duration, Instant};

const COMMAND_PREFIX: char = ':';
const SEARCH_PREFIX: char = '/';
const STATUS_TTL: Duration = Duration::from_secs(6);

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Panel {
    Sidebar,
    Notes,
    Viewer,
}

impl Panel {
    pub fn next(self) -> Panel {
        match self {
            Panel::Sidebar => Panel::Notes,
            Panel::Notes => Panel::Viewer,
            Panel::Viewer => Panel::Sidebar,
        }
    }

    pub fn previous(self) -> Panel {
        match self {
            Panel::Sidebar => Panel::Viewer,
            Panel::Notes => Panel::Sidebar,
            Panel::Viewer => Panel::Notes,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InputMode {
    Normal,
    Command,
    Search,
    Editing,
}

#[derive(Clone, Debug)]
pub struct StatusMessage {
    pub text: String,
    pub level: StatusLevel,
    pub created_at: Instant,
}

#[derive(Clone, Debug)]
pub enum StatusLevel {
    Info,
    Warn,
    Error,
}

pub struct App {
    pub notes_root: PathBuf,
    pub folders: Vec<FolderEntry>,
    pub folder_idx: usize,
    pub notes: Vec<NoteEntry>,
    pub note_idx: usize,
    pub rendered_note: RenderedNote,
    pub current_note: Option<NoteEntry>,
    pub current_note_body: String,
    pub panel: Panel,
    pub mode: InputMode,
    pub command_buffer: String,
    pub search_buffer: String,
    pub search_results: Vec<SearchResult>,
    pub search_idx: usize,
    pub status: Option<StatusMessage>,
    pub should_quit: bool,
    pub viewer_scroll: u16,
    pub show_help: bool,
    pub selected_link: Option<usize>,
    pub editor: Option<EditorState>,
    pub last_viewport_height: u16,
}

impl App {
    pub fn new(notes_root: PathBuf) -> Result<Self> {
        let root = ensure_workspace(&notes_root)?;
        let mut app = Self {
            notes_root: root.clone(),
            folders: Vec::new(),
            folder_idx: 0,
            notes: Vec::new(),
            note_idx: 0,
            rendered_note: RenderedNote {
                lines: vec![],
                links: vec![],
            },
            current_note: None,
            current_note_body: String::new(),
            panel: Panel::Sidebar,
            mode: InputMode::Normal,
            command_buffer: String::new(),
            search_buffer: String::new(),
            search_results: Vec::new(),
            search_idx: 0,
            status: None,
            should_quit: false,
            viewer_scroll: 0,
            show_help: false,
            selected_link: None,
            editor: None,
            last_viewport_height: 0,
        };
        app.refresh_folders()?;
        app.refresh_notes()?;
        app.open_current_note()?;
        Ok(app)
    }

    pub fn tick(&mut self) {
        if let Some(status) = &self.status {
            if status.created_at.elapsed() > STATUS_TTL {
                self.status = None;
            }
        }
    }

    pub fn handle_event(&mut self, key: KeyEvent) -> Result<()> {
        if key.kind != KeyEventKind::Press {
            return Ok(());
        }

        match self.mode {
            InputMode::Normal => self.handle_normal_mode(key),
            InputMode::Command => self.handle_command_mode(key),
            InputMode::Search => self.handle_search_mode(key),
            InputMode::Editing => self.handle_edit_mode(key),
        }
    }

    pub fn set_last_viewport_height(&mut self, height: u16) {
        self.last_viewport_height = height;
        if self.mode == InputMode::Editing {
            self.ensure_editor_cursor_visible();
        } else {
            self.clamp_viewer_scroll();
        }
    }

    pub fn ensure_editor_cursor_visible(&mut self) {
        if let Some(editor) = &self.editor {
            let cursor_line = editor.cursor_line as u16;
            let height = self.last_viewport_height.saturating_sub(2);
            if cursor_line < self.viewer_scroll {
                self.viewer_scroll = cursor_line;
            } else if cursor_line >= self.viewer_scroll + height {
                self.viewer_scroll = cursor_line.saturating_sub(height - 1);
            }
        }
    }

    fn handle_normal_mode(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Char('q') if key.modifiers.is_empty() => self.should_quit = true,
            KeyCode::Char('c') if key.modifiers == KeyModifiers::CONTROL => {
                self.should_quit = true;
            }
            KeyCode::Tab => self.panel = self.panel.next(),
            KeyCode::BackTab => self.panel = self.panel.previous(),
            KeyCode::Char(':') => {
                self.mode = InputMode::Command;
                self.command_buffer.clear();
            }
            KeyCode::Char('/') => {
                self.mode = InputMode::Search;
                self.search_buffer.clear();
                self.search_results.clear();
                self.search_idx = 0;
            }
            KeyCode::Char('e') => {
                self.enter_edit_mode()?;
            }
            KeyCode::Char('r') => {
                self.full_refresh()?;
                self.set_status("Workspace refreshed", StatusLevel::Info);
            }
            KeyCode::Char('h') => {
                self.show_help = !self.show_help;
            }
            KeyCode::Char('[') => self.select_previous_link(),
            KeyCode::Char(']') => self.select_next_link(),
            KeyCode::Left => self.panel = self.panel.previous(),
            KeyCode::Right => self.panel = self.panel.next(),
            KeyCode::Up => self.move_selection(-1)?,
            KeyCode::Down => self.move_selection(1)?,
            KeyCode::PageUp => self.scroll_view(-5),
            KeyCode::PageDown => self.scroll_view(5),
            KeyCode::Enter => self.activate_selection()?,
            _ => {}
        }
        Ok(())
    }

    fn handle_command_mode(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Esc => {
                self.mode = InputMode::Normal;
                self.command_buffer.clear();
            }
            KeyCode::Enter => {
                let input = self.command_buffer.clone();
                self.command_buffer.clear();
                self.mode = InputMode::Normal;
                if !input.trim().is_empty() {
                    match commands::parse(&input) {
                        Ok(cmd) => self.execute_command(cmd)?,
                        Err(err) => self.set_status(&err.to_string(), StatusLevel::Error),
                    }
                }
            }
            KeyCode::Backspace => {
                self.command_buffer.pop();
            }
            KeyCode::Char(ch) => {
                self.command_buffer.push(ch);
            }
            KeyCode::Left => {}
            KeyCode::Right => {}
            _ => {}
        }
        Ok(())
    }

    fn handle_search_mode(&mut self, key: KeyEvent) -> Result<()> {
        match key.code {
            KeyCode::Esc => {
                self.mode = InputMode::Normal;
                self.search_buffer.clear();
                self.search_results.clear();
            }
            KeyCode::Enter => {
                if let Some(result) = self.search_results.get(self.search_idx).cloned() {
                    self.mode = InputMode::Normal;
                    let path = result.path;
                    self.open_note_at_path(&path)?;
                    self.search_buffer.clear();
                    self.search_results.clear();
                }
            }
            KeyCode::Backspace => {
                self.search_buffer.pop();
                self.update_search_results()?;
            }
            KeyCode::Char(ch) => {
                self.search_buffer.push(ch);
                self.update_search_results()?;
            }
            KeyCode::Up => {
                if self.search_idx > 0 {
                    self.search_idx -= 1;
                }
            }
            KeyCode::Down => {
                if self.search_idx + 1 < self.search_results.len() {
                    self.search_idx += 1;
                }
            }
            _ => {}
        }
        Ok(())
    }

    fn handle_edit_mode(&mut self, key: KeyEvent) -> Result<()> {
        let editor = match self.editor.as_mut() {
            Some(editor) => editor,
            None => {
                self.mode = InputMode::Normal;
                return Ok(());
            }
        };

        match key.code {
            KeyCode::Esc => {
                self.mode = InputMode::Normal;
                self.editor = None;
                self.viewer_scroll = 0;
                self.set_status("Canceled changes", StatusLevel::Warn);
            }
            KeyCode::Enter => {
                editor.insert_newline();
            }
            KeyCode::Backspace => editor.backspace(),
            KeyCode::Delete => editor.delete_char(),
            KeyCode::Tab => editor.insert_tab(2),
            KeyCode::Char('s') if key.modifiers == KeyModifiers::CONTROL => {
                self.persist_editor()?;
            }
            KeyCode::Up => {
                if editor.cursor_line > 0 {
                    editor.cursor_line -= 1;
                    editor.clamp_cursor();
                }
            }
            KeyCode::Down => {
                if editor.cursor_line + 1 < editor.lines.len() {
                    editor.cursor_line += 1;
                    editor.clamp_cursor();
                }
            }
            KeyCode::Left => {
                if editor.cursor_col > 0 {
                    editor.cursor_col -= 1;
                } else if editor.cursor_line > 0 {
                    editor.cursor_line -= 1;
                    editor.cursor_col = editor.lines[editor.cursor_line].len();
                }
            }
            KeyCode::Right => {
                if editor.cursor_col < editor.lines[editor.cursor_line].len() {
                    editor.cursor_col += 1;
                } else if editor.cursor_line + 1 < editor.lines.len() {
                    editor.cursor_line += 1;
                    editor.cursor_col = 0;
                }
            }
            KeyCode::Home => editor.move_to_start_of_line(),
            KeyCode::End => editor.move_to_end_of_line(),
            KeyCode::PageUp => self.scroll_view(-5),
            KeyCode::PageDown => self.scroll_view(5),
            KeyCode::Char(ch) => {
                if key.modifiers.is_empty() {
                    editor.insert_char(ch);
                }
            }
            _ => {}
        }

        self.ensure_editor_cursor_visible();
        Ok(())
    }

    pub fn set_status(&mut self, text: &str, level: StatusLevel) {
        self.status = Some(StatusMessage {
            text: text.to_string(),
            level,
            created_at: Instant::now(),
        });
    }

    pub fn should_quit(&self) -> bool {
        self.should_quit
    }

    fn refresh_folders(&mut self) -> Result<()> {
        self.folders = list_folders(&self.notes_root)?;
        if self.folders.is_empty() {
            create_folder(&self.notes_root, "inbox")?;
            self.folders = list_folders(&self.notes_root)?;
        }
        self.folder_idx = self.folder_idx.min(self.folders.len().saturating_sub(1));
        Ok(())
    }

    fn refresh_notes(&mut self) -> Result<()> {
        if let Some(folder) = self.folders.get(self.folder_idx) {
            self.notes = list_notes(&folder.path)?;
            self.note_idx = self.note_idx.min(self.notes.len().saturating_sub(1));
        } else {
            self.notes.clear();
        }
        Ok(())
    }

    fn open_current_note(&mut self) -> Result<()> {
        if let Some(note) = self.notes.get(self.note_idx).cloned() {
            let body = read_note(&note.path)
                .with_context(|| format!("Unable to read note {}", note.path.display()))?;
            self.current_note_body = body;
            self.current_note = Some(note);
        } else {
            self.current_note_body.clear();
            self.current_note = None;
        }
        self.rebuild_markdown();
        Ok(())
    }

    fn rebuild_markdown(&mut self) {
        self.rendered_note = markdown::render_markdown(&self.current_note_body, self.selected_link);
        if self.selected_link.is_some()
            && !self
                .rendered_note
                .links
                .iter()
                .any(|link| Some(link.index) == self.selected_link)
        {
            self.selected_link = None;
        }
    }

    fn move_selection(&mut self, delta: isize) -> Result<()> {
        match self.panel {
            Panel::Sidebar => {
                if self.folders.is_empty() {
                    return Ok(());
                }
                let new_index = clamp_index(self.folder_idx as isize + delta, self.folders.len());
                if new_index != self.folder_idx {
                    self.folder_idx = new_index;
                    self.refresh_notes()?;
                    self.open_current_note()?;
                }
            }
            Panel::Notes => {
                if self.notes.is_empty() {
                    return Ok(());
                }
                let new_index = clamp_index(self.note_idx as isize + delta, self.notes.len());
                if new_index != self.note_idx {
                    self.note_idx = new_index;
                    self.open_current_note()?;
                }
            }
            Panel::Viewer => {
                self.scroll_view(delta as i32);
            }
        }
        Ok(())
    }

    fn scroll_view(&mut self, delta: i32) {
        let max_lines = if self.mode == InputMode::Editing {
            self.editor.as_ref().map(|e| e.lines.len()).unwrap_or(0)
        } else {
            self.rendered_note.lines.len()
        };
        let max_scroll = max_lines.saturating_sub(self.last_viewport_height as usize) as i32;
        let mut new_scroll = self.viewer_scroll as i32 + delta;
        if new_scroll < 0 {
            new_scroll = 0;
        }
        if new_scroll > max_scroll {
            new_scroll = max_scroll;
        }
        self.viewer_scroll = new_scroll.max(0) as u16;
    }

    fn activate_selection(&mut self) -> Result<()> {
        match self.panel {
            Panel::Sidebar => {
                self.panel = Panel::Notes;
            }
            Panel::Notes => {
                self.open_current_note()?;
                self.panel = Panel::Viewer;
            }
            Panel::Viewer => {
                self.follow_selected_link()?;
            }
        }
        Ok(())
    }

    fn enter_edit_mode(&mut self) -> Result<()> {
        if let Some(note) = &self.current_note {
            self.mode = InputMode::Editing;
            self.panel = Panel::Viewer;
            self.editor = Some(EditorState::from_text(&self.current_note_body));
            self.viewer_scroll = 0;
            self.set_status(&format!("Editing {}", note.title), StatusLevel::Info);
        } else {
            self.set_status("No note selected to edit", StatusLevel::Warn);
        }
        Ok(())
    }

    fn persist_editor(&mut self) -> Result<()> {
        if let (Some(editor), Some(note)) = (self.editor.take(), self.current_note.clone()) {
            write_note(&note.path, &editor.as_text())?;
            self.mode = InputMode::Normal;
            self.viewer_scroll = 0;
            self.set_status("Saved changes", StatusLevel::Info);
            self.refresh_notes()?;
            if let Some(idx) = self
                .notes
                .iter()
                .position(|candidate| candidate.path == note.path)
            {
                self.note_idx = idx;
            }
            self.open_current_note()?;
        }
        Ok(())
    }

    fn update_search_results(&mut self) -> Result<()> {
        self.search_results = search_notes(&self.notes_root, &self.search_buffer)?;
        self.search_idx = 0;
        Ok(())
    }

    fn execute_command(&mut self, command: Command) -> Result<()> {
        match command {
            Command::NewNote { title } => self.command_new_note(&title)?,
            Command::NewFolder { name } => self.command_new_folder(&name)?,
            Command::DeleteNote => self.command_delete_note()?,
            Command::DeleteFolder => self.command_delete_folder()?,
            Command::Refresh => {
                self.full_refresh()?;
                self.set_status("Workspace refreshed", StatusLevel::Info);
            }
            Command::Help => {
                self.show_help = !self.show_help;
            }
        }
        Ok(())
    }

    fn command_new_note(&mut self, title: &str) -> Result<()> {
        let folder = self
            .folders
            .get(self.folder_idx)
            .context("No folder selected")?
            .path
            .clone();
        let note_path = create_note(&folder, title)?;
        self.set_status("Note created", StatusLevel::Info);
        self.refresh_notes()?;
        if let Some(idx) = self.notes.iter().position(|note| note.path == note_path) {
            self.note_idx = idx;
            self.open_current_note()?;
        }
        Ok(())
    }

    fn command_new_folder(&mut self, name: &str) -> Result<()> {
        let path = create_folder(&self.notes_root, name)?;
        self.set_status(
            &format!(
                "Folder '{}' created",
                path.file_name().unwrap().to_string_lossy()
            ),
            StatusLevel::Info,
        );
        self.refresh_folders()?;
        if let Some(idx) = self.folders.iter().position(|folder| folder.path == path) {
            self.folder_idx = idx;
            self.refresh_notes()?;
            self.open_current_note()?;
        }
        Ok(())
    }

    fn command_delete_note(&mut self) -> Result<()> {
        if let Some(note) = self.current_note.clone() {
            delete_note(&note.path)?;
            self.set_status("Note deleted", StatusLevel::Warn);
            self.refresh_notes()?;
            self.note_idx = self.note_idx.min(self.notes.len().saturating_sub(1));
            self.open_current_note()?;
        } else {
            self.set_status("No note selected", StatusLevel::Warn);
        }
        Ok(())
    }

    fn command_delete_folder(&mut self) -> Result<()> {
        if self.folders.len() <= 1 {
            self.set_status("Cannot delete the last folder", StatusLevel::Warn);
            return Ok(());
        }
        if let Some(folder) = self.folders.get(self.folder_idx) {
            delete_folder(&folder.path)?;
            self.set_status("Folder deleted", StatusLevel::Warn);
            self.folder_idx = 0;
            self.refresh_folders()?;
            self.refresh_notes()?;
            self.open_current_note()?;
        }
        Ok(())
    }

    fn full_refresh(&mut self) -> Result<()> {
        self.refresh_folders()?;
        self.refresh_notes()?;
        self.open_current_note()?;
        Ok(())
    }

    fn select_next_link(&mut self) {
        if self.rendered_note.links.is_empty() {
            return;
        }
        if let Some(current) = self.selected_link {
            let index = self
                .rendered_note
                .links
                .iter()
                .position(|link| link.index == current);
            let next = index
                .map(|i| (i + 1) % self.rendered_note.links.len())
                .unwrap_or(0);
            self.selected_link = Some(self.rendered_note.links[next].index);
        } else {
            self.selected_link = Some(self.rendered_note.links[0].index);
        }
        self.rebuild_markdown();
    }

    fn select_previous_link(&mut self) {
        if self.rendered_note.links.is_empty() {
            return;
        }
        if let Some(current) = self.selected_link {
            let index = self
                .rendered_note
                .links
                .iter()
                .position(|link| link.index == current)
                .unwrap_or(0);
            let prev = if index == 0 {
                self.rendered_note.links.len() - 1
            } else {
                index - 1
            };
            self.selected_link = Some(self.rendered_note.links[prev].index);
        } else {
            let last = self.rendered_note.links.len() - 1;
            self.selected_link = Some(self.rendered_note.links[last].index);
        }
        self.rebuild_markdown();
    }

    fn follow_selected_link(&mut self) -> Result<()> {
        let selected = match self.selected_link {
            Some(index) => self
                .rendered_note
                .links
                .iter()
                .find(|link| link.index == index)
                .cloned(),
            None => None,
        };

        if let Some(link) = selected {
            if let Some(path) = self.find_note_by_slug(&link.slug)? {
                self.open_note_at_path(&path)?;
                self.set_status(
                    &format!("Opened linked note '{}'", link.label),
                    StatusLevel::Info,
                );
            } else {
                self.set_status(
                    &format!("No note found for [[{}]]", link.label),
                    StatusLevel::Warn,
                );
            }
        }
        Ok(())
    }

    fn find_note_by_slug(&self, slug: &str) -> Result<Option<PathBuf>> {
        for folder in &self.folders {
            let notes = list_notes(&folder.path)?;
            if let Some(note) = notes
                .iter()
                .find(|note| note.filename.trim_end_matches(".md").starts_with(slug))
            {
                return Ok(Some(note.path.clone()));
            }
        }
        Ok(None)
    }

    fn open_note_at_path(&mut self, path: &Path) -> Result<()> {
        let folder_path = path.parent().context("Note without parent folder")?;
        if let Some(idx) = self
            .folders
            .iter()
            .position(|folder| folder.path == folder_path)
        {
            self.folder_idx = idx;
            self.refresh_notes()?;
            if let Some(note_idx) = self.notes.iter().position(|note| note.path == path) {
                self.note_idx = note_idx;
            }
            self.open_current_note()?;
            self.panel = Panel::Viewer;
        }
        Ok(())
    }

    pub fn active_note_title(&self) -> String {
        self.current_note
            .as_ref()
            .map(|note| note.title.clone())
            .unwrap_or_else(|| "No note selected".to_string())
    }

    pub fn active_folder_name(&self) -> String {
        self.folders
            .get(self.folder_idx)
            .map(|folder| folder.name.clone())
            .unwrap_or_else(|| "No folder".to_string())
    }

    pub fn command_prompt(&self) -> String {
        format!("{}{}", COMMAND_PREFIX, self.command_buffer)
    }

    pub fn search_prompt(&self) -> String {
        format!("{}{}", SEARCH_PREFIX, self.search_buffer)
    }

    fn clamp_viewer_scroll(&mut self) {
        let max_lines = self.rendered_note.lines.len();
        if max_lines <= self.last_viewport_height as usize {
            self.viewer_scroll = 0;
            return;
        }
        let max_scroll = max_lines - self.last_viewport_height as usize;
        self.viewer_scroll = self.viewer_scroll.min(max_scroll as u16);
    }
}

fn clamp_index(target: isize, len: usize) -> usize {
    if len == 0 {
        return 0;
    }
    target.clamp(0, (len - 1) as isize) as usize
}

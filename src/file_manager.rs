use crate::app::SidebarItem;
use std::io;
use std::path::{Path, PathBuf};

pub struct FileManager {
    pub notes_dir: PathBuf,
    items: Vec<SidebarItem>,
}

impl FileManager {
    pub fn new(notes_dir: &Path) -> Self {
        Self {
            notes_dir: notes_dir.to_path_buf(),
            items: Vec::new(),
        }
    }

    pub fn scan_directory(&mut self) -> io::Result<()> {
        self.items.clear();
        
        if !self.notes_dir.exists() {
            std::fs::create_dir_all(&self.notes_dir)?;
        }

        let entries: Vec<_> = std::fs::read_dir(&self.notes_dir)?
            .filter_map(|entry| entry.ok())
            .collect();

        // Separate folders and files
        let mut folders = Vec::new();
        let mut notes = Vec::new();

        for entry in entries {
            let path = entry.path();
            if path.is_dir() {
                folders.push(SidebarItem::Folder(path));
            } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
                notes.push(SidebarItem::Note(path));
            }
        }

        // Sort folders and notes
        folders.sort_by(|a, b| {
            let a_path = match a {
                SidebarItem::Folder(p) => p,
                _ => unreachable!(),
            };
            let b_path = match b {
                SidebarItem::Folder(p) => p,
                _ => unreachable!(),
            };
            a_path.cmp(b_path)
        });

        notes.sort_by(|a, b| {
            let a_path = match a {
                SidebarItem::Note(p) => p,
                _ => unreachable!(),
            };
            let b_path = match b {
                SidebarItem::Note(p) => p,
                _ => unreachable!(),
            };
            a_path.cmp(b_path)
        });

        // Combine: folders first, then notes
        self.items.extend(folders);
        self.items.extend(notes);

        Ok(())
    }

    pub fn get_sidebar_items(&self) -> Vec<SidebarItem> {
        self.items.clone()
    }
}

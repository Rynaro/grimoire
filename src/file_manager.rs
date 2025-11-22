use anyhow::Result;
use chrono::{DateTime, Local, TimeZone};
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

#[derive(Clone, Debug)]
pub struct FileItem {
    pub name: String,
    pub path: PathBuf,
    pub is_file: bool,
    pub modified: DateTime<Local>,
}

pub struct FileManager {
    notes_dir: PathBuf,
    items: Vec<FileItem>,
    filtered_items: Vec<FileItem>,
    search_active: bool,
}

impl FileManager {
    pub fn new(notes_dir: &Path) -> Result<Self> {
        let mut fm = Self {
            notes_dir: notes_dir.to_path_buf(),
            items: Vec::new(),
            filtered_items: Vec::new(),
            search_active: false,
        };
        fm.refresh()?;
        Ok(fm)
    }

    pub fn refresh(&mut self) -> Result<()> {
        self.items.clear();
        self.load_items()?;
        if !self.search_active {
            self.filtered_items = self.items.clone();
        }
        Ok(())
    }

    fn load_items(&mut self) -> Result<()> {
        if !self.notes_dir.exists() {
            fs::create_dir_all(&self.notes_dir)?;
        }

        let mut items: Vec<FileItem> = Vec::new();

        // Add folders first
        for entry in WalkDir::new(&self.notes_dir)
            .max_depth(1)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path == self.notes_dir {
                continue;
            }

            let metadata = entry.metadata()?;
            let modified = metadata
                .modified()
                .map(|t| {
                    let secs = t.duration_since(std::time::UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs() as i64;
                    Local.timestamp_opt(secs, 0)
                        .single()
                        .unwrap_or_else(|| Local::now())
                })
                .unwrap_or_else(|_| Local::now());

            let name = path
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_string();

            items.push(FileItem {
                name,
                path: path.to_path_buf(),
                is_file: metadata.is_file(),
                modified,
            });
        }

        // Sort: folders first, then files, both by name
        items.sort_by(|a, b| {
            match (a.is_file, b.is_file) {
                (false, true) => std::cmp::Ordering::Less,
                (true, false) => std::cmp::Ordering::Greater,
                _ => a.name.cmp(&b.name),
            }
        });

        self.items = items;
        Ok(())
    }

    pub fn items(&self) -> &[FileItem] {
        &self.filtered_items
    }

    pub fn create_new_note(&self) -> Result<PathBuf> {
        let timestamp = Local::now().format("%Y%m%d_%H%M%S");
        let filename = format!("note_{}.md", timestamp);
        let path = self.notes_dir.join(&filename);
        
        fs::write(&path, "# New Note\n\n")?;
        Ok(path)
    }

    pub fn delete_item(&self, path: &Path) -> Result<()> {
        if path.is_dir() {
            fs::remove_dir_all(path)?;
        } else {
            fs::remove_file(path)?;
        }
        Ok(())
    }

    pub fn search(&mut self, query: &str) {
        if query.is_empty() {
            self.search_active = false;
            self.filtered_items = self.items.clone();
            return;
        }

        self.search_active = true;
        self.filtered_items = self.items
            .iter()
            .filter(|item| {
                item.name.to_lowercase().contains(&query.to_lowercase())
            })
            .cloned()
            .collect();
    }

    pub fn search_content(&self, query: &str) -> Vec<&FileItem> {
        if query.is_empty() {
            return Vec::new();
        }

        self.items
            .iter()
            .filter(|item| {
                if !item.is_file {
                    return false;
                }
                if let Ok(content) = fs::read_to_string(&item.path) {
                    content.to_lowercase().contains(&query.to_lowercase())
                } else {
                    false
                }
            })
            .collect()
    }
}

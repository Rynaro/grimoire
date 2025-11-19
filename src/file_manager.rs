use crate::state::Item;
use anyhow::Result;
use dirs::home_dir;
use std::path::{Path, PathBuf};
use std::fs;
use walkdir::WalkDir;

pub struct FileManager {
    notes_dir: PathBuf,
}

impl FileManager {
    pub fn new() -> Result<Self> {
        let notes_dir = home_dir()
            .ok_or_else(|| anyhow::anyhow!("Could not find home directory"))?
            .join(".grimoire")
            .join("notes");

        // Create notes directory if it doesn't exist
        fs::create_dir_all(&notes_dir)?;

        Ok(Self { notes_dir })
    }

    pub fn get_notes_dir(&self) -> PathBuf {
        self.notes_dir.clone()
    }

    pub fn list_items(&self, path: &Path) -> Result<Vec<Item>> {
        let mut items = Vec::new();

        if !path.exists() {
            return Ok(items);
        }

        let mut entries: Vec<_> = fs::read_dir(path)?
            .filter_map(|e| e.ok())
            .collect();

        // Sort: folders first, then files, both alphabetically
        entries.sort_by(|a, b| {
            let a_meta = a.metadata().ok();
            let b_meta = b.metadata().ok();
            let a_is_dir = a_meta.map(|m| m.is_dir()).unwrap_or(false);
            let b_is_dir = b_meta.map(|m| m.is_dir()).unwrap_or(false);

            match (a_is_dir, b_is_dir) {
                (true, false) => std::cmp::Ordering::Less,
                (false, true) => std::cmp::Ordering::Greater,
                _ => a.file_name().cmp(&b.file_name()),
            }
        });

        for entry in entries {
            let path = entry.path();
            let metadata = entry.metadata()?;

            if metadata.is_dir() {
                items.push(Item::Folder(path));
            } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
                items.push(Item::Note(path));
            }
        }

        Ok(items)
    }

    pub fn search_files(&self, query: &str) -> Result<Vec<PathBuf>> {
        let mut results = Vec::new();
        let query_lower = query.to_lowercase();

        for entry in WalkDir::new(&self.notes_dir)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("md") {
                if path
                    .file_name()
                    .and_then(|s| s.to_str())
                    .map(|s| s.to_lowercase().contains(&query_lower))
                    .unwrap_or(false)
                {
                    results.push(path.to_path_buf());
                }
            }
        }

        Ok(results)
    }

    pub fn search_content(&self, query: &str) -> Result<Vec<(PathBuf, Vec<String>)>> {
        let mut results = Vec::new();
        let query_lower = query.to_lowercase();

        for entry in WalkDir::new(&self.notes_dir)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("md") {
                if let Ok(content) = fs::read_to_string(path) {
                    let lines: Vec<String> = content
                        .lines()
                        .enumerate()
                        .filter_map(|(i, line)| {
                            if line.to_lowercase().contains(&query_lower) {
                                Some(format!("{}: {}", i + 1, line))
                            } else {
                                None
                            }
                        })
                        .collect();

                    if !lines.is_empty() {
                        results.push((path.to_path_buf(), lines));
                    }
                }
            }
        }

        Ok(results)
    }
}

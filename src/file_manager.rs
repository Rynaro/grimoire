use anyhow::{Context, Result};
use dirs;
use std::fs;
use std::path::{Path, PathBuf};
use walkdir::WalkDir;

pub struct FileManager {
    notes_dir: PathBuf,
}

impl FileManager {
    pub fn new() -> Result<Self> {
        let notes_dir = dirs::home_dir()
            .context("Could not find home directory")?
            .join(".grimoire")
            .join("notes");

        // Create notes directory if it doesn't exist
        fs::create_dir_all(&notes_dir)
            .context("Failed to create notes directory")?;

        Ok(Self { notes_dir })
    }

    pub fn get_notes_dir(&self) -> &Path {
        &self.notes_dir
    }

    pub fn list_items(&self) -> Result<Vec<FileItem>> {
        let mut items = Vec::new();
        
        if !self.notes_dir.exists() {
            return Ok(items);
        }

        let mut entries: Vec<_> = fs::read_dir(&self.notes_dir)
            .context("Failed to read notes directory")?
            .collect::<Result<Vec<_>, _>>()
            .context("Failed to read directory entries")?;

        entries.sort_by_key(|e| e.path());

        for entry in entries {
            let path = entry.path();
            let metadata = fs::metadata(&path)?;
            
            if metadata.is_dir() {
                items.push(FileItem::Folder(path));
            } else if path.extension().and_then(|s| s.to_str()) == Some("md") {
                items.push(FileItem::Note(path));
            }
        }

        Ok(items)
    }

    pub fn create_note(&self, name: &str) -> Result<PathBuf> {
        let mut filename = name.to_string();
        if !filename.ends_with(".md") {
            filename.push_str(".md");
        }
        let path = self.notes_dir.join(&filename);
        
        if path.exists() {
            anyhow::bail!("Note already exists: {}", filename);
        }

        fs::write(&path, "")?;
        Ok(path)
    }

    pub fn create_folder(&self, name: &str) -> Result<PathBuf> {
        let path = self.notes_dir.join(name);
        
        if path.exists() {
            anyhow::bail!("Folder already exists: {}", name);
        }

        fs::create_dir(&path)?;
        Ok(path)
    }

    pub fn delete_note(&self, path: &Path) -> Result<()> {
        if path.is_dir() {
            fs::remove_dir_all(path)?;
        } else {
            fs::remove_file(path)?;
        }
        Ok(())
    }

    pub fn read_note(&self, path: &Path) -> Result<String> {
        fs::read_to_string(path).context("Failed to read note")
    }

    pub fn write_note(&self, path: &Path, content: &str) -> Result<()> {
        fs::write(path, content).context("Failed to write note")
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
                    .and_then(|n| n.to_str())
                    .map(|n| n.to_lowercase().contains(&query_lower))
                    .unwrap_or(false)
                {
                    results.push(path.to_path_buf());
                }
            }
        }

        Ok(results)
    }

    pub fn search_content(&self, query: &str) -> Result<Vec<PathBuf>> {
        let mut results = Vec::new();
        let query_lower = query.to_lowercase();

        for entry in WalkDir::new(&self.notes_dir)
            .into_iter()
            .filter_map(|e| e.ok())
        {
            let path = entry.path();
            if path.is_file() && path.extension().and_then(|s| s.to_str()) == Some("md") {
                if let Ok(content) = fs::read_to_string(path) {
                    if content.to_lowercase().contains(&query_lower) {
                        results.push(path.to_path_buf());
                    }
                }
            }
        }

        Ok(results)
    }
}

#[derive(Clone, Debug)]
pub enum FileItem {
    Folder(PathBuf),
    Note(PathBuf),
}

impl FileItem {
    pub fn path(&self) -> &Path {
        match self {
            FileItem::Folder(p) => p,
            FileItem::Note(p) => p,
        }
    }

    pub fn name(&self) -> String {
        match self {
            FileItem::Folder(p) => p
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_string(),
            FileItem::Note(p) => p
                .file_name()
                .and_then(|n| n.to_str())
                .unwrap_or("")
                .to_string(),
        }
    }

    pub fn is_folder(&self) -> bool {
        matches!(self, FileItem::Folder(_))
    }
}

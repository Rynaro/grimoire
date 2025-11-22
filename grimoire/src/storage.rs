use anyhow::{Context, Result};
use chrono::{DateTime, Local};
use std::cmp::Ordering;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::time::SystemTime;
use walkdir::WalkDir;

pub const NOTE_EXTENSION: &str = "md";

#[derive(Clone, Debug)]
pub struct FolderEntry {
    pub name: String,
    pub path: PathBuf,
    pub note_count: usize,
}

#[derive(Clone, Debug)]
pub struct NoteEntry {
    pub title: String,
    pub filename: String,
    pub path: PathBuf,
    pub modified: SystemTime,
    pub preview: String,
}

#[derive(Clone, Debug)]
pub enum SearchKind {
    Title,
    Content,
}

#[derive(Clone, Debug)]
pub struct SearchResult {
    pub kind: SearchKind,
    pub path: PathBuf,
    pub title: String,
    pub preview: String,
}

pub fn ensure_workspace(root: &Path) -> Result<PathBuf> {
    if !root.exists() {
        fs::create_dir_all(root)
            .with_context(|| format!("Unable to create notes directory at {}", root.display()))?;
    }

    let inbox = root.join("inbox");
    if !inbox.exists() {
        fs::create_dir_all(&inbox)
            .with_context(|| format!("Unable to create inbox folder at {}", inbox.display()))?;
    }

    Ok(root.to_path_buf())
}

pub fn list_folders(root: &Path) -> Result<Vec<FolderEntry>> {
    let mut folders: Vec<FolderEntry> = fs::read_dir(root)
        .with_context(|| format!("Cannot read notes directory {}", root.display()))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| entry.path().is_dir())
        .map(|entry| {
            let name = entry.file_name().to_string_lossy().to_string();
            let path = entry.path();
            let note_count = count_note_files(&path).unwrap_or(0);
            FolderEntry {
                name: pretty_name(&name),
                path,
                note_count,
            }
        })
        .collect();

    folders.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));

    Ok(folders)
}

fn count_note_files(dir: &Path) -> Result<usize, io::Error> {
    let mut total = 0;
    for entry in fs::read_dir(dir)? {
        let entry = entry?;
        if entry.path().is_file() {
            if entry
                .path()
                .extension()
                .map(|ext| ext == NOTE_EXTENSION)
                .unwrap_or(false)
            {
                total += 1;
            }
        }
    }
    Ok(total)
}

pub fn list_notes(folder: &Path) -> Result<Vec<NoteEntry>> {
    let mut notes: Vec<NoteEntry> = fs::read_dir(folder)
        .with_context(|| format!("Cannot list notes in {}", folder.display()))?
        .filter_map(|entry| entry.ok())
        .filter(|entry| {
            entry.path().is_file()
                && entry
                    .path()
                    .extension()
                    .map(|ext| ext == NOTE_EXTENSION)
                    .unwrap_or(false)
        })
        .map(|entry| {
            let path = entry.path();
            let filename = entry.file_name().to_string_lossy().to_string();
            let title = title_from_filename(&filename);
            let metadata = entry.metadata().ok();
            let modified = metadata
                .and_then(|m| m.modified().ok())
                .unwrap_or(SystemTime::now());
            let preview = read_preview_line(&path).unwrap_or_default();
            NoteEntry {
                title,
                filename,
                path,
                modified,
                preview,
            }
        })
        .collect();

    notes.sort_by(|a, b| b.modified.cmp(&a.modified));

    Ok(notes)
}

pub fn read_note(path: &Path) -> Result<String> {
    fs::read_to_string(path).with_context(|| format!("Unable to read {}", path.display()))
}

pub fn write_note(path: &Path, body: &str) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent).with_context(|| {
            format!("Unable to create parent directories for {}", path.display())
        })?;
    }
    fs::write(path, body).with_context(|| format!("Unable to write {}", path.display()))
}

pub fn create_folder(root: &Path, name: &str) -> Result<PathBuf> {
    let slug = slugify(name);
    if slug.is_empty() {
        anyhow::bail!("Folder name cannot be empty");
    }

    let mut candidate = root.join(&slug);
    let mut counter = 1;
    while candidate.exists() {
        counter += 1;
        candidate = root.join(format!("{}-{}", slug, counter));
    }

    fs::create_dir_all(&candidate)
        .with_context(|| format!("Unable to create folder {}", candidate.display()))?;

    Ok(candidate)
}

pub fn create_note(folder: &Path, title: &str) -> Result<PathBuf> {
    if !folder.exists() {
        anyhow::bail!("Folder {} does not exist", folder.display());
    }

    let mut slug = slugify(title);
    if slug.is_empty() {
        slug = "note".to_string();
    }

    let mut candidate = folder.join(format!("{}.{}", slug, NOTE_EXTENSION));
    let mut counter = 1;

    while candidate.exists() {
        counter += 1;
        candidate = folder.join(format!("{}-{}.{}", slug, counter, NOTE_EXTENSION));
    }

    write_note(&candidate, &format!("# {}\n\n", title))?;
    Ok(candidate)
}

pub fn delete_note(path: &Path) -> Result<()> {
    if path.exists() {
        fs::remove_file(path)
            .with_context(|| format!("Unable to delete note {}", path.display()))?;
    }
    Ok(())
}

pub fn delete_folder(path: &Path) -> Result<()> {
    if !path.exists() {
        return Ok(());
    }

    if fs::read_dir(path)?.next().is_some() {
        anyhow::bail!("Folder {} is not empty", path.display());
    }

    fs::remove_dir(path).with_context(|| format!("Unable to delete folder {}", path.display()))
}

pub fn search_notes(root: &Path, query: &str) -> Result<Vec<SearchResult>> {
    let needle = query.trim().to_lowercase();
    if needle.is_empty() {
        return Ok(Vec::new());
    }

    let mut results = Vec::new();
    for entry in WalkDir::new(root).into_iter().filter_map(|e| e.ok()) {
        let path = entry.path();
        if !path.is_file() {
            continue;
        }
        if path
            .extension()
            .map(|ext| ext == NOTE_EXTENSION)
            .unwrap_or(false)
        {
            let title = title_from_filename(
                path.file_name()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .as_ref(),
            );
            let filename = path
                .file_name()
                .map(|s| s.to_string_lossy().to_lowercase())
                .unwrap_or_default();
            if filename.contains(&needle) {
                let preview = format!("matches in title — {}", path.display());
                results.push(SearchResult {
                    kind: SearchKind::Title,
                    path: path.to_path_buf(),
                    title: title.clone(),
                    preview,
                });
                continue;
            }

            if let Ok(body) = fs::read_to_string(path) {
                if let Some(line) = body
                    .lines()
                    .find(|line| line.to_lowercase().contains(&needle))
                {
                    let snippet = line.trim();
                    results.push(SearchResult {
                        kind: SearchKind::Content,
                        path: path.to_path_buf(),
                        title,
                        preview: snippet.to_string(),
                    });
                }
            }
        }
    }

    results.sort_by(|a, b| {
        let kind_cmp = rank_kind(&a.kind).cmp(&rank_kind(&b.kind));
        if kind_cmp == Ordering::Equal {
            a.title.to_lowercase().cmp(&b.title.to_lowercase())
        } else {
            kind_cmp
        }
    });

    Ok(results)
}

fn rank_kind(kind: &SearchKind) -> u8 {
    match kind {
        SearchKind::Title => 0,
        SearchKind::Content => 1,
    }
}

pub fn format_timestamp(time: SystemTime) -> String {
    let datetime: DateTime<Local> = time.into();
    datetime.format("%Y-%m-%d %H:%M").to_string()
}

pub fn pretty_name(name: &str) -> String {
    let replaced = name.replace('-', " ").replace('_', " ");
    capitalize_each_word(&replaced)
}

pub fn title_from_filename(filename: &str) -> String {
    let trimmed = filename.trim_end_matches(&format!(".{}", NOTE_EXTENSION));
    pretty_name(trimmed)
}

pub fn slugify(input: &str) -> String {
    let trimmed = input.trim().to_lowercase();
    let mut slug = String::new();
    let mut prev_dash = false;
    for ch in trimmed.chars() {
        if ch.is_ascii_alphanumeric() {
            slug.push(ch);
            prev_dash = false;
        } else if ch.is_whitespace() || ch == '-' || ch == '_' {
            if !prev_dash && !slug.is_empty() {
                slug.push('-');
                prev_dash = true;
            }
        }
    }
    slug.trim_matches('-').to_string()
}

fn capitalize_each_word(text: &str) -> String {
    let mut result = String::new();
    let mut capitalize_next = true;
    for ch in text.chars() {
        if !ch.is_alphabetic() {
            result.push(ch);
            capitalize_next = true;
            continue;
        }
        if capitalize_next {
            result.extend(ch.to_uppercase());
        } else {
            result.push(ch);
        }
        capitalize_next = false;
    }
    result
}

fn read_preview_line(path: &Path) -> Result<String> {
    let body = fs::read_to_string(path)?;
    Ok(body
        .lines()
        .find(|line| !line.trim().is_empty())
        .unwrap_or_default()
        .trim()
        .chars()
        .take(80)
        .collect())
}

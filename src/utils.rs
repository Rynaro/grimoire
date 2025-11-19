// Utility functions for the application

use std::path::PathBuf;

pub fn extract_wiki_links(content: &str) -> Vec<String> {
    use regex::Regex;
    let re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();
    re.captures_iter(content)
        .filter_map(|cap| cap.get(1).map(|m| m.as_str().to_string()))
        .collect()
}

pub fn resolve_wiki_link(link: &str, current_path: &PathBuf) -> Option<PathBuf> {
    // Simple resolution: look for files with matching name
    let base_dir = current_path.parent()?;
    let link_lower = link.to_lowercase();
    
    // Try exact match first
    let exact = base_dir.join(format!("{}.md", link));
    if exact.exists() {
        return Some(exact);
    }
    
    // Try case-insensitive match
    if let Ok(entries) = std::fs::read_dir(base_dir) {
        for entry in entries.flatten() {
            if let Some(name) = entry.path().file_stem().and_then(|s| s.to_str()) {
                if name.to_lowercase() == link_lower && entry.path().extension().and_then(|s| s.to_str()) == Some("md") {
                    return Some(entry.path());
                }
            }
        }
    }
    
    None
}

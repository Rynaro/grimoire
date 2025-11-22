use anyhow::Result;
use std::fs;
use std::path::PathBuf;

pub struct Note {
    pub path: PathBuf,
    pub content: String,
    pub title: String,
}

impl Note {
    pub fn load(path: &PathBuf) -> Result<Self> {
        let content = fs::read_to_string(path)?;
        let title = path
            .file_stem()
            .and_then(|s| s.to_str())
            .unwrap_or("Untitled")
            .to_string();

        Ok(Self {
            path: path.clone(),
            content,
            title,
        })
    }

    pub fn save(&self) -> Result<()> {
        fs::write(&self.path, &self.content)?;
        Ok(())
    }

    pub fn render_markdown(&self) -> String {
        // For terminal display, we'll do basic markdown formatting
        // Convert markdown to plain text with some formatting hints
        let mut result = String::new();
        let mut in_code_block = false;
        
        for line in self.content.lines() {
            if line.starts_with("```") {
                in_code_block = !in_code_block;
                continue;
            }
            
            if in_code_block {
                result.push_str(&format!("  {}\n", line));
                continue;
            }
            
            if line.starts_with("# ") {
                result.push_str(&format!("{}\n", &line[2..]));
            } else if line.starts_with("## ") {
                result.push_str(&format!("  {}\n", &line[3..]));
            } else if line.starts_with("### ") {
                result.push_str(&format!("    {}\n", &line[4..]));
            } else if line.starts_with("- ") || line.starts_with("* ") {
                result.push_str(&format!("  • {}\n", &line[2..]));
            } else if line.starts_with("> ") {
                result.push_str(&format!("  │ {}\n", &line[2..]));
            } else {
                result.push_str(&format!("{}\n", line));
            }
        }
        
        result
    }

    pub fn extract_links(&self) -> Vec<String> {
        use regex::Regex;
        let re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();
        re.captures_iter(&self.content)
            .map(|cap| cap.get(1).unwrap().as_str().to_string())
            .collect()
    }
}

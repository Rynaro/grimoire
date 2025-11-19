use pulldown_cmark::{Options, Parser};
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};

pub struct MarkdownRenderer {
    options: Options,
}

impl MarkdownRenderer {
    pub fn new() -> Self {
        let mut options = Options::empty();
        options.insert(Options::ENABLE_STRIKETHROUGH);
        options.insert(Options::ENABLE_TABLES);
        options.insert(Options::ENABLE_FOOTNOTES);
        options.insert(Options::ENABLE_TASKLISTS);
        options.insert(Options::ENABLE_SMART_PUNCTUATION);

        Self { options }
    }

    pub fn render(&self, markdown: &str) -> Vec<Line> {
        use regex::Regex;
        
        // Pre-process wiki-style links [[note_name]] to markdown links
        let wiki_link_re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();
        let processed_markdown = wiki_link_re.replace_all(markdown, |caps: &regex::Captures| {
            let note_name = &caps[1];
            format!("[{}]({}.md)", note_name, note_name)
        });
        
        let parser = Parser::new_ext(&processed_markdown, self.options);
        let mut lines = Vec::new();
        let mut current_line = Vec::new();
        let mut in_code_block = false;
        let mut code_block_lang = String::new();

        for event in parser {
            match event {
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Heading(level, _, _)) => {
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line.clone()));
                        current_line.clear();
                    }
                    let style = match level {
                        pulldown_cmark::HeadingLevel::H1 => Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD),
                        pulldown_cmark::HeadingLevel::H2 => Style::default().fg(Color::Blue).add_modifier(Modifier::BOLD),
                        _ => Style::default().fg(Color::Magenta).add_modifier(Modifier::BOLD),
                    };
                    let indent = match level {
                        pulldown_cmark::HeadingLevel::H1 => 0,
                        pulldown_cmark::HeadingLevel::H2 => 1,
                        pulldown_cmark::HeadingLevel::H3 => 2,
                        pulldown_cmark::HeadingLevel::H4 => 3,
                        pulldown_cmark::HeadingLevel::H5 => 4,
                        pulldown_cmark::HeadingLevel::H6 => 5,
                    };
                    current_line.push(Span::styled("  ".repeat(indent), style));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Heading(..)) => {
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line.clone()));
                        current_line.clear();
                    }
                }
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::CodeBlock(_)) => {
                    in_code_block = true;
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line.clone()));
                        current_line.clear();
                    }
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::CodeBlock(_)) => {
                    in_code_block = false;
                    code_block_lang.clear();
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line.clone()));
                        current_line.clear();
                    }
                }
                // Code spans are handled as text events in pulldown-cmark 0.9
                // They're already included in the Text event
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Strong) => {
                    current_line.push(Span::styled("", Style::default().add_modifier(Modifier::BOLD)));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Strong) => {}
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Emphasis) => {
                    current_line.push(Span::styled("", Style::default().add_modifier(Modifier::ITALIC)));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Emphasis) => {}
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Link(_, url, _)) => {
                    // Highlight note links differently
                    let is_note_link = url.ends_with(".md");
                    let style = if is_note_link {
                        Style::default().fg(Color::Cyan).add_modifier(Modifier::UNDERLINED | Modifier::BOLD)
                    } else {
                        Style::default().fg(Color::Blue).add_modifier(Modifier::UNDERLINED)
                    };
                    current_line.push(Span::styled("[", style));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Link(_, url, _)) => {
                    let is_note_link = url.ends_with(".md");
                    let style = if is_note_link {
                        Style::default().fg(Color::Cyan).add_modifier(Modifier::UNDERLINED | Modifier::BOLD)
                    } else {
                        Style::default().fg(Color::Blue).add_modifier(Modifier::UNDERLINED)
                    };
                    current_line.push(Span::styled(format!("]({})", url), style));
                }
                pulldown_cmark::Event::Text(text) => {
                    let style = if in_code_block {
                        Style::default()
                            .fg(Color::Green)
                            .bg(Color::Rgb(20, 20, 20))
                    } else {
                        Style::default()
                    };
                    current_line.push(Span::styled(text.to_string(), style));
                }
                pulldown_cmark::Event::SoftBreak | pulldown_cmark::Event::HardBreak => {
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line.clone()));
                        current_line.clear();
                    }
                }
                _ => {}
            }
        }

        if !current_line.is_empty() {
            lines.push(Line::from(current_line));
        }

        if lines.is_empty() {
            lines.push(Line::from(Span::styled(
                "Empty note",
                Style::default().fg(Color::DarkGray),
            )));
        }

        lines
    }

    pub fn extract_links(&self, markdown: &str) -> Vec<String> {
        let parser = Parser::new_ext(markdown, self.options);
        let mut links = Vec::new();

        for event in parser {
            if let pulldown_cmark::Event::Start(pulldown_cmark::Tag::Link(_, url, _)) = event {
                links.push(url.to_string());
            }
        }

        links
    }

    pub fn extract_note_links(&self, markdown: &str, _notes_dir: &std::path::Path) -> Vec<String> {
        use regex::Regex;
        
        let mut links = Vec::new();
        
        // Extract wiki-style links [[note_name]]
        let wiki_link_re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();
        for cap in wiki_link_re.captures_iter(markdown) {
            if let Some(link) = cap.get(1) {
                links.push(link.as_str().to_string());
            }
        }
        
        // Extract markdown links that point to .md files
        let md_link_re = Regex::new(r"\[([^\]]+)\]\(([^\)]+\.md)\)").unwrap();
        for cap in md_link_re.captures_iter(markdown) {
            if let Some(url) = cap.get(2) {
                let url_str = url.as_str();
                // Extract filename without extension
                if let Some(name) = std::path::Path::new(url_str)
                    .file_stem()
                    .and_then(|n| n.to_str())
                {
                    links.push(name.to_string());
                }
            }
        }
        
        links
    }
}

use pulldown_cmark::{Options, Parser};
use ratatui::text::{Line, Span};

pub struct MarkdownRenderer;

impl MarkdownRenderer {
    pub fn new() -> Self {
        Self
    }

    pub fn render(&self, content: &str, width: usize) -> Vec<Line> {
        let mut options = Options::empty();
        options.insert(Options::ENABLE_STRIKETHROUGH);
        options.insert(Options::ENABLE_TABLES);
        options.insert(Options::ENABLE_FOOTNOTES);
        options.insert(Options::ENABLE_TASKLISTS);

        let parser = Parser::new_ext(content, options);
        let mut lines = Vec::new();
        let mut current_line = Vec::new();
        let mut in_code_block = false;
        let mut code_lang = String::new();

        for event in parser {
            match event {
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Heading(level, _, _)) => {
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line));
                        current_line = Vec::new();
                    }
                    let level_num = match level {
                        pulldown_cmark::HeadingLevel::H1 => 1,
                        pulldown_cmark::HeadingLevel::H2 => 2,
                        pulldown_cmark::HeadingLevel::H3 => 3,
                        pulldown_cmark::HeadingLevel::H4 => 4,
                        pulldown_cmark::HeadingLevel::H5 => 5,
                        pulldown_cmark::HeadingLevel::H6 => 6,
                    };
                    let style = match level_num {
                        1 => ratatui::style::Style::default()
                            .add_modifier(ratatui::style::Modifier::BOLD)
                            .fg(ratatui::style::Color::Cyan),
                        2 => ratatui::style::Style::default()
                            .add_modifier(ratatui::style::Modifier::BOLD)
                            .fg(ratatui::style::Color::Blue),
                        _ => ratatui::style::Style::default()
                            .add_modifier(ratatui::style::Modifier::BOLD),
                    };
                    current_line.push(Span::styled("  ".repeat(level_num - 1), style));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Heading(_, _, _)) => {
                    lines.push(Line::from(current_line));
                    current_line = Vec::new();
                }
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::CodeBlock(kind)) => {
                    if !current_line.is_empty() {
                        lines.push(Line::from(current_line));
                        current_line = Vec::new();
                    }
                    in_code_block = true;
                    code_lang = match kind {
                        pulldown_cmark::CodeBlockKind::Fenced(lang) => lang.to_string(),
                        _ => String::new(),
                    };
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::CodeBlock(_)) => {
                    in_code_block = false;
                    code_lang.clear();
                }
                pulldown_cmark::Event::Text(text) => {
                    if in_code_block {
                        // For code blocks, we'll use simple formatting
                        current_line.push(Span::styled(
                            text.to_string(),
                            ratatui::style::Style::default().fg(ratatui::style::Color::Green),
                        ));
                    } else {
                        // Parse note links [[note-name]] in the text
                        let text_str = text.to_string();
                        let mut last_end = 0;
                        for (start, _) in text_str.match_indices("[[") {
                            if start > last_end {
                                // Add text before the link
                                current_line.push(Span::from(text_str[last_end..start].to_string()));
                            }
                            if let Some(end) = text_str[start+2..].find("]]") {
                                let end_pos = start + 2 + end + 2;
                                let note_name = text_str[start+2..start+2+end].to_string();
                                current_line.push(Span::styled(
                                    format!("[[{}]]", note_name),
                                    ratatui::style::Style::default()
                                        .fg(ratatui::style::Color::Cyan)
                                        .add_modifier(ratatui::style::Modifier::UNDERLINED),
                                ));
                                last_end = end_pos;
                            } else {
                                // Incomplete link, just add the text
                                current_line.push(Span::from(text_str[start..].to_string()));
                                last_end = text_str.len();
                                break;
                            }
                        }
                        if last_end < text_str.len() {
                            current_line.push(Span::from(text_str[last_end..].to_string()));
                        }
                    }
                }
                pulldown_cmark::Event::Code(code) => {
                    current_line.push(Span::styled(
                        format!("`{}`", code),
                        ratatui::style::Style::default()
                            .fg(ratatui::style::Color::Yellow)
                            .bg(ratatui::style::Color::DarkGray),
                    ));
                }
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Strong) => {
                    // Will be handled by End tag
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Strong) => {
                    // Bold text
                }
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Emphasis) => {
                    // Will be handled by End tag
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Emphasis) => {
                    // Italic text
                }
                pulldown_cmark::Event::Start(pulldown_cmark::Tag::Link(link_type, url, title)) => {
                    current_line.push(Span::styled(
                        "[",
                        ratatui::style::Style::default().fg(ratatui::style::Color::Blue),
                    ));
                }
                pulldown_cmark::Event::End(pulldown_cmark::Tag::Link(link_type, url, title)) => {
                    current_line.push(Span::styled(
                        format!("]({})", url),
                        ratatui::style::Style::default().fg(ratatui::style::Color::Blue),
                    ));
                }
                pulldown_cmark::Event::SoftBreak => {
                    lines.push(Line::from(current_line));
                    current_line = Vec::new();
                }
                pulldown_cmark::Event::HardBreak => {
                    lines.push(Line::from(current_line));
                    current_line = Vec::new();
                }
                _ => {}
            }
        }

        if !current_line.is_empty() {
            lines.push(Line::from(current_line));
        }

        // Wrap lines to fit width
        let mut wrapped_lines = Vec::new();
        for line in lines {
            let line_text: String = line.spans.iter().map(|s| s.content.as_ref()).collect();
            let line_width: usize = line.spans.iter().map(|s| {
                s.content.chars().map(|c| unicode_width::UnicodeWidthChar::width(c).unwrap_or(1)).sum::<usize>()
            }).sum();
            
            if line_width <= width {
                wrapped_lines.push(line);
            } else {
                // Simple word wrapping - just add the line as is for now
                // Full wrapping would require more complex logic
                wrapped_lines.push(line);
            }
        }

        wrapped_lines
    }
}

impl Default for MarkdownRenderer {
    fn default() -> Self {
        Self::new()
    }
}

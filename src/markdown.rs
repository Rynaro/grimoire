use pulldown_cmark::{Parser, Options, Event, Tag};
use ratatui::{
    style::{Color, Modifier, Style},
    text::{Line, Span},
    widgets::{Block, Paragraph, Wrap},
};
use regex::Regex;

pub fn render_markdown<'a>(content: &str, block: Block<'a>) -> Paragraph<'a> {
    // First, replace wiki-links with markdown links for rendering
    let wiki_link_re = Regex::new(r"\[\[([^\]]+)\]\]").unwrap();
    let processed_content = wiki_link_re.replace_all(content, |caps: &regex::Captures| {
        let link_text = &caps[1];
        format!("[{}]({})", link_text, link_text)
    });

    let mut spans: Vec<Line> = Vec::new();
    let mut current_line: Vec<Span> = Vec::new();
    let mut in_code_block = false;
    let mut in_emphasis = false;
    let mut in_strong = false;

    let options = Options::empty();
    let parser = Parser::new(&processed_content);

    for event in parser {
        match event {
            Event::Start(Tag::Heading(level, _, _)) => {
                if !current_line.is_empty() {
                    spans.push(Line::from(current_line.clone()));
                    current_line.clear();
                }
                let style = match level {
                    pulldown_cmark::HeadingLevel::H1 => Style::default().fg(Color::Cyan).add_modifier(Modifier::BOLD),
                    pulldown_cmark::HeadingLevel::H2 => Style::default().fg(Color::Cyan),
                    _ => Style::default().fg(Color::Blue),
                };
                let level_num = match level {
                    pulldown_cmark::HeadingLevel::H1 => 1,
                    pulldown_cmark::HeadingLevel::H2 => 2,
                    pulldown_cmark::HeadingLevel::H3 => 3,
                    pulldown_cmark::HeadingLevel::H4 => 4,
                    pulldown_cmark::HeadingLevel::H5 => 5,
                    pulldown_cmark::HeadingLevel::H6 => 6,
                };
                current_line.push(Span::styled("#".repeat(level_num) + " ", style));
            }
            Event::End(Tag::Heading(..)) => {
                spans.push(Line::from(current_line.clone()));
                current_line.clear();
            }
            Event::Start(Tag::CodeBlock(_)) => {
                in_code_block = true;
                if !current_line.is_empty() {
                    spans.push(Line::from(current_line.clone()));
                    current_line.clear();
                }
            }
            Event::End(Tag::CodeBlock(_)) => {
                in_code_block = false;
                if !current_line.is_empty() {
                    spans.push(Line::from(current_line.clone()));
                    current_line.clear();
                }
            }
            Event::Code(text) => {
                // Inline code
                current_line.push(Span::styled(
                    format!("`{}`", text),
                    Style::default().fg(Color::Green).bg(Color::Black),
                ));
            }
            Event::Start(Tag::Emphasis) => {
                in_emphasis = true;
            }
            Event::End(Tag::Emphasis) => {
                in_emphasis = false;
            }
            Event::Start(Tag::Strong) => {
                in_strong = true;
            }
            Event::End(Tag::Strong) => {
                in_strong = false;
            }
            Event::Start(Tag::Link(_, url, _)) => {
                // Check if it's a wiki-link (url matches the link text pattern)
                current_line.push(Span::styled("[", Style::default().fg(Color::Magenta)));
            }
            Event::End(Tag::Link(_, url, _)) => {
                // Check if it's a wiki-link
                let is_wiki_link = !url.starts_with("http") && !url.starts_with("/");
                let link_style = if is_wiki_link {
                    Style::default().fg(Color::Magenta).add_modifier(Modifier::BOLD)
                } else {
                    Style::default().fg(Color::Blue)
                };
                current_line.push(Span::styled(
                    format!("]({})", url),
                    link_style,
                ));
            }
            Event::Text(text) => {
                if in_code_block {
                    current_line.push(Span::styled(
                        text.to_string(),
                        Style::default().fg(Color::Green).bg(Color::Black),
                    ));
                } else {
                    let mut style = Style::default();
                    if in_emphasis {
                        style = style.add_modifier(Modifier::ITALIC);
                    }
                    if in_strong {
                        style = style.add_modifier(Modifier::BOLD);
                    }
                    
                    // Simple text rendering (wiki-links are handled by Link events after preprocessing)
                    current_line.push(Span::styled(text.to_string(), style));
                }
            }
            Event::SoftBreak => {
                spans.push(Line::from(current_line.clone()));
                current_line.clear();
            }
            Event::HardBreak => {
                spans.push(Line::from(current_line.clone()));
                current_line.clear();
            }
            _ => {}
        }
    }

    if !current_line.is_empty() {
        spans.push(Line::from(current_line));
    }

    if spans.is_empty() {
        spans.push(Line::from(""));
    }

    Paragraph::new(spans).block(block).wrap(Wrap { trim: true })
}

use crate::storage::slugify;
use once_cell::sync::Lazy;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use regex::Regex;

#[derive(Clone, Debug)]
pub struct LinkTarget {
    pub label: String,
    pub slug: String,
    pub index: usize,
}

#[derive(Clone, Debug)]
pub struct RenderedNote {
    pub lines: Vec<Line<'static>>,
    pub links: Vec<LinkTarget>,
}

static LINK_PATTERN: Lazy<Regex> =
    Lazy::new(|| Regex::new(r"\[\[([^\]]+)\]\]").expect("invalid link regex"));

pub fn render_markdown(content: &str, selected_link: Option<usize>) -> RenderedNote {
    let mut lines = Vec::new();
    let mut links = Vec::new();
    let mut link_index = 0usize;
    let mut in_code_block = false;

    for raw_line in content.lines() {
        let trimmed = raw_line.trim_start();

        if trimmed.starts_with("```") {
            in_code_block = !in_code_block;
            let style = Style::default()
                .fg(Color::DarkGray)
                .add_modifier(Modifier::DIM);
            lines.push(Line::from(vec![Span::styled(raw_line.to_string(), style)]));
            continue;
        }

        let mut base_style = Style::default();

        if in_code_block {
            base_style = Style::default().fg(Color::Green).bg(Color::Black);
        } else if trimmed.starts_with("# ") {
            base_style = Style::default()
                .fg(Color::Yellow)
                .add_modifier(Modifier::BOLD);
        } else if trimmed.starts_with("## ") {
            base_style = Style::default()
                .fg(Color::LightYellow)
                .add_modifier(Modifier::BOLD);
        } else if trimmed.starts_with("### ") {
            base_style = Style::default().fg(Color::LightMagenta);
        } else if trimmed.starts_with("- ") || trimmed.starts_with("* ") {
            base_style = Style::default().fg(Color::Cyan);
        }

        let spans = inline_with_links(
            raw_line,
            base_style,
            selected_link,
            &mut links,
            &mut link_index,
        );
        lines.push(Line::from(spans));
    }

    if lines.is_empty() {
        lines.push(Line::from(""));
    }

    RenderedNote { lines, links }
}

fn inline_with_links(
    text: &str,
    base: Style,
    selected_link: Option<usize>,
    links: &mut Vec<LinkTarget>,
    link_index: &mut usize,
) -> Vec<Span<'static>> {
    let mut spans = Vec::new();
    let mut last = 0;
    for capture in LINK_PATTERN.captures_iter(text) {
        if let Some(m) = capture.get(0) {
            if m.start() > last {
                spans.extend(render_inline_segment(&text[last..m.start()], base));
            }
            let label = capture.get(1).unwrap().as_str().trim().to_string();
            let slug = slugify(&label);
            let mut link_style = Style::default()
                .fg(Color::LightCyan)
                .add_modifier(Modifier::BOLD | Modifier::UNDERLINED);
            if Some(*link_index) == selected_link {
                link_style = link_style.add_modifier(Modifier::REVERSED);
            }
            spans.push(Span::styled(format!("[[{}]]", label), link_style));
            links.push(LinkTarget {
                label,
                slug,
                index: *link_index,
            });
            *link_index += 1;
            last = m.end();
        }
    }
    if last < text.len() {
        spans.extend(render_inline_segment(&text[last..], base));
    }
    spans
}

fn render_inline_segment(text: &str, base: Style) -> Vec<Span<'static>> {
    if text.is_empty() {
        return Vec::new();
    }

    if !text.contains('`') {
        return vec![Span::styled(text.to_string(), base)];
    }

    let mut spans = Vec::new();
    let mut toggle = false;
    for segment in text.split('`') {
        if toggle {
            spans.push(Span::styled(
                segment.to_string(),
                Style::default()
                    .fg(Color::Green)
                    .add_modifier(Modifier::ITALIC),
            ));
        } else if !segment.is_empty() {
            spans.push(Span::styled(segment.to_string(), base));
        }
        toggle = !toggle;
    }
    spans
}

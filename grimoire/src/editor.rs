use unicode_width::UnicodeWidthChar;

#[derive(Clone, Debug)]
pub struct EditorState {
    pub lines: Vec<String>,
    pub cursor_line: usize,
    pub cursor_col: usize,
    pub dirty: bool,
}

impl EditorState {
    pub fn from_text(text: &str) -> Self {
        let mut lines: Vec<String> = text.split('\n').map(|line| line.to_string()).collect();
        if lines.is_empty() {
            lines.push(String::new());
        }
        Self {
            cursor_line: lines.len().saturating_sub(1),
            cursor_col: lines.last().map(|l| l.len()).unwrap_or(0),
            lines,
            dirty: false,
        }
    }

    pub fn as_text(&self) -> String {
        self.lines.join("\n")
    }

    pub fn insert_char(&mut self, ch: char) {
        if let Some(line) = self.lines.get_mut(self.cursor_line) {
            line.insert(self.cursor_col, ch);
            self.cursor_col += ch.len_utf8();
        }
        self.dirty = true;
    }

    pub fn insert_tab(&mut self, spaces: usize) {
        for _ in 0..spaces {
            self.insert_char(' ');
        }
    }

    pub fn insert_newline(&mut self) {
        if self.cursor_line >= self.lines.len() {
            self.lines.push(String::new());
            self.cursor_line = self.lines.len() - 1;
            self.cursor_col = 0;
        } else {
            let split_point = self.cursor_col;
            let current_line = self.lines[self.cursor_line].clone();
            let (left, right) = current_line.split_at(split_point);
            self.lines[self.cursor_line] = left.to_string();
            self.lines.insert(self.cursor_line + 1, right.to_string());
            self.cursor_line += 1;
            self.cursor_col = 0;
        }
        self.dirty = true;
    }

    pub fn backspace(&mut self) {
        if self.cursor_col > 0 {
            if let Some(line) = self.lines.get_mut(self.cursor_line) {
                self.cursor_col = self.cursor_col.saturating_sub(1);
                line.remove(self.cursor_col);
            }
        } else if self.cursor_line > 0 {
            let current_line = self.lines.remove(self.cursor_line);
            self.cursor_line -= 1;
            let prev_len = self.lines[self.cursor_line].len();
            self.lines[self.cursor_line].push_str(&current_line);
            self.cursor_col = prev_len;
        }
        self.dirty = true;
    }

    pub fn delete_char(&mut self) {
        if self.cursor_line >= self.lines.len() {
            return;
        }

        let current_len = self.lines[self.cursor_line].len();
        if self.cursor_col < current_len {
            if let Some(line) = self.lines.get_mut(self.cursor_line) {
                line.remove(self.cursor_col);
            }
        } else if self.cursor_line + 1 < self.lines.len() {
            let next_line = self.lines.remove(self.cursor_line + 1);
            if let Some(line) = self.lines.get_mut(self.cursor_line) {
                line.push_str(&next_line);
            }
        }
        self.dirty = true;
    }

    pub fn move_to_start_of_line(&mut self) {
        self.cursor_col = 0;
    }

    pub fn move_to_end_of_line(&mut self) {
        if let Some(line) = self.lines.get(self.cursor_line) {
            self.cursor_col = line.len();
        }
    }

    pub fn clamp_cursor(&mut self) {
        if self.cursor_line >= self.lines.len() {
            self.cursor_line = self.lines.len().saturating_sub(1);
        }
        let max_col = self
            .lines
            .get(self.cursor_line)
            .map(|l| l.len())
            .unwrap_or(0);
        if self.cursor_col > max_col {
            self.cursor_col = max_col;
        }
    }

    pub fn cursor_display_col(&self) -> u16 {
        if let Some(line) = self.lines.get(self.cursor_line) {
            let width: usize = line
                .chars()
                .take(self.cursor_col)
                .map(|c| c.width().unwrap_or(1))
                .sum();
            width as u16
        } else {
            0
        }
    }
}

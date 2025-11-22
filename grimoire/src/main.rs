mod app;
mod commands;
mod editor;
mod markdown;
mod storage;
mod ui;

use crate::app::App;
use anyhow::Result;
use crossterm::event::{self, Event};
use crossterm::execute;
use crossterm::terminal::{
    disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen,
};
use ratatui::backend::CrosstermBackend;
use ratatui::Terminal;
use std::env;
use std::io;
use std::path::PathBuf;
use std::time::Duration;

fn main() -> Result<()> {
    let notes_dir = resolve_notes_dir();
    let mut app = App::new(notes_dir)?;
    let result = run_app(&mut app);
    restore_terminal()?;
    result
}

fn run_app(app: &mut App) -> Result<()> {
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;
    terminal.clear()?;

    let tick_rate = Duration::from_millis(200);

    loop {
        terminal.draw(|f| ui::draw(f, app))?;

        if event::poll(tick_rate)? {
            match event::read()? {
                Event::Key(key) => {
                    app.handle_event(key)?;
                }
                Event::Resize(_, _) => {}
                _ => {}
            }
        }

        app.tick();

        if app.should_quit() {
            break;
        }
    }

    terminal.show_cursor()?;
    Ok(())
}

fn restore_terminal() -> Result<()> {
    disable_raw_mode()?;
    execute!(io::stdout(), LeaveAlternateScreen)?;
    Ok(())
}

fn resolve_notes_dir() -> PathBuf {
    if let Some(arg) = env::args().nth(1) {
        return PathBuf::from(arg);
    }
    if let Ok(env_path) = env::var("GRIMOIRE_DIR") {
        if !env_path.trim().is_empty() {
            return PathBuf::from(env_path);
        }
    }
    if let Some(data_dir) = dirs::data_dir() {
        return data_dir.join("grimoire");
    }
    PathBuf::from("grimoire-notes")
}

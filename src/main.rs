mod app;
mod components;
mod file_manager;
mod markdown;
mod ui;

use app::App;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode, KeyEventKind},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use ratatui::{
    backend::CrosstermBackend,
    Terminal,
};
use std::io;

fn main() -> io::Result<()> {
    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    // Create app
    let mut app = App::new()?;
    let result = run_app(&mut terminal, &mut app);

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = result {
        println!("Error: {:?}", err);
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> io::Result<()> {
    loop {
        terminal.draw(|f| ui::draw(f, app))?;

        if let Event::Key(key) = event::read()? {
            if key.kind == KeyEventKind::Press {
                match key.code {
                    KeyCode::Char('q') => return Ok(()),
                    KeyCode::Esc => {
                        match app.mode {
                            app::Mode::Editing => {
                                app.mode = app::Mode::Viewing;
                            }
                            app::Mode::Searching => {
                                app.mode = app::Mode::Viewing;
                                app.search_query.clear();
                                app.perform_search();
                            }
                            _ => {
                                return Ok(());
                            }
                        }
                    }
                    KeyCode::Char('e') => {
                        if app.mode == app::Mode::Viewing {
                            app.mode = app::Mode::Editing;
                        }
                    }
                    KeyCode::Char('n') => {
                        app.create_new_note()?;
                    }
                    KeyCode::Char('d') => {
                        app.delete_current_note()?;
                    }
                    KeyCode::Char('/') => {
                        app.mode = app::Mode::Searching;
                    }
                    KeyCode::Up | KeyCode::Char('k') => {
                        app.navigate_up();
                    }
                    KeyCode::Down | KeyCode::Char('j') => {
                        app.navigate_down();
                    }
                    KeyCode::Enter => {
                        app.select_item();
                    }
                    KeyCode::Backspace => {
                        app.handle_backspace();
                    }
                    KeyCode::Tab => {
                        app.toggle_focus();
                    }
                    _ => {
                        app.handle_input(key);
                    }
                }
            }
        }
    }
}

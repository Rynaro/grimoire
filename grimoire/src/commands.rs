use anyhow::{bail, Result};

#[derive(Debug)]
pub enum Command {
    NewNote { title: String },
    NewFolder { name: String },
    DeleteNote,
    DeleteFolder,
    Refresh,
    Help,
}

pub fn parse(input: &str) -> Result<Command> {
    let trimmed = input.trim();
    if trimmed.is_empty() {
        bail!("Command cannot be empty");
    }

    let mut parts = trimmed.split_whitespace();
    let keyword = parts.next().unwrap().to_lowercase();
    let remainder = parts.collect::<Vec<_>>().join(" ");

    match keyword.as_str() {
        "note" | "n" => {
            if remainder.is_empty() {
                bail!("Usage: :note <title>");
            }
            Ok(Command::NewNote {
                title: remainder.trim().to_string(),
            })
        }
        "folder" | "f" => {
            if remainder.is_empty() {
                bail!("Usage: :folder <name>");
            }
            Ok(Command::NewFolder {
                name: remainder.trim().to_string(),
            })
        }
        "delete" | "rm" | "d" => {
            if remainder.is_empty() {
                bail!("Usage: :delete <note|folder>");
            }
            match remainder.as_str() {
                "note" | "n" => Ok(Command::DeleteNote),
                "folder" | "f" => Ok(Command::DeleteFolder),
                other => bail!("Unknown delete target '{}'", other),
            }
        }
        "refresh" | "r" => Ok(Command::Refresh),
        "help" | "h" => Ok(Command::Help),
        other => bail!("Unknown command '{}'", other),
    }
}

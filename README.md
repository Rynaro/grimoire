# Grimoire

A beautiful, resource-efficient terminal-based notes application inspired by Apple Notes and Obsidian.

## Features

- **Sidebar Navigation**: Browse folders and notes with intuitive navigation
- **Markdown Support**: Full markdown rendering with syntax highlighting
- **Note Linking**: Create links between notes using `[[note-name]]` syntax
- **File Management**: Create, delete, and organize notes
- **Search**: Search across file names and content
- **Beautiful TUI**: Clean, modern terminal interface

## Installation

### From Source

```bash
# Clone the repository
git clone <repository-url>
cd grimoire

# Build the application
cargo build --release

# Run the application
cargo run --release
```

### Using Docker

```bash
# Build and run using docker-compose (recommended)
docker-compose up --build

# Or build and run manually
docker build -t grimoire .
docker run -it --rm -v $(pwd)/notes:/root/.grimoire/notes grimoire
```

## Usage

### Keyboard Shortcuts

**View Mode:**
- `q` - Quit the application
- `e` - Edit current note
- `n` - Create new note (opens command mode)
- `d` - Delete current note
- `/` - Search mode
- `↑/↓` - Navigate sidebar
- `Enter` - Open selected note

**Edit Mode:**
- `Esc` - Cancel editing (discard changes)
- `Ctrl+S` - Save and return to view mode
- `Arrow keys` - Navigate cursor
- `Home/End` - Move to beginning/end of text

**Command Mode:**
- `:new <name>` - Create a new note
- `:delete <name>` - Delete a note
- `Enter` - Execute command
- `Esc` - Cancel command

**Search Mode:**
- Type to search across note content
- `↑/↓` - Navigate results
- `Enter` - Open selected note
- `Esc` - Cancel search

### Note Linking

Create links between notes using double brackets:

```markdown
This note references [[another-note]] and [[yet-another-note]].
```

Links are rendered in cyan and underlined in the view mode.

## File Structure

Notes are stored in `~/.grimoire/notes/` by default. All notes are plain markdown files (`.md`), giving you full control over your data.

## Development

```bash
# Run in development mode
cargo run

# Run tests
cargo test

# Build for release
cargo build --release
```

## Technology Stack

- **Rust** - High performance, memory-efficient language
- **ratatui** - Modern terminal UI library
- **pulldown-cmark** - Markdown parser
- **syntect** - Syntax highlighting
- **crossterm** - Cross-platform terminal manipulation

## License

MIT License

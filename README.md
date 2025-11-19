# Grimoire

A beautiful, resource-efficient terminal-based notes application inspired by Apple Notes and Obsidian.

## Features

- **Beautiful TUI**: Modern terminal interface with syntax highlighting
- **Markdown Support**: Full markdown rendering with syntax highlighting
- **Wiki-Links**: Create connections between notes using `[[note-name]]` syntax
- **File Management**: 
  - Create, delete, and organize notes
  - Search files and content
  - Navigate through folders
- **Resource Efficient**: Built with Rust for optimal performance
- **User Sovereignty**: All notes stored as plain markdown files in your filesystem

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
# Build and run with Docker Compose
docker-compose up --build

# Or build the image manually
docker build -t grimoire .
docker run -it --rm -v grimoire-notes:/root/.grimoire/notes grimoire
```

## Usage

### Navigation

- `j` / `↓` - Move down in sidebar
- `k` / `↑` - Move up in sidebar
- `h` / `←` - Focus sidebar
- `l` / `→` - Focus note area
- `Enter` - Open selected note/folder
- `Esc` - Clear selection / Exit current mode

### Editing

- `i` - Enter insert mode
- `Esc` - Exit insert mode (auto-saves)
- In insert mode, type normally to edit notes

### Commands

- `:` - Enter command mode
- `:q` or `:quit` - Quit application
- `:w` or `:write` - Save current note
- `/` - Search content across all notes

### Shortcuts

- `Ctrl+N` - Create new note
- `Ctrl+D` - Delete current item
- `Ctrl+F` - Follow first wiki-link in current note
- `Ctrl+Q` - Quit application

### Wiki-Links

Create links between notes using double brackets:

```markdown
This is a note about [[another-note]].
```

Wiki-links are highlighted in magenta and can be navigated using `Ctrl+F`.

## File Structure

Notes are stored in `~/.grimoire/notes/` by default. All notes are plain markdown (`.md`) files that you can edit with any text editor.

```
~/.grimoire/notes/
├── folder1/
│   ├── note1.md
│   └── note2.md
└── note3.md
```

## Development

### Prerequisites

- Rust 1.75 or later
- Cargo

### Building

```bash
# Development build
cargo build

# Release build
cargo build --release

# Run with logging
RUST_LOG=debug cargo run
```

### Project Structure

```
grimoire/
├── src/
│   ├── main.rs          # Application entry point
│   ├── app.rs           # Main application logic
│   ├── state.rs         # Application state management
│   ├── file_manager.rs  # File system operations
│   ├── markdown.rs      # Markdown rendering
│   ├── utils.rs         # Utility functions
│   └── components/
│       ├── sidebar.rs   # Sidebar component
│       └── note_view.rs # Note view/edit component
├── Cargo.toml
├── Dockerfile
└── docker-compose.yml
```

## Docker Development

For containerized development:

```bash
# Build the container
docker-compose build

# Run the container
docker-compose up

# Access notes volume
docker volume inspect grimoire_grimoire-notes
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Acknowledgments

- Inspired by Apple Notes and Obsidian
- Built with [ratatui](https://github.com/ratatui-org/ratatui) (formerly tui-rs)
- Markdown parsing with [pulldown-cmark](https://github.com/raphlinus/pulldown-cmark)

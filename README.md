# Grimoire

A beautiful, resource-efficient terminal-based notes application built with Rust.

## Features

- **Beautiful TUI**: Inspired by Apple Notes, with a clean and intuitive interface
- **Sidebar Navigation**: Browse folders and notes with ease
- **Markdown Support**: Write and view notes with markdown formatting
- **Note Linking**: Link between notes using `[[note name]]` syntax
- **File Management**: Create, edit, and delete notes and folders
- **Search**: Search by filename or content
- **Vim-like Navigation**: Familiar keyboard shortcuts (j/k for navigation, etc.)
- **Resource Efficient**: Built with Rust for minimal resource usage
- **User Sovereignty**: All notes stored as plain files in the filesystem

## Installation

### From Source

```bash
# Clone the repository
git clone <repository-url>
cd grimoire

# Build the application
cargo build --release

# Run the application
./target/release/grimoire
```

### Using Docker

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or build the image manually
docker build -t grimoire .
docker run -it -v $(pwd)/notes:/app/notes grimoire
```

## Usage

### Keyboard Shortcuts

#### Normal Mode
- `q` - Quit the application
- `n` - Create a new note
- `d` - Delete selected note/folder
- `e` - Edit the current note (enter Insert mode)
- `j` / `↓` - Move selection down
- `k` / `↑` - Move selection up
- `Enter` - Open selected note
- `/` - Search mode
- `:` - Command mode
- `Tab` - Toggle sidebar visibility
- `Esc` - Clear selection / Exit current mode

#### Insert Mode
- `Esc` - Save and exit to Normal mode
- Type normally to edit the note

#### Search Mode
- Type your search query
- `Enter` - Execute search
- `Esc` - Cancel search

#### Command Mode
- `:w` or `:write` - Save current note
- `:q` or `:quit` - Quit application
- `Esc` - Cancel command

### Note Organization

Notes are stored in the `notes/` directory as plain markdown files. You can organize them using folders, and the application will respect your filesystem structure.

### Markdown Support

Grimoire supports standard markdown syntax:
- Headers (`#`, `##`, `###`)
- Lists (`-`, `*`)
- Code blocks (```)
- Blockquotes (`>`)
- And more!

### Note Linking

Link to other notes using double brackets:
```
Check out [[another note]] for more information.
```

## Development

### Requirements

- Rust 1.75 or later
- Cargo

### Building

```bash
cargo build
```

### Running Tests

```bash
cargo test
```

## Architecture

- **Rust**: Core language for performance and safety
- **ratatui**: Terminal UI framework
- **crossterm**: Cross-platform terminal manipulation
- **pulldown-cmark**: Markdown parsing
- **walkdir**: File system traversal

## License

MIT License

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

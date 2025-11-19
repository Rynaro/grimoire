# Grimoire

A beautiful, resource-efficient terminal-based note-taking application inspired by Apple Notes and Obsidian.

## Features

- **Sidebar Navigation**: Browse folders and notes with an intuitive sidebar
- **Markdown Support**: Full markdown rendering with syntax highlighting
- **Note Linking**: Support for both wiki-style links `[[note_name]]` and markdown links
- **File Management**: Create, delete, search files and content
- **Beautiful TUI**: Modern terminal interface with color-coded elements
- **Resource Efficient**: Built with Rust for optimal performance

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
# Build the Docker image
docker-compose build

# Run the application
docker-compose run --rm grimoire
```

For development with local notes directory:

```bash
# Mount your local notes directory
docker-compose run --rm -v $(pwd)/notes:/root/.grimoire grimoire
```

## Usage

### Basic Navigation

- `j` / `↓` - Navigate down in sidebar
- `k` / `↑` - Navigate up in sidebar
- `Enter` - Select/open note
- `Tab` - Switch focus between sidebar and editor
- `q` - Quit application
- `Esc` - Exit edit mode or cancel search

### Note Management

- `n` - Create a new note
- `d` - Delete current note
- `e` - Edit current note
- `/` - Search notes (filename and content)

### Note Linking

Grimoire supports two types of note links:

1. **Wiki-style links**: `[[note_name]]` - Creates a link to another note
2. **Markdown links**: `[Link Text](note_name.md)` - Standard markdown links

Press `l` while viewing a note to navigate to the first linked note.

### File Storage

Notes are stored in `~/.grimoire/` directory. All notes are plain markdown files (`.md`), giving you complete control over your data. You can:

- Edit notes with any text editor
- Use git to version control your notes
- Sync notes across devices using your preferred method
- Organize notes in folders

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `q` | Quit application |
| `Esc` | Exit edit/search mode |
| `e` | Edit current note |
| `n` | Create new note |
| `d` | Delete current note |
| `/` | Search notes |
| `Tab` | Switch focus (sidebar ↔ editor) |
| `j`/`↓` | Navigate down |
| `k`/`↑` | Navigate up |
| `Enter` | Select/open note |
| `l` | Navigate to linked note |

## Development

### Prerequisites

- Rust 1.75 or later
- Cargo (Rust package manager)

### Building

```bash
cargo build
```

### Running Tests

```bash
cargo test
```

### Docker Development

```bash
# Build for development
docker-compose build

# Run with local notes mounted
docker-compose run --rm -v $(pwd)/notes:/root/.grimoire grimoire
```

## Architecture

- **Language**: Rust
- **TUI Framework**: Ratatui (formerly tui-rs)
- **Markdown Parser**: pulldown-cmark
- **Terminal Backend**: crossterm

## Design Philosophy

Grimoire is designed with the following principles:

1. **User Sovereignty**: Your notes are stored as plain markdown files - you own your data
2. **Resource Efficiency**: Built with Rust for minimal resource usage
3. **Beautiful UX**: Terminal interface doesn't mean sacrificing aesthetics
4. **Simplicity**: Focus on core note-taking functionality

## License

[Add your license here]

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

# Grimoire

A beautiful, terminal-based notes application built with Ruby. Grimoire provides a modern TUI (Terminal User Interface) experience inspired by Apple Notes and Obsidian, while keeping your notes as plain markdown files in the filesystem.

## Features

- **Beautiful TUI**: Clean, intuitive interface with sidebar navigation
- **Markdown Support**: Full markdown editing and rendering
- **Note Linking**: Support for wiki-style links (`[[note name]]`) and markdown links
- **File Management**: Create, delete, search files and content
- **Folder Organization**: Organize notes in folders
- **Search**: Search across file names and content
- **Lightweight**: Minimal resource usage while maintaining functionality
- **File System Based**: Your notes are stored as plain `.md` files - you have full control

## Installation

### Using Bundler

```bash
bundle install
```

### Using Docker (Recommended for Development)

```bash
docker-compose build
docker-compose run --rm grimoire
```

Or for interactive development:

```bash
docker-compose up
```

## Usage

### Basic Usage

```bash
ruby bin/grimoire
```

Or specify a custom notes directory:

```bash
GRIMOIRE_NOTES_DIR=/path/to/notes ruby bin/grimoire
```

### Keyboard Shortcuts

#### Navigation
- `↑` / `k` - Move up in sidebar
- `↓` / `j` - Move down in sidebar
- `Page Up` - Scroll note up
- `Page Down` - Scroll note down

#### Note Operations
- `e` - Enter edit mode
- `v` - Enter view mode
- `n` - Create new note
- `d` - Delete selected note/folder
- `/` - Search mode
- `ESC` - Exit search/edit mode
- `Ctrl+S` - Save note (in edit mode)
- `q` - Quit application

#### Search
- `/` - Enter search mode
- Type to search across note content
- `Enter` - Open selected search result
- `ESC` - Exit search mode

## Notes Directory Structure

By default, Grimoire stores notes in `~/.grimoire/notes/`. You can organize notes in folders:

```
~/.grimoire/notes/
├── note1.md
├── note2.md
└── folder1/
    ├── note3.md
    └── note4.md
```

## Note Linking

Grimoire supports two types of note linking:

1. **Wiki-style links**: `[[note name]]` - Creates a link to another note
2. **Markdown links**: `[link text](note.md)` or `[link text](folder/note.md)`

## Development

### Project Structure

```
.
├── lib/
│   └── grimoire/
│       ├── application.rb          # Main application class
│       ├── components/
│       │   ├── sidebar.rb          # Sidebar component
│       │   └── note_area.rb        # Note viewing/editing area
│       └── utils/
│           ├── file_manager.rb     # File operations
│           ├── markdown_renderer.rb # Markdown processing
│           └── search.rb           # Search functionality
├── bin/
│   └── grimoire                    # Executable entry point
├── Gemfile                         # Dependencies
└── Dockerfile                      # Container setup
```

### Dependencies

- **curses**: Terminal UI framework
- **pastel**: Terminal colors and styling
- **rouge**: Syntax highlighting
- **kramdown**: Markdown parsing
- **kramdown-parser-gfm**: GitHub Flavored Markdown support

### Running Tests

```bash
# Install dependencies
bundle install

# Run the application
ruby bin/grimoire
```

### Docker Development

The Docker setup mounts your local `notes/` directory and code, making development easy:

```bash
# Build and run
docker-compose up

# Rebuild after dependency changes
docker-compose build

# Run in detached mode
docker-compose up -d
```

## Security Considerations

All dependencies have been chosen with security in mind:
- **curses**: Standard library, well-maintained
- **pastel**: Pure Ruby, no external dependencies
- **rouge**: Syntax highlighter, widely used
- **kramdown**: Markdown parser, actively maintained

Notes are stored as plain text files in your filesystem - no database, no cloud sync, full control.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License - see LICENSE file for details

## Roadmap

Future enhancements may include:
- Enhanced markdown rendering with syntax highlighting
- Better note linking navigation
- Tags and metadata support
- Export functionality
- Themes and customization
- Plugin system

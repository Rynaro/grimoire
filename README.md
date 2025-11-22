# 📖 Grimoire

> Your personal knowledge codex - A beautiful, fast, and minimalist terminal-based note-taking application.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Go Version](https://img.shields.io/badge/go-1.21+-00ADD8.svg)
![Platform](https://img.shields.io/badge/platform-linux%20%7C%20macos%20%7C%20windows-lightgrey.svg)

## ✨ Features

- 📁 **Folder Organization** - Organize notes in a hierarchical folder structure
- 📝 **Markdown Support** - Write with full markdown support and beautiful syntax highlighting
- 🎨 **Beautiful TUI** - Apple Notes-inspired interface with smooth navigation
- ⚡ **Lightning Fast** - Built with Go for minimal resource usage and maximum speed
- 🔍 **Powerful Search** - Search by filename or content across your entire knowledge base
- 💾 **Filesystem-Based** - Your notes, your files, your sovereignty - stored as plain markdown
- 🔗 **Note Linking** - Link notes together using `[[note name]]` syntax (rendered in markdown)
- ⌨️ **Vim-Style Navigation** - Familiar keybindings for efficient navigation
- 🐳 **Docker Ready** - Quick preview and development with included Docker setup

## 🚀 Quick Start

### Using Go (Recommended)

```bash
# Install
go install github.com/yourusername/grimoire@latest

# Run
grimoire
```

### Build from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/grimoire.git
cd grimoire

# Build
make build

# Run
./grimoire
```

### Using Docker

```bash
# Build and run with docker-compose
make docker-compose-up

# Or with plain Docker
make docker-run
```

## 📖 Usage

### Default Notes Location

By default, Grimoire stores your notes in `~/.grimoire/`. You can specify a custom directory:

```bash
grimoire /path/to/your/notes
```

### Keyboard Shortcuts

#### Navigation
- `Tab` / `Shift+Tab` - Cycle between panes (Folders → Notes → Content)
- `↑` / `k` - Move up
- `↓` / `j` - Move down
- `g` - Go to top
- `G` - Go to bottom
- `PgUp` / `PgDn` - Scroll content page by page
- `Enter` - Open folder or note
- `Backspace` - Navigate to parent folder

#### File Operations
- `n` - Create new note
- `N` - Create new folder
- `d` - Delete current note/folder (requires confirmation)
- `e` - Edit current note
- `Esc` - Exit edit mode (saves automatically)
- `Ctrl+S` - Quick save while editing

#### Search
- `/` - Search notes by filename
- `?` - Search notes by content
- `Enter` - Execute search
- `Esc` - Cancel search

#### General
- `q` - Quit application
- `Ctrl+C` - Force quit

## 🎨 Interface

Grimoire features a three-pane layout inspired by Apple Notes:

```
┌─────────────┬──────────────┬────────────────────────┐
│  📁 FOLDERS │  📝 NOTES    │    📄 CONTENT          │
│             │              │                        │
│ 📄 All Notes│ 📄 Welcome   │  # Welcome to Grimoire │
│ 📁 Projects │ 📄 Ideas     │                        │
│ 📁 Personal │ 📁 Archive   │  Your notes here...    │
│ 📁 Work     │              │                        │
│             │              │                        │
└─────────────┴──────────────┴────────────────────────┘
  VIEW                  📄 All Notes          q to quit
```

## 🏗️ Architecture

### Technology Stack

- **Language**: Go 1.21+
- **TUI Framework**: [Bubble Tea](https://github.com/charmbracelet/bubbletea) by Charm
- **Styling**: [Lipgloss](https://github.com/charmbracelet/lipgloss)
- **Markdown Rendering**: [Glamour](https://github.com/charmbracelet/glamour)
- **Components**: [Bubbles](https://github.com/charmbracelet/bubbles)

### Project Structure

```
grimoire/
├── main.go                 # Application entry point
├── internal/
│   ├── app/
│   │   ├── app.go         # Main TUI application
│   │   └── handlers.go    # Event handlers and commands
│   └── storage/
│       └── storage.go     # Filesystem storage implementation
├── Dockerfile             # Docker container configuration
├── docker-compose.yml     # Docker Compose setup
├── Makefile              # Build automation
└── README.md             # This file
```

## 🔧 Development

### Prerequisites

- Go 1.21 or higher
- Make (optional, for using Makefile)
- Docker (optional, for containerized development)

### Development Workflow

```bash
# Install dependencies
make deps

# Run in development mode
make dev

# Format code
make fmt

# Run tests (9 unit tests, all passing ✅)
make test

# Build binary
make build
```

### Docker Development

```bash
# Build Docker image
make docker-build

# Run in Docker with volume mount
make docker-run

# Use docker-compose for development
make docker-compose-up
```

Your notes will be stored in the `./notes` directory when using Docker.

## 🎯 Design Philosophy

Grimoire is built on these core principles:

1. **User Sovereignty** - Your notes are stored as plain markdown files in your filesystem. No proprietary formats, no lock-in.

2. **Performance First** - Written in Go with minimal dependencies. Grimoire uses very few resources and starts instantly.

3. **Beauty & Functionality** - Terminal applications don't have to be ugly. Grimoire brings modern design to the terminal.

4. **Simplicity** - Complex features are hidden until needed. The interface is clean and focused.

## 🗺️ Roadmap

### Completed ✅
- ✅ Three-pane interface (Folders, Notes, Content)
- ✅ Markdown rendering with syntax highlighting
- ✅ File management (Create, Delete)
- ✅ Search (Filename and Content)
- ✅ Edit mode with auto-save
- ✅ Folder navigation
- ✅ Docker support

### Future Features 🚀
- [ ] Vim mode (advanced keybindings)
- [ ] Tags system
- [ ] Templates for new notes
- [ ] Export to PDF/HTML
- [ ] Cloud sync support (optional)
- [ ] Themes and customization
- [ ] Note encryption
- [ ] Git integration for version control
- [ ] Mobile companion app

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- [Charm](https://charm.sh/) - For the amazing TUI libraries
- [Apple Notes](https://www.apple.com/notes/) - Design inspiration
- The Go community - For excellent tooling and support

## 📧 Contact

For questions, suggestions, or discussions, please open an issue on GitHub.

---

**Built with ❤️ using Go and Bubble Tea**

*"Knowledge is power, but only if you can find it when you need it."*

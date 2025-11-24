# ✦ Grimoire

> A beautiful, lightweight terminal-based notes application built with Ruby

Grimoire is a terminal-based note-taking application inspired by Apple Notes and Obsidian, designed for users who want full sovereignty over their notes while enjoying a delightful terminal UI experience.

## ✨ Features

- 📝 **Markdown Support** - Full markdown rendering with syntax highlighting
- 🎨 **Beautiful TUI** - Elegant terminal interface with intuitive navigation
- 🔗 **Note Linking** - Connect your thoughts with `[[note name]]` syntax
- 📁 **Folder Organization** - Organize notes in folders that live in your filesystem
- 🔍 **Powerful Search** - Search by note names or content across all notes
- ⚡ **Lightning Fast** - Minimal resource usage, maximum productivity
- 🔒 **Privacy First** - Your notes, your filesystem, your control
- 🐳 **Docker Ready** - Easy setup with Docker for development and preview

## 🚀 Quick Start

### Using Docker (Recommended)

```bash
# Build and run
docker-compose up --build

# Or use docker directly
docker build -t grimoire .
docker run -it -v $(pwd)/notes:/root/grimoire_notes grimoire
```

### Local Installation

#### Prerequisites
- Ruby 3.0 or higher
- ncurses development libraries

#### Install Dependencies

```bash
# On Ubuntu/Debian
sudo apt-get install ruby ruby-dev libncurses-dev

# On macOS
brew install ruby ncurses

# Install gems
bundle install
```

#### Run Grimoire

```bash
ruby grimoire.rb
```

## 🎮 Keyboard Shortcuts

### Navigation
- `j/k` or `↓/↑` - Move selection up/down
- `h/l` or `←/→` - Switch between folders and notes
- `Space` or `PgDn` - Scroll down in note view
- `b` or `PgUp` - Scroll up in note view

### Actions
- `Enter` - Open selected note
- `e` - Edit current note
- `n` - Create new note
- `d` - Delete current note
- `/` or `s` - Search notes
- `s` (in edit mode) - Save changes

### Edit Mode
- `j/k` - Move between lines
- `i` - Insert new line
- `x` - Delete current line
- `o` - Edit line (simplified)
- `q` or `ESC` - Exit edit mode

### Other
- `?` - Toggle help menu
- `q` - Quit application

## 📁 Note Storage

Notes are stored as plain markdown files in your filesystem:

```
~/grimoire_notes/
  ├── note1.md
  ├── note2.md
  └── folder/
      └── note3.md
```

You can customize the storage location by setting the `GRIMOIRE_NOTES_DIR` environment variable:

```bash
export GRIMOIRE_NOTES_DIR=/path/to/your/notes
ruby grimoire.rb
```

## 🔗 Note Linking

Create connections between notes using wiki-style links:

```markdown
# My Note

This relates to [[Another Note]] and [[Important Ideas]].
```

Linked notes will be highlighted in the viewer.

## 🎨 Markdown Support

Grimoire supports full markdown syntax:

- **Headers** (H1-H6)
- **Bold**, *italic*, and ***bold italic***
- `code blocks` with syntax highlighting
- > Blockquotes
- Lists (ordered and unordered)
- [Links](https://example.com)
- Horizontal rules
- Tables (via Redcarpet)

### Syntax Highlighting

Code blocks support syntax highlighting for many languages:

````markdown
```ruby
def hello
  puts "Hello, Grimoire!"
end
```
````

## 🔧 Development

### Project Structure

```
grimoire/
├── grimoire.rb              # Main entry point
├── lib/
│   ├── core/
│   │   └── notes_manager.rb # File system management
│   ├── renderers/
│   │   └── markdown_renderer.rb # Markdown to terminal rendering
│   └── ui/
│       └── application.rb   # Main TUI controller
├── Gemfile                  # Ruby dependencies
├── Dockerfile              # Container configuration
└── docker-compose.yml      # Docker Compose setup
```

### Dependencies

Core gems used (all security-conscious choices):

- **curses** - Terminal UI framework
- **rouge** - Syntax highlighting
- **redcarpet** - Markdown parsing
- **pastel** - Terminal colors
- **tty-*** - TTY toolkit components

### Running Tests

```bash
# TODO: Add tests
bundle exec rspec
```

## 🐳 Docker Development

The included Docker setup provides an isolated environment:

```bash
# Build image
docker-compose build

# Run with volume mounting for live development
docker-compose up

# Access shell in container
docker-compose run grimoire /bin/sh
```

Your notes will be persisted in the `./notes` directory on your host machine.

## 🎯 Roadmap

- [x] Basic TUI with sidebar and note area
- [x] Markdown rendering with syntax highlighting
- [x] File management (create, delete, read, write)
- [x] Note linking support
- [x] Docker setup
- [ ] Full-featured editor (currently simplified)
- [ ] Interactive search with fuzzy matching
- [ ] Note templates
- [ ] Tags support
- [ ] Export to PDF/HTML
- [ ] Git integration for versioning
- [ ] Encryption support
- [ ] Plugin system

## 🤝 Contributing

Contributions are welcome! This is a work in progress.

## 📄 License

MIT License - Your notes, your rules.

## 💬 Philosophy

Grimoire believes in:

1. **User Sovereignty** - Your notes belong to you, stored in plain text on your filesystem
2. **Simplicity** - Do one thing well: manage notes elegantly in the terminal
3. **Performance** - Lightweight and fast, never bloated
4. **Privacy** - No cloud, no tracking, no telemetry
5. **Beauty** - Terminal apps can be beautiful and joyful to use

---

Built with ♥ and Ruby

**Note**: This is a first iteration with core functionality. The editor is simplified and some features are placeholders for future development. Contributions welcome!

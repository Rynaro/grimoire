# ✦ Grimoire

> A beautiful, lightweight terminal-based notes application built with Ruby, following Domain-Driven Design and SOLID principles

Grimoire is a terminal-based note-taking application inspired by Apple Notes and Obsidian, designed for users who want full sovereignty over their notes while enjoying a delightful terminal UI experience.

## ✨ Features

- 📝 **Markdown Support** - Full markdown rendering with syntax highlighting
- 🎨 **Beautiful TUI** - Elegant terminal interface with intuitive navigation
- 🔗 **Note Linking** - Connect your thoughts with `[[note name]]` syntax
- 📁 **Folder Organization** - Organize notes in folders that live in your filesystem
- 🔍 **Powerful Search** - Search by note names or content across all notes
- ⚡ **Lightning Fast** - Minimal resource usage, maximum productivity
- 🔒 **Privacy First** - Your notes, your filesystem, your control
- 🏗️ **Clean Architecture** - Built with DDD and SOLID principles
- 🐳 **Docker Ready** - Easy setup with Docker for development and preview

## 🏛️ Architecture

Grimoire follows **Domain-Driven Design** (DDD) with a clean layered architecture:

```
┌─────────────────────────────────────────┐
│  UI Layer (Terminal Components)        │  ← Presentation
├─────────────────────────────────────────┤
│  Application Layer (Use Cases)         │  ← Orchestration
├─────────────────────────────────────────┤
│  Domain Layer (Entities, Value Objects)│  ← Business Logic
├─────────────────────────────────────────┤
│  Infrastructure (Persistence, Rendering)│  ← Technical Details
└─────────────────────────────────────────┘
```

### SOLID Principles

- ✅ **Single Responsibility**: Each class has one reason to change
- ✅ **Open/Closed**: Open for extension, closed for modification
- ✅ **Liskov Substitution**: Proper interface implementations
- ✅ **Interface Segregation**: Small, focused interfaces
- ✅ **Dependency Inversion**: Depend on abstractions via DI container

## 🚀 Quick Start

### Using Docker (Recommended)

**Important**: Use `docker-compose run` (not `up`) for proper terminal interaction:

```bash
# Easy way - Use the helper script
./docker-run.sh

# Or manually with docker-compose
docker-compose build
docker-compose run --rm grimoire

# Or with docker directly
docker build -t grimoire .
docker run -it --rm -v $(pwd)/notes:/root/grimoire_notes grimoire
```

**Why `run` instead of `up`?** Curses applications need proper TTY allocation, which `docker-compose run` provides but `up` doesn't.

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

Or use the setup script:

```bash
./setup.sh
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
- `/` - Search notes
- `s` (in edit mode) - Save changes

### Edit Mode
- `j/k` - Move between lines
- `i` - Insert new line
- `x` - Delete current line
- `q` or `ESC` - Exit edit mode

### Other
- `?` - Toggle help menu
- `q` - Quit application

## 📁 Project Structure

```
grimoire/
├── lib/
│   ├── domain/                    # Domain Layer (DDD)
│   │   ├── entities/
│   │   │   └── note.rb           # Note aggregate root
│   │   ├── value_objects/
│   │   │   ├── note_path.rb
│   │   │   ├── note_content.rb
│   │   │   ├── note_metadata.rb
│   │   │   └── folder_path.rb
│   │   ├── repositories/
│   │   │   └── note_repository.rb # Repository interface
│   │   └── services/
│   │       └── note_search_service.rb
│   │
│   ├── application/               # Application Layer
│   │   └── use_cases/
│   │       ├── create_note.rb
│   │       ├── update_note.rb
│   │       ├── delete_note.rb
│   │       ├── list_notes.rb
│   │       ├── search_notes.rb
│   │       └── get_note.rb
│   │
│   ├── infrastructure/            # Infrastructure Layer
│   │   ├── persistence/
│   │   │   └── file_system_note_repository.rb
│   │   └── rendering/
│   │       ├── markdown_renderer.rb
│   │       └── terminal_formatter.rb
│   │
│   ├── ui/                        # UI Layer
│   │   └── terminal/
│   │       ├── application.rb    # Main controller
│   │       └── components/       # UI components
│   │           ├── sidebar.rb
│   │           ├── note_viewer.rb
│   │           ├── note_editor.rb
│   │           ├── status_bar.rb
│   │           └── help_overlay.rb
│   │
│   └── container.rb               # DI Container
│
├── grimoire.rb                    # Entry point
├── Gemfile                        # Dependencies
├── Dockerfile                     # Container setup
└── docker-compose.yml             # Docker Compose
```

## 🎯 Domain Model

### Entities
- **Note** - Aggregate root with identity and lifecycle

### Value Objects
- **NotePath** - Immutable file path
- **NoteContent** - Markdown content
- **NoteMetadata** - Name, timestamps, tags
- **FolderPath** - Folder location

### Domain Services
- **NoteSearchService** - Complex search operations

### Repositories
- **NoteRepository** - Interface for persistence
- **FileSystemNoteRepository** - File system implementation

## 📦 Technology Stack

### Core
- **Language**: Ruby 3.2+
- **Architecture**: Domain-Driven Design (DDD)
- **Patterns**: Repository, Dependency Injection, Value Object
- **TUI Framework**: Curses
- **Markdown Parser**: Redcarpet
- **Syntax Highlighting**: Rouge
- **Terminal Colors**: Pastel
- **DI Container**: Dry-Container & Dry-AutoInject

### Security Considerations
All dependencies chosen for:
- Active maintenance
- Security track record  
- Minimal dependency chains
- Pure Ruby implementations where possible

## 🔧 Development

### Using Make

```bash
make help          # Show all commands
make install       # Install dependencies
make run          # Run locally
make docker-build  # Build Docker image
make docker-run    # Run in Docker
make docker-shell  # Shell access in container
```

### Dependency Injection

Grimoire uses `dry-container` for dependency injection:

```ruby
# Define dependencies in container.rb
Container.register :note_repository do
  FileSystemNoteRepository.new
end

# Auto-inject into classes
class Application
  include Import[
    :list_notes_use_case,
    :create_note_use_case,
    :markdown_renderer
  ]
end
```

### Adding New Use Cases

1. Create use case in `lib/application/use_cases/`
2. Register in `lib/container.rb`
3. Inject into UI layer
4. Use in controller

Example:

```ruby
# lib/application/use_cases/archive_note.rb
class ArchiveNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(path:)
    note = @repository.find_by_path(path)
    # Archive logic...
  end
end

# lib/container.rb
register :archive_note_use_case do
  Application::UseCases::ArchiveNote.new(resolve(:note_repository))
end
```

## 📚 Documentation

- **Architecture**: See `ARCHITECTURE.md` for detailed architecture
- **DDD Guide**: `notes/examples/DDD_Architecture_Guide.md`
- **SOLID Principles**: `notes/examples/SOLID_Principles.md`

## 🧪 Testing (Planned)

The architecture makes testing straightforward:

```ruby
# Unit test: Domain
describe Note do
  it 'extracts linked notes' do
    note = Note.new(...)
    expect(note.linked_notes).to eq(['Other Note'])
  end
end

# Integration test: Use Cases
describe CreateNote do
  it 'creates and saves note' do
    mock_repo = instance_double(NoteRepository)
    use_case = CreateNote.new(mock_repo)
    # ...
  end
end
```

## 🎯 Design Decisions

### Why DDD?

- **Clear boundaries** between layers
- **Domain-focused** - business logic is central
- **Testable** - easy to mock and test
- **Maintainable** - changes are localized
- **Scalable** - easy to extend

### Why SOLID?

- **Single Responsibility** - easier to understand
- **Open/Closed** - extend without modifying
- **Dependency Inversion** - loose coupling
- **Interface Segregation** - focused interfaces

### Why File System?

- **User sovereignty** - complete control
- **No vendor lock-in** - plain text files
- **Git-friendly** - version control ready
- **Transparent** - easy to understand
- **Portable** - works anywhere

## 🔮 Future Enhancements

- [ ] Full-featured editor
- [ ] Interactive fuzzy search
- [ ] Note templates
- [ ] Tags and metadata
- [ ] Export to PDF/HTML
- [ ] Git integration
- [ ] Encryption support
- [ ] Plugin system
- [ ] Multiple repository backends (Database, Cloud)

## 🤝 Contributing

Contributions are welcome! See `CONTRIBUTING.md` for guidelines.

When contributing, please maintain:
- DDD architecture
- SOLID principles
- Clean separation of concerns
- Test coverage (when added)

## 📄 License

MIT License - See `LICENSE` file.

Your notes, your rules. ✨

## 💬 Philosophy

Grimoire believes in:

1. **User Sovereignty** - Your notes belong to you
2. **Clean Architecture** - Code that's easy to understand and maintain
3. **SOLID Design** - Principles that lead to better software
4. **Privacy** - No cloud, no tracking, no telemetry
5. **Beauty** - Terminal apps can be beautiful and joyful

---

Built with ♥, Ruby, and clean architecture principles.

**Note**: The editor is simplified for this version. For full editing capabilities, notes can be edited with any external text editor since they're plain markdown files!

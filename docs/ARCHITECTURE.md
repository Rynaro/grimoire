# Grimoire Architecture

This document describes the architecture and design decisions behind Grimoire.

## Technology Stack

### Core
- **Language**: Go 1.21+
- **TUI Framework**: Bubble Tea (The Elm Architecture for Go)
- **Styling**: Lipgloss (terminal styling)
- **Markdown Rendering**: Glamour (markdown rendering)
- **UI Components**: Bubbles (pre-built components)

### Why Go?

1. **Performance**: Compiled, fast, minimal resource usage
2. **Single Binary**: Easy distribution, no runtime dependencies
3. **Concurrency**: Built-in goroutines for responsive UI
4. **Cross-platform**: Works on Linux, macOS, Windows
5. **Excellent TUI Libraries**: Charm.sh ecosystem

### Why Not Python?

While Python is excellent for many use cases, we chose Go because:
- Faster startup time and execution
- No runtime dependency (Python interpreter)
- Better resource efficiency
- Single binary distribution
- More responsive TUI

## Project Structure

```
grimoire/
├── main.go                      # Application entry point
├── internal/                    # Internal packages (not importable by others)
│   ├── app/
│   │   ├── app.go              # Main TUI model and views
│   │   └── handlers.go         # Event handlers and commands
│   └── storage/
│       └── storage.go          # Storage interface and filesystem implementation
├── docs/                       # Documentation
│   ├── ARCHITECTURE.md         # This file
│   └── KEYBINDINGS.md         # Keybindings reference
├── examples/                   # Example notes
│   └── notes/                  # Sample notes structure
├── Dockerfile                  # Container configuration
├── docker-compose.yml          # Docker Compose setup
├── Makefile                    # Build automation
├── go.mod                      # Go module definition
├── go.sum                      # Go module checksums
└── README.md                   # Main documentation
```

## Architecture Overview

Grimoire follows a clean architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────┐
│              main.go                        │
│         (Application Entry)                 │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│           internal/app/                     │
│     (TUI Layer - Bubble Tea)                │
│  ┌─────────────────────────────────────┐   │
│  │  Model (State Management)           │   │
│  │  - UI state                         │   │
│  │  - Current selections               │   │
│  │  - Mode tracking                    │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  View (Rendering)                   │   │
│  │  - Three-pane layout                │   │
│  │  - Markdown rendering               │   │
│  │  - Status bar                       │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  Update (Event Handling)            │   │
│  │  - Keyboard input                   │   │
│  │  - Commands                         │   │
│  │  - State transitions                │   │
│  └─────────────────────────────────────┘   │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│         internal/storage/                   │
│      (Storage Layer - Filesystem)           │
│  ┌─────────────────────────────────────┐   │
│  │  Storage Interface                  │   │
│  │  - CRUD operations                  │   │
│  │  - Search                           │   │
│  └─────────────────────────────────────┘   │
│  ┌─────────────────────────────────────┐   │
│  │  FileStorage Implementation         │   │
│  │  - Markdown files                   │   │
│  │  - Directory structure              │   │
│  └─────────────────────────────────────┘   │
└─────────────────┬───────────────────────────┘
                  │
                  ▼
┌─────────────────────────────────────────────┐
│            Filesystem                       │
│     ~/.grimoire/ (or custom path)           │
│  ├── Note1.md                               │
│  ├── Note2.md                               │
│  └── Folder/                                │
│      ├── Note3.md                           │
│      └── Subfolder/                         │
└─────────────────────────────────────────────┘
```

## Design Patterns

### The Elm Architecture (via Bubble Tea)

Grimoire uses The Elm Architecture, which provides:

1. **Model**: Single source of truth for application state
2. **Update**: Pure functions that handle events and return new state
3. **View**: Pure functions that render the UI based on state

Benefits:
- Predictable state management
- Easy to test
- Clear data flow
- Time-travel debugging possible

### Repository Pattern

The storage layer uses a repository pattern:

```go
type Storage interface {
    GetNotes(folder string) ([]Note, error)
    SaveNote(path, content string) error
    CreateNote(folder, name string) (string, error)
    // ... more methods
}
```

Benefits:
- Easy to swap implementations (filesystem, database, cloud)
- Testable with mocks
- Clear contract

## Data Flow

### Loading Notes

```
User navigates → Update handler → LoadNotes command → 
Storage layer reads filesystem → Returns notes → 
Update receives message → Updates model state → 
View renders new state
```

### Editing Note

```
User presses 'e' → Switch to Edit mode → 
User edits in textarea → User presses Esc → 
SaveNote command → Storage writes file → 
Switch to View mode → Render updated note
```

### Search

```
User presses '/' → Switch to Search mode → 
User types query → User presses Enter → 
SearchNotes command → Storage walks filesystem → 
Returns results → Update notes list → 
View renders results
```

## Key Components

### App Model

```go
type Model struct {
    storage        storage.Storage  // Storage backend
    folders        []storage.Note   // List of folders
    notes          []storage.Note   // List of notes
    currentFolder  string           // Current folder path
    currentNote    *storage.Note    // Currently selected note
    folderIndex    int              // Selected folder index
    noteIndex      int              // Selected note index
    activePane     Pane             // Currently focused pane
    mode           Mode             // Current mode (View/Edit/Search)
    viewport       viewport.Model   // Content viewer
    textarea       textarea.Model   // Content editor
    searchInput    textinput.Model  // Search input
    // ... more fields
}
```

### Storage Note

```go
type Note struct {
    Name     string      // File/folder name
    Path     string      // Full path
    Content  string      // File content (for files)
    Modified time.Time   // Last modified time
    IsFolder bool        // Is this a folder?
}
```

## State Management

### Modes

Grimoire operates in different modes:

- **ModeView**: Normal viewing and navigation
- **ModeEdit**: Editing a note
- **ModeSearch**: Searching by filename
- **ModeSearchContent**: Searching by content
- **ModeCreateNote**: Creating a new note
- **ModeCreateFolder**: Creating a new folder
- **ModeDelete**: Confirming deletion

### Panes

Three panes with independent focus:

- **PaneFolders**: Folder list
- **PaneNotes**: Notes list
- **PaneContent**: Note content (view/edit)

## Rendering Pipeline

### Markdown Rendering

1. Raw markdown text from file
2. Glamour renders to ANSI-styled text
3. Viewport displays with scrolling
4. Lipgloss applies additional styling

### Layout

1. Calculate pane widths based on terminal size
2. Render each pane separately
3. Apply borders and styling
4. Join horizontally with Lipgloss
5. Add status bar at bottom

## Performance Considerations

### Fast Startup

- No initialization beyond directory check
- Lazy loading of note content
- Efficient file system operations

### Low Memory Usage

- Only load content for current note
- Stream large files
- Efficient data structures

### Responsive UI

- Non-blocking operations
- Debounced search
- Efficient rendering

## Storage Design

### Filesystem Structure

```
~/.grimoire/
├── Welcome.md              # Auto-created welcome note
├── Personal/
│   ├── Journal.md
│   └── Ideas.md
├── Work/
│   ├── Projects/
│   │   ├── Project1.md
│   │   └── Project2.md
│   └── Meetings.md
└── References.md
```

### Advantages

1. **Transparency**: Plain markdown files, no database
2. **Portability**: Easy to sync, backup, or migrate
3. **Accessibility**: Use any text editor
4. **Version Control**: Works with Git
5. **Ownership**: User owns their data

### Trade-offs

- No complex queries (but search is fast enough)
- No transactions (but notes are independent)
- No schema enforcement (but markdown is flexible)

## Future Architecture

### Planned Improvements

1. **Plugin System**: Allow custom storage backends
2. **Configuration**: YAML/TOML config file
3. **Themes**: Customizable color schemes
4. **Caching**: Speed up large repositories
5. **Indexing**: Faster full-text search

### Extensibility

The architecture supports future extensions:

- Cloud sync plugins
- Encryption layer
- Git integration
- Export plugins
- Custom renderers

## Testing Strategy

### Unit Tests

- Storage operations
- State transitions
- Command handlers

### Integration Tests

- Full user workflows
- File system operations
- Search functionality

### Manual Testing

- Different terminal emulators
- Various screen sizes
- Edge cases

## Security Considerations

### Current

- Read/write only in designated directory
- No network operations
- No external commands
- Sanitized file paths

### Future

- Note encryption
- Access control
- Secure sync

## Performance Benchmarks

Expected performance:

- **Startup**: < 100ms
- **Search (1000 notes)**: < 1s
- **File operations**: < 10ms
- **Memory usage**: < 10MB

## Conclusion

Grimoire's architecture prioritizes:

1. **Simplicity**: Easy to understand and maintain
2. **Performance**: Fast and resource-efficient
3. **User Sovereignty**: Plain files, no lock-in
4. **Extensibility**: Easy to add features

The use of Go and Bubble Tea provides an excellent foundation for a beautiful, fast, and maintainable terminal application.

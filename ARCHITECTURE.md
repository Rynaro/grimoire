# Grimoire Architecture

This document provides an overview of Grimoire's internal architecture.

## High-Level Overview

```
┌─────────────────────────────────────────────┐
│           grimoire.rb (Entry Point)         │
└────────────────┬────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────┐
│         UI::Application (Main TUI)          │
│  - Event loop                               │
│  - Window management                        │
│  - Input handling                           │
│  - View rendering                           │
└───────┬──────────────────────┬──────────────┘
        │                      │
        ▼                      ▼
┌──────────────────┐  ┌───────────────────────┐
│  Core::          │  │  Renderers::          │
│  NotesManager    │  │  MarkdownProcessor    │
│                  │  │                       │
│ - File I/O       │  │ - Markdown parsing    │
│ - Note CRUD      │  │ - Syntax highlighting │
│ - Search         │  │ - Terminal formatting │
│ - Linking        │  │                       │
└──────┬───────────┘  └───────────────────────┘
       │
       ▼
┌──────────────────┐
│   Filesystem     │
│   (markdown)     │
└──────────────────┘
```

## Components

### 1. grimoire.rb (Entry Point)

The main entry point that:
- Initializes the application
- Handles top-level exception catching
- Provides graceful shutdown

### 2. UI::Application

The main TUI controller (`lib/ui/application.rb`):

**Responsibilities:**
- Initializing the curses environment
- Managing the main event loop
- Handling keyboard input
- Coordinating between UI components
- Managing application state (current note, mode, etc.)

**Key Methods:**
- `run()` - Main application loop
- `render_ui()` - Redraws the entire interface
- `render_sidebar()` - Renders folder/note list
- `render_main_area()` - Renders note content
- `handle_input()` - Processes keyboard events

**State Management:**
```ruby
@mode               # :view, :edit, :command
@current_folder     # Currently selected folder
@selected_note_index # Index of selected note
@current_note       # Currently open note
@scroll_offset      # Scroll position
@edit_buffer        # Lines of text in edit mode
```

### 3. Core::NotesManager

File system abstraction (`lib/core/notes_manager.rb`):

**Responsibilities:**
- Managing note files and directories
- CRUD operations on notes
- Searching notes and content
- Handling note links

**Key Methods:**
- `list_notes()` - Get all notes (with optional folder filter)
- `list_folders()` - Get all folders
- `read_note(path)` - Read note content
- `write_note(path, content)` - Save note
- `create_note(name, folder)` - Create new note
- `delete_note(path)` - Delete note
- `search_notes(query)` - Search by name
- `search_content(query)` - Full-text search
- `find_linked_notes(content)` - Extract [[links]]

**Data Structure:**
```ruby
{
  name: "My Note",           # Display name
  path: "folder/note.md",    # Relative path
  full_path: "/abs/path",    # Absolute path
  modified: Time             # Last modified time
}
```

### 4. Renderers::MarkdownProcessor

Markdown rendering (`lib/renderers/markdown_renderer.rb`):

**Responsibilities:**
- Converting markdown to terminal-formatted text
- Syntax highlighting for code blocks
- Styling headers, lists, quotes, etc.
- Processing [[note links]]

**Components:**
- `MarkdownRenderer` - Custom Redcarpet renderer
- `MarkdownProcessor` - Main processing interface

**Styling:**
- Uses `Pastel` for terminal colors
- Uses `Rouge` for syntax highlighting
- Custom rendering for each markdown element

## Data Flow

### Opening a Note

```
User Input (Enter key)
    ↓
UI::Application#handle_view_input
    ↓
UI::Application#open_selected_note
    ↓
Core::NotesManager#read_note
    ↓
[Filesystem read]
    ↓
Renderers::MarkdownProcessor#render
    ↓
UI::Application#render_viewer
    ↓
[Display on screen]
```

### Editing a Note

```
User Input (e key)
    ↓
UI::Application#enter_edit_mode
    ↓
Core::NotesManager#read_note
    ↓
[Load content into edit_buffer]
    ↓
[User edits with j/k/i/x/o]
    ↓
User Input (s key)
    ↓
UI::Application#save_note
    ↓
Core::NotesManager#write_note
    ↓
[Filesystem write]
```

### Searching Notes

```
User Input (/ key)
    ↓
UI::Application#search_notes
    ↓
Core::NotesManager#search_notes(query)
    ↓
[Filter notes by name]
    ↓
UI::Application#render_sidebar
    ↓
[Display filtered results]
```

## File System Structure

```
~/grimoire_notes/           # Root notes directory
  ├── note1.md             # Top-level note
  ├── note2.md
  └── folder1/             # Subfolder
      ├── note3.md
      └── subfolder/       # Nested folder
          └── note4.md
```

**Key Principles:**
1. All notes are `.md` files
2. Folders are regular directories
3. Structure mirrors filesystem
4. No database or index files
5. User has complete control

## Color Scheme

Curses color pairs (defined in `init_colors`):

```
1: Cyan on Black    - Borders, status bar
2: Yellow on Black  - Section headers
3: Green on Black   - Help text
4: White on Blue    - Selected items
5: Black on Cyan    - Modal backgrounds
6: Red on Black     - Edit mode indicators
7: Magenta on Black - Special elements
```

## Modes

### View Mode (`:view`)
- Default mode
- Navigate notes and folders
- Scroll through note content
- Read-only operations

**Available Commands:**
- Navigation: `j`, `k`, `h`, `l`, arrows
- Actions: `Enter`, `e`, `n`, `d`, `/`
- Scrolling: `Space`, `b`, PgUp, PgDn
- Quit: `q`

### Edit Mode (`:edit`)
- Active when editing a note
- Line-based editing (simplified)
- Save/discard changes

**Available Commands:**
- Navigation: `j`, `k`
- Edit: `i`, `x`, `o`
- Save: `s`
- Cancel: `q`, ESC

### Command Mode (`:command`)
- Future: interactive commands
- Currently not implemented
- Planned for search, filters, etc.

## Key Technical Decisions

### Why Curses?

- Native Ruby gem
- Cross-platform
- Well-documented
- Lightweight
- Full terminal control

### Why Redcarpet + Rouge?

- **Redcarpet**: Fast, secure markdown parser
- **Rouge**: Pure Ruby syntax highlighter
- No JavaScript dependencies
- Security-conscious choices
- Active maintenance

### Why File System Storage?

- User sovereignty
- No vendor lock-in
- Easy backup
- Git-friendly
- Transparent data format
- Works with any text editor

### Why Not vim/Emacs/etc?

- Learning curve
- Single-purpose focus
- Modern UX expectations
- Cross-platform consistency

## Performance Considerations

### Current Optimizations

1. **Lazy Loading**: Notes are only read when opened
2. **Cached Listings**: Directory scans are performed on-demand
3. **Partial Rendering**: Only visible lines are rendered
4. **Minimal Dependencies**: Keep gem count low

### Known Limitations

1. **Large Files**: No streaming for large notes
2. **Many Notes**: Linear search through all notes
3. **No Indexing**: Full-text search is O(n)
4. **Single-threaded**: UI blocks during I/O

### Future Optimizations

1. Add file watching (using `listen` gem)
2. Build search index
3. Implement virtual scrolling
4. Add caching layer
5. Async file operations

## Security Considerations

### File System Access

- Sandboxed to notes directory
- Path traversal prevention via `sanitize_filename`
- No shell command execution
- No eval or dynamic code

### Dependencies

All gems chosen for:
- Active maintenance
- Security track record
- Minimal dependency chains
- Pure Ruby when possible

### User Data

- No telemetry
- No network access
- No external services
- Everything local

## Extension Points

### Adding New Renderers

Implement a new renderer class:

```ruby
class MyRenderer < Redcarpet::Render::Base
  def initialize
    @pastel = Pastel.new
  end
  
  def header(text, level)
    # Custom header rendering
  end
  
  # ... more methods
end
```

### Adding New Commands

Add to `handle_view_input` or `handle_edit_input`:

```ruby
when 't'  # New command
  my_custom_action
end
```

### Adding New UI Components

Create in `lib/ui/`:

```ruby
module Grimoire
  module UI
    class MyComponent
      def render(window, x, y, width, height)
        # Rendering logic
      end
    end
  end
end
```

## Testing Strategy

### Unit Tests (Planned)

- Test `NotesManager` methods
- Test markdown rendering
- Test file system operations
- Mock file I/O

### Integration Tests (Planned)

- Test UI flows
- Test state transitions
- Test keyboard handling
- Use in-memory file system

### Manual Testing

Current approach:
- Run application
- Test each feature
- Verify file system changes
- Check different terminals

## Future Architecture Changes

### Planned Improvements

1. **Plugin System**: Allow extensions
2. **Configuration**: YAML/TOML config file
3. **Themes**: Customizable color schemes
4. **Hooks**: Before/after note save, etc.
5. **API Layer**: Separate UI from core logic

### Potential Refactors

1. Split `Application` into smaller components
2. Extract `Sidebar` and `NoteView` classes
3. Add `StateManager` for application state
4. Implement `CommandDispatcher` pattern
5. Add proper event system

---

**Document Status**: Living document, updated as architecture evolves

**Last Updated**: 2025-11-24

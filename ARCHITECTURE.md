# Grimoire Architecture

This document provides a comprehensive overview of Grimoire's architecture, design decisions, and patterns.

## Table of Contents

1. [Overview](#overview)
2. [Architecture Layers](#architecture-layers)
3. [Domain-Driven Design](#domain-driven-design)
4. [SOLID Principles](#solid-principles)
5. [Design Patterns](#design-patterns)
6. [Dependency Flow](#dependency-flow)
7. [Component Breakdown](#component-breakdown)
8. [Data Flow](#data-flow)
9. [Extension Points](#extension-points)

## Overview

Grimoire follows a **clean architecture** approach inspired by:
- Domain-Driven Design (DDD) by Eric Evans
- Clean Architecture by Robert C. Martin
- SOLID principles
- Hexagonal Architecture (Ports and Adapters)

### High-Level View

```
┌────────────────────────────────────────────────────┐
│               UI Layer (Presentation)              │
│  ┌──────────┐  ┌──────────┐  ┌────────────────┐  │
│  │ Sidebar  │  │  Viewer  │  │  Status Bar    │  │
│  └──────────┘  └──────────┘  └────────────────┘  │
└────────────────────┬───────────────────────────────┘
                     │ depends on
┌────────────────────▼───────────────────────────────┐
│          Application Layer (Use Cases)             │
│  ┌────────────┐  ┌────────────┐  ┌─────────────┐ │
│  │ CreateNote │  │ UpdateNote │  │ SearchNotes │ │
│  └────────────┘  └────────────┘  └─────────────┘ │
└────────────────────┬───────────────────────────────┘
                     │ uses
┌────────────────────▼───────────────────────────────┐
│         Domain Layer (Business Logic)              │
│  ┌───────┐  ┌─────────────┐  ┌────────────────┐  │
│  │ Note  │  │ NotePath    │  │ NoteRepository │  │
│  │Entity │  │ValueObject  │  │   Interface    │  │
│  └───────┘  └─────────────┘  └────────────────┘  │
└────────────────────▲───────────────────────────────┘
                     │ implemented by
┌────────────────────┴───────────────────────────────┐
│        Infrastructure Layer (Technical)            │
│  ┌──────────────────────┐  ┌──────────────────┐   │
│  │ FileSystemRepository │  │ MarkdownRenderer │   │
│  └──────────────────────┘  └──────────────────┘   │
└────────────────────────────────────────────────────┘
```

## Architecture Layers

### 1. Domain Layer (`lib/domain/`)

The **core** of the application. Contains pure business logic with **zero dependencies** on other layers.

**Responsibilities:**
- Define business entities
- Enforce business rules
- Define repository interfaces
- Contain domain services

**Key Components:**

#### Entities
```ruby
# Note - Aggregate Root
class Note
  attr_reader :path, :content, :metadata
  
  def update_content(new_content)
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
  
  def linked_notes
    @content.extract_links
  end
end
```

**Characteristics:**
- Has identity (distinguished by ID)
- Has lifecycle
- Mutable
- Enforces invariants

#### Value Objects
```ruby
# NotePath - Immutable Value Object
class NotePath
  attr_reader :value
  
  def initialize(path)
    @value = validate_and_normalize(path)
    freeze  # Immutable
  end
  
  def ==(other)
    other.is_a?(NotePath) && other.value == value
  end
end
```

**Characteristics:**
- Immutable (frozen)
- No identity (equality by value)
- Self-validating
- Lightweight

#### Repository Interfaces
```ruby
class NoteRepository
  def save(note)
    raise NotImplementedError
  end
  
  def find_by_path(path)
    raise NotImplementedError
  end
end
```

**Why Interfaces?**
- Dependency Inversion Principle
- Domain doesn't depend on infrastructure
- Easy to test with mocks
- Swappable implementations

#### Domain Services
```ruby
class NoteSearchService
  def initialize(repository)
    @repository = repository
  end
  
  def search_by_content(query, folder: nil)
    # Complex logic spanning multiple entities
  end
end
```

**When to Use:**
- Logic doesn't naturally fit in an entity
- Operations spanning multiple entities
- Stateless operations

### 2. Application Layer (`lib/application/`)

**Thin orchestration layer**. No business logic, just coordination.

**Responsibilities:**
- Define use cases
- Orchestrate domain objects
- Transaction boundaries
- Error handling

**Example:**
```ruby
class CreateNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(name:, folder: nil, content: '')
    # Validate input
    validate_input(name)
    
    # Create domain object
    note = Domain::Entities::Note.create(
      name: name,
      folder: folder,
      content: content
    )
    
    # Check business rule
    if @repository.exists?(note.path)
      raise ArgumentError, "Note already exists"
    end
    
    # Persist
    @repository.save(note)
    
    note
  end
end
```

**Characteristics:**
- Single public method (`call`)
- Depends on repository interface (not implementation)
- Returns domain objects
- No knowledge of UI or infrastructure

### 3. Infrastructure Layer (`lib/infrastructure/`)

**Technical implementations**. Contains all framework and library-specific code.

**Responsibilities:**
- Implement repository interfaces
- Provide rendering services
- Handle external systems
- Technical utilities

**Example:**
```ruby
class FileSystemNoteRepository < Domain::Repositories::NoteRepository
  def save(note)
    full_path = @root_dir.join(note.path.to_s)
    FileUtils.mkdir_p(full_path.dirname)
    File.write(full_path, note.content.to_s)
  end
  
  def find_by_path(path)
    # File system specific implementation
    full_path = @root_dir.join(path.to_s)
    return nil unless full_path.exist?
    
    build_note_from_file(path, full_path)
  end
end
```

**Key Point**: Infrastructure depends on domain (interfaces), not vice versa.

### 4. UI Layer (`lib/ui/`)

**Presentation layer**. Handles user interaction and display.

**Responsibilities:**
- Display information
- Capture user input
- Coordinate UI components
- Call use cases

**Example:**
```ruby
class Application
  include Import[
    :list_notes_use_case,
    :create_note_use_case,
    :update_note_use_case
  ]
  
  def handle_input(char)
    case char
    when 'n'
      note = create_note_use_case.call(name: generate_name)
      display_note(note)
    when 'e'
      content = edit_buffer.join("\n")
      update_note_use_case.call(path: current_note.path, content: content)
    end
  end
end
```

**Component Pattern:**
```ruby
class Sidebar
  def initialize(formatter)
    @formatter = formatter
  end
  
  def render(window, folders:, notes:, current_folder:)
    render_header(window)
    render_folders(window, folders, current_folder)
    render_notes(window, notes)
  end
end
```

## Domain-Driven Design

### Ubiquitous Language

Terms used consistently across codebase and documentation:

- **Note** - A markdown document
- **Path** - File system location of a note
- **Content** - The markdown text
- **Metadata** - Name, timestamps, tags
- **Folder** - Directory containing notes
- **Repository** - Persistence abstraction
- **Use Case** - Single application operation

### Bounded Context

Grimoire has one bounded context: **Note Management**

Within this context:
- **Aggregate**: Note (with Path, Content, Metadata)
- **Services**: NoteSearchService
- **Repositories**: NoteRepository

### Aggregate Root

**Note** is the aggregate root:

```ruby
class Note
  attr_reader :path, :content, :metadata
  
  # Factory method
  def self.create(name:, folder: nil, content: '')
    # Encapsulates creation logic
  end
  
  # Business operations
  def update_content(new_content)
    # Maintains invariants
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
  
  # Identity
  def id
    @path.to_s
  end
end
```

**Why Note is Aggregate Root:**
- Has clear identity (path)
- Controls access to its components
- Enforces invariants
- Clear transactional boundary

### Value Objects

Grimoire uses many value objects:

```ruby
# All value objects are:
# 1. Immutable
# 2. Self-validating
# 3. Comparable by value

class NoteContent
  def initialize(text)
    @text = text.to_s
    freeze  # Immutable
  end
  
  def extract_links
    @text.scan(/\[\[([^\]]+)\]\]/).flatten
  end
  
  def ==(other)
    other.is_a?(NoteContent) && other.text == text
  end
end
```

**Benefits:**
- Thread-safe (immutable)
- No side effects
- Easy to test
- Clear semantics

## SOLID Principles

### Single Responsibility Principle (SRP)

Each class has **one reason to change**:

```ruby
# ✓ CreateNote - Only creates notes
class CreateNote
  def call(name:, folder: nil, content: '')
    # ...
  end
end

# ✓ UpdateNote - Only updates notes
class UpdateNote
  def call(path:, content:)
    # ...
  end
end

# ✓ Sidebar - Only renders sidebar
class Sidebar
  def render(window, folders:, notes:)
    # ...
  end
end
```

### Open/Closed Principle (OCP)

**Open for extension, closed for modification**:

```ruby
# Repository interface - closed for modification
class NoteRepository
  def save(note)
    raise NotImplementedError
  end
end

# Extended without modifying original - open for extension
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(path, content)
  end
end

# Future extension
class DatabaseNoteRepository < NoteRepository
  def save(note)
    db.insert(note.to_h)
  end
end
```

### Liskov Substitution Principle (LSP)

Subtypes are **substitutable** for base types:

```ruby
# Any NoteRepository implementation works
def some_use_case(repository)
  note = Note.create(name: 'Test')
  repository.save(note)  # Works with any implementation
  repository.find_by_path(note.path)  # Contract is maintained
end

# Both work correctly
some_use_case(FileSystemNoteRepository.new)
some_use_case(DatabaseNoteRepository.new)  # Would work if implemented
```

### Interface Segregation Principle (ISP)

**Small, focused interfaces**:

```ruby
# ✓ Focused interface
class NoteRepository
  def save(note)
  end
  
  def find_by_path(path)
  end
end

# ✓ Separate concern
class NoteSearchService
  def search_by_name(query)
  end
end

# ✗ Avoid fat interfaces
class MegaInterface
  def save(note)
  end
  
  def render_markdown(content)
  end
  
  def display_in_terminal(note)
  end
end
```

### Dependency Inversion Principle (DIP)

**Depend on abstractions, not concretions**:

```ruby
# ✓ Depends on abstraction (NoteRepository interface)
class CreateNote
  def initialize(repository)  # Interface, not implementation
    @repository = repository
  end
  
  def call(name:)
    note = Note.create(name: name)
    @repository.save(note)  # Abstract method
  end
end

# ✗ Depends on concretion
class CreateNote
  def call(name:)
    note = Note.create(name: name)
    File.write("#{name}.md", note.content)  # Concrete implementation
  end
end
```

## Design Patterns

### Repository Pattern

**Abstracts persistence logic**:

```ruby
# Interface (in domain)
class NoteRepository
  def save(note)
  end
  
  def find_by_path(path)
  end
end

# Implementation (in infrastructure)
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(full_path, note.content.to_s)
  end
  
  def find_by_path(path)
    build_note_from_file(path)
  end
end
```

**Benefits:**
- Domain doesn't know about persistence
- Easy to swap implementations
- Testable with mock repositories
- Centralized data access

### Dependency Injection Pattern

**Using dry-container**:

```ruby
class Container
  extend Dry::Container::Mixin
  
  # Register dependencies
  register :note_repository do
    FileSystemNoteRepository.new
  end
  
  register :create_note_use_case do
    CreateNote.new(resolve(:note_repository))
  end
end

# Auto-injection
Import = Dry::AutoInject(Container)

class Application
  include Import[
    :create_note_use_case,
    :update_note_use_case
  ]
  
  # Dependencies injected automatically
end
```

**Benefits:**
- Loose coupling
- Easy testing (swap dependencies)
- Configuration in one place
- Clear dependencies

### Component Pattern (UI)

**Composable UI components**:

```ruby
class Application
  def initialize
    @sidebar = Sidebar.new(formatter)
    @viewer = NoteViewer.new(renderer, formatter)
    @status_bar = StatusBar.new(formatter)
  end
  
  def render_ui
    @sidebar.render(...)
    @viewer.render(...)
    @status_bar.render(...)
  end
end
```

**Benefits:**
- Separation of concerns
- Reusable components
- Easy to test
- Clear responsibilities

## Dependency Flow

### The Dependency Rule

> Dependencies point inward toward the domain.

```
UI → Application → Domain ← Infrastructure
```

**What this means:**
- UI depends on Application (use cases)
- Application depends on Domain (entities, interfaces)
- Infrastructure depends on Domain (implements interfaces)
- Domain depends on **nothing**

### Example Flow

```ruby
# UI depends on Application
class Application
  include Import[:create_note_use_case]  # Application layer
  
  def handle_input
    create_note_use_case.call(name: 'Test')
  end
end

# Application depends on Domain
class CreateNote
  def initialize(repository)  # Domain interface
    @repository = repository
  end
  
  def call(name:)
    note = Domain::Entities::Note.create(name: name)  # Domain entity
    @repository.save(note)
  end
end

# Infrastructure depends on Domain
class FileSystemNoteRepository < Domain::Repositories::NoteRepository
  def save(note)  # Domain entity
    # Infrastructure implementation
  end
end
```

## Component Breakdown

### Domain Components

**Entities:**
- `Note` - Aggregate root

**Value Objects:**
- `NotePath` - File path
- `NoteContent` - Markdown content
- `NoteMetadata` - Metadata
- `FolderPath` - Folder path

**Repositories:**
- `NoteRepository` - Interface

**Services:**
- `NoteSearchService` - Search operations

### Application Components

**Use Cases:**
- `CreateNote` - Create new note
- `UpdateNote` - Update existing note
- `DeleteNote` - Delete note
- `GetNote` - Retrieve single note
- `ListNotes` - List all notes
- `SearchNotes` - Search operations

### Infrastructure Components

**Persistence:**
- `FileSystemNoteRepository` - File system implementation

**Rendering:**
- `MarkdownRenderer` - Markdown to terminal
- `TerminalFormatter` - Terminal formatting utilities

### UI Components

**Main Controller:**
- `Application` - Coordinates everything

**Components:**
- `Sidebar` - Folder and note list
- `NoteViewer` - Display note content
- `NoteEditor` - Edit note content
- `StatusBar` - Status information
- `HelpOverlay` - Help screen

## Data Flow

### Opening a Note

```
User Input (Enter)
    ↓
Application#handle_input
    ↓
Application#open_selected_note
    ↓
GetNote#call (use case)
    ↓
NoteRepository#find_by_path
    ↓
FileSystemNoteRepository (reads file)
    ↓
Domain::Entities::Note (built)
    ↓
Application (stores current_note)
    ↓
NoteViewer#render
    ↓
MarkdownRenderer#render
    ↓
Display on screen
```

### Creating a Note

```
User Input ('n')
    ↓
Application#create_new_note
    ↓
CreateNote#call (use case)
    ↓
Note.create (factory method)
    ↓
NoteRepository#save
    ↓
FileSystemNoteRepository (writes file)
    ↓
Note (returned)
    ↓
Application (updates UI)
```

## Extension Points

### Adding New Repository

```ruby
# 1. Implement interface
class DatabaseNoteRepository < Domain::Repositories::NoteRepository
  def save(note)
    @db.insert(notes: note.to_h)
  end
  
  def find_by_path(path)
    data = @db.find(path: path.to_s)
    build_note_from_data(data)
  end
end

# 2. Register in container
Container.register :note_repository do
  DatabaseNoteRepository.new
end

# That's it! All use cases now use database
```

### Adding New Use Case

```ruby
# 1. Create use case
class ArchiveNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(path:)
    note = @repository.find_by_path(path)
    # Archive logic...
  end
end

# 2. Register in container
Container.register :archive_note_use_case do
  ArchiveNote.new(resolve(:note_repository))
end

# 3. Inject into UI
class Application
  include Import[:archive_note_use_case]
end
```

### Adding New UI Component

```ruby
# 1. Create component
class TagsPanel
  def initialize(formatter)
    @formatter = formatter
  end
  
  def render(window, tags:)
    # Rendering logic
  end
end

# 2. Use in Application
class Application
  def initialize
    @tags_panel = TagsPanel.new(terminal_formatter)
  end
  
  def render_ui
    @tags_panel.render(stdscr, tags: current_tags)
  end
end
```

## Best Practices

1. **Keep domain pure** - No infrastructure dependencies
2. **Thin application layer** - Just orchestration
3. **Rich domain model** - Logic in entities
4. **Immutable value objects** - Use freeze
5. **Small interfaces** - ISP
6. **Depend on abstractions** - DIP
7. **One public method per use case** - Single responsibility
8. **Component composition** - Build complex UIs from simple pieces

## Testing Strategy

### Unit Tests (Domain)
```ruby
describe Note do
  describe '#linked_notes' do
    it 'extracts wiki links from content' do
      note = Note.new(...)
      expect(note.linked_notes).to contain_exactly('Other Note')
    end
  end
end
```

### Integration Tests (Application)
```ruby
describe CreateNote do
  let(:repository) { instance_double(NoteRepository) }
  subject { CreateNote.new(repository) }
  
  it 'creates and saves note' do
    expect(repository).to receive(:save)
    subject.call(name: 'Test')
  end
end
```

### Component Tests (UI)
```ruby
describe Sidebar do
  it 'renders folders' do
    window = mock_window
    sidebar.render(window, folders: [...], ...)
    expect(window).to have_received(:addstr).with(/📁/)
  end
end
```

---

**Document Status**: Living document, updated as architecture evolves
**Last Updated**: 2025-11-24

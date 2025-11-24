# Domain-Driven Design & SOLID Principles in Grimoire

This document explains how Grimoire implements DDD and SOLID principles, and why these architectural decisions matter.

## Executive Summary

Grimoire has been completely refactored to follow:
- ✅ **Domain-Driven Design (DDD)** - Clean layered architecture
- ✅ **SOLID Principles** - Better code quality and maintainability
- ✅ **Dependency Injection** - Loose coupling via dry-container
- ✅ **Repository Pattern** - Abstracted persistence
- ✅ **Value Objects** - Immutable, self-validating types
- ✅ **Use Case Pattern** - Single-responsibility application logic

## Why DDD and SOLID?

### Before (Monolithic Approach)
```ruby
# ❌ Everything mixed together
class NotesManager
  def create_note(name, folder)
    # File system logic
    # Validation logic
    # Business logic
    # All in one place
  end
  
  def render_markdown(content)
    # Rendering mixed with business logic
  end
end
```

**Problems:**
- Hard to test
- Tight coupling
- Mixed concerns
- Difficult to change
- No clear boundaries

### After (DDD + SOLID)
```ruby
# ✅ Clear separation of concerns

# Domain Layer - Business Logic
class Note
  def update_content(new_content)
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
end

# Application Layer - Use Cases
class CreateNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(name:, folder: nil)
    note = Note.create(name: name, folder: folder)
    @repository.save(note)
  end
end

# Infrastructure Layer - Technical Details
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(path, note.content.to_s)
  end
end
```

**Benefits:**
- Easy to test
- Loose coupling
- Clear responsibilities
- Easy to extend
- Clear boundaries

## Domain-Driven Design Implementation

### 1. Layered Architecture

```
┌─────────────────────────────────────┐
│  UI Layer                           │ ← User interaction
│  (Terminal components)              │
├─────────────────────────────────────┤
│  Application Layer                  │ ← Use cases
│  (CreateNote, UpdateNote, etc.)    │
├─────────────────────────────────────┤
│  Domain Layer                       │ ← Business logic
│  (Entities, Value Objects)         │
├─────────────────────────────────────┤
│  Infrastructure Layer               │ ← Technical details
│  (File system, Rendering)          │
└─────────────────────────────────────┘
```

**Key Rule**: Dependencies point **inward** toward the domain.

### 2. Domain Model

#### Entities (Has Identity)
```ruby
class Note
  attr_reader :path, :content, :metadata
  
  # Identity based on path
  def id
    @path.to_s
  end
  
  # Business operations
  def update_content(new_content)
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
  
  # Domain logic
  def linked_notes
    @content.extract_links
  end
end
```

**Why Entity?**
- Has identity (path)
- Has lifecycle
- Mutable
- Encapsulates business logic

#### Value Objects (No Identity)
```ruby
class NotePath
  attr_reader :value
  
  def initialize(path)
    @value = validate_and_normalize(path)
    freeze  # Immutable
  end
  
  # Equality by value
  def ==(other)
    other.is_a?(NotePath) && other.value == value
  end
end
```

**Why Value Object?**
- Immutable
- Self-validating
- No identity
- Compared by value
- Thread-safe

#### Aggregates
**Note** is an aggregate root that controls access to:
- `NotePath` (value object)
- `NoteContent` (value object)
- `NoteMetadata` (value object)

```ruby
# ✓ Access through aggregate root
note.update_content(new_content)

# ✗ Don't access internals directly
note.content.text = new_content  # Violates encapsulation
```

### 3. Repository Pattern

**Interface (in domain):**
```ruby
module Domain
  module Repositories
    class NoteRepository
      def save(note)
        raise NotImplementedError
      end
      
      def find_by_path(path)
        raise NotImplementedError
      end
    end
  end
end
```

**Implementation (in infrastructure):**
```ruby
module Infrastructure
  module Persistence
    class FileSystemNoteRepository < Domain::Repositories::NoteRepository
      def save(note)
        File.write(full_path, note.content.to_s)
      end
      
      def find_by_path(path)
        build_note_from_file(path)
      end
    end
  end
end
```

**Benefits:**
- Domain doesn't know about file system
- Easy to swap implementations (database, cloud, etc.)
- Easy to test with mocks
- Clear abstraction boundary

### 4. Domain Services

```ruby
class NoteSearchService
  def initialize(repository)
    @repository = repository
  end
  
  def search_by_content(query, folder: nil)
    notes = @repository.find_all(folder: folder)
    # Complex search logic that doesn't belong to Note entity
  end
end
```

**When to Use:**
- Logic doesn't fit naturally in an entity
- Operations spanning multiple entities
- Stateless operations

### 5. Use Cases (Application Services)

```ruby
class CreateNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(name:, folder: nil, content: '')
    # 1. Validate input
    validate_input(name)
    
    # 2. Create domain object
    note = Domain::Entities::Note.create(
      name: name,
      folder: folder,
      content: content
    )
    
    # 3. Check business rules
    if @repository.exists?(note.path)
      raise ArgumentError, "Note already exists"
    end
    
    # 4. Persist
    @repository.save(note)
    
    # 5. Return
    note
  end
end
```

**Characteristics:**
- Single public method (`call`)
- Orchestrates domain objects
- No business logic (that's in domain)
- Thin layer

## SOLID Principles Implementation

### S - Single Responsibility Principle

**One class, one reason to change.**

```ruby
# ✓ GOOD: Each class has single responsibility
class CreateNote
  def call(name:, folder: nil)
    # Only handles note creation
  end
end

class UpdateNote
  def call(path:, content:)
    # Only handles note updates
  end
end

class DeleteNote
  def call(path:)
    # Only handles note deletion
  end
end

# ✗ BAD: Multiple responsibilities
class NoteManager
  def create_note(name)
  end
  
  def update_note(path, content)
  end
  
  def delete_note(path)
  end
  
  def render_markdown(content)
  end
  
  def save_to_file(note)
  end
end
```

**In Grimoire:**
- Each use case does one thing
- Each UI component renders one thing
- Each value object represents one concept

### O - Open/Closed Principle

**Open for extension, closed for modification.**

```ruby
# ✓ GOOD: Can extend without modifying
class NoteRepository
  def save(note)
    raise NotImplementedError
  end
end

# Extension 1: File system
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(path, content)
  end
end

# Extension 2: Database (no changes to existing code!)
class DatabaseNoteRepository < NoteRepository
  def save(note)
    db.insert(note.to_h)
  end
end

# Extension 3: Cloud storage
class S3NoteRepository < NoteRepository
  def save(note)
    s3.put_object(key: note.path, body: note.content)
  end
end
```

**In Grimoire:**
- Repository pattern allows new storage backends
- Component pattern allows new UI components
- Use case pattern allows new operations

### L - Liskov Substitution Principle

**Subtypes must be substitutable for base types.**

```ruby
def some_operation(repository: NoteRepository)
  note = Note.create(name: 'Test')
  repository.save(note)
  
  # Contract: Should be able to retrieve what we saved
  loaded = repository.find_by_path(note.path)
  expect(loaded.content).to eq(note.content)
end

# ✓ All implementations must honor the contract
some_operation(repository: FileSystemNoteRepository.new)
some_operation(repository: DatabaseNoteRepository.new)
some_operation(repository: InMemoryNoteRepository.new)
```

**In Grimoire:**
- All repository implementations honor the interface contract
- All value objects are interchangeable
- UI components follow consistent rendering contract

### I - Interface Segregation Principle

**Don't depend on methods you don't use.**

```ruby
# ✓ GOOD: Small, focused interfaces
class NoteRepository
  def save(note)
  end
  
  def find_by_path(path)
  end
  
  def find_all(folder: nil)
  end
end

class NoteSearchService
  def search_by_name(query)
  end
  
  def search_by_content(query)
  end
end

# ✗ BAD: Fat interface
class MegaNotesInterface
  def save(note)
  end
  
  def find_by_path(path)
  end
  
  def search_by_name(query)
  end
  
  def search_by_content(query)
  end
  
  def render_markdown(content)
  end
  
  def export_to_pdf(note)
  end
  
  def send_email(note, recipient)
  end
end
```

**In Grimoire:**
- Repository interface has only persistence methods
- Search service has only search methods
- Renderer has only rendering methods
- Use cases have single `call` method

### D - Dependency Inversion Principle

**Depend on abstractions, not concretions.**

```ruby
# ✓ GOOD: Depends on abstraction
class CreateNote
  def initialize(repository)  # NoteRepository interface
    @repository = repository
  end
  
  def call(name:)
    note = Note.create(name: name)
    @repository.save(note)  # Abstract method
  end
end

# Container wires up concrete implementation
Container.register :note_repository do
  FileSystemNoteRepository.new  # Concrete
end

Container.register :create_note_use_case do
  CreateNote.new(resolve(:note_repository))  # Abstract
end

# ✗ BAD: Depends on concretion
class CreateNote
  def call(name:)
    note = Note.create(name: name)
    # Directly depends on file system
    File.write("#{note.path}.md", note.content)
  end
end
```

**In Grimoire:**
- Use cases depend on repository interfaces
- UI depends on use cases (application layer)
- Infrastructure implements domain interfaces
- Dependency injection via container

## Dependency Injection

Using `dry-container` and `dry-auto_inject`:

```ruby
# Define container
class Container
  extend Dry::Container::Mixin
  
  # Register dependencies
  register :note_repository do
    FileSystemNoteRepository.new
  end
  
  register :markdown_renderer do
    MarkdownRenderer.new
  end
  
  register :create_note_use_case do
    CreateNote.new(resolve(:note_repository))
  end
end

# Create auto-injection helper
Import = Dry::AutoInject(Container)

# Inject dependencies
class Application
  include Import[
    :create_note_use_case,
    :update_note_use_case,
    :markdown_renderer
  ]
  
  # Dependencies available as methods
  def handle_input
    create_note_use_case.call(name: 'Test')
  end
end
```

**Benefits:**
- Loose coupling
- Easy to test (swap dependencies)
- Configuration in one place
- Clear dependencies

## Real-World Comparisons

### Without DDD/SOLID (Monolithic)

```ruby
# Everything in one file, tightly coupled
class Application
  def create_note(name)
    # Validation
    raise "Invalid name" if name.empty?
    
    # Business logic
    filename = "#{name.gsub(/[^A-Za-z0-9]/, '_')}.md"
    
    # File system logic
    File.write("/home/user/notes/#{filename}", "# #{name}\n\n")
    
    # Rendering logic
    markdown = Redcarpet::Markdown.new(...)
    rendered = markdown.render(File.read("/home/user/notes/#{filename}"))
    
    # Display logic
    stdscr.addstr(rendered)
  end
end
```

**Problems:**
- Can't test without file system
- Can't swap file system for database
- Can't change rendering without touching everything
- Hard to understand
- Tight coupling

### With DDD/SOLID (Clean Architecture)

```ruby
# Domain
class Note
  def self.create(name:, folder: nil)
    # Business logic
  end
end

# Application
class CreateNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(name:)
    note = Note.create(name: name)
    @repository.save(note)
  end
end

# Infrastructure
class FileSystemNoteRepository
  def save(note)
    File.write(path, note.content.to_s)
  end
end

# UI
class Application
  include Import[:create_note_use_case]
  
  def handle_create
    note = create_note_use_case.call(name: user_input)
    display_note(note)
  end
end
```

**Benefits:**
- Easy to test (mock repository)
- Easy to swap storage (change one line in container)
- Easy to change rendering (inject different renderer)
- Clear responsibilities
- Loose coupling

## Testing Benefits

### Unit Tests (Domain)
```ruby
# No dependencies, easy to test
describe Note do
  it 'extracts linked notes' do
    content = NoteContent.new("See [[Other Note]]")
    note = Note.new(path: path, content: content, metadata: metadata)
    
    expect(note.linked_notes).to eq(['Other Note'])
  end
end
```

### Integration Tests (Application)
```ruby
# Mock dependencies
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
# Test components in isolation
describe Sidebar do
  let(:formatter) { instance_double(TerminalFormatter) }
  subject { Sidebar.new(formatter) }
  
  it 'renders folders' do
    expect { subject.render(...) }.not_to raise_error
  end
end
```

## Practical Benefits

### Easy to Extend

Want database support? Just implement the interface:

```ruby
class PostgresNoteRepository < NoteRepository
  def save(note)
    connection.exec_params(
      'INSERT INTO notes ...',
      [note.path, note.content.to_s]
    )
  end
end

# Change one line
Container.register :note_repository do
  PostgresNoteRepository.new
end
```

### Easy to Test

Mock repository for testing:

```ruby
class MockNoteRepository < NoteRepository
  attr_reader :saved_notes
  
  def initialize
    @saved_notes = []
  end
  
  def save(note)
    @saved_notes << note
  end
end
```

### Easy to Understand

Each file has clear purpose:
- `lib/domain/entities/note.rb` - What is a note?
- `lib/application/use_cases/create_note.rb` - How to create a note?
- `lib/infrastructure/persistence/file_system_note_repository.rb` - How to store a note?
- `lib/ui/terminal/components/sidebar.rb` - How to display sidebar?

## Summary

| Aspect | Before | After |
|--------|--------|-------|
| **Architecture** | Monolithic | Layered (DDD) |
| **Coupling** | Tight | Loose |
| **Testability** | Hard | Easy |
| **Extensibility** | Difficult | Simple |
| **Maintainability** | Complex | Clear |
| **Dependencies** | Scattered | Injected |
| **Responsibilities** | Mixed | Separated |

## Key Takeaways

1. **DDD** provides clear structure and boundaries
2. **SOLID** ensures quality and maintainability
3. **Repository pattern** abstracts persistence
4. **Value objects** provide type safety
5. **Use cases** organize application logic
6. **Dependency injection** enables flexibility
7. **Clean architecture** makes code understandable

## Further Reading

- See `ARCHITECTURE.md` for detailed architecture
- See `notes/examples/DDD_Architecture_Guide.md` for domain modeling
- See `notes/examples/SOLID_Principles.md` for principle examples

---

**Remember**: These patterns exist to make code better. Use them pragmatically, not dogmatically!

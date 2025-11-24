# SOLID Principles in Grimoire

This document shows how Grimoire implements SOLID principles.

## Overview

**SOLID** is an acronym for five design principles:

1. **S**ingle Responsibility Principle
2. **O**pen/Closed Principle
3. **L**iskov Substitution Principle
4. **I**nterface Segregation Principle
5. **D**ependency Inversion Principle

## 1. Single Responsibility Principle (SRP)

> A class should have one, and only one, reason to change.

### Example: Use Cases

```ruby
# ✓ Good: Single responsibility
class CreateNote
  def call(name:, folder: nil, content: '')
    # Only handles note creation
  end
end

class DeleteNote
  def call(path:)
    # Only handles note deletion
  end
end

# ✗ Bad: Multiple responsibilities
class NoteManager
  def create_note(name)
    # ...
  end
  
  def delete_note(path)
    # ...
  end
  
  def render_note(note)
    # ...
  end
  
  def search_notes(query)
    # ...
  end
end
```

### In Grimoire

- **NotesManager** (old) → Split into multiple use cases
- **MarkdownRenderer** - Only renders markdown
- **FileSystemNoteRepository** - Only handles persistence
- **Sidebar** - Only renders sidebar
- **NoteViewer** - Only displays notes

## 2. Open/Closed Principle (OCP)

> Open for extension, closed for modification.

### Example: Repository Pattern

```ruby
# Base interface - closed for modification
class NoteRepository
  def save(note)
    raise NotImplementedError
  end
end

# Extended - open for extension
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(path, note.content.to_s)
  end
end

# Future extension - no changes to existing code
class DatabaseNoteRepository < NoteRepository
  def save(note)
    db.insert(note.to_h)
  end
end
```

### In Grimoire

- Repository interface allows new implementations
- Can add new use cases without changing existing ones
- Component-based UI allows new components

## 3. Liskov Substitution Principle (LSP)

> Subtypes must be substitutable for their base types.

### Example: Repository Implementations

```ruby
def some_use_case(repository: NoteRepository)
  # Works with any NoteRepository implementation
  note = Note.create(name: 'Test')
  repository.save(note)
  
  loaded = repository.find_by_path(note.path)
  # Contract: find_by_path returns same note
end

# Works with FileSystemNoteRepository
use_case(repository: FileSystemNoteRepository.new)

# Would also work with DatabaseNoteRepository
use_case(repository: DatabaseNoteRepository.new)
```

### In Grimoire

- `FileSystemNoteRepository` can replace `NoteRepository`
- All value objects are interchangeable with their interface
- UI components follow consistent rendering contract

## 4. Interface Segregation Principle (ISP)

> Clients shouldn't depend on interfaces they don't use.

### Example: Focused Interfaces

```ruby
# ✓ Good: Small, focused interfaces
class NoteRepository
  def save(note)
  end
  
  def find_by_path(path)
  end
  
  def find_all(folder: nil)
  end
end

class NoteSearcher
  def search_by_name(query)
  end
  
  def search_by_content(query)
  end
end

# ✗ Bad: Fat interface
class NotesInterface
  def save(note)
  end
  
  def find_by_path(path)
  end
  
  def search_by_name(query)
  end
  
  def render_markdown(content)
  end
  
  def display_in_terminal(note)
  end
  
  def export_to_pdf(note)
  end
end
```

### In Grimoire

- **NoteRepository** - Only persistence methods
- **NoteSearchService** - Only search methods
- **MarkdownRenderer** - Only rendering methods
- Each use case has single method (`call`)

## 5. Dependency Inversion Principle (DIP)

> Depend on abstractions, not concretions.

### Example: Use Cases

```ruby
# ✓ Good: Depends on abstraction
class CreateNote
  def initialize(repository) # NoteRepository interface
    @repository = repository
  end
  
  def call(name:)
    note = Note.create(name: name)
    @repository.save(note) # Abstract method
  end
end

# ✗ Bad: Depends on concretion
class CreateNote
  def call(name:)
    note = Note.create(name: name)
    # Directly couples to file system
    File.write("#{name}.md", note.content)
  end
end
```

### In Grimoire

```ruby
# Container wires up dependencies
class Container
  register :note_repository do
    FileSystemNoteRepository.new # Concrete
  end
  
  register :create_note_use_case do
    CreateNote.new(resolve(:note_repository)) # Abstract
  end
end

# UI depends on abstractions
class Application
  include Import[
    :list_notes_use_case,    # Abstraction
    :create_note_use_case,   # Abstraction
    :markdown_renderer       # Abstraction
  ]
end
```

## Benefits in Practice

### Testability

```ruby
# Easy to test with mock repository
describe CreateNote do
  it 'creates and saves note' do
    mock_repo = instance_double(NoteRepository)
    use_case = CreateNote.new(mock_repo)
    
    expect(mock_repo).to receive(:save)
    use_case.call(name: 'Test')
  end
end
```

### Flexibility

```ruby
# Easy to swap implementations
Container.register :note_repository do
  if ENV['USE_DATABASE']
    DatabaseNoteRepository.new
  else
    FileSystemNoteRepository.new
  end
end
```

### Maintainability

- Changes isolated to single class
- Clear responsibilities
- Easy to understand
- Reduced coupling

## Anti-Patterns to Avoid

### God Object
```ruby
# ✗ Avoid
class Application
  def create_note(name)
    # Direct file system access
    File.write(...)
  end
  
  def render_markdown(content)
    # Direct rendering
  end
  
  def handle_input(key)
    # Direct input handling
  end
end
```

### Feature Envy
```ruby
# ✗ Avoid
class SomeClass
  def do_something(note)
    # Using too much of note's data
    name = note.metadata.name
    content = note.content.text
    path = note.path.value
    # Should be in Note class
  end
end
```

### Shotgun Surgery
```ruby
# ✗ Avoid: Change in one place requires changes everywhere
def create_note(name)
  File.write(...)
end

def update_note(name, content)
  File.write(...)
end

def delete_note(name)
  File.delete(...)
end
# Better: Centralize in repository
```

## Summary

| Principle | Grimoire Implementation |
|-----------|------------------------|
| SRP | One class, one responsibility |
| OCP | Repository pattern, component system |
| LSP | Proper inheritance, interface compliance |
| ISP | Small, focused interfaces |
| DIP | DI container, depend on abstractions |

## Further Reading

- [[DDD Architecture Guide]]
- [[Welcome]]

---

**Remember**: SOLID principles are guidelines, not laws. Use judgment and pragmatism!

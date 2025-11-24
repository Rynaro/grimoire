# DDD Architecture Guide

This document explains the Domain-Driven Design architecture used in Grimoire.

## Domain-Driven Design

DDD is an approach to software development that emphasizes:

1. **Ubiquitous Language** - Shared vocabulary between developers and domain experts
2. **Bounded Contexts** - Clear boundaries between different parts of the system
3. **Domain Model** - Rich model representing business concepts
4. **Layered Architecture** - Separation of concerns

## Grimoire's Layers

### 1. Domain Layer (`lib/domain/`)

The heart of the application. Contains pure business logic with no dependencies on infrastructure.

#### Entities

```ruby
# Note - Aggregate Root
class Note
  attr_reader :path, :metadata, :content
  
  def update_content(new_content)
    # Business logic here
  end
  
  def linked_notes
    @content.extract_links
  end
end
```

**Characteristics:**
- Has identity (path)
- Has lifecycle
- Enforces business rules

#### Value Objects

```ruby
# NotePath - Immutable value
class NotePath
  attr_reader :value
  
  def initialize(path)
    @value = validate_and_normalize(path)
    freeze
  end
end
```

**Characteristics:**
- Immutable
- No identity (compared by value)
- Validations in constructor

#### Domain Services

```ruby
class NoteSearchService
  def search_by_content(query, folder: nil)
    # Complex logic that doesn't belong to a single entity
  end
end
```

**When to use:**
- Logic spanning multiple entities
- Doesn't naturally fit in an entity
- Stateless operations

### 2. Application Layer (`lib/application/`)

Orchestrates use cases. Thin layer that coordinates domain objects.

```ruby
class CreateNote
  def initialize(repository)
    @repository = repository
  end
  
  def call(name:, folder: nil, content: '')
    note = Domain::Entities::Note.create(
      name: name,
      folder: folder,
      content: content
    )
    
    @repository.save(note)
    note
  end
end
```

**Responsibilities:**
- Define use cases
- Transaction boundaries
- Coordinate domain objects
- No business logic

### 3. Infrastructure Layer (`lib/infrastructure/`)

Technical implementations. Can be swapped without affecting domain.

```ruby
class FileSystemNoteRepository < NoteRepository
  def save(note)
    # File system specific implementation
  end
  
  def find_by_path(path)
    # File system specific implementation
  end
end
```

**Contains:**
- Repository implementations
- External service adapters
- Rendering engines
- Persistence logic

### 4. UI Layer (`lib/ui/`)

User interface. Depends on application layer only.

```ruby
class Application
  include Import[
    :list_notes_use_case,
    :create_note_use_case,
    # ... other use cases
  ]
  
  def handle_input(char)
    case char
    when 'n'
      create_note_use_case.call(name: generate_name)
    end
  end
end
```

## Dependency Flow

```
UI → Application → Domain ← Infrastructure
```

**Key principle**: Dependencies point inward toward the domain.

- UI depends on Application
- Application depends on Domain
- Infrastructure depends on Domain (implements interfaces)
- Domain depends on nothing

## Repository Pattern

Abstracts data persistence:

```ruby
# Domain - Interface
class NoteRepository
  def save(note)
    raise NotImplementedError
  end
end

# Infrastructure - Implementation
class FileSystemNoteRepository < NoteRepository
  def save(note)
    File.write(path, note.content.to_s)
  end
end
```

**Benefits:**
- Domain doesn't know about file system
- Easy to swap implementations
- Testable with mock repositories

## Dependency Injection

Using `dry-container` and `dry-auto_inject`:

```ruby
class Container
  extend Dry::Container::Mixin
  
  register :note_repository do
    FileSystemNoteRepository.new
  end
  
  register :create_note_use_case do
    CreateNote.new(resolve(:note_repository))
  end
end

Import = Dry::AutoInject(Container)
```

**Benefits:**
- Loose coupling
- Easy testing
- Configuration in one place

## Aggregates

**Note** is an aggregate root:

- Controls access to its internal objects
- Enforces invariants
- Has clear boundaries

## Value Objects

Grimoire uses many value objects:

- **NotePath** - File path
- **NoteContent** - Markdown content
- **NoteMetadata** - Metadata
- **FolderPath** - Folder path

**Why?**
- Encapsulation
- Validation
- Immutability
- Type safety

## Best Practices

1. **Keep domain pure** - No infrastructure dependencies
2. **Thin application layer** - Just orchestration
3. **Rich domain model** - Business logic in entities
4. **Immutable value objects** - Use freeze
5. **Small interfaces** - Interface segregation
6. **Depend on abstractions** - Use repository interfaces

## Testing Strategy

### Unit Tests (Domain)
```ruby
describe Note do
  it 'extracts linked notes from content' do
    note = Note.new(...)
    expect(note.linked_notes).to eq(['Other Note'])
  end
end
```

### Integration Tests (Application)
```ruby
describe CreateNote do
  let(:repository) { instance_double(NoteRepository) }
  
  it 'creates and saves note' do
    use_case = CreateNote.new(repository)
    # ...
  end
end
```

## Further Reading

- [[SOLID Principles]]
- [[Welcome]]

---

**Remember**: DDD is about modeling your domain well, not about patterns. Use what makes sense!

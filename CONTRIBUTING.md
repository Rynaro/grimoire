# Contributing to Grimoire

Thank you for your interest in contributing to Grimoire! 🎉

## Architecture First

Grimoire follows **Domain-Driven Design (DDD)** and **SOLID principles**. Please familiarize yourself with:
- `ARCHITECTURE.md` - Detailed architecture documentation
- `DDD_AND_SOLID.md` - Explanation of patterns used
- `notes/examples/DDD_Architecture_Guide.md` - Domain modeling guide

## Development Setup

### Prerequisites
- Ruby 3.0 or higher
- ncurses development libraries
- Git

### Local Setup

```bash
# Clone repository
git clone <repository-url>
cd grimoire

# Run setup script
./setup.sh

# Or install manually
bundle install
```

### Docker Setup

```bash
# Build and run
docker-compose up --build

# Access shell
docker-compose run --rm grimoire /bin/sh
```

## Project Structure

```
lib/
├── domain/                    # ← Pure business logic
│   ├── entities/             # Entities with identity
│   ├── value_objects/        # Immutable values
│   ├── repositories/         # Interfaces only
│   └── services/             # Domain services
│
├── application/               # ← Use cases
│   └── use_cases/            # Application operations
│
├── infrastructure/            # ← Technical implementations
│   ├── persistence/          # Repository implementations
│   └── rendering/            # Rendering services
│
└── ui/                        # ← User interface
    └── terminal/             # Terminal UI components
```

## Contributing Guidelines

### 1. Respect the Architecture

**DO:**
- ✅ Keep domain layer pure (no infrastructure dependencies)
- ✅ Make use cases thin (orchestration only)
- ✅ Use dependency injection
- ✅ Follow SOLID principles
- ✅ Create immutable value objects
- ✅ Use repository pattern for persistence

**DON'T:**
- ❌ Add infrastructure dependencies to domain
- ❌ Put business logic in use cases
- ❌ Directly couple to concrete implementations
- ❌ Create mutable value objects
- ❌ Access file system from domain

### 2. Follow SOLID Principles

#### Single Responsibility
```ruby
# ✓ Good: One responsibility
class CreateNote
  def call(name:, folder: nil)
    # Only creates notes
  end
end

# ✗ Bad: Multiple responsibilities
class NoteManager
  def create_note(name)
  end
  
  def render_note(note)
  end
end
```

#### Dependency Inversion
```ruby
# ✓ Good: Depend on abstraction
class CreateNote
  def initialize(repository)  # Interface
    @repository = repository
  end
end

# ✗ Bad: Depend on concretion
class CreateNote
  def call(name:)
    File.write(...)  # Concrete implementation
  end
end
```

### 3. Adding New Features

#### Adding a Use Case

1. **Create the use case**:
```ruby
# lib/application/use_cases/archive_note.rb
module Grimoire
  module Application
    module UseCases
      class ArchiveNote
        def initialize(repository)
          @repository = repository
        end
        
        def call(path:)
          note = @repository.find_by_path(path)
          # Archive logic
        end
      end
    end
  end
end
```

2. **Register in container**:
```ruby
# lib/container.rb
register :archive_note_use_case do
  Application::UseCases::ArchiveNote.new(resolve(:note_repository))
end
```

3. **Inject into UI**:
```ruby
class Application
  include Import[:archive_note_use_case]
  
  def handle_archive
    archive_note_use_case.call(path: current_note.path)
  end
end
```

#### Adding a Value Object

```ruby
# lib/domain/value_objects/note_tags.rb
module Grimoire
  module Domain
    module ValueObjects
      class NoteTags
        attr_reader :tags
        
        def initialize(tags)
          @tags = Array(tags).map(&:to_s).freeze
          freeze  # Immutable!
        end
        
        def include?(tag)
          @tags.include?(tag)
        end
        
        def ==(other)
          other.is_a?(NoteTags) && other.tags == tags
        end
      end
    end
  end
end
```

#### Adding a Repository Implementation

```ruby
# lib/infrastructure/persistence/database_note_repository.rb
module Grimoire
  module Infrastructure
    module Persistence
      class DatabaseNoteRepository < Domain::Repositories::NoteRepository
        def save(note)
          connection.exec_params(
            'INSERT INTO notes (path, content, metadata) VALUES ($1, $2, $3)',
            [note.path.to_s, note.content.to_s, note.metadata.to_h.to_json]
          )
        end
        
        def find_by_path(path)
          result = connection.exec_params(
            'SELECT * FROM notes WHERE path = $1',
            [path.to_s]
          ).first
          
          return nil unless result
          build_note_from_row(result)
        end
      end
    end
  end
end
```

#### Adding a UI Component

```ruby
# lib/ui/terminal/components/tags_panel.rb
module Grimoire
  module UI
    module Terminal
      module Components
        class TagsPanel
          include Curses
          
          def initialize(formatter)
            @formatter = formatter
          end
          
          def render(window, tags:, start_x:, start_y:, width:)
            window.setpos(start_y, start_x)
            window.attron(color_pair(2) | A_BOLD) do
              window.addstr('🏷️  TAGS')
            end
            
            tags.each_with_index do |tag, idx|
              window.setpos(start_y + idx + 1, start_x + 2)
              window.addstr("• #{tag}"[0...width])
            end
          end
        end
      end
    end
  end
end
```

### 4. Code Style

- Use `frozen_string_literal: true`
- Follow standard Ruby conventions
- Keep methods small (< 10 lines preferred)
- Use descriptive variable names
- Add comments for complex logic
- Use modules for namespacing

### 5. Testing (When Added)

```ruby
# spec/domain/entities/note_spec.rb
describe Grimoire::Domain::Entities::Note do
  describe '#linked_notes' do
    it 'extracts wiki-style links' do
      content = Grimoire::Domain::ValueObjects::NoteContent.new(
        "See [[Other Note]] and [[Another Note]]"
      )
      note = described_class.new(
        path: path,
        content: content,
        metadata: metadata
      )
      
      expect(note.linked_notes).to contain_exactly('Other Note', 'Another Note')
    end
  end
end

# spec/application/use_cases/create_note_spec.rb
describe Grimoire::Application::UseCases::CreateNote do
  let(:repository) { instance_double(Grimoire::Domain::Repositories::NoteRepository) }
  subject { described_class.new(repository) }
  
  it 'creates and saves note' do
    expect(repository).to receive(:save)
    
    note = subject.call(name: 'Test Note')
    
    expect(note.name).to eq('Test Note')
  end
end
```

## Pull Request Process

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Follow architecture guidelines
   - Respect SOLID principles
   - Add tests (when testing is set up)
   - Update documentation

4. **Test locally**
   ```bash
   ruby grimoire.rb
   # Test the feature thoroughly
   ```

5. **Commit with clear messages**
   ```bash
   git commit -m "Add archive note functionality
   
   - Create ArchiveNote use case
   - Add archive folder to repository
   - Update UI to show archive option
   
   Follows SRP by separating archive logic into its own use case."
   ```

6. **Push and create PR**
   ```bash
   git push origin feature/your-feature-name
   ```

7. **PR Description**
   - Describe what the change does
   - Explain why it's needed
   - Note any architecture decisions
   - Reference related issues

## Code Review Criteria

We'll review for:
- ✅ Follows DDD architecture
- ✅ Respects SOLID principles
- ✅ Proper dependency injection
- ✅ Clear separation of concerns
- ✅ Immutable value objects
- ✅ Repository pattern usage
- ✅ Clean, readable code
- ✅ Appropriate documentation

## Areas for Contribution

### High Priority
- [ ] Full-featured text editor
- [ ] Interactive fuzzy search
- [ ] Comprehensive test suite
- [ ] Better error handling
- [ ] Configuration file support

### New Features
- [ ] Note templates
- [ ] Tags support (add Tag value object)
- [ ] Export functionality (new use case + repository method)
- [ ] Git integration (new repository implementation)
- [ ] Note encryption
- [ ] Multiple themes
- [ ] Plugin system

### Architecture Improvements
- [ ] Add more value objects (URL, Email, etc.)
- [ ] Extract more domain services
- [ ] Add specification pattern for search
- [ ] Event sourcing for note changes
- [ ] CQRS for read/write separation

### Infrastructure
- [ ] Database repository implementation
- [ ] Cloud storage repository
- [ ] Alternative renderers (HTML, PDF)
- [ ] Caching layer

### Documentation
- [ ] More architecture examples
- [ ] Video walkthrough
- [ ] Migration guide from other apps
- [ ] API documentation

## Questions?

- Open an issue for bugs or features
- Start a discussion for architecture questions
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Grimoire better! 🙏

**Remember**: Clean architecture makes code last. Take time to do it right!

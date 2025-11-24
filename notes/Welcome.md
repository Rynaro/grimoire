# Welcome to Grimoire ✦

Welcome to **Grimoire**, your personal terminal-based knowledge companion built with **Domain-Driven Design** principles!

## Getting Started

Grimoire helps you capture, organize, and connect your thoughts—all from the comfort of your terminal.

### Quick Tips

- Press `?` to see all keyboard shortcuts
- Press `n` to create a new note
- Press `e` to edit the current note
- Press `/` to search your notes

## Architecture

Grimoire is built following **Domain-Driven Design (DDD)** and **SOLID principles**:

### Layered Architecture

```
┌─────────────────────────────────┐
│   UI Layer (Terminal)           │
├─────────────────────────────────┤
│   Application Layer (Use Cases) │
├─────────────────────────────────┤
│   Domain Layer (Entities, VOs)  │
├─────────────────────────────────┤
│   Infrastructure (File System)  │
└─────────────────────────────────┘
```

### Domain Model

- **Note** - Aggregate Root Entity
- **NotePath** - Value Object
- **NoteContent** - Value Object
- **NoteMetadata** - Value Object
- **FolderPath** - Value Object

### SOLID Principles

- **Single Responsibility**: Each class has one reason to change
- **Open/Closed**: Open for extension, closed for modification
- **Liskov Substitution**: Proper interface implementations
- **Interface Segregation**: Small, focused interfaces
- **Dependency Inversion**: Depend on abstractions via DI

## Features

### Markdown Support

Grimoire fully supports markdown syntax:

- **Bold text**
- *Italic text*
- `inline code`
- And much more!

### Code Blocks

```ruby
# Example: Domain Entity
class Note
  def update_content(new_content)
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
end
```

```python
# Example: Clean architecture
def create_note(name, folder=None):
    """Use case orchestrates domain logic"""
    note = Note.create(name=name, folder=folder)
    repository.save(note)
    return note
```

### Note Linking

Connect your notes using `[[note name]]` syntax:

Check out the [[DDD Architecture Guide]] and [[SOLID Principles]].

---

## Your Notes, Your Way

All your notes are stored as plain markdown files in your filesystem. You have complete control and ownership.

**Happy note-taking!** 📝

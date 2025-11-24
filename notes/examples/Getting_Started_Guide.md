# Getting Started Guide

## What is Grimoire?

Grimoire is a **terminal-based note-taking application** built with **Domain-Driven Design (DDD)** and **SOLID principles**. It respects your privacy and gives you complete control over your notes.

## Architecture Overview

Unlike monolithic note apps, Grimoire is built with clean architecture:

```
UI Layer → Application Layer → Domain Layer ← Infrastructure Layer
```

This means:
- **Easy to test** - Mock dependencies
- **Easy to extend** - Add features without breaking existing code
- **Easy to maintain** - Clear separation of concerns
- **Easy to understand** - Well-organized codebase

## Philosophy

### Your Notes, Your Filesystem

Unlike cloud-based note apps, Grimoire stores all your notes as **plain markdown files** directly in your filesystem. This means:

- ✓ Complete ownership of your data
- ✓ Easy backup (just copy the folder)
- ✓ Use any text editor alongside Grimoire
- ✓ Version control with Git if you want
- ✓ No vendor lock-in

### Markdown-First

All notes are written in markdown, which means:

```markdown
# Headers are easy
**Bold** and *italic* text
- Lists
- Are
- Simple

Code blocks work great too!
```

### Beautiful Terminal UI

Just because it's in the terminal doesn't mean it can't be beautiful. Grimoire features:

- Clean, organized interface
- Syntax highlighting for code blocks
- Intuitive navigation
- Helpful visual feedback

## Your First Note

1. **Launch Grimoire**:
   ```bash
   ruby grimoire.rb
   ```

2. **Create a note** - Press `n`
   - A note with timestamp name is created automatically

3. **Edit the note** - Press `e`
   - Navigate with `j`/`k`
   - Insert line with `i`
   - Delete line with `x`
   - Save with `s`

4. **View the note** - Press `Enter` to open

## Organizing Notes

### Folders

Create folders by organizing your markdown files:

```
notes/
  ├── projects/
  │   ├── project_a.md
  │   └── project_b.md
  ├── personal/
  │   └── journal.md
  └── ideas.md
```

Grimoire automatically detects and displays folders!

### Linking Notes

Connect related ideas using `[[note name]]` syntax:

```markdown
# My Project

Related documents:
- [[Project Plan]]
- [[Meeting Notes]]
- [[Technical Design]]

See also: [[personal/Ideas]]
```

## Understanding the Architecture

Grimoire's clean architecture makes it special:

### Domain Layer
**What notes ARE**

```ruby
class Note
  def update_content(new_content)
    @content = NoteContent.new(new_content)
    @metadata = @metadata.touch
  end
end
```

Pure business logic, no dependencies.

### Application Layer
**What you can DO with notes**

```ruby
class CreateNote
  def call(name:, folder: nil)
    note = Note.create(name: name, folder: folder)
    repository.save(note)
  end
end
```

Orchestrates operations.

### Infrastructure Layer
**HOW notes are stored**

```ruby
class FileSystemNoteRepository
  def save(note)
    File.write(path, note.content.to_s)
  end
end
```

Technical implementation details.

### UI Layer
**HOW you interact**

Terminal interface that coordinates everything.

## Advanced Usage

### Custom Storage Location

Set where your notes are stored:

```bash
export GRIMOIRE_NOTES_DIR=/path/to/notes
ruby grimoire.rb
```

### Docker Setup

Use Docker for isolated environment:

```bash
docker-compose up --build
```

Your notes persist in `./notes` directory.

### Extending Grimoire

Thanks to clean architecture, extending Grimoire is straightforward:

**Want database storage?** Implement `NoteRepository` interface:

```ruby
class DatabaseNoteRepository < NoteRepository
  def save(note)
    db.insert(notes: note.to_h)
  end
end
```

**Want new features?** Create a new use case:

```ruby
class ArchiveNote
  def call(path:)
    # Archive logic
  end
end
```

## SOLID Principles in Action

Grimoire demonstrates all five SOLID principles:

### Single Responsibility
Each class does one thing:
- `CreateNote` - Creates notes
- `UpdateNote` - Updates notes
- `Sidebar` - Renders sidebar

### Open/Closed
Open for extension, closed for modification:
- Add new repository implementations
- Add new use cases
- No need to modify existing code

### Liskov Substitution
Subtypes are substitutable:
- Any `NoteRepository` implementation works
- Swap storage backends easily

### Interface Segregation
Small, focused interfaces:
- Repository has only persistence methods
- Renderer has only rendering methods

### Dependency Inversion
Depend on abstractions:
- Use cases depend on repository interface
- Not on concrete file system implementation

## Best Practices

1. **One note per topic** - Keep notes focused
2. **Use folders** - Organize by project or category
3. **Link related notes** - Build a knowledge graph
4. **Regular backups** - Your notes are files, back them up
5. **Version control** - Consider using Git for important notes

## Troubleshooting

### Notes not showing up
- Check `$GRIMOIRE_NOTES_DIR` environment variable
- Make sure files have `.md` extension
- Verify file permissions

### Editor not working
- Current editor is simplified
- Use external editor for complex edits
- Files are at `~/grimoire_notes/` by default

### Performance issues
- Large notes may be slow to render
- Consider splitting into smaller notes
- Use folders to organize many notes

## Next Steps

- Read [[DDD Architecture Guide]] to understand the design
- Read [[SOLID Principles]] to see patterns in action
- Check [[Keyboard Shortcuts]] for all commands
- Explore the codebase to learn more

## Learning Resources

### In This Repository
- `ARCHITECTURE.md` - Detailed architecture
- `DDD_AND_SOLID.md` - Patterns explained
- `CONTRIBUTING.md` - How to contribute
- `README.md` - Full documentation

### External
- Domain-Driven Design by Eric Evans
- Clean Architecture by Robert C. Martin
- Ruby best practices

---

**Welcome to clean, maintainable, extensible note-taking!** 📝

Related: [[Welcome]], [[Keyboard Shortcuts]]

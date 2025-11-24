# Getting Started Guide

## What is Grimoire?

Grimoire is a **terminal-based note-taking application** that respects your privacy and gives you complete control over your notes.

## Philosophy

### Your Notes, Your Filesystem

Unlike cloud-based note apps, Grimoire stores all your notes as plain markdown files directly in your filesystem. This means:

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

- Syntax highlighting for code blocks
- Clean, organized interface
- Intuitive navigation
- Helpful visual feedback

## Your First Note

1. Press `n` to create a new note
2. Start typing (the note is created automatically)
3. Press `s` to save
4. Press `q` to return to view mode

## Organizing Notes

### Folders

Create folders by simply organizing your markdown files:

```
notes/
  ├── projects/
  │   ├── project_a.md
  │   └── project_b.md
  ├── personal/
  │   └── journal.md
  └── ideas.md
```

### Linking Notes

Connect related ideas using `[[note name]]` syntax:

```markdown
This idea relates to [[My Other Note]].
```

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

---

**Next Steps**: Check out [[Keyboard Shortcuts]] and start writing!

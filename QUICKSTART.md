# Grimoire Quick Start Guide

Get up and running with Grimoire in under 5 minutes! ⚡

## Installation

### Option 1: Quick Install (Recommended)

```bash
# Clone the repository
git clone https://github.com/yourusername/grimoire.git
cd grimoire

# Run the install script
./install.sh
```

### Option 2: Manual Build

```bash
# Clone the repository
git clone https://github.com/yourusername/grimoire.git
cd grimoire

# Build
go build -o grimoire .

# Run
./grimoire
```

### Option 3: Using Docker

```bash
# Clone the repository
git clone https://github.com/yourusername/grimoire.git
cd grimoire

# Run with docker-compose
docker-compose up --build
```

## First Launch

When you first launch Grimoire, it will:

1. Create a notes directory at `~/.grimoire/`
2. Generate a welcome note with instructions
3. Open the beautiful three-pane interface

```bash
grimoire
```

## Interface Overview

```
┌─────────────┬──────────────┬────────────────────────┐
│  FOLDERS    │   NOTES      │      CONTENT           │
│  (Left)     │  (Middle)    │      (Right)           │
│             │              │                        │
│ Browse      │ Select       │ View or edit           │
│ folders     │ notes        │ note content           │
└─────────────┴──────────────┴────────────────────────┘
```

## Essential Keyboard Shortcuts

| Action | Key |
|--------|-----|
| **Navigate** | `↑` `↓` or `j` `k` |
| **Switch panes** | `Tab` |
| **Create note** | `n` |
| **Create folder** | `N` |
| **Edit note** | `e` |
| **Save & exit** | `Esc` (in edit mode) |
| **Search** | `/` |
| **Quit** | `q` |

## Your First Note

1. **Launch Grimoire**
   ```bash
   grimoire
   ```

2. **Press `n` to create a new note**
   - Type a name (e.g., "My First Note")
   - Press `Enter`

3. **Start writing!**
   - Use Markdown syntax
   - The note opens in edit mode automatically

4. **Press `Esc` to save and view your note**
   - Beautiful markdown rendering
   - Syntax highlighting included

## Create Your First Folder

1. **Press `N` (Shift+n) to create a folder**
   - Type a name (e.g., "Personal")
   - Press `Enter`

2. **Navigate into the folder**
   - Use `↑`/`↓` to select it
   - Press `Enter` to open

3. **Create notes inside**
   - Press `n` to create notes in this folder

4. **Navigate back**
   - Press `Backspace` to go to parent folder

## Organize Your Notes

### Recommended Structure

```
~/.grimoire/
├── Personal/
│   ├── Journal/
│   │   ├── 2025-11.md
│   │   └── 2025-12.md
│   └── Ideas.md
├── Work/
│   ├── Projects/
│   │   ├── ProjectA.md
│   │   └── ProjectB.md
│   └── Meetings.md
└── References/
    ├── Books.md
    ├── Articles.md
    └── Quotes.md
```

### Tips for Organization

1. **Use folders for categories**: Personal, Work, Projects, etc.
2. **Use descriptive names**: "2025-11-22 Meeting Notes" instead of "notes.md"
3. **Link related notes**: Use `[[Note Name]]` syntax
4. **Keep it simple**: Don't over-organize

## Markdown Basics

Grimoire supports full Markdown syntax:

```markdown
# Heading 1
## Heading 2
### Heading 3

**bold** and *italic*

- Bullet list
- Another item

1. Numbered list
2. Another item

[Link](https://example.com)

`inline code`

​```
code block
​```

> Blockquote

---

Horizontal rule
```

## Search Your Notes

### Search by Filename
1. Press `/`
2. Type your query
3. Press `Enter`
4. Navigate results with `↑`/`↓`

### Search by Content
1. Press `?`
2. Type your query
3. Press `Enter`
4. Browse matching notes

## Using with Git (Optional)

Track your notes with version control:

```bash
cd ~/.grimoire
git init
git add .
git commit -m "Initial notes"

# Optional: Push to remote
git remote add origin your-repo-url
git push -u origin main
```

## Custom Notes Directory

Use a different location for your notes:

```bash
# One-time use
grimoire /path/to/my/notes

# Or set an alias
alias mynotes="grimoire ~/Documents/Notes"
```

## Example Workflow

### Daily Journal

1. Create a `Journal` folder
2. Each day, create a new note: `2025-11-22.md`
3. Write your thoughts
4. Link to related notes with `[[Note Name]]`

### Project Management

1. Create a `Projects` folder
2. One note per project
3. Use checkboxes for tasks:
   ```markdown
   - [ ] Task 1
   - [x] Task 2 (completed)
   ```

### Knowledge Base

1. Create topic folders: `Programming`, `Design`, `Writing`
2. Write comprehensive notes
3. Link related concepts
4. Use the search to find anything instantly

## Docker Usage

### Run with Docker

```bash
# Build and run
make docker-run

# Your notes will be in ./notes directory
```

### Development with Docker

```bash
# Use docker-compose
docker-compose up --build

# Access the container
docker exec -it grimoire sh
```

## Troubleshooting

### Application won't start

```bash
# Check Go version
go version  # Should be 1.21+

# Rebuild
make clean
make build
```

### Notes not saving

- Check directory permissions
- Ensure `~/.grimoire` is writable
- Try a custom directory with write access

### Display issues

- Ensure your terminal supports 256 colors
- Try a different terminal emulator
- Update your terminal

### Performance issues

- Large notes (>1MB) may be slow to render
- Consider splitting large notes
- Search is optimized for <10,000 notes

## Next Steps

- Read the full [README.md](README.md) for more details
- Check [KEYBINDINGS.md](docs/KEYBINDINGS.md) for all shortcuts
- Review [ARCHITECTURE.md](docs/ARCHITECTURE.md) if you want to contribute
- Explore the [examples](examples/) directory

## Getting Help

- Check the [documentation](docs/)
- Open an issue on GitHub
- Read the [Contributing Guide](CONTRIBUTING.md)

## Have Fun!

Grimoire is designed to make note-taking enjoyable. Don't worry about getting everything perfect—just start writing and let your knowledge base grow naturally!

---

**Happy note-taking! 📖✨**

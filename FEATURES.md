# Grimoire Features Overview

A comprehensive guide to all features available in Grimoire.

## 🎨 User Interface

### Layout
```
┌─────────────────────────────────────────────────────────────┐
│  Grimoire - Your Personal Codex                             │
├──────────┬──────────────────────────────────────────────────┤
│          │                                                  │
│  📁 Tree │           📖 Content Area                        │
│          │                                                  │
│  Folders │  ┌────────────────────────────────────────┐    │
│  & Notes │  │                                        │    │
│          │  │   Rendered Markdown (View Mode)       │    │
│          │  │   or                                   │    │
│  ▾ inbox │  │   Editor (Edit Mode)                   │    │
│  ▾ proj  │  │                                        │    │
│    note1 │  │   - Beautiful rendering                │    │
│    note2 │  │   - Syntax highlighting                │    │
│          │  │   - Full markdown support              │    │
│          │  └────────────────────────────────────────┘    │
│          │                                                  │
├──────────┴──────────────────────────────────────────────────┤
│  ^N New  ^E Edit/View  ^S Save  ^F Search  ^Q Quit          │
└─────────────────────────────────────────────────────────────┘
```

### Color Scheme
- **Primary**: Accent color for borders and highlights
- **Panel**: Background for sidebar
- **Surface**: Main background
- **Text**: Standard text color
- **Muted**: Secondary text

## 📝 Note Management

### Creating Notes

#### Simple Note
```
Ctrl+N → Enter "My Note" → Start Writing
```

#### Note in Folder
```
Ctrl+N → Enter "projects/Project Ideas" → Start Writing
```

#### Auto-Generated Template
```markdown
# Note Title

Created: 2025-11-19 10:30

---

Start writing your thoughts here...
```

### Editing Notes

1. **Open Note**: Click or press Enter in tree
2. **Edit Mode**: Press `Ctrl+E`
3. **Write**: Full markdown editing
4. **Save**: Press `Ctrl+S`
5. **View**: Press `Ctrl+E` to see rendered version

### Deleting Notes

1. **Select Note**: Navigate to note in tree
2. **Delete**: Press `Ctrl+D`
3. **Confirm**: Confirm in dialog
4. **Done**: Note removed from disk

## 📋 Markdown Features

### Text Formatting

```markdown
**Bold text**
*Italic text*
~~Strikethrough~~
`Inline code`
```

**Bold text**
*Italic text*
~~Strikethrough~~
`Inline code`

### Headers

```markdown
# Header 1
## Header 2
### Header 3
#### Header 4
```

### Lists

#### Unordered
```markdown
- Item 1
- Item 2
  - Nested item
  - Another nested item
```

#### Ordered
```markdown
1. First item
2. Second item
3. Third item
```

#### Task Lists
```markdown
- [x] Completed task
- [ ] Pending task
- [ ] Another task
```

### Code Blocks

#### Python
```markdown
​```python
def hello_world():
    print("Hello, Grimoire!")
​```
```

#### JavaScript
```markdown
​```javascript
function greet(name) {
    console.log(`Hello, ${name}!`);
}
​```
```

Supports 100+ languages with syntax highlighting!

### Tables

```markdown
| Feature | Status | Priority |
|---------|--------|----------|
| Notes   | ✅ Done | High     |
| Search  | ✅ Done | High     |
| Themes  | 🚧 Soon | Medium   |
```

### Links

#### External Links
```markdown
[Markdown Guide](https://www.markdownguide.org/)
```

#### Wiki-Style Links
```markdown
[[Another Note]]
[[folder/Nested Note]]
```

### Quotes

```markdown
> "The best way to predict the future is to invent it."
> — Alan Kay
```

## 🔍 Search Features

### Opening Search
```
Ctrl+F → Search dialog opens
```

### Search Capabilities

1. **Filename Search**: Matches note names
2. **Content Search**: Searches inside notes
3. **Live Results**: Updates as you type
4. **Context Preview**: Shows matching lines
5. **Quick Open**: Click result to open

### Search Tips

- Use lowercase for case-insensitive search
- Search works across all notes and folders
- Results show file path and context
- Press Escape or click Close to exit

## ⌨️ Keyboard Shortcuts

### Essential Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+N` | New Note | Create a new note |
| `Ctrl+E` | Toggle Mode | Switch between Edit and View |
| `Ctrl+S` | Save | Save current note |
| `Ctrl+D` | Delete | Delete current note |
| `Ctrl+F` | Search | Search all notes |
| `F5` | Refresh | Refresh file tree |
| `Ctrl+Q` | Quit | Exit Grimoire |

### Navigation Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `↑` / `↓` | Navigate | Move up/down in tree |
| `j` / `k` | Navigate | Vim-style navigation |
| `Enter` | Open | Open selected note |
| `Tab` | Focus | Switch between panels |
| `Escape` | Cancel | Close modals |

### Editor Shortcuts

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+A` | Select All | Select all text |
| `Ctrl+C` | Copy | Copy selection |
| `Ctrl+V` | Paste | Paste from clipboard |
| `Ctrl+X` | Cut | Cut selection |
| `Ctrl+Z` | Undo | Undo last change |
| `Ctrl+Y` | Redo | Redo last undo |

## 🗂️ File Organization

### Folder Structure

```
notes/
├── inbox/              # Quick capture
│   └── ideas.md
├── projects/           # Project notes
│   ├── project-a.md
│   └── project-b.md
├── reference/          # Reference material
│   └── commands.md
└── archive/            # Old notes
    └── 2024/
```

### Best Practices

1. **Use Descriptive Names**: Clear note titles
2. **Group by Topic**: Organize in folders
3. **Link Related Notes**: Use `[[wiki-links]]`
4. **Regular Cleanup**: Archive old notes
5. **Consistent Naming**: Use consistent conventions

## 🔗 Note Linking

### Wiki-Style Links

```markdown
See [[Project Ideas]] for more details.
Check out [[work/Meeting Notes]] from last week.
```

### Creating Linked Notes

1. Write `[[New Note Name]]` in any note
2. Save the note
3. Press `Ctrl+N` to create the linked note
4. Enter the exact name
5. Notes are now connected!

### Link Benefits

- Build a knowledge graph
- Navigate between related topics
- Create a personal wiki
- Track connections

## 🎯 Workflows

### Daily Notes

```markdown
# 2025-11-19

## Tasks
- [ ] Task 1
- [ ] Task 2

## Notes
Meeting with team...

## Links
- [[Project X]]
- [[Next Meeting]]
```

### Project Management

```markdown
# Project Name

Status: In Progress
Owner: Your Name

## Goals
1. Goal 1
2. Goal 2

## Tasks
- [ ] Task 1
- [ ] Task 2

## Notes
[[Meeting Notes]]
[[Technical Specs]]
```

### Learning Notes

```markdown
# Topic: Python Decorators

## Summary
Key concepts...

## Examples
​```python
@decorator
def function():
    pass
​```

## Resources
- [[Python Basics]]
- [Documentation](https://docs.python.org)
```

## 🚀 Advanced Features

### Command Line Options

```bash
# Custom notes directory
python grimoire.py --notes-dir ~/my-notes

# Help
python grimoire.py --help
```

### Docker Usage

```bash
# Run in Docker
docker-compose run --rm grimoire

# Mount custom directory
docker run -it --rm -v ~/notes:/notes grimoire
```

### File Operations

All notes are stored as plain files:
- Edit with any text editor
- Version control with Git
- Backup with standard tools
- Sync with Dropbox, etc.

## 📊 Limitations

Current limitations (future enhancements):

1. **No Tags**: Tags system planned for v1.1
2. **No Export**: PDF/HTML export coming
3. **No Themes**: Custom themes in development
4. **No Vim Mode**: Vim bindings planned
5. **No Plugins**: Plugin system in roadmap

## 💡 Tips & Tricks

### Tip 1: Quick Capture
Create an `inbox` folder for quick notes, organize later.

### Tip 2: Templates
Create note templates in a `templates/` folder.

### Tip 3: Git Integration
Initialize git in notes directory for version control:
```bash
cd ~/grimoire-notes
git init
git add .
git commit -m "Initial commit"
```

### Tip 4: Backups
Regularly backup your notes:
```bash
tar -czf notes-backup.tar.gz ~/grimoire-notes/
```

### Tip 5: Search Operators
Use specific terms for better search results.

### Tip 6: Keyboard First
Learn shortcuts for maximum productivity.

### Tip 7: Folder Strategy
Use folders for projects, keep root for quick access.

### Tip 8: Link Liberally
Create many connections between notes.

### Tip 9: Daily Notes
Start each day with a daily note.

### Tip 10: Review Regularly
Set time to review and organize notes.

## 🎓 Learning Resources

- **README.md**: Full documentation
- **QUICKSTART.md**: Get started quickly
- **ARCHITECTURE.md**: Technical details
- **examples/**: Sample notes

## 🤝 Getting Help

- Check documentation first
- Search issues on GitHub
- Open a new issue
- Join community discussions

---

**Master these features and become a Grimoire power user!** 🚀

For more details, see the main README.md file.

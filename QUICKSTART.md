# Grimoire Quick Start Guide 🚀

Get up and running with Grimoire in less than 5 minutes!

## Installation Options

### Option 1: Local Installation (Fastest)

```bash
# Install dependencies
pip install -r requirements.txt

# Launch Grimoire
python grimoire.py
```

Your notes will be stored in `~/grimoire-notes/` by default.

### Option 2: Docker (Isolated)

```bash
# Build and run
docker-compose build
docker-compose run --rm grimoire
```

Your notes will be stored in `./notes/` directory.

## First Steps

1. **Launch the app** - You'll see a welcome note automatically
2. **Navigate** - Use arrow keys or `j/k` to move through the file tree
3. **Open a note** - Press Enter on any note
4. **Edit mode** - Press `Ctrl+E` to start editing
5. **Save** - Press `Ctrl+S` to save changes
6. **New note** - Press `Ctrl+N` to create a new note

## Essential Keyboard Shortcuts

```
Ctrl+N  - Create new note
Ctrl+E  - Toggle Edit/View mode
Ctrl+S  - Save note
Ctrl+F  - Search notes
Ctrl+Q  - Quit
```

## Creating Your First Note

1. Press `Ctrl+N`
2. Type: "My First Note"
3. Press Enter
4. Start writing!

To create a note in a folder:
1. Press `Ctrl+N`
2. Type: "projects/Project Ideas"
3. Press Enter

## Markdown Basics

```markdown
# Heading 1
## Heading 2

**Bold text**
*Italic text*

- List item
- Another item

`code inline`

```python
# Code block
print("Hello Grimoire!")
```

[[Link to Another Note]]
```

## Tips

- **Tab** switches between sidebar and editor
- Notes are saved as `.md` files in your notes directory
- You can edit notes with any text editor
- Use Git for version control (recommended!)

## What's Next?

- Organize notes into folders
- Use wiki-links `[[Note Name]]` to connect ideas
- Search with `Ctrl+F` to find anything
- Build your knowledge base!

## Need Help?

- Press `Ctrl+Q` to quit anytime
- Check the main README.md for detailed documentation
- All your notes are stored as plain text files

---

**Happy note-taking! 📖✨**

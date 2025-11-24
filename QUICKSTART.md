# Grimoire Quick Start Guide

Get up and running with Grimoire in under 5 minutes! ⚡

## Option 1: Docker (Easiest)

Perfect for trying Grimoire without installing dependencies:

```bash
# Build and run with Docker Compose
docker-compose up --build

# Your notes will be saved in ./notes directory
```

That's it! Grimoire will launch in your terminal.

To stop: Press `q` to quit Grimoire, then `Ctrl+C` to stop Docker.

## Option 2: Local Installation

### Prerequisites

- Ruby 3.0 or higher
- ncurses libraries

### Quick Setup

```bash
# Run the setup script
./setup.sh

# Start Grimoire
ruby grimoire.rb
```

### Manual Setup

If the setup script doesn't work:

**On Ubuntu/Debian:**
```bash
sudo apt-get install ruby ruby-dev libncurses-dev
bundle install
ruby grimoire.rb
```

**On macOS:**
```bash
brew install ruby ncurses
bundle install
ruby grimoire.rb
```

## First Steps in Grimoire

Once Grimoire launches, you'll see:

1. **Left Sidebar**: Lists folders and notes
2. **Main Area**: Displays the selected note
3. **Status Bar**: Shows current mode and helpful hints

### Try These Commands

1. Press `?` to see all keyboard shortcuts
2. Press `j` or `k` to navigate notes
3. Press `Enter` to open a note
4. Press `e` to edit a note
5. Press `n` to create a new note
6. Press `q` to quit

## Keyboard Shortcuts Cheat Sheet

| Key | Action |
|-----|--------|
| `?` | Show help |
| `j/k` or `↓/↑` | Navigate up/down |
| `Enter` | Open note |
| `e` | Edit note |
| `n` | New note |
| `d` | Delete note |
| `/` | Search |
| `Space` | Scroll down |
| `b` | Scroll up |
| `q` | Quit |

## Where Are My Notes?

Notes are stored as plain markdown files in:

- **Docker**: `./notes/` in your project directory
- **Local**: `~/grimoire_notes/` by default

You can edit these files with any text editor!

### Custom Notes Directory

```bash
export GRIMOIRE_NOTES_DIR=/path/to/your/notes
ruby grimoire.rb
```

## Example Notes

Grimoire comes with three example notes in `notes/examples/`:

- **Welcome.md** - Introduction to Grimoire
- **DDD_Architecture_Guide.md** - Explains the architecture
- **SOLID_Principles.md** - Shows design principles

## Understanding the Architecture

Grimoire is built with **Domain-Driven Design (DDD)** and **SOLID principles**:

```
┌─────────────────────────────┐
│   UI Layer                  │  ← What you see
├─────────────────────────────┤
│   Application (Use Cases)   │  ← What you can do
├─────────────────────────────┤
│   Domain (Business Logic)   │  ← What notes are
├─────────────────────────────┤
│   Infrastructure (Files)    │  ← How it's stored
└─────────────────────────────┘
```

**Why does this matter?**
- Clean, maintainable code
- Easy to extend and modify
- Easy to test
- Clear separation of concerns

Learn more:
- See `ARCHITECTURE.md` for details
- See `DDD_AND_SOLID.md` for patterns
- Read the example notes for guides

## Common Tasks

### Creating Your First Note

1. Press `n` (new note)
2. A note with timestamp name is created automatically
3. Press `e` to edit it
4. Add your content (simplified editor):
   - `j/k` - Move between lines
   - `i` - Insert new line
   - `x` - Delete line
   - `s` - Save
   - `q` - Cancel

### Organizing with Folders

Create folders by creating markdown files in subdirectories:

```bash
# In your notes directory
mkdir -p work/projects
mkdir personal
echo "# Project Plan" > work/projects/project.md
echo "# Journal" > personal/journal.md
```

Grimoire will automatically detect and display folders!

### Linking Notes

Use wiki-style links in your notes:

```markdown
# My Note

This relates to [[Another Note]] and [[Important Ideas]].

See also: [[work/projects/project]]
```

Links are highlighted in cyan when viewing.

### Searching Notes

Press `/` or `s` to search (simplified in current version).

For full-text search, use your file system:

```bash
# Search note content
grep -r "search term" ~/grimoire_notes/

# Find note by name
find ~/grimoire_notes/ -name "*keyword*.md"
```

## Troubleshooting

### "curses gem won't install"

Install ncurses development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libncurses-dev

# macOS
brew install ncurses
```

Then try again:
```bash
bundle install
```

### "Terminal colors look wrong"

Set your TERM environment variable:

```bash
export TERM=xterm-256color
ruby grimoire.rb
```

### "Can't create notes directory"

Check permissions or set a custom directory:

```bash
export GRIMOIRE_NOTES_DIR=$HOME/my_notes
mkdir -p $HOME/my_notes
ruby grimoire.rb
```

### "Container won't start"

Make sure Docker is running:

```bash
docker --version
docker-compose --version
```

Try rebuilding:

```bash
docker-compose down
docker-compose up --build
```

## Using Make Commands

Grimoire includes a Makefile for convenience:

```bash
make help          # Show all commands
make install       # Install dependencies
make run          # Run locally
make docker-build  # Build Docker image
make docker-run    # Run in Docker
make docker-shell  # Access container shell
make clean        # Clean temporary files
```

## Next Steps

### Learn the Architecture

Grimoire's architecture makes it easy to:
- Add new features
- Change storage backends
- Extend functionality
- Maintain code quality

Read:
- `ARCHITECTURE.md` - Detailed architecture
- `DDD_AND_SOLID.md` - Design patterns explained
- `CONTRIBUTING.md` - How to contribute

### Customize Your Setup

1. **Change notes location**:
   ```bash
   export GRIMOIRE_NOTES_DIR=/path/to/notes
   ```

2. **Use with Docker volume**:
   Edit `docker-compose.yml`:
   ```yaml
   volumes:
     - /your/path:/root/grimoire_notes
   ```

3. **Integrate with editor**:
   Notes are plain markdown - edit with any editor!

### Explore Example Notes

The example notes explain:
- DDD architecture in detail
- SOLID principles with examples
- How to extend Grimoire
- Best practices

## Getting Help

- **In-app help**: Press `?`
- **Architecture**: See `ARCHITECTURE.md`
- **Patterns**: See `DDD_AND_SOLID.md`
- **Contributing**: See `CONTRIBUTING.md`
- **Issues**: Open a GitHub issue

## What Makes Grimoire Different?

1. **Clean Architecture** - Built with DDD and SOLID principles
2. **Your Data** - Plain markdown files, no lock-in
3. **Privacy First** - No cloud, no tracking
4. **Beautiful TUI** - Elegant terminal interface
5. **Extensible** - Easy to add features or change storage

## Philosophy

Grimoire believes:
- Your notes belong to you
- Clean code is maintainable code
- Terminal apps can be beautiful
- Privacy matters
- Open source is better

---

**Happy note-taking!** 📝✨

*Your notes, your way, in your terminal.*

**Note**: The current editor is simplified. For full editing, use your favorite text editor on the markdown files!

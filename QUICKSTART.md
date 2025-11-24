# Grimoire Quick Start Guide

Get up and running with Grimoire in under 5 minutes! ⚡

## Option 1: Docker (Easiest)

Perfect for trying Grimoire without installing dependencies:

```bash
# Start Grimoire with Docker Compose
docker-compose up --build

# Your notes will be saved in ./notes directory
```

That's it! Grimoire will launch in your terminal.

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

## Where Are My Notes?

Notes are stored as markdown files in:

- **Docker**: `./notes/` in your project directory
- **Local**: `~/grimoire_notes/` (or set `GRIMOIRE_NOTES_DIR`)

You can edit these files with any text editor!

## Keyboard Shortcuts Cheat Sheet

| Key | Action |
|-----|--------|
| `?` | Show help |
| `j/k` or `↓/↑` | Navigate |
| `Enter` | Open note |
| `e` | Edit note |
| `n` | New note |
| `d` | Delete note |
| `/` | Search |
| `Space` | Scroll down |
| `q` | Quit |

## Example Notes

Grimoire comes with example notes:

- **Welcome.md** - Introduction and overview
- **Keyboard_Shortcuts.md** - Full keyboard reference
- **Getting_Started_Guide.md** - Detailed guide

## Customization

### Change Notes Directory

```bash
export GRIMOIRE_NOTES_DIR=/path/to/your/notes
ruby grimoire.rb
```

### With Docker

Edit `docker-compose.yml` to change the volume mount:

```yaml
volumes:
  - /your/path:/root/grimoire_notes
```

## Troubleshooting

### "curses gem won't install"

Make sure you have ncurses development libraries:

```bash
# Ubuntu/Debian
sudo apt-get install libncurses-dev

# macOS
brew install ncurses
```

### "Terminal colors look wrong"

Make sure your terminal supports 256 colors:

```bash
export TERM=xterm-256color
```

### "Can't create notes directory"

Check permissions or set a custom directory:

```bash
export GRIMOIRE_NOTES_DIR=$HOME/my_notes
mkdir -p $HOME/my_notes
```

## Next Steps

- Read the full [README.md](README.md) for detailed features
- Check out [CONTRIBUTING.md](CONTRIBUTING.md) to contribute
- Customize your notes organization
- Create your first note collection!

## Getting Help

- Press `?` inside Grimoire for help
- Check the example notes
- Open an issue on GitHub

---

**Happy note-taking!** 📝✨

*Your notes, your way, in your terminal.*

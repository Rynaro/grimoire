# Grimoire Quick Start Guide

## Building and Running

### Local Development

```bash
# Build the application
cargo build --release

# Run the application
cargo run --release
```

### Docker

```bash
# Build and run with Docker Compose
docker-compose up --build

# Or run directly
docker build -t grimoire .
docker run -it --rm grimoire
```

## Basic Usage

### First Steps

1. **Start the app**: Run `cargo run --release` or use Docker
2. **Navigate**: Use `j`/`k` to move up/down in the sidebar
3. **Open a note**: Press `Enter` on a note
4. **Edit**: Press `i` to enter insert mode, type your content
5. **Save**: Press `Esc` to exit insert mode (auto-saves)

### Creating Your First Note

1. Press `Ctrl+N` to create a new note
2. You'll automatically enter insert mode
3. Type your markdown content:

```markdown
# My First Note

This is a **bold** note with *emphasis*.

## Features

- Markdown support
- Wiki-links: [[another-note]]
- Code blocks

```rust
fn main() {
    println!("Hello, Grimoire!");
}
```
```

4. Press `Esc` to save and exit insert mode

### Wiki-Links

Create connections between notes:

```markdown
This note references [[another-note]].
```

- Wiki-links are highlighted in **magenta**
- Press `Ctrl+F` to follow the first wiki-link in the current note

### Search

- Press `/` to search content across all notes
- Type your search query and press `Enter`
- The first matching note will open

### Commands

Press `:` to enter command mode:

- `:q` or `:quit` - Quit the application
- `:w` or `:write` - Save current note
- `:search <query>` - Search for content

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| `j` / `↓` | Move down |
| `k` / `↑` | Move up |
| `h` / `←` | Focus sidebar |
| `l` / `→` | Focus note area |
| `Enter` | Open note/folder |
| `i` | Enter insert mode |
| `Esc` | Exit mode / Clear selection |
| `Ctrl+N` | Create new note |
| `Ctrl+D` | Delete current item |
| `Ctrl+F` | Follow wiki-link |
| `Ctrl+Q` | Quit |
| `/` | Search |
| `:` | Command mode |

## File Location

Notes are stored in: `~/.grimoire/notes/`

All notes are plain markdown files that you can edit with any text editor.

## Tips

- Use folders to organize your notes
- Wiki-links help create a knowledge graph
- Markdown syntax is fully supported
- Notes auto-save when you exit insert mode
- Use search (`/`) to quickly find content

Enjoy your Grimoire! 📚

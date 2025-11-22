## Grimoire — Terminal Notes Codex

Grimoire is a resource-friendly, terminal-first note taking environment inspired by Apple Notes. It keeps your content as plain Markdown on disk so you retain full ownership and can use any external tooling alongside the TUI.

### Highlights
- **Three-pane layout**: folders in the sidebar, notes list, and a Markdown-aware reader/editor pane with inline code and bidirectional link highlighting (`[[note]]`).
- **Fast navigation**: arrow keys, `Tab`/`Shift+Tab` to move focus, `[ / ]` to jump between links, and a global search overlay (`/`) that searches both filenames and content.
- **Command palette**: press `:` to create/delete folders or notes (`:note <title>`, `:folder <name>`, `:delete note|folder`, `:refresh`, `:help`).
- **Inline editing**: press `e` to enter editing mode, write Markdown directly in the viewer, and use `Ctrl+S` to persist changes.
- **Filesystem first**: notes are saved as `.md` files in a configurable directory (`GRIMOIRE_DIR` env var or CLI arg). Default is `${XDG_DATA_HOME:-~/.local/share}/grimoire`.
- **Link following**: `[[Note Title]]` blocks are detected, styled, and can be opened with `Enter`.

### Getting Started
```bash
cd grimoire
cargo run --release               # uses ~/.local/share/grimoire
cargo run --release -- /path/to/vault
GRIMOIRE_DIR=/notes cargo run
```

### Keymap Snapshot
- `Arrow keys` navigate lists; `PageUp/PageDown` scroll viewer
- `Tab` / `Shift+Tab` cycle focus between sidebar → notes → viewer
- `:` open command palette, `/` start global search
- `e` edit note, `Ctrl+S` save, `Esc` cancel
- `[` / `]` cycle note links, `Enter` follow when in viewer
- `r` refresh filesystem state, `q` quits

### Docker Support
Build a portable container (great for quick previews):
```bash
cd grimoire
docker build -t grimoire .
docker run --rm -it \
  -v "$PWD/notes:/notes" \
  -e GRIMOIRE_DIR=/notes \
  --name grimoire \
  grimoire
```
Mount any host directory at `/notes` to own your data. The image ships the compiled binary (`target/release/grimoire`) so startup is instant.

### Repository Layout
- `grimoire/src/` – application code split into `app`, `ui`, `storage`, `markdown`, `editor`, and `commands` modules
- `grimoire/Cargo.toml` – crate definition
- `grimoire/Dockerfile` – container recipe referenced above

### Next Ideas
- Hidden Vim-mode keymap toggle (foundation is laid in the input layer)
- Richer Markdown styling (tables, checkboxes) and auto-link suggestions
- Optional sync/watch mode using filesystem notifications

Enjoy the spellbook! 
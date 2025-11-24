# Grimoire

Grimoire is a curses-powered, security-conscious notes companion that keeps every idea in plain Markdown under your direct filesystem control. It blends an Obsidian/Apple Notes inspired layout with keyboard-first ergonomics so you can browse folders, open backlinks, search across files, and jump into your favourite `$EDITOR` without leaving the terminal.

## Feature Highlights

- **Tree sidebar** listing every folder and `.md` note, with collapse/expand and context-aware creation commands.
- **Live note pane** with lightweight Markdown highlighting, [[wikilink]] detection, and quick link jumping.
- **Command palette keys** for creating/deleting files, searching titles (`/`) or full text (`?`), and launching your editor (`e`).
- **Filesystem-native storage** (default `~/Grimoire`) with slugged filenames, safe path sanitisation, and automatic empty-folder cleanup.
- **Docker workflow** for fast previewing or sandboxing, plus RSpec coverage for config, repository, and search helpers.

## Prerequisites

- Ruby `>= 3.1` with Bundler.
- `ncurses` headers (`sudo apt install libncurses-dev` on Debian/Ubuntu).
- A terminal editor available in `$EDITOR` (falls back to `nano`).

## Installation

```bash
git clone <repo> grimoire && cd grimoire
bundle install
bin/grimoire --init          # writes ~/.config/grimoire/config.yml
bin/grimoire                 # launches the TUI
```

### Configuration

`~/.config/grimoire/config.yml`

```yaml
notes_root: /home/alex/Grimoire
editor: nvim
```

Change `notes_root` to point to any directory you want Grimoire to manage. The CLI also accepts `--root`, `--editor`, and `--config` overrides per invocation.

## Keybindings

| Key | Action |
| --- | --- |
| `Tab` | Toggle focus between sidebar and note pane |
| `↑` / `↓` | Navigate folders/notes or scroll the note |
| `Space` | Collapse/expand selected folder |
| `Enter` | Open note / toggle folder |
| `n` | Create note (use `Folder/Note Title` to nest) |
| `f` | Create folder (prompted for relative path) |
| `d` | Delete selected note/folder (with confirmation) |
| `e` | Edit current note in `$EDITOR` |
| `/` | Search notes by title/path |
| `?` | Search across note content |
| `o` or `Enter` (in note focus) | Follow `[[Link]]` under the cursor |
| `q` | Quit |

## Notes, Markdown, and Links

- Notes are plain `.md` files; filenames are slugified (e.g., “Daily Log” → `daily-log.md`).
- Linking works with `[[Note Title]]` or `[[folder/note]]`. When duplicates exist, Grimoire tries the current folder before searching globally.
- Basic Markdown cues (headings, quotes, checkboxes, code fences, bold, links) are colourised in the note pane.

## Search & Navigation

- `/` uses fuzzy/regex matching on titles and relative paths.
- `?` scans file contents and returns a picker with line numbers/snippets. Selecting a result jumps directly to that line.
- Status bar always shows the latest action or hint; a mini help line lists the high-value shortcuts.

## Docker Workflow

```bash
# build the development image
docker build -t grimoire .

# run with your host notes mounted (create ./notes or change the path)
docker run --rm -it \
  -v "$(pwd)/notes:/data/grimoire" \
  -e EDITOR="${EDITOR:-nano}" \
  grimoire
```

Or use Compose:

```bash
docker compose up --build
```

The container launches `bin/grimoire --root /data/grimoire`, so mounting a host directory keeps your notes persistent.

## Testing

```bash
bundle exec rspec
```

Current specs cover:

- Repository CRUD, sanitisation, and link resolution.
- Search helpers for titles and line-numbered content hits.
- Config load/save defaults.

## Architecture Notes

- `Grimoire::Config` keeps settings under `~/.config/grimoire` and enforces `0700` permissions on the notes root.
- `Grimoire::Repository` is the single gateway for filesystem work: slug generation, sanitised paths, creation, deletion, and link resolution.
- `Grimoire::TUI` orchestrates the curses layout (sidebar, note area, overlays), command routing, prompts, and external editor hand-offs.
- `Grimoire::Formatter` provides a minimal Markdown-aware tokenizer for colourful rendering without large dependencies.
- `Grimoire::Search` composes on top of the repository for both metadata and full-text queries.

## Security Considerations

- Relative paths are aggressively sanitised to prevent `..` traversal.
- Notes live on your disk; no network calls, sync clients, or hidden services run inside the TUI.
- Config and notes directories are created with owner-only permissions when possible.

## Roadmap Ideas

- Optional encrypted vaults or hardware-key integration.
- Backlink graph view and backlinks pane.
- Live preview/editor mode for Markdown without jumping to `$EDITOR`.
- Background indexing for faster fuzzy search.

Pull requests or suggestions welcome—this is your personal grimoire; bend it to your rituals.

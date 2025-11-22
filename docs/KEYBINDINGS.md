# Grimoire Keybindings Reference

Complete reference for all keyboard shortcuts in Grimoire.

## Global Shortcuts

| Key | Action |
|-----|--------|
| `q` | Quit Grimoire |
| `Ctrl+C` | Force quit |
| `Tab` | Cycle forward through panes (Folders → Notes → Content) |
| `Shift+Tab` | Cycle backward through panes |

## Navigation

### In Lists (Folders & Notes Panes)

| Key | Action |
|-----|--------|
| `↑` or `k` | Move up one item |
| `↓` or `j` | Move down one item |
| `g` | Go to first item |
| `G` | Go to last item |
| `Enter` | Open selected item (navigate into folder or open note) |
| `Backspace` | Navigate to parent folder |

### In Content Pane

| Key | Action |
|-----|--------|
| `↑` or `k` | Scroll up one line |
| `↓` or `j` | Scroll down one line |
| `PgUp` | Scroll up one page |
| `PgDn` | Scroll down one page |
| `g` | Scroll to top of note |
| `G` | Scroll to bottom of note |

## File Operations

| Key | Action |
|-----|--------|
| `n` | Create new note in current folder |
| `N` | Create new folder |
| `d` | Delete current note/folder (requires confirmation) |
| `e` | Edit current note |

## Edit Mode

| Key | Action |
|-----|--------|
| `Esc` | Save and exit edit mode |
| `Ctrl+S` | Quick save without exiting |
| Standard text editing keys | Edit content |

## Search

| Key | Action |
|-----|--------|
| `/` | Search notes by filename |
| `?` | Search notes by content |
| `Enter` | Execute search |
| `Esc` | Cancel search |

## Confirmation Dialogs

| Key | Action |
|-----|--------|
| `y` or `Y` | Confirm action |
| `n` or `N` | Cancel action |
| `Esc` | Cancel action |

## Tips

- **Vim users**: The keybindings are inspired by Vim for familiarity
- **Mouse support**: Currently keyboard-only, mouse support may be added in future
- **Custom bindings**: Future versions will support custom keybinding configuration

## Pane Focus Indicator

The active pane is highlighted with a colored border:
- **Purple border** - Active pane
- **Gray border** - Inactive pane

## Mode Indicator

The status bar at the bottom shows the current mode:
- **VIEW** - Normal viewing mode
- **EDIT** - Editing a note
- **SEARCH** - Searching by filename
- **SEARCH CONTENT** - Searching by content

## Common Workflows

### Creating a New Note

1. Navigate to desired folder (if any)
2. Press `n`
3. Type note name
4. Press `Enter`
5. Note opens in edit mode automatically

### Organizing Notes

1. Create folders with `N`
2. Navigate into folders with `Enter`
3. Move back with `Backspace`
4. Create notes in current location with `n`

### Finding Information

1. Quick find by name: Press `/`
2. Search in content: Press `?`
3. Navigate results with `↑`/`↓`
4. Open result with `Enter`

### Editing Notes

1. Select note
2. Press `e` to edit
3. Make changes
4. Press `Esc` to save and exit
5. Or `Ctrl+S` to save and continue editing

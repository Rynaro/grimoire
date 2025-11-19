#!/usr/bin/env python3
"""
Grimoire - A beautiful terminal-based note-taking application
Inspired by Apple Notes and Obsidian
"""

import os
import re
from pathlib import Path
from typing import Optional, List
from datetime import datetime

from textual.app import App, ComposeResult
from textual.binding import Binding
from textual.containers import Container, Horizontal, Vertical, VerticalScroll
from textual.widgets import (
    DirectoryTree,
    Footer,
    Header,
    Static,
    Input,
    TextArea,
    Label,
    Button,
)
from textual.screen import Screen, ModalScreen
from textual import events
from textual.reactive import reactive
from rich.markdown import Markdown
from rich.syntax import Syntax
from rich.panel import Panel
from rich.text import Text as RichText


class GrimoireDirectoryTree(DirectoryTree):
    """Custom DirectoryTree that filters for markdown files and shows a nice tree."""
    
    def filter_paths(self, paths):
        """Filter to show only directories and markdown files."""
        return [
            path for path in paths
            if path.is_dir() or path.suffix.lower() in ['.md', '.markdown']
        ]


class MarkdownViewer(VerticalScroll):
    """Widget to display rendered markdown content."""
    
    content = reactive("")
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.border_title = "📖 View Mode"
    
    def watch_content(self, content: str) -> None:
        """Update the displayed content when it changes."""
        self.update_display(content)
    
    def update_display(self, content: str) -> None:
        """Render markdown content."""
        self.remove_children()
        if content:
            md = Markdown(content, code_theme="monokai", hyperlinks=True)
            self.mount(Static(md))
        else:
            self.mount(Static("📝 No note selected. Press [bold cyan]Ctrl+N[/] to create a new note.", classes="empty-state"))


class NoteEditor(Vertical):
    """Widget for editing notes with markdown support."""
    
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.text_area = TextArea(language="markdown", theme="monokai")
        self.text_area.border_title = "✏️  Edit Mode"
        self.current_file: Optional[Path] = None
    
    def compose(self) -> ComposeResult:
        yield self.text_area
    
    def load_file(self, file_path: Path) -> None:
        """Load a file into the editor."""
        self.current_file = file_path
        if file_path.exists():
            content = file_path.read_text(encoding='utf-8')
            self.text_area.text = content
        else:
            self.text_area.text = ""
    
    def save_file(self) -> bool:
        """Save the current file."""
        if self.current_file:
            try:
                self.current_file.parent.mkdir(parents=True, exist_ok=True)
                self.current_file.write_text(self.text_area.text, encoding='utf-8')
                return True
            except Exception as e:
                return False
        return False
    
    def get_content(self) -> str:
        """Get the current content."""
        return self.text_area.text


class NewNoteModal(ModalScreen):
    """Modal for creating a new note."""
    
    def __init__(self, notes_dir: Path, **kwargs):
        super().__init__(**kwargs)
        self.notes_dir = notes_dir
    
    def compose(self) -> ComposeResult:
        with Container(id="new-note-dialog"):
            yield Label("Create New Note", id="dialog-title")
            yield Input(placeholder="Enter note name (e.g., 'My Note' or 'folder/My Note')", id="note-name-input")
            with Horizontal(id="dialog-buttons"):
                yield Button("Create", variant="primary", id="create-btn")
                yield Button("Cancel", variant="default", id="cancel-btn")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "create-btn":
            input_widget = self.query_one("#note-name-input", Input)
            note_name = input_widget.value.strip()
            if note_name:
                # Ensure .md extension
                if not note_name.lower().endswith('.md'):
                    note_name += '.md'
                
                note_path = self.notes_dir / note_name
                self.dismiss(note_path)
            else:
                self.dismiss(None)
        else:
            self.dismiss(None)
    
    def on_input_submitted(self, event: Input.Submitted) -> None:
        """Handle Enter key in input."""
        note_name = event.value.strip()
        if note_name:
            if not note_name.lower().endswith('.md'):
                note_name += '.md'
            note_path = self.notes_dir / note_name
            self.dismiss(note_path)


class DeleteConfirmModal(ModalScreen):
    """Modal for confirming file deletion."""
    
    def __init__(self, file_path: Path, **kwargs):
        super().__init__(**kwargs)
        self.file_path = file_path
    
    def compose(self) -> ComposeResult:
        with Container(id="delete-dialog"):
            yield Label("⚠️  Delete Note", id="dialog-title")
            yield Label(f"Are you sure you want to delete:\n\n[bold]{self.file_path.name}[/bold]", id="delete-message")
            with Horizontal(id="dialog-buttons"):
                yield Button("Delete", variant="error", id="delete-btn")
                yield Button("Cancel", variant="default", id="cancel-btn")
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "delete-btn":
            self.dismiss(True)
        else:
            self.dismiss(False)


class SearchModal(ModalScreen):
    """Modal for searching notes."""
    
    def __init__(self, notes_dir: Path, **kwargs):
        super().__init__(**kwargs)
        self.notes_dir = notes_dir
        self.search_results: List[Path] = []
    
    def compose(self) -> ComposeResult:
        with Container(id="search-dialog"):
            yield Label("🔍 Search Notes", id="dialog-title")
            yield Input(placeholder="Search in note names and content...", id="search-input")
            yield VerticalScroll(id="search-results")
            with Horizontal(id="dialog-buttons"):
                yield Button("Close", variant="default", id="close-btn")
    
    def on_mount(self) -> None:
        """Focus the search input when mounted."""
        self.query_one("#search-input", Input).focus()
    
    def on_input_changed(self, event: Input.Changed) -> None:
        """Perform search as user types."""
        query = event.value.strip().lower()
        if not query:
            self.query_one("#search-results", VerticalScroll).remove_children()
            return
        
        self.search_results = []
        results_container = self.query_one("#search-results", VerticalScroll)
        results_container.remove_children()
        
        # Search through all markdown files
        for md_file in self.notes_dir.rglob("*.md"):
            try:
                content = md_file.read_text(encoding='utf-8')
                relative_path = md_file.relative_to(self.notes_dir)
                
                # Search in filename
                if query in str(relative_path).lower():
                    self.search_results.append(md_file)
                    result_widget = Button(f"📄 {relative_path}", classes="search-result", name=str(md_file))
                    results_container.mount(result_widget)
                # Search in content
                elif query in content.lower():
                    # Find context around match
                    lines = content.split('\n')
                    for i, line in enumerate(lines):
                        if query in line.lower():
                            context = line[:100]
                            self.search_results.append(md_file)
                            result_widget = Button(
                                f"📄 {relative_path}\n   {context}...",
                                classes="search-result",
                                name=str(md_file)
                            )
                            results_container.mount(result_widget)
                            break
            except Exception:
                continue
    
    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "close-btn":
            self.dismiss(None)
        elif event.button.classes and "search-result" in event.button.classes:
            # Return the selected file
            file_path = Path(event.button.name)
            self.dismiss(file_path)


class Grimoire(App):
    """The main Grimoire application."""
    
    CSS = """
    Screen {
        background: $surface;
    }
    
    #main-container {
        width: 100%;
        height: 100%;
    }
    
    #sidebar {
        width: 30;
        border-right: solid $primary;
        background: $panel;
    }
    
    #content-area {
        width: 1fr;
    }
    
    DirectoryTree {
        padding: 0 1;
        background: $panel;
    }
    
    MarkdownViewer {
        padding: 1 2;
        border: solid $primary;
    }
    
    NoteEditor {
        height: 100%;
    }
    
    TextArea {
        border: solid $primary;
    }
    
    .empty-state {
        padding: 2 4;
        text-align: center;
        color: $text-muted;
    }
    
    /* Modal Styles */
    ModalScreen {
        align: center middle;
    }
    
    #new-note-dialog, #delete-dialog, #search-dialog {
        width: 60;
        height: auto;
        background: $panel;
        border: thick $primary;
        padding: 1 2;
    }
    
    #search-dialog {
        width: 80;
        height: 30;
    }
    
    #dialog-title {
        width: 100%;
        content-align: center middle;
        text-style: bold;
        color: $accent;
        margin-bottom: 1;
    }
    
    #delete-message {
        margin: 1 0;
        content-align: center middle;
    }
    
    #note-name-input, #search-input {
        width: 100%;
        margin-bottom: 1;
    }
    
    #dialog-buttons {
        width: 100%;
        height: auto;
        align: center middle;
    }
    
    #dialog-buttons Button {
        margin: 0 1;
    }
    
    #search-results {
        width: 100%;
        height: 15;
        border: solid $primary;
        margin-bottom: 1;
    }
    
    .search-result {
        width: 100%;
        margin: 0 0 1 0;
        text-align: left;
    }
    """
    
    BINDINGS = [
        Binding("ctrl+q", "quit", "Quit", priority=True),
        Binding("ctrl+n", "new_note", "New Note", priority=True),
        Binding("ctrl+s", "save", "Save", priority=True),
        Binding("ctrl+d", "delete_note", "Delete", priority=True),
        Binding("ctrl+e", "toggle_mode", "Toggle Edit/View", priority=True),
        Binding("ctrl+f", "search", "Search", priority=True),
        Binding("f5", "refresh", "Refresh", priority=True),
    ]
    
    def __init__(self, notes_dir: str = None):
        super().__init__()
        self.title = "Grimoire - Your Personal Codex"
        self.sub_title = "Terminal Note-Taking"
        
        # Set up notes directory
        if notes_dir:
            self.notes_dir = Path(notes_dir).resolve()
        else:
            self.notes_dir = Path.home() / "grimoire-notes"
        
        self.notes_dir.mkdir(parents=True, exist_ok=True)
        
        # Create a welcome note if directory is empty
        self._create_welcome_note()
        
        self.current_file: Optional[Path] = None
        self.edit_mode = False
    
    def _create_welcome_note(self) -> None:
        """Create a welcome note if the notes directory is empty."""
        if not any(self.notes_dir.rglob("*.md")):
            welcome_file = self.notes_dir / "Welcome to Grimoire.md"
            welcome_content = """# Welcome to Grimoire 📖✨

Grimoire is your personal knowledge codex in the terminal.

## Getting Started

### Navigation
- Use **↑/↓** or **j/k** to navigate the file tree
- Press **Enter** to open a note
- Use **Tab** to switch between sidebar and content

### Keyboard Shortcuts
- **Ctrl+N** - Create a new note
- **Ctrl+E** - Toggle between Edit and View mode
- **Ctrl+S** - Save your changes
- **Ctrl+D** - Delete current note
- **Ctrl+F** - Search through your notes
- **F5** - Refresh the file tree
- **Ctrl+Q** - Quit Grimoire

### Markdown Support
Grimoire supports full markdown syntax:

- **Bold**, *italic*, ~~strikethrough~~
- Lists (ordered and unordered)
- Code blocks with syntax highlighting
- Headers, quotes, and more!

```python
def hello_grimoire():
    print("Happy note-taking!")
```

### Note Linking
Link between notes using wiki-style links:
- `[[Note Name]]` - links to another note
- `[[folder/Note Name]]` - links to notes in folders

### Organization
- Create folders in the file tree
- Use forward slashes when creating notes: `project/ideas.md`
- All notes are stored as plain markdown files

## Features

✨ Beautiful terminal interface
📝 Markdown editing with syntax highlighting  
🔗 Wiki-style note linking
🔍 Full-text search across all notes
📁 File-based storage (you own your data!)
⚡ Fast and lightweight

---

**Pro Tip**: You can organize notes in folders just like you would in your file system. Your notes directory is at:
`{notes_dir}`

Start taking notes and build your personal knowledge base! 🚀
""".format(notes_dir=self.notes_dir)
            
            welcome_file.write_text(welcome_content, encoding='utf-8')
    
    def compose(self) -> ComposeResult:
        """Create child widgets."""
        yield Header()
        
        with Horizontal(id="main-container"):
            with Vertical(id="sidebar"):
                yield GrimoireDirectoryTree(str(self.notes_dir), id="file-tree")
            
            with Container(id="content-area"):
                yield MarkdownViewer(id="viewer")
                yield NoteEditor(id="editor")
        
        yield Footer()
    
    def on_mount(self) -> None:
        """Handle mounting of the app."""
        # Hide editor initially
        editor = self.query_one("#editor", NoteEditor)
        editor.display = False
        
        # Focus the directory tree
        tree = self.query_one("#file-tree", GrimoireDirectoryTree)
        tree.focus()
    
    def on_directory_tree_file_selected(self, event: DirectoryTree.FileSelected) -> None:
        """Handle file selection in the directory tree."""
        file_path = Path(event.path)
        
        # Only handle markdown files
        if file_path.suffix.lower() not in ['.md', '.markdown']:
            return
        
        self.current_file = file_path
        self._load_note(file_path)
    
    def _load_note(self, file_path: Path) -> None:
        """Load a note into the viewer/editor."""
        if not file_path.exists():
            return
        
        content = file_path.read_text(encoding='utf-8')
        
        # Update viewer or editor depending on mode
        if self.edit_mode:
            editor = self.query_one("#editor", NoteEditor)
            editor.load_file(file_path)
        else:
            viewer = self.query_one("#viewer", MarkdownViewer)
            viewer.content = content
    
    def action_toggle_mode(self) -> None:
        """Toggle between view and edit mode."""
        viewer = self.query_one("#viewer", MarkdownViewer)
        editor = self.query_one("#editor", NoteEditor)
        
        if self.edit_mode:
            # Switch to view mode
            # First save if there's content
            if self.current_file:
                editor.save_file()
                content = editor.get_content()
                viewer.content = content
            
            editor.display = False
            viewer.display = True
            self.edit_mode = False
        else:
            # Switch to edit mode
            if self.current_file:
                editor.load_file(self.current_file)
            
            viewer.display = False
            editor.display = True
            self.edit_mode = True
            editor.text_area.focus()
    
    def action_save(self) -> None:
        """Save the current note."""
        if self.edit_mode and self.current_file:
            editor = self.query_one("#editor", NoteEditor)
            if editor.save_file():
                self.notify("💾 Note saved successfully!", severity="information")
                
                # Update viewer content
                viewer = self.query_one("#viewer", MarkdownViewer)
                viewer.content = editor.get_content()
            else:
                self.notify("❌ Failed to save note", severity="error")
    
    async def action_new_note(self) -> None:
        """Create a new note."""
        result = await self.push_screen_wait(NewNoteModal(self.notes_dir))
        
        if result:
            note_path: Path = result
            
            # Create the note with a template
            note_path.parent.mkdir(parents=True, exist_ok=True)
            if not note_path.exists():
                template = f"""# {note_path.stem}

Created: {datetime.now().strftime("%Y-%m-%d %H:%M")}

---

Start writing your thoughts here...
"""
                note_path.write_text(template, encoding='utf-8')
            
            # Refresh the tree
            tree = self.query_one("#file-tree", GrimoireDirectoryTree)
            tree.reload()
            
            # Load the new note
            self.current_file = note_path
            
            # Switch to edit mode
            if not self.edit_mode:
                self.action_toggle_mode()
            else:
                editor = self.query_one("#editor", NoteEditor)
                editor.load_file(note_path)
            
            self.notify(f"📝 Created note: {note_path.name}", severity="information")
    
    async def action_delete_note(self) -> None:
        """Delete the current note."""
        if not self.current_file:
            self.notify("No note selected to delete", severity="warning")
            return
        
        result = await self.push_screen_wait(DeleteConfirmModal(self.current_file))
        
        if result:
            try:
                self.current_file.unlink()
                self.notify(f"🗑️  Deleted: {self.current_file.name}", severity="information")
                
                # Clear the viewer/editor
                viewer = self.query_one("#viewer", MarkdownViewer)
                viewer.content = ""
                
                editor = self.query_one("#editor", NoteEditor)
                editor.text_area.text = ""
                
                self.current_file = None
                
                # Refresh the tree
                tree = self.query_one("#file-tree", GrimoireDirectoryTree)
                tree.reload()
            except Exception as e:
                self.notify(f"❌ Failed to delete note: {e}", severity="error")
    
    async def action_search(self) -> None:
        """Search for notes."""
        result = await self.push_screen_wait(SearchModal(self.notes_dir))
        
        if result:
            file_path: Path = result
            self.current_file = file_path
            self._load_note(file_path)
            
            # Expand the tree to show the file
            tree = self.query_one("#file-tree", GrimoireDirectoryTree)
            tree.reload()
    
    def action_refresh(self) -> None:
        """Refresh the file tree."""
        tree = self.query_one("#file-tree", GrimoireDirectoryTree)
        tree.reload()
        self.notify("🔄 File tree refreshed", severity="information")


def main():
    """Main entry point."""
    import argparse
    
    parser = argparse.ArgumentParser(
        description="Grimoire - A beautiful terminal-based note-taking application"
    )
    parser.add_argument(
        "--notes-dir",
        type=str,
        default=None,
        help="Directory to store notes (default: ~/grimoire-notes)"
    )
    
    args = parser.parse_args()
    
    app = Grimoire(notes_dir=args.notes_dir)
    app.run()


if __name__ == "__main__":
    main()

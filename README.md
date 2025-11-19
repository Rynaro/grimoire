# Grimoire 📖✨

A beautiful, powerful terminal-based note-taking application inspired by Apple Notes and Obsidian.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Python](https://img.shields.io/badge/python-3.11+-blue.svg)

## ✨ Features

### 🎨 Beautiful Terminal UI
- Modern, intuitive interface built with [Textual](https://textual.textualize.io/)
- Smooth navigation and responsive design
- Syntax-highlighted markdown editing
- Clean, distraction-free writing experience

### 📝 Powerful Note-Taking
- **Markdown Support**: Full markdown syntax with live rendering
- **Syntax Highlighting**: Code blocks with beautiful syntax highlighting
- **Wiki-style Links**: Connect notes with `[[Note Name]]` syntax
- **Rich Formatting**: Headers, lists, tables, quotes, and more

### 🗂️ Smart Organization
- **Folder Structure**: Organize notes in nested folders
- **File Tree Navigation**: Easy browsing with keyboard shortcuts
- **Quick Search**: Full-text search across all notes (Ctrl+F)
- **File Operations**: Create, delete, and manage notes seamlessly

### 💾 Data Sovereignty
- **Plain Text**: Notes stored as standard markdown files
- **Own Your Data**: Complete control over your notes
- **Portable**: Easy backup, sync, and version control with Git
- **No Lock-in**: Use notes with any markdown editor

### ⚡ Performance
- **Lightweight**: Minimal resource usage
- **Fast Startup**: Instant launch and response
- **Efficient**: Optimized for large note collections

## 🚀 Quick Start

### Installation

#### Method 1: Direct Python (Recommended for local use)

```bash
# Clone the repository
git clone <repository-url>
cd grimoire

# Install dependencies
pip install -r requirements.txt

# Run Grimoire
python grimoire.py

# Or specify a custom notes directory
python grimoire.py --notes-dir /path/to/your/notes
```

#### Method 2: Docker (Recommended for isolation/testing)

```bash
# Build and run with Docker Compose
docker-compose build
docker-compose run --rm grimoire

# Your notes will be saved in ./notes directory
```

#### Method 3: Docker (Manual)

```bash
# Build the image
docker build -t grimoire .

# Run the container
docker run -it --rm -v $(pwd)/notes:/notes grimoire

# On Windows (PowerShell)
docker run -it --rm -v ${PWD}/notes:/notes grimoire
```

## 🎯 Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **Ctrl+N** | Create a new note |
| **Ctrl+E** | Toggle between Edit and View mode |
| **Ctrl+S** | Save current note |
| **Ctrl+D** | Delete current note |
| **Ctrl+F** | Search through notes |
| **F5** | Refresh file tree |
| **Ctrl+Q** | Quit Grimoire |
| **Tab** | Switch focus between panels |
| **↑/↓** or **j/k** | Navigate file tree |
| **Enter** | Open selected note |

### Creating Notes

1. Press **Ctrl+N** to create a new note
2. Enter a name like `My Note` or `projects/Ideas` for folders
3. Start writing in the editor (auto-markdown mode)
4. Press **Ctrl+S** to save

### Organizing Notes

- Create folders by using `/` in note names: `work/meeting-notes.md`
- Notes are automatically organized in the sidebar
- Use the file tree to browse your knowledge base

### Linking Notes

Connect your thoughts using wiki-style links:

```markdown
Check out my [[Project Ideas]] and [[work/Q4 Goals]].
```

### Searching

Press **Ctrl+F** to search:
- Searches both filenames and content
- Live results as you type
- Click a result to open that note

## 📁 Project Structure

```
grimoire/
├── grimoire.py           # Main application
├── requirements.txt      # Python dependencies
├── Dockerfile           # Container configuration
├── docker-compose.yml   # Docker Compose setup
├── README.md           # This file
└── notes/              # Your notes directory (created automatically)
    └── Welcome to Grimoire.md
```

## 🛠️ Development

### Prerequisites

- Python 3.11 or higher
- pip or conda for package management
- Docker (optional, for containerized deployment)

### Setup Development Environment

```bash
# Clone the repository
git clone <repository-url>
cd grimoire

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run in development mode
python grimoire.py --notes-dir ./dev-notes
```

### Docker Development

```bash
# Build the image
docker-compose build

# Run with live code mounting
docker-compose up

# The docker-compose.yml already mounts the code for hot-reload
```

## 🎨 Customization

### Custom Notes Directory

```bash
# Use a custom location for your notes
python grimoire.py --notes-dir ~/Documents/MyNotes

# Or set it in docker-compose.yml
volumes:
  - ~/Documents/MyNotes:/notes
```

### Themes

Grimoire uses Textual's theming system. You can customize the appearance by modifying the CSS in `grimoire.py`.

## 🔧 Technical Details

### Architecture

- **Framework**: [Textual](https://textual.textualize.io/) - Modern TUI framework
- **Markdown**: [markdown-it-py](https://github.com/executablebooks/markdown-it-py) for parsing
- **Rendering**: [Rich](https://rich.readthedocs.io/) for beautiful terminal output
- **Syntax Highlighting**: [Pygments](https://pygments.org/) for code blocks

### Storage

- Notes are stored as plain `.md` files
- Directory structure mirrors your organization
- UTF-8 encoding for universal compatibility
- No database - just files you can version control

### Performance

- Lazy loading of note content
- Efficient file tree traversal
- Minimal memory footprint
- Fast full-text search

## 🤝 Contributing

Contributions are welcome! Here are some ideas:

- 🎨 New themes and color schemes
- 🔌 Plugin system for extensions
- 📊 Note statistics and analytics
- 🔄 Sync with cloud services
- 📱 Mobile companion app
- 🌐 Web interface option

## 📝 License

MIT License - See LICENSE file for details

## 🙏 Acknowledgments

- Inspired by [Obsidian](https://obsidian.md/) and Apple Notes
- Built with [Textual](https://textual.textualize.io/)
- Powered by [Rich](https://rich.readthedocs.io/)

## 📮 Support

- Issues: Open an issue on GitHub
- Questions: Start a discussion on GitHub Discussions
- Updates: Watch the repository for new releases

---

**Happy note-taking! 📖✨**

Built with ❤️ for terminal enthusiasts and knowledge workers.

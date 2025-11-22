# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-22

### Added
- Initial release of Grimoire
- Three-pane interface (Folders, Notes, Content)
- Markdown rendering with syntax highlighting
- Note creation and deletion
- Folder creation and deletion
- File system-based storage
- Search by filename
- Search by content
- Edit mode with auto-save
- Vim-style navigation (hjkl, gg, G)
- Tab navigation between panes
- Docker and docker-compose support
- Beautiful TUI with Bubble Tea
- Welcome note for new users
- Keyboard shortcuts reference

### Technical Details
- Built with Go 1.21+
- Uses Bubble Tea for TUI
- Uses Glamour for markdown rendering
- Uses Lipgloss for styling
- Zero dependencies for storage (filesystem-based)

## [Unreleased]

### Planned Features
- Vim mode with advanced keybindings
- Tags system
- Templates for new notes
- Export to PDF/HTML
- Theme customization
- Note encryption
- Git integration
- Mobile companion app

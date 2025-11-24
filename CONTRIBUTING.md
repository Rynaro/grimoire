# Contributing to Grimoire

Thank you for your interest in contributing to Grimoire! 🎉

## Development Setup

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd grimoire
   ```

2. **Install dependencies**
   ```bash
   ./setup.sh
   # Or manually:
   bundle install
   ```

3. **Run Grimoire**
   ```bash
   ruby grimoire.rb
   ```

## Project Structure

```
grimoire/
├── grimoire.rb              # Main entry point
├── lib/
│   ├── core/               # Core business logic
│   │   └── notes_manager.rb
│   ├── renderers/          # Markdown and syntax highlighting
│   │   └── markdown_renderer.rb
│   └── ui/                 # Terminal UI components
│       └── application.rb
├── notes/                  # Example notes
├── Gemfile                 # Dependencies
├── Dockerfile             # Container setup
└── tests/                 # Tests (coming soon)
```

## Coding Guidelines

### Ruby Style

- Follow standard Ruby conventions
- Use `frozen_string_literal: true`
- Keep methods small and focused
- Write descriptive variable names

### Security

This is a notes app - security matters! When adding dependencies:

- Choose well-maintained, popular gems
- Avoid gems with known vulnerabilities
- Keep dependencies minimal
- Review code that handles user data

### Performance

Grimoire should be lightweight:

- Avoid loading unnecessary dependencies
- Lazy-load when possible
- Keep the UI responsive
- Test with large note collections

## Areas for Contribution

### High Priority

- [ ] Full-featured text editor (current implementation is simplified)
- [ ] Interactive search with fuzzy matching
- [ ] Comprehensive test suite
- [ ] Better error handling
- [ ] Configuration file support

### Features

- [ ] Note templates
- [ ] Tags and metadata
- [ ] Export functionality (PDF, HTML)
- [ ] Git integration
- [ ] Note encryption
- [ ] Plugin system
- [ ] Multiple themes
- [ ] Vim-style commands

### UI/UX

- [ ] Better scrolling behavior
- [ ] Mouse support
- [ ] Split view for multiple notes
- [ ] Preview mode while editing
- [ ] Better visual feedback

### Documentation

- [ ] Video tutorials
- [ ] More example notes
- [ ] Architecture documentation
- [ ] API documentation

## Testing

Currently, Grimoire lacks comprehensive tests. We'd love help building:

- Unit tests for core logic
- Integration tests for the TUI
- End-to-end tests

## Submitting Changes

1. **Fork the repository**

2. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

3. **Make your changes**
   - Write clear, concise commit messages
   - Add tests if applicable
   - Update documentation

4. **Test your changes**
   ```bash
   ruby grimoire.rb
   # Test various scenarios
   ```

5. **Submit a pull request**
   - Describe what your changes do
   - Reference any related issues
   - Include screenshots for UI changes

## Code Review Process

- All submissions require review
- We'll provide constructive feedback
- Changes may be requested
- Once approved, we'll merge your PR

## Questions?

- Open an issue for bugs or feature requests
- Start a discussion for general questions
- Check existing issues before creating new ones

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Grimoire better! 🙏

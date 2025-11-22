# Contributing to Grimoire

First off, thank you for considering contributing to Grimoire! It's people like you that make Grimoire such a great tool.

## Code of Conduct

This project and everyone participating in it is governed by respect and kindness. By participating, you are expected to uphold this code.

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check the existing issues as you might find out that you don't need to create one. When you are creating a bug report, please include as many details as possible:

* **Use a clear and descriptive title**
* **Describe the exact steps which reproduce the problem**
* **Provide specific examples to demonstrate the steps**
* **Describe the behavior you observed after following the steps**
* **Explain which behavior you expected to see instead and why**
* **Include screenshots if possible**
* **Include your environment details** (OS, Go version, terminal emulator)

### Suggesting Enhancements

Enhancement suggestions are tracked as GitHub issues. When creating an enhancement suggestion, please include:

* **Use a clear and descriptive title**
* **Provide a step-by-step description of the suggested enhancement**
* **Provide specific examples to demonstrate the steps**
* **Describe the current behavior and explain which behavior you expected to see instead**
* **Explain why this enhancement would be useful**

### Pull Requests

* Fill in the required template
* Do not include issue numbers in the PR title
* Follow the Go coding style
* Include thoughtfully-worded, well-structured tests
* Document new code
* End all files with a newline

## Development Process

1. **Fork the repository**
2. **Clone your fork**
   ```bash
   git clone https://github.com/yourusername/grimoire.git
   cd grimoire
   ```

3. **Create a branch**
   ```bash
   git checkout -b feature/amazing-feature
   ```

4. **Make your changes**
   - Write your code
   - Add tests if applicable
   - Update documentation if needed

5. **Test your changes**
   ```bash
   make test
   go run . # Manual testing
   ```

6. **Commit your changes**
   ```bash
   git commit -m "Add amazing feature"
   ```

7. **Push to your fork**
   ```bash
   git push origin feature/amazing-feature
   ```

8. **Open a Pull Request**

## Development Setup

### Prerequisites

* Go 1.21 or higher
* Git
* A terminal that supports 256 colors

### Building from Source

```bash
# Clone the repository
git clone https://github.com/yourusername/grimoire.git
cd grimoire

# Install dependencies
make deps

# Build
make build

# Run
./grimoire
```

### Running Tests

```bash
make test
```

### Code Style

* Follow standard Go conventions
* Run `go fmt` before committing
* Use meaningful variable and function names
* Add comments for exported functions
* Keep functions small and focused

### Project Structure

```
grimoire/
├── main.go              # Entry point
├── internal/
│   ├── app/            # TUI application logic
│   └── storage/        # Storage layer
├── Dockerfile          # Container configuration
└── README.md           # Documentation
```

## Testing

We value well-tested code. When adding new features:

1. Add unit tests for new functions
2. Test edge cases
3. Ensure existing tests still pass
4. Test in different environments if possible

## Documentation

* Update README.md if you change functionality
* Add inline comments for complex logic
* Update CHANGELOG.md with your changes
* Document new features

## Git Commit Messages

* Use the present tense ("Add feature" not "Added feature")
* Use the imperative mood ("Move cursor to..." not "Moves cursor to...")
* Limit the first line to 72 characters or less
* Reference issues and pull requests liberally after the first line

Examples:
```
Add note linking feature

Implement [[note name]] syntax for linking between notes.
Closes #123
```

## Questions?

Feel free to open an issue with your question or reach out to the maintainers.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

Thank you for contributing to Grimoire! 🎉

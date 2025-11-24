# Quick Start Guide

## Installation

1. Install dependencies:
```bash
bundle install
```

2. Run the application:
```bash
ruby bin/grimoire
```

## Using Docker

1. Build and run:
```bash
docker-compose up
```

2. Your notes will be stored in `./notes/` directory (mounted as volume)

## First Steps

1. **Create a note**: Press `n` and type a note name
2. **Edit a note**: Select a note and press `e`
3. **Save**: Press `Ctrl+S` while in edit mode
4. **Search**: Press `/` and type your search query
5. **Navigate**: Use arrow keys or `j`/`k` to move up/down
6. **Quit**: Press `q`

## Example Notes

Create markdown files in `~/.grimoire/notes/` or your custom directory:

```markdown
# My First Note

This is a **markdown** note with *formatting*.

## Links

- Link to another note: [[Another Note]]
- Markdown link: [Click here](another-note.md)

## Code

```ruby
def hello
  puts "Hello, Grimoire!"
end
```

## Lists

- Item 1
- Item 2
  - Sub-item
```

## Tips

- Notes are stored as plain `.md` files - edit them with any text editor
- Use folders to organize: create folders in the notes directory
- Wiki-style links `[[note name]]` help connect related notes
- Search works across all note content, not just filenames

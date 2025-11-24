#!/bin/bash
# Grimoire setup script

set -e

echo "✦ Setting up Grimoire..."
echo ""

# Check Ruby version
if ! command -v ruby &> /dev/null; then
    echo "❌ Ruby is not installed. Please install Ruby 3.0 or higher."
    exit 1
fi

RUBY_VERSION=$(ruby -v | cut -d' ' -f2 | cut -d'.' -f1)
if [ "$RUBY_VERSION" -lt 3 ]; then
    echo "❌ Ruby 3.0 or higher is required. Current version: $(ruby -v)"
    exit 1
fi

echo "✓ Ruby version: $(ruby -v)"

# Check for ncurses
if [ "$(uname)" == "Darwin" ]; then
    # macOS
    if ! brew list ncurses &> /dev/null; then
        echo "⚠️  ncurses not found. Installing via Homebrew..."
        brew install ncurses
    fi
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    # Linux
    if ! dpkg -l | grep -q libncurses-dev; then
        echo "⚠️  ncurses development libraries not found."
        echo "Please install them with:"
        echo "  sudo apt-get install libncurses-dev"
        exit 1
    fi
fi

echo "✓ ncurses libraries available"

# Install bundler if not present
if ! command -v bundle &> /dev/null; then
    echo "📦 Installing Bundler..."
    gem install bundler
fi

# Install dependencies
echo "📦 Installing gem dependencies..."
bundle install

# Create notes directory
NOTES_DIR="${GRIMOIRE_NOTES_DIR:-$HOME/grimoire_notes}"
if [ ! -d "$NOTES_DIR" ]; then
    echo "📁 Creating notes directory at $NOTES_DIR..."
    mkdir -p "$NOTES_DIR"
    
    # Copy example notes
    if [ -d "notes" ]; then
        cp -r notes/* "$NOTES_DIR/"
        echo "✓ Example notes copied to $NOTES_DIR"
    fi
fi

echo ""
echo "✨ Setup complete!"
echo ""
echo "To start Grimoire, run:"
echo "  ruby grimoire.rb"
echo ""
echo "Or with Docker:"
echo "  docker-compose up --build"
echo ""
echo "Your notes will be stored in: $NOTES_DIR"
echo ""
echo "Happy note-taking! 📝"

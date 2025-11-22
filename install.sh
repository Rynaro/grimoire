#!/bin/bash

# Grimoire Installation Script

set -e

echo "📖 Installing Grimoire..."

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go 1.21 or higher."
    echo "Visit: https://golang.org/dl/"
    exit 1
fi

# Check Go version
GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
REQUIRED_VERSION="1.21"

if [ "$(printf '%s\n' "$REQUIRED_VERSION" "$GO_VERSION" | sort -V | head -n1)" != "$REQUIRED_VERSION" ]; then
    echo "❌ Go version $REQUIRED_VERSION or higher is required. You have $GO_VERSION"
    exit 1
fi

echo "✓ Go $GO_VERSION detected"

# Build the application
echo "🔨 Building Grimoire..."
go build -o grimoire .

# Make it executable
chmod +x grimoire

# Determine installation directory
INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"

# Create installation directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Move the binary
echo "📦 Installing to $INSTALL_DIR..."
mv grimoire "$INSTALL_DIR/"

# Check if directory is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo ""
    echo "⚠️  Warning: $INSTALL_DIR is not in your PATH"
    echo "Add this line to your ~/.bashrc or ~/.zshrc:"
    echo ""
    echo "  export PATH=\"\$PATH:$INSTALL_DIR\""
    echo ""
fi

echo ""
echo "✅ Grimoire installed successfully!"
echo ""
echo "Get started:"
echo "  $ grimoire"
echo ""
echo "For help, visit: https://github.com/yourusername/grimoire"

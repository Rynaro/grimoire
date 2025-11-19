#!/bin/bash
# Quick run script for Grimoire

set -e

echo "🔮 Starting Grimoire..."
echo ""

# Check if Python is available
if ! command -v python3 &> /dev/null; then
    echo "❌ Python 3 is not installed. Please install Python 3.11 or higher."
    exit 1
fi

# Check if dependencies are installed
if ! python3 -c "import textual" &> /dev/null; then
    echo "📦 Installing dependencies..."
    pip install -r requirements.txt
    echo ""
fi

# Run Grimoire
python3 grimoire.py "$@"

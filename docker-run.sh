#!/bin/bash
# Helper script to run Grimoire in Docker with proper terminal setup

set -e

echo "✦ Grimoire Docker Runner"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if docker-compose is available
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null 2>&1; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ docker-compose is not installed. Please install it first."
    exit 1
fi

# Build the image
echo "📦 Building Docker image..."
$COMPOSE_CMD build

echo ""
echo "✨ Starting Grimoire..."
echo ""
echo "📝 Notes: Use Ctrl+P, Ctrl+Q to detach (if needed)"
echo "   Or press 'q' inside Grimoire to quit"
echo ""
sleep 1

# Run with proper terminal allocation
# Using 'run' instead of 'up' ensures proper TTY allocation
$COMPOSE_CMD run --rm grimoire

echo ""
echo "✅ Grimoire stopped. Your notes are saved in ./notes/"

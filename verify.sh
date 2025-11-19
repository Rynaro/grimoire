#!/bin/bash
# Grimoire Installation Verification Script

set -e

echo "🔮 Grimoire Installation Verification"
echo "======================================"
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track status
all_passed=true

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    all_passed=false
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check Python version
echo "Checking Python..."
if command -v python3 &> /dev/null; then
    python_version=$(python3 --version | cut -d' ' -f2)
    major=$(echo $python_version | cut -d'.' -f1)
    minor=$(echo $python_version | cut -d'.' -f2)
    
    if [ "$major" -ge 3 ] && [ "$minor" -ge 11 ]; then
        check_pass "Python $python_version (meets requirement: 3.11+)"
    else
        check_fail "Python $python_version (requires 3.11+)"
    fi
else
    check_fail "Python 3 not found"
fi
echo ""

# Check files
echo "Checking project files..."
files=(
    "grimoire.py"
    "requirements.txt"
    "Dockerfile"
    "docker-compose.yml"
    "README.md"
    "QUICKSTART.md"
    "LICENSE"
    "Makefile"
)

for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file not found"
    fi
done
echo ""

# Check Python dependencies
echo "Checking Python dependencies..."
if command -v python3 &> /dev/null; then
    deps=("textual" "rich" "markdown_it" "pygments")
    
    for dep in "${deps[@]}"; do
        if python3 -c "import $dep" 2>/dev/null; then
            check_pass "$dep installed"
        else
            check_warn "$dep not installed (run: pip install -r requirements.txt)"
        fi
    done
else
    check_warn "Cannot check dependencies (Python 3 not found)"
fi
echo ""

# Check Docker
echo "Checking Docker (optional)..."
if command -v docker &> /dev/null; then
    docker_version=$(docker --version | cut -d' ' -f3 | tr -d ',')
    check_pass "Docker $docker_version installed"
    
    if command -v docker-compose &> /dev/null; then
        compose_version=$(docker-compose --version | cut -d' ' -f4 | tr -d ',')
        check_pass "Docker Compose $compose_version installed"
    else
        check_warn "Docker Compose not found (optional)"
    fi
else
    check_warn "Docker not found (optional, but recommended)"
fi
echo ""

# Check syntax
echo "Checking Python syntax..."
if python3 -m py_compile grimoire.py 2>/dev/null; then
    check_pass "grimoire.py syntax valid"
else
    check_fail "grimoire.py has syntax errors"
fi
echo ""

# Summary
echo "======================================"
if [ "$all_passed" = true ]; then
    echo -e "${GREEN}✓ All checks passed!${NC}"
    echo ""
    echo "You're ready to use Grimoire! 🎉"
    echo ""
    echo "Quick start:"
    echo "  ./run.sh                    # Run with default settings"
    echo "  python3 grimoire.py         # Run directly"
    echo "  make docker-run             # Run in Docker"
    echo ""
    echo "For more information, see:"
    echo "  - README.md for full documentation"
    echo "  - QUICKSTART.md for getting started"
    echo "  - TEST.md for testing instructions"
else
    echo -e "${RED}✗ Some checks failed${NC}"
    echo ""
    echo "Please fix the issues above before running Grimoire."
    echo ""
    echo "Common fixes:"
    echo "  - Install Python 3.11+: https://www.python.org/downloads/"
    echo "  - Install dependencies: pip install -r requirements.txt"
    echo "  - Install Docker: https://docs.docker.com/get-docker/"
fi
echo "======================================"

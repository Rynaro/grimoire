# Grimoire Test Guide

This document helps you test that Grimoire is working correctly.

## Pre-Installation Tests

### 1. Check Python Version
```bash
python3 --version
# Should be 3.11 or higher
```

### 2. Verify Repository Files
Ensure these files exist:
- [x] grimoire.py
- [x] requirements.txt
- [x] Dockerfile
- [x] docker-compose.yml
- [x] README.md

## Installation Tests

### Local Installation

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Check for import errors
python3 -c "import textual; import rich; print('✅ Dependencies OK')"

# 3. Run syntax check
python3 -m py_compile grimoire.py
```

### Docker Installation

```bash
# 1. Build image
docker-compose build

# 2. Verify build
docker images | grep grimoire
```

## Functional Tests

### Test 1: Launch Application

```bash
python3 grimoire.py --notes-dir ./test-notes
```

**Expected**: Application launches with a welcome note visible

### Test 2: Navigation
1. Use arrow keys to navigate the file tree
2. Press Enter on "Welcome to Grimoire.md"

**Expected**: Note content displays in viewer

### Test 3: Edit Mode
1. Press `Ctrl+E` to enter edit mode
2. Type some text
3. Press `Ctrl+S` to save

**Expected**: Editor shows, text can be typed, save confirmation appears

### Test 4: Create New Note
1. Press `Ctrl+N`
2. Enter "Test Note" as the name
3. Press Enter

**Expected**: Modal appears, new note creates, editor opens

### Test 5: Create Note in Folder
1. Press `Ctrl+N`
2. Enter "test-folder/Nested Note"
3. Press Enter

**Expected**: Folder and note created, visible in tree

### Test 6: Search Functionality
1. Press `Ctrl+F`
2. Type "welcome"

**Expected**: Search modal appears, results show, can click to open

### Test 7: Delete Note
1. Select a note
2. Press `Ctrl+D`
3. Confirm deletion

**Expected**: Confirmation modal, note deleted, tree refreshed

### Test 8: Markdown Rendering
1. Open any note with markdown
2. Press `Ctrl+E` to view mode

**Expected**: 
- Headers formatted
- Bold/italic working
- Code blocks highlighted
- Lists rendered

### Test 9: View/Edit Toggle
1. Open a note
2. Press `Ctrl+E` multiple times

**Expected**: Smooth toggle between modes, content preserved

### Test 10: Quit Application
1. Press `Ctrl+Q`

**Expected**: Application closes cleanly

## Docker Tests

### Test 1: Run in Docker

```bash
docker-compose run --rm grimoire
```

**Expected**: Application launches in container

### Test 2: Persistent Notes

```bash
# First run
docker-compose run --rm grimoire
# Create a note, save, quit

# Second run
docker-compose run --rm grimoire
# Note should still exist
```

**Expected**: Notes persist between container runs

## Performance Tests

### Startup Time
```bash
time python3 grimoire.py --notes-dir ./test-notes
# Quit immediately with Ctrl+Q
```

**Expected**: Launch in under 1 second

### Large File Set
Create 100 test notes:
```bash
mkdir -p test-notes
for i in {1..100}; do
    echo "# Note $i" > "test-notes/note-$i.md"
done

python3 grimoire.py --notes-dir ./test-notes
```

**Expected**: Application remains responsive, tree loads quickly

## Edge Cases

### Test 1: Empty Directory
```bash
python3 grimoire.py --notes-dir ./empty-dir
```

**Expected**: Welcome note created automatically

### Test 2: Special Characters in Names
Create note named: `Test: Special @#$ Characters`

**Expected**: Note creates without errors

### Test 3: Very Long Note
Create note with 10,000 lines

**Expected**: Opens and edits smoothly

### Test 4: Unicode Content
Create note with emoji and international characters: `📝 Test Note 日本語 Español`

**Expected**: Displays correctly

## Cleanup

```bash
# Remove test directories
rm -rf test-notes empty-dir

# Remove Docker containers
docker-compose down

# Remove Docker images
docker rmi grimoire
```

## Reporting Issues

If any test fails, report:
1. Which test failed
2. Error message (if any)
3. Python version
4. Operating system
5. Terminal emulator

## Success Criteria

All tests should pass with:
- ✅ No crashes
- ✅ No error messages
- ✅ Expected behavior observed
- ✅ Data persists correctly
- ✅ Good performance

---

**Happy Testing! 🧪**

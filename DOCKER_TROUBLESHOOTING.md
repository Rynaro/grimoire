# Docker Troubleshooting for Grimoire

## The Problem: Docker Container Hangs

If you're experiencing the container hanging or appearing "static" with no response, this is a common issue with curses-based terminal applications in Docker.

## Why This Happens

Curses (the library used for terminal UI) requires:
1. **Interactive terminal (TTY)** - Proper terminal allocation
2. **STDIN open** - Ability to read keyboard input
3. **Proper terminal type** - TERM environment variable set

When using `docker-compose up`, Docker doesn't always provide proper TTY allocation, causing curses to hang.

## Solutions

### ✅ Solution 1: Use `docker-compose run` (Recommended)

```bash
# Build first
docker-compose build

# Run with proper TTY allocation
docker-compose run --rm grimoire
```

**Why this works**: `docker-compose run` allocates a proper interactive terminal (TTY), which curses requires.

### ✅ Solution 2: Use the Helper Script

```bash
./docker-run.sh
```

This script automatically uses the correct Docker commands.

### ✅ Solution 3: Use Docker Directly

```bash
docker build -t grimoire .
docker run -it --rm -v $(pwd)/notes:/root/grimoire_notes grimoire
```

The `-it` flags ensure interactive terminal allocation.

## Common Issues & Fixes

### Issue: "Container starts but nothing happens"

**Cause**: TTY not properly allocated.

**Fix**: Use `docker-compose run` instead of `docker-compose up`:
```bash
docker-compose run --rm grimoire
```

### Issue: "Error: Grimoire requires an interactive terminal (TTY)"

**Cause**: Running without `-it` flags or proper TTY.

**Fix**: Always include `-it` when using `docker run`:
```bash
docker run -it grimoire  # Correct
docker run grimoire      # Wrong - no TTY
```

### Issue: "Terminal colors look wrong"

**Cause**: TERM environment variable not set correctly.

**Fix**: The docker-compose.yml already sets `TERM=xterm-256color`. If running manually:
```bash
docker run -it -e TERM=xterm-256color grimoire
```

### Issue: "Can't read keyboard input"

**Cause**: STDIN not connected.

**Fix**: Ensure `stdin_open: true` in docker-compose.yml, or use `-i` flag:
```bash
docker run -it grimoire  # -i for stdin, -t for tty
```

### Issue: "Notes don't persist"

**Cause**: Volume not mounted.

**Fix**: Mount the notes directory:
```bash
docker run -it -v $(pwd)/notes:/root/grimoire_notes grimoire
```

Or use docker-compose which handles this automatically.

## Understanding Docker Commands

### `docker-compose up` vs `docker-compose run`

| Command | TTY Allocation | Use Case |
|---------|---------------|----------|
| `up` | Limited | Services that don't need interaction |
| `run` | Full | Interactive applications like Grimoire |

**For Grimoire, always use `run`!**

### Docker Run Flags

- `-i` (interactive) - Keep STDIN open
- `-t` (tty) - Allocate pseudo-TTY
- `--rm` - Remove container after exit
- `-v` - Mount volume

Example:
```bash
docker run -it --rm -v $(pwd)/notes:/root/grimoire_notes grimoire
#          │  │   │                                         └─ image name
#          │  │   └─ remove after exit
#          │  └─ allocate TTY
#          └─ interactive (keep STDIN open)
```

## Testing Your Setup

### Test 1: Check if container builds

```bash
docker-compose build
```

Expected: Build succeeds without errors.

### Test 2: Check TTY allocation

```bash
docker-compose run --rm grimoire ruby -e "puts STDIN.tty?"
```

Expected output: `true`

### Test 3: Check terminal type

```bash
docker-compose run --rm grimoire env | grep TERM
```

Expected output: `TERM=xterm-256color`

### Test 4: Test curses

```bash
docker-compose run --rm grimoire ruby -e "require 'curses'; puts 'Curses OK'"
```

Expected output: `Curses OK`

## Alternative: Run Locally

If Docker continues to have issues, run Grimoire locally:

```bash
# Install dependencies
./setup.sh

# Run directly
ruby grimoire.rb
```

## Quick Command Reference

```bash
# ✅ Correct way to run
docker-compose run --rm grimoire

# ✅ Or use helper script
./docker-run.sh

# ✅ Or direct Docker
docker run -it --rm -v $(pwd)/notes:/root/grimoire_notes grimoire

# ❌ Wrong - will hang
docker-compose up

# ❌ Wrong - no TTY
docker run grimoire

# ❌ Wrong - no interaction
docker run -d grimoire
```

## Still Having Issues?

1. **Check Docker version**:
   ```bash
   docker --version
   docker-compose --version
   ```
   
2. **Try rebuilding**:
   ```bash
   docker-compose down
   docker-compose build --no-cache
   docker-compose run --rm grimoire
   ```

3. **Check terminal emulator**:
   - Make sure your terminal supports 256 colors
   - Try a different terminal (iTerm2, Alacritty, etc.)

4. **Enable debug mode**:
   ```bash
   docker-compose run --rm -e DEBUG=1 grimoire
   ```

5. **Check logs**:
   ```bash
   docker-compose logs
   ```

## Summary

**Key Points**:
- ✅ Use `docker-compose run --rm grimoire`
- ✅ Or use `./docker-run.sh`
- ❌ Don't use `docker-compose up` (it hangs)
- ✅ Always ensure `-it` flags for interactive terminals
- ✅ Notes persist in `./notes` directory

**Quick Fix**:
```bash
docker-compose build && docker-compose run --rm grimoire
```

---

**Still stuck?** Open an issue with:
- Docker version
- docker-compose version
- Terminal emulator
- Operating system
- Full error output with `DEBUG=1`

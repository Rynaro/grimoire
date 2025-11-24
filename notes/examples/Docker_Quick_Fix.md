# Docker Quick Fix

## Problem

If you ran `docker-compose up` and the container appeared to hang with no response, this is because curses-based terminal applications need proper TTY allocation.

## Solution

Use `docker-compose run` instead of `docker-compose up`:

```bash
# Quick fix
docker-compose build
docker-compose run --rm grimoire
```

## Or Use the Helper Script

```bash
./docker-run.sh
```

## Why This Works

| Command | TTY Allocation | For Grimoire? |
|---------|---------------|---------------|
| `docker-compose up` | ❌ Limited | No - hangs |
| `docker-compose run` | ✅ Full | Yes - works! |

**Curses applications** (like Grimoire) need:
- Interactive terminal (TTY)
- STDIN connected
- Proper terminal type

`docker-compose run` provides all of these, while `up` doesn't.

## Quick Commands

```bash
# ✅ Correct - use run
docker-compose run --rm grimoire

# ✅ Or helper script
./docker-run.sh

# ✅ Or direct Docker
docker run -it --rm -v $(pwd)/notes:/root/grimoire_notes grimoire

# ❌ Wrong - will hang
docker-compose up
```

## More Help

See `DOCKER_TROUBLESHOOTING.md` for detailed troubleshooting.

---

**TL;DR**: Use `./docker-run.sh` or `docker-compose run --rm grimoire`

#!/usr/bin/env bash
set -euo pipefail
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
HASH="$(echo "$REPO_DIR" | sed 's|/|-|g')"
TARGET_DIR="$HOME/.claude/projects/$HASH"
TARGET="$TARGET_DIR/memory"
SOURCE="$REPO_DIR/docs/memory"
mkdir -p "$TARGET_DIR"
if [ -L "$TARGET" ]; then
  echo "Symlink already exists: $TARGET -> $(readlink "$TARGET")"
  exit 0
fi
[ -e "$TARGET" ] && { echo "ERROR: $TARGET exists, not a symlink"; exit 1; }
ln -s "$SOURCE" "$TARGET"
echo "Linked: $TARGET -> $SOURCE"

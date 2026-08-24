#!/usr/bin/env bash
# Push docs/ to the GitHub wiki.
#
# GitHub does not create the wiki's git repository until the first page exists,
# and there is no API for creating it. So the very first time, open
#   https://github.com/Samy104/omarchy-spaces/wiki
# click "Create the first page", save anything, then run this. Every run after
# that is fully automatic.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WIKI_URL="${WIKI_URL:-https://github.com/Samy104/omarchy-spaces.wiki.git}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

if ! git clone -q "$WIKI_URL" "$TMP/wiki" 2>/dev/null; then
  echo "Could not clone $WIKI_URL"
  echo "Create the first page in the browser, then re-run:"
  echo "  https://github.com/Samy104/omarchy-spaces/wiki"
  exit 1
fi

find "$TMP/wiki" -maxdepth 1 -name '*.md' -delete
cp "$REPO_DIR"/docs/*.md "$TMP/wiki/"

cd "$TMP/wiki"
if git diff --quiet && git diff --cached --quiet && [ -z "$(git status --porcelain)" ]; then
  echo "wiki already up to date"
  exit 0
fi
git add -A
git commit -q -m "Sync wiki from docs/"
git push -q origin HEAD
echo "wiki updated from docs/"

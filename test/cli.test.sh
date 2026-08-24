#!/usr/bin/env bash
# Exercise the installed CLI against a throwaway HOME, so a broken `init` or a
# path that only resolves inside the repo fails here rather than on a user's
# machine. This is the test that would have caught the install-time crash.
set -euo pipefail
cd "$(dirname "$0")/.."
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT

# Copy the CLI somewhere with no repo above it, the way install.sh does.
mkdir -p "$T/bin"
cp bin/omarchy-spaces "$T/bin/omarchy-spaces"
chmod +x "$T/bin/omarchy-spaces"

export XDG_CONFIG_HOME="$T/config" XDG_STATE_HOME="$T/state"
S="$T/bin/omarchy-spaces"

"$S" init >/dev/null
"$S" validate >/dev/null
[ "$("$S" current)" = "personal" ] || { echo "  FAIL default space is not personal"; exit 1; }
"$S" switch work >/dev/null
[ "$("$S" current)" = "work" ] || { echo "  FAIL switch did not stick"; exit 1; }
argv=$("$S" which https://example.com)
echo "$argv" | grep -q 'Profile 1' || { echo "  FAIL work space did not route to Profile 1: $argv"; exit 1; }
"$S" next >/dev/null
[ "$("$S" current)" = "personal" ] || { echo "  FAIL next did not cycle"; exit 1; }
[ "$("$S" get email)" = "samy104@gmail.com" ] || { echo "  FAIL get email"; exit 1; }
"$S" status >/dev/null

echo "  ok   CLI works from an install location with no repo above it"

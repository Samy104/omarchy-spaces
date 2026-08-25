#!/usr/bin/env bash
# Everything. Run before committing.
set -euo pipefail
cd "$(dirname "$0")/.."
echo "unit"
node test/logic.test.js | tail -2
echo "parity"
./test/parity.sh
echo "embedded config"
python3 test/embedded.test.py
echo "safe file reads"
timeout 60 python3 test/safe_read.test.py | tail -2
echo "startup layouts"
python3 test/startup.test.py | tail -2
echo "theme mapping"
python3 test/theme.test.py | tail -2
echo "keybind tables"
python3 test/keybind_parity.test.py
echo "relative navigation"
python3 test/relative.test.py | tail -2
echo "cli smoke"
./test/cli.test.sh

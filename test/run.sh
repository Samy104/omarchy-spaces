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
echo "cli smoke"
./test/cli.test.sh

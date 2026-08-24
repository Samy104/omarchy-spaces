#!/usr/bin/env bash
# The CLI (python) and the shell plugin (JS) each implement the policy rules.
# They must agree on every minute of the day for every space and app, otherwise
# the bar widget and the command line would disagree about what is muted.
#
# Both dumps are emitted as compact JSON so this is a byte comparison of the
# decisions, not of the serializer's whitespace habits.
set -euo pipefail
cd "$(dirname "$0")"
py=$(mktemp); js=$(mktemp)
trap 'rm -f "$py" "$js"' EXIT
python3 dump_policy.py > "$py"
node    dump_policy.js > "$js"
if cmp -s "$py" "$js"; then
  n=$(python3 -c "import json;print(len(json.load(open('$py'))))")
  echo "  ok   python and JS agree on all $n space/minute decisions"
else
  echo "  FAIL python and JS disagree"
  python3 - "$py" "$js" <<'PY'
import json, sys
a=json.load(open(sys.argv[1])); b=json.load(open(sys.argv[2]))
shown=0
for x,y in zip(a,b):
    if x!=y and shown<5:
        print("    py:", json.dumps(x)); print("    js:", json.dumps(y)); print(); shown+=1
print("    total differing rows:", sum(1 for x,y in zip(a,b) if x!=y))
PY
  exit 1
fi

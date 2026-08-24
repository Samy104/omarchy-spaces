# The starter config exists twice: embedded in bin/omarchy-spaces so `init`
# works from any install location, and in config/spaces.example.json where the
# unit tests read it. This asserts they stay identical.
import json, os, re, sys

here = os.path.dirname(os.path.abspath(__file__))
root = os.path.dirname(here)

src = open(os.path.join(root, "bin", "omarchy-spaces")).read()
m = re.search(r'DEFAULT_CONFIG = r"""(.*?)"""', src, re.S)
if not m:
    print("  FAIL bin/omarchy-spaces has no DEFAULT_CONFIG block")
    sys.exit(1)

try:
    embedded = json.loads(m.group(1))
except json.JSONDecodeError as e:
    print("  FAIL embedded DEFAULT_CONFIG is not valid JSON: %s" % e)
    sys.exit(1)

example = json.load(open(os.path.join(root, "config", "spaces.example.json")))

if embedded != example:
    print("  FAIL embedded config and config/spaces.example.json differ")
    sys.exit(1)

print("  ok   embedded starter config matches config/spaces.example.json")

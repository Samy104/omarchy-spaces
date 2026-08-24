# relative_slot decides where SUPER+CTRL+arrow lands. It must never leave the
# active space's range, which is the bug this covers: Hyprland's own e+1 and
# e-1 walk every workspace on the machine.
#
# hyprctl is stubbed so this runs without a compositor.
import importlib.util, json, os, sys

here = os.path.dirname(os.path.abspath(__file__))
cli = type(sys)("cli")
source = open(os.path.join(here, "..", "bin", "omarchy-spaces")).read()
source = source.replace('if __name__ == "__main__":\n    sys.exit(main(sys.argv[1:]))', "")
exec(source, cli.__dict__)

cfg = {
    "spaces": [
        {"id": "personal", "workspaces": {"count": 10}},
        {"id": "work", "workspaces": {"count": 10}},
    ]
}

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
        print("  ok   %s" % name)
    else:
        failed += 1
        print("  FAIL %s: got %r, want %r" % (name, got, want))


def stub(current_real, occupied_reals):
    cli.current_real_ws = lambda: current_real
    cli.hypr_json = lambda what: (
        [{"id": r, "windows": 1} for r in occupied_reals] if what == "workspaces" else None)
    cli.read_slot = lambda space_id, default=1: default


print("\nrelative_slot stays inside the active space")

# work owns real 11 to 20. Nothing else occupied, so it steps plainly.
stub(11, [11])
check("work at slot 1, prev wraps to slot 10 not into personal",
      cli.relative_slot(cfg, "work", -1), 10)
stub(20, [20])
check("work at slot 10, next wraps to slot 1",
      cli.relative_slot(cfg, "work", 1), 1)

# personal owns real 1 to 10.
stub(1, [1])
check("personal at slot 1, prev wraps to slot 10 not into work",
      cli.relative_slot(cfg, "personal", -1), 10)

# Occupied slots are preferred, the way Hyprland's e+1 skips empties.
stub(11, [11, 13, 16])
check("work skips empty slots forward", cli.relative_slot(cfg, "work", 1), 3)
stub(11, [11, 13, 16])
check("work skips empty slots backward, wrapping", cli.relative_slot(cfg, "work", -1), 6)

# Occupied workspaces belonging to another space must not be considered. With
# only one occupied slot inside work's own range it falls back to a plain step,
# which is right; what matters is that personal's busy workspaces never pull it
# out of range.
stub(11, [1, 2, 3, 11])
check("personal's busy workspaces are invisible from work",
      cli.relative_slot(cfg, "work", 1), 2)
stub(11, [1, 2, 3, 11])
check("and backward too", cli.relative_slot(cfg, "work", -1), 10)

# The invariant, stated directly: whatever the compositor reports, the answer
# is always a slot this space owns.
bad = []
for current in range(1, 11):
    for step in (1, -1):
        stub(10 + current, [1, 2, 3, 7, 10 + current, 10 + (current % 10) + 1])
        got = cli.relative_slot(cfg, "work", step)
        if not (1 <= got <= 10):
            bad.append((current, step, got))
check("every start and direction stays within work's 10 slots", bad, [])

print("\n%d passed, %d failed\n" % (passed, failed))
sys.exit(0 if failed == 0 else 1)

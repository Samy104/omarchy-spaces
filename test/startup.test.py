# Startup layout parsing. The runner launches processes, so what is tested here
# is the part that decides what to launch and what to skip.
import ast, os, sys, types

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
cli = types.ModuleType("cli")
src = open(os.path.join(root, "bin", "omarchy-spaces")).read()
src = src.replace('if __name__ == "__main__":\n    sys.exit(main(sys.argv[1:]))', "")
exec(src, cli.__dict__)

passed = failed = 0


def check(name, got, want):
    global passed, failed
    if got == want:
        passed += 1
        print("  ok   %s" % name)
    else:
        failed += 1
        print("  FAIL %s: got %r, want %r" % (name, got, want))


BASE = {"spaces": [{"id": "w", "startup": {"enabled": True, "slots": [
    {"slot": 2, "layout": "stack", "entries": [
        {"name": "A", "command": "foo"},
        {"name": "B", "command": "bar", "enabled": False},
        {"name": "C", "note": "browser tab, add the URL yourself"}]},
    {"slot": 1, "layout": "nonsense", "entries": ["baz"]},
]}}]}

print("\nparsing")
slots = cli.startup_slots(BASE, "w")
check("both slots parsed", [s["slot"] for s in slots], [2, 1])
check("an unknown layout falls back to split", slots[1]["layout"], "split")
check("stack survives", slots[0]["layout"], "stack")
check("a bare string becomes an entry", slots[1]["entries"][0]["command"], "baz")

print("\nentries with no command")
entries = slots[0]["entries"]
check("kept rather than dropped, so they can be fixed", len(entries), 3)
check("the one with no command is named", entries[2]["name"], "C")
check("and is never enabled", entries[2]["enabled"], False)
check("an explicitly disabled entry stays disabled", entries[1]["enabled"], False)
check("a normal entry is enabled", entries[0]["enabled"], True)

print("\nslot ordering is the author's, not sorted")
# The app reorders by moving array elements, so the runner must respect order.
check("run order follows the array", [s["slot"] for s in slots], [2, 1])

print("\ndisabling")
off = {"spaces": [{"id": "w", "startup": {"enabled": False, "slots": [
    {"slot": 1, "entries": [{"name": "A", "command": "foo"}]}]}}]}
check("a disabled layout still parses", len(cli.startup_slots(off, "w")), 1)
check("but reports itself off", cli.startup_config(off, "w").get("enabled"), False)

print("\nno startup block at all")
check("empty rather than an error", cli.startup_slots({"spaces": [{"id": "w"}]}, "w"), [])

print("\ninherited from defaults")
inh = {"defaults": {"startup": {"enabled": True, "slots": [
           {"slot": 1, "entries": [{"name": "Shared", "command": "everywhere"}]}]}},
       "spaces": [{"id": "a"}, {"id": "b", "startup": {"slots": [
           {"slot": 1, "entries": [{"name": "Own", "command": "mine"}]}]}}]}
check("a space with none inherits", cli.startup_slots(inh, "a")[0]["entries"][0]["name"], "Shared")
check("a space with its own overrides", cli.startup_slots(inh, "b")[0]["entries"][0]["name"], "Own")

print("\nbrowser app windows are recoverable, tabs are not")
appwin = {"class": "chrome-mail.google.com__-Profile_1", "title": "Inbox", "pid": None}
cfg = {"spaces": [{"id": "w", "browser": {"command": "google-chrome-stable"}}]}
got = cli.command_for_window(cfg, "w", appwin)
check("an app window rebuilds a command", "--app=https://mail.google.com" in got["command"], True)
check("and carries the profile", '--profile-directory="Profile 1"' in got["command"], True)
check("and matches on its class", got["match"], "chrome-mail.google.com__-Profile_1")

print("\n%d passed, %d failed\n" % (passed, failed))
sys.exit(0 if failed == 0 else 1)

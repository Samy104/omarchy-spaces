# Dump every policy decision the python implementation makes, for parity checking.
import importlib.util, json, os, sys
here = os.path.dirname(os.path.abspath(__file__))
spec = importlib.util.spec_from_loader("cli", None)
cli = importlib.util.module_from_spec(spec)
exec(open(os.path.join(here, "..", "bin", "omarchy-spaces")).read().replace(
    'if __name__ == "__main__":\n    sys.exit(main(sys.argv[1:]))', ''), cli.__dict__)

cfg = json.load(open(os.path.join(here, "..", "config", "spaces.example.json")))
apps = ["Signal", "Slack", "Ghost", "spotify", "SLACK.desktop", ""]
out = []
for sid in cli.space_ids(cfg):
    for m in range(1440):
        pol = cli.resolve_policy(cfg, sid, m)
        row = [sid, m, sorted(pol["allowFrom"]), pol["source"], bool(pol["allowUnassigned"])]
        for a in apps:
            owner = cli.space_for_app(cfg, a)
            allowed = (bool(pol["allowUnassigned"]) if owner is None
                       else owner in pol["allowFrom"])
            row.append([a, owner, allowed])
        out.append(row)
print(json.dumps(out, separators=(",", ":")))

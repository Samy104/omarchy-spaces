# Publishing

Notes for listing this plugin on
[omarchyplugins.com](https://omarchyplugins.com), and what was done to meet the
official [develop](https://omarchyplugins.com/develop.html) and
[publish](https://omarchyplugins.com/publish.html) guidelines.

## Compliance

| Requirement | State |
|---|---|
| `manifest.json` in the repo root | yes |
| Required fields, including `license` | all present |
| Reverse-domain id, not `omarchy.*` | `io.github.samy104.omarchy-spaces` |
| Semantic versioning | 0.3.0 |
| Entry points are safe relative paths that exist | verified |
| No symlinks in the plugin folder | verified |
| `omarchy plugin validate` | passes for both plugins |
| `qmllint -I $OMARCHY_PATH/shell` | zero errors |
| `omarchy plugin list --json` reports id, kinds, enabled | verified |
| Survives disable, re-enable, removal | verified |
| README with install, usage, config, removal, dependencies | yes |
| Public repo, LICENSE, preview image | yes |
| No `omarchy.clonedFrom` key | verified |
| Public repo, LICENSE, preview image | yes |
| Icon shipped at six theme sizes | `assets/icon.png` |
| GitHub topics | omarchy, omarchy-plugin, omarchy-shell |

## Why there are two plugin folders

This is one package. It ships two plugin directories because Omarchy's
third-party scanner allows exactly one manifest per top-level folder:

```bash
scan_thirdparty() {
  for sub in "$dir"/*/; do
    [[ -f "$sub/manifest.json" ]] || continue
    emit_manifest thirdparty "$sub/manifest.json"
  done
}
```

First-party plugins get a wider scan, `find -mindepth 2 -maxdepth 3` matching
`*.manifest.json`, which is how `omarchy.bar` ships Clock, Tray, and Workspaces
from one source directory. Third-party plugins do not. A sibling manifest
placed in a third-party folder is silently ignored, which I confirmed by adding
one and rescanning.

One bar widget per plugin id is also how Omarchy does it internally. Its own
workspace widget is `omarchy.workspaces`, separate from `omarchy.bar`.

So two bar widgets, the space indicator and the workspace slots, means two
directories. It is a scanner constraint, not a packaging decision.

They behave as one package. Same repository, same version, installed by the
same script, enabled together by `install.sh`, and removed together. The
workspace widget declares in its description that it requires the main plugin,
and falls back to real workspace ids if the main plugin is missing rather than
breaking.

Only the main plugin is submitted to the marketplace. Its manifest is in the
repo root, which is what the marketplace reads.

## No panel kind

The guidelines require a bar widget's panel to forward `opened`, `open()`, and
`close()`. This plugin declares no `panel` kind, so that does not apply. The
switcher uses the Omarchy menu through a managed block in
`~/.config/omarchy/extensions/omarchy-menu.jsonc`, and configuration lives in a
separate GTK4 app rather than inside the shell process.

That is deliberate. A panel would have to build its own Wayland layer window,
and the marketplace note is worth repeating: plugins run unsandboxed inside the
long-running shell. Less code in that process is better.

## Submitting

Open the
[submission form](https://github.com/HANCORE-linux/omarchy-plugin-marketplace/issues/new?template=submit-plugin.yml)
with the repository link, a category, and tags. Automated validation runs
against the current commit before a maintainer reviews it.

Add the `omarchy-shell` and `omarchy-plugin` topics to the GitHub repository so
it shows up under those topics as well.

## Before each release

```bash
./test/run.sh
omarchy plugin validate ~/.config/omarchy/plugins/io.github.samy104.omarchy-spaces
omarchy plugin validate ~/.config/omarchy/plugins/io.github.samy104.omarchy-spaces-workspaces
/usr/lib/qt6/bin/qmllint -I /usr/share/omarchy/shell *.qml workspaces/*.qml
omarchy plugin list --json | grep samy104
./scripts/publish-wiki.sh
```

Bump `version` in both manifests and in the README status line together.

## Documentation coverage

Every CLI command, subcommand, and config key is checked against the docs
before release. The check is mechanical rather than a read-through, since a
reader skims and a script does not:

```bash
python3 - <<'CHECK'
import re, glob
cli = open("bin/omarchy-spaces").read()
docs = "".join(open(f).read() for f in glob.glob("docs/*.md")) + open("README.md").read()
cmds = set(re.findall(r'"([a-z-]+)":', re.search(r'COMMANDS = \{(.*?)\n\}', cli, re.S).group(1)))
print("undocumented:", sorted(c for c in cmds if c not in docs) or "none")
CHECK
```

It has caught two real gaps: the `discover` family and `switchNotification`.

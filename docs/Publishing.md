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
| `omarchy plugin validate` | passes |
| `qmllint -I $OMARCHY_PATH/shell` | zero errors |
| `omarchy plugin list --json` reports id, kinds, enabled | verified |
| Survives disable, re-enable, removal | verified |
| README with install, usage, config, removal, dependencies | yes |
| Public repo, LICENSE, preview image | yes |
| No `omarchy.clonedFrom` key | verified |
| Public repo, LICENSE, preview image | yes |
| Icon shipped at six theme sizes | `assets/icon.png` |
| Exactly one `manifest.json`, at the root | verified |
| GitHub topics | omarchy, omarchy-plugin, omarchy-shell |

## One plugin, two placements

The marketplace requires exactly one `manifest.json`, at the repository root:

```js
/^(?:[^/]+\/)?manifest\.json$/i          // root, or one directory deep
if (submission && (manifestPaths.length !== 1 || manifestPaths[0] !== "manifest.json"))
    checkError("unsupported-repository-layout", ...)
```

The first submission failed on exactly that. This repository shipped a second
plugin under `workspaces/`, one directory deep, so the pattern matched two
manifests and the rule rejected it.

The fix was not to bury the second manifest deeper until the regex stopped
matching. That would have satisfied the check while ignoring what it is for.
The two widgets are now one widget with two faces, chosen per placement by a
`mode` setting, with `allowMultiple: true` in the manifest. Place it twice and
you get what two plugins gave.

Omarchy's own Spacer and Indicators do the same thing, so this is the idiomatic
shape rather than a workaround.

One thing that caught me out: `omarchy plugin enable --section left` *moves* an
existing placement rather than adding a second one. A second placement has to
be written into `shell.json` directly, which `install.sh --replace-workspaces`
does.

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

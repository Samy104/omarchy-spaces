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

## Two plugins, one repository

The repository ships two plugin folders.

`io.github.samy104.omarchy-spaces` is the main plugin, and its manifest is in
the repo root, which is what the marketplace reads.

`io.github.samy104.spaces-workspaces` is the workspace widget, in
`workspaces/`. It is optional and only useful alongside the main plugin, so it
is not listed separately. `install.sh` installs both.

If the marketplace ever requires one plugin per repository, the widget moves to
its own repo without any code change.

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
```

Bump `version` in both manifests and in the README status line together.

import QtQuick
import qs.Commons
import qs.Ui

// One bar widget with two faces, chosen per placement by its `mode` setting.
//
// The marketplace requires one plugin per repository, and Omarchy allows one
// bar widget per plugin, so the space indicator and the workspace numbers
// cannot be separate plugins. They do not have to be: allowMultiple lets the
// same widget be placed twice with different settings, which is how Omarchy's
// own Spacer and Indicators work. Put it on the left in workspaces mode and on
// the right in indicator mode and the result is what two plugins gave, from
// one manifest.
//
// Both faces are instantiated and one is hidden, rather than loaded on demand.
// A Loader adds a frame where item is still null and the bar has already asked
// for an implicit width, and the widget then measures zero and never recovers.
BarWidget {
  id: root
  moduleName: "io.github.samy104.omarchy-spaces"

  readonly property var spacesService: bar && bar.shell
    ? bar.shell.serviceFor("io.github.samy104.omarchy-spaces") : null

  readonly property bool workspacesMode: setting("mode", "indicator") === "workspaces"

  implicitWidth: workspacesMode ? workspacesFace.implicitWidth : indicatorFace.implicitWidth
  implicitHeight: workspacesMode ? workspacesFace.implicitHeight : indicatorFace.implicitHeight
  visible: implicitWidth > 0

  SpaceWorkspaces {
    id: workspacesFace
    anchors.fill: parent
    visible: root.workspacesMode
    bar: root.bar
    settings: root.settings
    spacesService: root.spacesService
  }

  SpaceIndicator {
    id: indicatorFace
    anchors.fill: parent
    visible: !root.workspacesMode
    bar: root.bar
    settings: root.settings
    spacesService: root.spacesService
  }
}

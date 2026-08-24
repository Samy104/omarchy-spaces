import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland
import qs.Commons
import qs.Ui

// Workspace indicators numbered by slot within the active space.
//
// Omarchy's stock widget prints real Hyprland workspace ids, so a space whose
// range is 11 to 20 shows 11 to 20 while the user presses 1 to 0. This one
// subtracts the active space's offset, so the number on the bar is the number
// you type.
//
// Falls back to real ids when the Spaces service is missing or isolation is
// turned off, which makes it a safe drop-in replacement either way.
BarWidget {
  id: root
  moduleName: "io.github.samy104.omarchy-spaces-workspaces"

  readonly property var spacesService: bar && bar.shell
    ? bar.shell.serviceFor("io.github.samy104.omarchy-spaces") : null

  // Coerced with !! because an && chain yields its last operand, and the
  // service's properties read back undefined for the first frame or two after
  // the shell starts. Without this the binding warns "Unable to assign
  // [undefined] to bool" on every launch.
  readonly property bool scoped: !!(spacesService
    && spacesService.configLoaded
    && spacesService.workspaceIsolation)

  readonly property int offset: scoped ? (spacesService.wsOffset || 0) : 0
  readonly property int slotCount: scoped ? (spacesService.wsCount || 10) : 10
  readonly property int minSlots: setting("minSlots", 5)

  readonly property string spaceColor: scoped
    ? String(spacesService.colorFor(spacesService.activeSpaceId) || "") : ""

  function realFor(slot) { return offset + slot }

  function workspaceById(id) {
    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      if (values[i].id === id) return values[i]
    }
    return null
  }

  // Slots to draw: always the first `minSlots`, plus any slot in this space's
  // range that currently holds a window. Slots belonging to other spaces are
  // deliberately absent, that is the isolation being visible.
  function slots() {
    var out = []
    var floor = Math.min(minSlots, slotCount)
    for (var s = 1; s <= floor; s++) out.push(s)

    var values = Hyprland.workspaces.values
    for (var i = 0; i < values.length; i++) {
      var slot = values[i].id - offset
      if (slot >= 1 && slot <= slotCount && out.indexOf(slot) === -1) out.push(slot)
    }
    out.sort(function (a, b) { return a - b })
    return out
  }

  // Route through the CLI when scoped so the slot is remembered for the next
  // switch back. Unscoped, dispatch directly.
  function focusSlot(slot) {
    if (!bar) return
    if (scoped) {
      bar.run("omarchy-spaces workspace " + slot)
    } else {
      bar.run("hyprctl dispatch " + Util.shellQuote(
        'hl.dsp.focus({ workspace = "' + realFor(slot) + '" })'))
    }
  }

  readonly property real trailingGap: vertical ? 0 : Style.spaceReal(1.5)

  implicitWidth: grid.implicitWidth + trailingGap
  implicitHeight: grid.implicitHeight

  GridLayout {
    id: grid
    anchors.fill: parent
    anchors.rightMargin: root.trailingGap
    columns: root.vertical ? 1 : root.slots().length
    columnSpacing: root.vertical ? 0 : Style.space(1)
    rowSpacing: root.vertical ? Style.space(2) : 0

    Repeater {
      model: root.slots()

      WidgetButton {
        required property int modelData

        readonly property int realId: root.realFor(modelData)
        readonly property var workspace: root.workspaceById(realId)
        readonly property bool occupied: workspace !== null
          && workspace.toplevels.values.length > 0
        readonly property bool focused: Hyprland.focusedWorkspace !== null
          && Hyprland.focusedWorkspace.id === realId

        bar: root.bar
        text: focused ? "󱓻" : (modelData === 10 ? "0" : String(modelData))
        opacity: occupied || focused ? 1 : 0.5
        horizontalMargin: 6
        verticalPadding: 6
        fixedWidth: root.vertical ? root.barSize : Style.space(20)
        fixedHeight: root.barSize
        tooltipText: root.scoped
          ? ("slot " + modelData + ", real workspace " + realId)
          : ""
        onPressed: function () { root.focusSlot(modelData) }
      }
    }
  }
}

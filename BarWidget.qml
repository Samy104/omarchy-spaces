import QtQuick
import qs.Commons
import qs.Ui

// Bar indicator for the active space.
//
// Left and right click open the Spaces picker in the Omarchy menu, middle
// click cycles to the next space. The label carries the space icon and name,
// and goes to the urgent color when the current policy blocks everything, so
// a silent desktop is never ambiguous about whether it is silent on purpose.
BarWidget {
  id: root
  moduleName: "io.github.samy104.omarchy-spaces"

  readonly property var spacesService: bar && bar.shell
    ? bar.shell.serviceFor("io.github.samy104.omarchy-spaces") : null

  readonly property string spaceId: spacesService ? spacesService.activeSpaceId : ""
  readonly property string spaceIcon: spacesService ? spacesService.iconFor(spaceId) : ""
  readonly property string spaceName: spacesService ? spacesService.displayName(spaceId) : ""
  readonly property bool filtering: spacesService ? spacesService.filtering : false
  readonly property bool fullyMuted: spacesService ? spacesService.fullyMuted : false

  readonly property bool showLabel: setting("showLabel", true)
  readonly property bool showPolicyDot: setting("showPolicyDot", true)

  // A dot appended to the label rather than an overlaid Rectangle. The bar
  // lays widgets out by implicit size, and a floating child would either be
  // clipped or push the neighbours around.
  readonly property string policyMark: {
    if (!showPolicyDot || !filtering) return ""
    return fullyMuted ? " ●" : " ○"
  }

  readonly property string label: {
    if (!spacesService) return ""
    if (spaceIcon === "" && spaceName === "") return ""
    var text = spaceIcon
    if (showLabel && !vertical && spaceName !== "") {
      text = text === "" ? spaceName : text + " " + spaceName
    }
    return text + policyMark
  }

  visible: label !== ""
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.label
    active: root.fullyMuted
    tooltipText: root.spaceName === "" ? "" : ("Space: " + root.spaceName)

    onPressed: function (b) {
      if (!root.bar) return
      if (b === Qt.MiddleButton) root.bar.run("omarchy-spaces next")
      else if (b === Qt.RightButton) root.bar.run("omarchy menu summon spaces")
      else root.bar.run("omarchy menu summon spaces")
    }
  }
}

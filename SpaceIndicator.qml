import QtQuick
import qs.Commons
import qs.Ui

// The active space, as a bar button.
//
// Not a BarWidget: this is one of two faces the plugin's single bar widget can
// wear, chosen by its `mode` setting. BarWidget.qml owns the registration and
// hands `bar` and `settings` down.
Item {
  id: root

  property QtObject bar: null
  property var settings: ({})
  property var spacesService: null

  function setting(name, fallback) {
    var v = settings ? settings[name] : undefined
    return v === undefined || v === null ? fallback : v
  }

  readonly property string spaceId: spacesService ? spacesService.activeSpaceId : ""
  readonly property string spaceIcon: spacesService ? spacesService.iconFor(spaceId) : ""
  readonly property string spaceName: spacesService ? spacesService.displayName(spaceId) : ""
  readonly property bool filtering: spacesService ? spacesService.filtering : false
  readonly property bool fullyMuted: spacesService ? spacesService.fullyMuted : false

  readonly property bool showLabel: setting("showLabel", true)
  readonly property bool showPolicyDot: setting("showPolicyDot", true)
  readonly property bool vertical: bar ? bar.vertical : false

  // A mark appended to the label rather than an overlaid Rectangle: the bar
  // lays widgets out by implicit size, so a floating child would be clipped or
  // shove its neighbours around.
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

  implicitWidth: label === "" ? 0 : button.implicitWidth
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
      else root.bar.run("omarchy menu summon spaces")
    }
  }
}

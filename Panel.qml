import QtQuick
import QtQuick.Layouts
import qs.Commons
import qs.Ui

// Switcher and policy view.
//
// The list picks a space. Below it, the panel states in plain words what the
// current policy allows and which schedule window produced it, because the
// most common question about a filter is not "what are the rules" but "why is
// it quiet right now".
PanelWindow {
  id: panel

  property QtObject bar: null
  property Item anchorItem: null
  property QtObject hostWidget: null
  property var spacesService: null

  property bool opened: false
  function open() { opened = true }
  function close() { opened = false }
  function toggle() { opened = !opened }

  visible: opened

  readonly property var svc: spacesService
  readonly property var spaces: svc ? svc.spaces : []
  readonly property var policy: svc ? svc.policy : ({ allowFrom: [], window: null, allowUnassigned: true })
  readonly property string activeId: svc ? svc.activeSpaceId : ""

  function allowedText() {
    if (!policy || !policy.allowFrom) return ""
    if (policy.allowFrom.length === 0) {
      return policy.allowUnassigned ? "Only apps with no space assigned" : "Nothing at all"
    }
    var names = []
    for (var i = 0; i < policy.allowFrom.length; i++) {
      names.push(svc ? svc.displayName(policy.allowFrom[i]) : policy.allowFrom[i])
    }
    var line = names.join(" and ")
    if (!policy.allowUnassigned) line += ", unassigned apps hidden"
    return line
  }

  function windowText() {
    if (!policy || !policy.window) return "No schedule window matches, using the space default"
    var w = policy.window
    var label = w.label ? (" " + w.label) : ""
    return w.from + " to " + w.to + label
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: Style.marginM
    spacing: Style.marginS

    Text {
      text: "Spaces"
      color: Style.colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.sizeM
      font.bold: true
    }

    Repeater {
      model: panel.spaces
      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 34
        radius: Style.cornerRadius
        color: modelData.id === panel.activeId ? Style.colors.surfaceVariant : "transparent"

        RowLayout {
          anchors.fill: parent
          anchors.leftMargin: Style.marginS
          anchors.rightMargin: Style.marginS
          spacing: Style.marginS

          Text {
            text: modelData.icon || "●"
            color: modelData.color || Style.colors.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.sizeM
          }
          Text {
            Layout.fillWidth: true
            text: modelData.name || modelData.id
            color: Style.colors.foreground
            font.family: Style.font.family
            font.pixelSize: Style.font.sizeS
          }
          Text {
            visible: !!modelData.email
            text: modelData.email || ""
            color: Style.colors.foregroundMuted
            font.family: Style.font.family
            font.pixelSize: Style.font.sizeXS
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: {
            if (panel.svc) panel.svc.switchTo(modelData.id)
            panel.close()
          }
        }
      }
    }

    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 1
      color: Style.colors.outline
    }

    Text {
      Layout.fillWidth: true
      text: "Showing: " + panel.allowedText()
      wrapMode: Text.WordWrap
      color: Style.colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.sizeXS
    }

    Text {
      Layout.fillWidth: true
      text: panel.windowText()
      wrapMode: Text.WordWrap
      color: Style.colors.foregroundMuted
      font.family: Style.font.family
      font.pixelSize: Style.font.sizeXS
    }

    Item {
      Layout.fillWidth: true
      implicitHeight: 26
      Text {
        anchors.verticalCenter: parent.verticalCenter
        text: "Edit schedule"
        color: Style.colors.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.sizeXS
      }
      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (panel.svc) panel.svc.openConfigInEditor()
          panel.close()
        }
      }
    }
  }
}

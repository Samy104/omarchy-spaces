import QtQuick
import qs.Commons
import qs.Ui

// Bar indicator for the active space.
//
// Left click opens the switcher panel, right click cycles to the next space,
// middle click opens the config file in the editor. The dot in the corner
// means the current policy is blocking something, so a quiet desktop is
// never ambiguous about whether it is quiet on purpose.
BarWidget {
  id: root
  moduleName: "spaces.omarchy-spaces"

  readonly property var spacesService: root.bar && root.bar.shell
    ? root.bar.shell.serviceFor("spaces.omarchy-spaces") : null

  readonly property string spaceId: spacesService ? spacesService.activeSpaceId : ""
  readonly property string spaceName: spacesService ? spacesService.displayName(spaceId) : ""
  readonly property string spaceIcon: spacesService ? spacesService.iconFor(spaceId) : "●"
  readonly property string spaceColor: spacesService ? spacesService.colorFor(spaceId) : ""
  readonly property bool filtering: spacesService ? spacesService.filtering : false
  readonly property bool fullyMuted: spacesService ? spacesService.fullyMuted : false

  readonly property bool showLabel: setting("showLabel", true)
  readonly property bool showPolicyDot: setting("showPolicyDot", true)

  implicitWidth: layout.implicitWidth + Style.bar.paddingH * 2
  implicitHeight: parent ? parent.height : Style.bar.sizeHorizontal

  Row {
    id: layout
    anchors.centerIn: parent
    spacing: 6

    Item {
      width: iconText.implicitWidth
      height: iconText.implicitHeight
      anchors.verticalCenter: parent.verticalCenter

      Text {
        id: iconText
        text: root.spaceIcon
        color: root.spaceColor !== "" ? root.spaceColor : Style.colors.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.sizeM
      }

      // Hollow dot for partial filtering, filled for a full mute.
      Rectangle {
        visible: root.showPolicyDot && root.filtering
        width: 5
        height: 5
        radius: 2.5
        color: root.fullyMuted ? Style.colors.error : "transparent"
        border.width: root.fullyMuted ? 0 : 1
        border.color: Style.colors.warning
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: -3
        anchors.topMargin: -1
      }
    }

    Text {
      visible: root.showLabel && !root.vertical && root.spaceName !== ""
      text: root.spaceName
      color: Style.colors.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.sizeS
      anchors.verticalCenter: parent.verticalCenter
    }
  }

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
    hoverEnabled: true
    onClicked: function (mouse) {
      if (mouse.button === Qt.LeftButton) root.togglePanel()
      else if (mouse.button === Qt.RightButton && root.spacesService) root.spacesService.cycle(1)
      else if (mouse.button === Qt.MiddleButton) root.openConfig()
    }
  }

  function openConfig() {
    if (spacesService) spacesService.openConfigInEditor()
  }

  function togglePanel() {
    if (panelLoader.item && panelLoader.item.toggle) panelLoader.item.toggle()
  }

  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
  function open() { if (panelLoader.item && panelLoader.item.open) panelLoader.item.open() }
  function close() { if (panelLoader.item && panelLoader.item.close) panelLoader.item.close() }

  Loader {
    id: panelLoader
    source: "Panel.qml"
    active: true
    onLoaded: {
      if ("bar" in item) item.bar = root.bar
      if ("anchorItem" in item) item.anchorItem = root
      if ("hostWidget" in item) item.hostWidget = root
      if ("spacesService" in item) item.spacesService = root.spacesService
    }
  }
}

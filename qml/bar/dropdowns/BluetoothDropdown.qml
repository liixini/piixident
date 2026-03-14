import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  // Dropdown animation state
  property bool active: false
  property var connectedDevices: []

  readonly property real animatedHeight: _animatedHeight

  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  height: _animatedHeight
  visible: _animatedHeight > 0
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)

  // Expand/collapse on toggle
  onActiveChanged: {
    if (active) {
      _targetHeight = bluetoothColumn.implicitHeight + 24
    } else {
      _targetHeight = 0
    }
  }

  // Bottom accent bar
  Rectangle {
    anchors.bottom: parent.bottom
    anchors.left: parent.left
    anchors.right: parent.right
    height: 2
    color: root.colors.primary
    property real animatedWidth: root.visible ? parent.width : 0
    width: animatedWidth
    Behavior on animatedWidth {
      NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
  }

  // Connected device list with battery levels
  Column {
    id: bluetoothColumn
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 10
    width: parent.width - 24

    onImplicitHeightChanged: {
      if (root.active) {
        root._targetHeight = implicitHeight + 24
      }
    }

    // Content fade-in and slide-up transition
    opacity: root.active && root._animatedHeight > (bluetoothColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (bluetoothColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // Section header
    Text {
      text: "BLUETOOTH DEVICES"
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }

    // Device delegate (icon, name, battery percentage)
    Repeater {
      model: root.connectedDevices
      delegate: Row {
        spacing: 12

        Text {
          text: "󰂯"
          font.pixelSize: 12
          font.family: Style.fontFamilyNerdIcons
          color: root.colors.primary
        }

        Text {
          text: modelData.name || "Unknown Device"
          color: root.colors.backgroundText
          font.pixelSize: 12
          font.family: Style.fontFamily
          font.weight: Font.Medium
          width: 120
        }

        Text {
          text: modelData.batteryAvailable && modelData.battery > 0 ? Math.round(modelData.battery * 100) + "%" : ""
          color: root.colors.tertiary
          font.pixelSize: 12
          font.family: Style.fontFamily
          font.weight: Font.Medium
          visible: text !== ""
        }
      }
    }
  }
}

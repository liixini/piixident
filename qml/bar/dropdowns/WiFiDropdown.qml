// Imports
import Quickshell.Io
import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  // Dropdown animation state
  property bool active: false
  property string wifiSsid: ""
  property int wifiSignalStrength: 0

  readonly property real animatedHeight: _animatedHeight

  property real _targetHeight: 0
  property real _animatedHeight: _targetHeight
  Behavior on _animatedHeight {
    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
  }

  height: _animatedHeight
  visible: _animatedHeight > 0
  color: Qt.rgba(root.colors.surface.r, root.colors.surface.g, root.colors.surface.b, 0.88)

  // Expand/collapse and scan trigger
  onActiveChanged: {
    if (active) {
      _targetHeight = wifiColumn.implicitHeight + 24
      wifiColumn.networkList = []
      wifiScanProcess.running = true
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

  // WiFi content column
  Column {
    id: wifiColumn
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.bottom: parent.bottom
    anchors.bottomMargin: 12
    spacing: 6
    width: parent.width - 24

    property var networkList: []

    // Content fade-in and slide-up transition
    opacity: root.active && root._animatedHeight > (wifiColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (wifiColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    onImplicitHeightChanged: {
      if (root.active) {
        root._targetHeight = implicitHeight + 24
      }
    }

    // WiFi network scanner
    Process {
      id: wifiScanProcess
      command: [Config.scriptsDir + "/bash/wifi-list"]
      stdout: SplitParser {
        id: wifiNetworkParser
        property var parts: []
        onRead: data => { parts.push(data) }
      }
      onExited: {
        try {
          let networks = JSON.parse(wifiNetworkParser.parts.join("\n").trim())
          wifiColumn.networkList = networks
        } catch (e) {
          console.log("WiFi list parse error:", e)
        }
        wifiNetworkParser.parts = []
      }
    }

    // WiFi connect process
    Process {
      id: wifiConnectProcess
      property string targetSsid: ""
      command: ["iwctl", "station", Config.wifiInterface, "connect", targetSsid]
    }

    // Section header
    Text {
      text: "WIFI"
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }

    // Current connection status
    Row {
      spacing: 8
      visible: root.wifiSsid !== ""
      Text {
        text: "󰤨"
        font.pixelSize: 12
        font.family: Style.fontFamilyNerdIcons
        color: root.colors.primary
        width: 14
        horizontalAlignment: Text.AlignHCenter
      }
      Text {
        text: root.wifiSsid || "Not connected"
        color: root.colors.primary
        font.pixelSize: 12
        font.family: Style.fontFamily
        font.weight: Font.DemiBold
      }
      Text {
        text: root.wifiSignalStrength + "%"
        color: root.colors.tertiary
        font.pixelSize: 12
        font.family: Style.fontFamily
        font.weight: Font.Medium
        width: 28
        horizontalAlignment: Text.AlignRight
      }
    }

    // Section divider
    Rectangle {
      width: parent.width
      height: 1
      color: Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2)
    }

    // Available networks header
    Text {
      text: "AVAILABLE"
      color: root.colors.tertiary
      font.pixelSize: 10
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }

    // Scanning placeholder
    Text {
      visible: wifiColumn.networkList.length === 0
      text: "Scanning..."
      color: root.colors.tertiary
      font.pixelSize: 11
      font.family: Style.fontFamily
      font.italic: true
    }

    // Network list with signal icons and security indicators
    Repeater {
      model: wifiColumn.networkList

      delegate: Item {
        width: netRow.implicitWidth
        height: netRow.implicitHeight

        property bool isConnected: modelData.connected || modelData.ssid === root.wifiSsid

        Row {
          id: netRow
          spacing: 8

          Text {
            text: {
              let s = modelData.signal || 0
              if (s <= 25) return "󰤟"
              if (s <= 50) return "󰤢"
              if (s <= 75) return "󰤥"
              return "󰤨"
            }
            font.pixelSize: 12
            font.family: Style.fontFamilyNerdIcons
            color: isConnected ? root.colors.primary : root.colors.tertiary
            width: 14
            horizontalAlignment: Text.AlignHCenter
          }

          Text {
            text: modelData.ssid
            color: isConnected ? root.colors.primary : root.colors.backgroundText
            font.pixelSize: 12
            font.family: Style.fontFamily
            font.weight: isConnected ? Font.DemiBold : Font.Medium
            width: 120
            elide: Text.ElideRight
          }

          Text {
            text: {
              let sec = modelData.security || ""
              if (sec === "psk") return "󰌆"
              if (sec === "open") return "󰌊"
              if (sec === "8021x") return "󰌆"
              return sec !== "" ? "󰌆" : ""
            }
            font.pixelSize: 11
            font.family: Style.fontFamilyNerdIcons
            color: root.colors.tertiary
            width: 14
            horizontalAlignment: Text.AlignHCenter
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            if (!isConnected) {
              wifiConnectProcess.targetSsid = modelData.ssid
              wifiConnectProcess.running = true
            }
          }
        }
      }
    }
  }
}

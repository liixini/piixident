// Imports
import QtQuick
import "../.."

Rectangle {
  id: root

  required property var colors

  // Dropdown animation state
  property bool active: false
  property string weatherCity: ""
  property var weatherForecast: []

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
      _targetHeight = forecastColumn.implicitHeight + 24
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

  // Forecast list (3-day)
  Column {
    id: forecastColumn
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
    opacity: root.active && root._animatedHeight > (forecastColumn.implicitHeight * 0.5) ? 1 : 0
    transform: Translate {
      y: root.active && root._animatedHeight > (forecastColumn.implicitHeight * 0.5) ? 0 : -15
    }
    Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    Behavior on y { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

    // City name header
    Text {
      text: root.weatherCity.toUpperCase()
      color: root.colors.primary
      font.pixelSize: 14
      font.family: Style.fontFamily
      font.weight: Font.DemiBold
    }

    // Forecast day delegate (day name, high/low temps, description)
    Repeater {
      model: root.weatherForecast.slice(0, 3)
      delegate: Row {
        spacing: 12

        Text {
          text: modelData.day
          color: root.colors.backgroundText
          font.pixelSize: 12
          font.family: Style.fontFamily
          font.weight: Font.Medium
          width: 60
        }

        Row {
          spacing: 6
          Text {
            text: "H: " + modelData.high
            color: root.colors.primary
            font.pixelSize: 12
            font.family: Style.fontFamily
            font.weight: Font.Medium
          }
          Text {
            text: "L: " + modelData.low
            color: root.colors.tertiary
            font.pixelSize: 12
            font.family: Style.fontFamily
            font.weight: Font.Medium
          }
        }

        Text {
          text: modelData.desc
          color: root.colors.backgroundText
          font.pixelSize: 12
          font.family: Style.fontFamily
          opacity: 0.85
          elide: Text.ElideRight
        }
      }
    }
  }
}

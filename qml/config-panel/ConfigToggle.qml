import QtQuick
import ".."

Item {
  property string label
  property bool checked
  property var colors
  signal toggled(bool v)

  width: parent ? parent.width : 400
  height: 36

  Row {
    anchors.fill: parent
    spacing: 12

    Text {
      width: 160
      text: label
      font.family: Style.fontFamily
      font.pixelSize: 12
      font.weight: Font.Medium
      color: colors ? colors.surfaceText : "#ddd"
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
    }

    Item {
      width: 48
      height: 24
      anchors.verticalCenter: parent.verticalCenter

      Canvas {
        id: toggleBg
        anchors.fill: parent
        property bool isOn: checked
        property color fillColor: isOn
          ? (colors ? colors.primary : "#4fc3f7")
          : (colors ? Qt.rgba(colors.surfaceVariant.r, colors.surfaceVariant.g, colors.surfaceVariant.b, 0.5) : Qt.rgba(1, 1, 1, 0.15))

        onFillColorChanged: requestPaint()
        onIsOnChanged: requestPaint()

        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var sk = 8
          ctx.fillStyle = fillColor
          ctx.beginPath()
          ctx.moveTo(sk, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - sk, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fill()
        }
      }

      Canvas {
        id: toggleKnob
        width: 22; height: 18
        y: 3
        x: checked ? parent.width - width - 4 : 4
        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        property color knobColor: checked
          ? (colors ? colors.primaryText : "#000")
          : (colors ? colors.surfaceText : "#fff")

        onKnobColorChanged: requestPaint()

        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var sk = 5
          ctx.fillStyle = knobColor
          ctx.beginPath()
          ctx.moveTo(sk, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - sk, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fill()
        }
      }

      MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: toggled(!checked)
      }
    }
  }
}

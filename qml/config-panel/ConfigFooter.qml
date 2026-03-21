import QtQuick
import ".."

Rectangle {
  id: root
  property var panel
  property var colors

  anchors.bottom: parent.bottom
  anchors.left: parent.left
  anchors.right: parent.right
  height: 52
  color: "transparent"

  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: 30
    anchors.rightMargin: 30
    height: 1
    color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15) : Qt.rgba(1, 1, 1, 0.1)
  }

  Row {
    anchors.right: parent.right
    anchors.rightMargin: 30
    anchors.verticalCenter: parent.verticalCenter
    spacing: 16

    Item {
      width: discardCanvas.width + 4
      height: 34
      opacity: root.panel.hasUnsavedChanges ? 1 : 0.3

      Canvas {
        id: discardCanvas
        anchors.centerIn: parent
        width: 120; height: 30

        property bool hovered: discardMouse.containsMouse
        property color fillColor: hovered
          ? (root.colors ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.2) : Qt.rgba(1, 0.3, 0.3, 0.2))
          : "transparent"
        property color strokeColor: root.colors ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.5) : Qt.rgba(1, 0.3, 0.3, 0.5)

        onFillColorChanged: requestPaint()
        onStrokeColorChanged: requestPaint()

        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var sk = root.panel.skewOffset
          ctx.fillStyle = fillColor
          ctx.beginPath()
          ctx.moveTo(sk, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - sk, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fill()
          ctx.strokeStyle = strokeColor
          ctx.lineWidth = 1
          ctx.stroke()
        }
      }

      Text {
        anchors.centerIn: discardCanvas
        text: "DISCARD"
        font.family: Style.fontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.5
        color: root.colors ? root.colors.error : "#ff6b6b"
      }

      MouseArea {
        id: discardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.panel.hasUnsavedChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (root.panel.hasUnsavedChanges) root.panel.discardChanges()
        }
      }
    }

    Item {
      width: saveCanvas.width + 4
      height: 34
      opacity: root.panel.hasUnsavedChanges ? 1 : 0.3

      Canvas {
        id: saveCanvas
        anchors.centerIn: parent
        width: 120; height: 30

        property bool hovered: saveMouse.containsMouse
        property color fillColor: hovered
          ? (root.colors ? root.colors.primary : "#4fc3f7")
          : (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(0.3, 0.8, 1, 0.2))
        property color strokeColor: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.6) : Qt.rgba(0.3, 0.8, 1, 0.6)

        onFillColorChanged: requestPaint()
        onStrokeColorChanged: requestPaint()

        onPaint: {
          var ctx = getContext("2d")
          ctx.clearRect(0, 0, width, height)
          var sk = root.panel.skewOffset
          ctx.fillStyle = fillColor
          ctx.beginPath()
          ctx.moveTo(sk, 0)
          ctx.lineTo(width, 0)
          ctx.lineTo(width - sk, height)
          ctx.lineTo(0, height)
          ctx.closePath()
          ctx.fill()
          ctx.strokeStyle = strokeColor
          ctx.lineWidth = 1
          ctx.stroke()
        }
      }

      Text {
        anchors.centerIn: saveCanvas
        text: "SAVE"
        font.family: Style.fontFamily
        font.pixelSize: 11
        font.weight: Font.Bold
        font.letterSpacing: 0.5
        color: saveMouse.containsMouse
          ? (root.colors ? root.colors.primaryText : "#000")
          : (root.colors ? root.colors.primary : "#4fc3f7")
      }

      MouseArea {
        id: saveMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.panel.hasUnsavedChanges ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
          if (root.panel.hasUnsavedChanges) root.panel.saveAll()
        }
      }
    }
  }
}

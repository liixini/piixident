import QtQuick
import ".."

Item {
  property string label
  property string value
  property string placeholder: ""
  property var colors
  signal edited(string v)

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

    Rectangle {
      width: parent.width - 172
      height: 30
      radius: 6
      color: colors ? Qt.rgba(colors.surfaceContainer.r, colors.surfaceContainer.g, colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
      border.width: fieldInput.activeFocus ? 1 : 0
      border.color: colors ? Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)

      TextInput {
        id: fieldInput
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        verticalAlignment: TextInput.AlignVCenter
        font.family: Style.fontFamilyCode
        font.pixelSize: 11
        color: colors ? colors.tertiary : "#8bceff"
        clip: true
        text: value
        selectByMouse: true
        selectionColor: colors ? Qt.rgba(colors.primary.r, colors.primary.g, colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)

        onTextEdited: edited(text)

        Text {
          anchors.fill: parent
          verticalAlignment: Text.AlignVCenter
          text: placeholder
          font: parent.font
          color: colors ? Qt.rgba(colors.surfaceText.r, colors.surfaceText.g, colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.2)
          visible: !parent.text && !parent.activeFocus
        }
      }
    }
  }
}

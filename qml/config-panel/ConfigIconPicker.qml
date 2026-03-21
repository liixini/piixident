import QtQuick
import ".."

Rectangle {
  id: root
  property var panel
  property var colors

  anchors.fill: parent
  color: Qt.rgba(0, 0, 0, 0.85)
  visible: panel._iconPickerVisible
  z: 100

  property var iconCategories: [
    { name: "Apps", icons: ["", "", "", "", "", "", "", "󰈹", "󰇮", "󰊯", "󰙯", "󱁤", "󰋋", "󰕼", "󰗃", "󱎓", "󰊻", "󰊤", "󰎆", "󰙪"] },
    { name: "System", icons: ["", "", "", "󰍹", "", "", "", "", "", "", "󰌌", "󰍽", "󰖲", "󰒔", "󰋑", "󰑣", "", "", "", ""] },
    { name: "Media", icons: ["", "󰎈", "󰎆", "󰎄", "󰐎", "", "󰎁", "󰎇", "󰕾", "󰖀", "󰕿", "󰎌", "󰝚", "󰸗", "󱎏", "", "󰕧", "󱜅", "󰟚", "󰎁"] },
    { name: "Files", icons: ["", "󰈙", "", "", "󰗀", "󰉋", "󰉏", "󰸩", "󰝰", "", "󱀲", "", "󰈔", "", "", "󰛫", "", "󰈤", "󱆃", ""] },
    { name: "Dev", icons: ["", "󰊤", "", "󰌛", "", "", "", "󰈮", "", "", "󰌞", "󰅩", "󰅢", "󱜙", "󰈿", "󰌜", "󰮯", "󰌏", "󰡄", ""] },
    { name: "Games", icons: ["󰊗", "󰺵", "󰊖", "", "󰀝", "󱎓", "󰮂", "", "", "", "", "", "󰮃", "󰺷", "󰊴", "", "󰊒", "󰊕", "", ""] },
    { name: "Arrows", icons: ["", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "", "󰁔", "󰁍"] },
    { name: "Weather", icons: ["", "", "", "", "󰖝", "󰖐", "󰖑", "󰖙", "", "󰖗", "󰖨", "󰖘", "󰼱", "󰼳", "", "󰛎", "󰖔", "󰖖", "󰖕", ""] },
    { name: "Misc", icons: ["", "", "", "", "󰃀", "", "", "󰀄", "󰐱", "󰙎", "", "󱉟", "", "", "", "", "󰒰", "", "󰗊", "󰇥"] }
  ]

  function focusSearch() {
    iconSearchInput.text = ""
    iconSearchInput.forceActiveFocus()
  }

  MouseArea {
    anchors.fill: parent
    onClicked: root.panel._iconPickerVisible = false
  }

  Rectangle {
    width: 660
    height: 520
    anchors.centerIn: parent
    radius: 12
    color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.95) : Qt.rgba(0.1, 0.12, 0.18, 0.95)
    border.width: 1
    border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.1)

    MouseArea { anchors.fill: parent; onClicked: {} }

    Column {
      anchors.fill: parent
      anchors.margins: 20
      spacing: 12

      Row {
        width: parent.width
        spacing: 12

        Text {
          text: "󰀻 ICON PICKER"
          font.family: Style.fontFamilyNerdIcons
          font.pixelSize: 16
          font.weight: Font.Bold
          font.letterSpacing: 1.0
          color: root.colors ? root.colors.primary : "#4fc3f7"
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: 20; height: 1 }

        Rectangle {
          width: 200
          height: 30
          radius: 6
          color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
          border.width: iconSearchInput.activeFocus ? 1 : 0
          border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
          anchors.verticalCenter: parent.verticalCenter

          TextInput {
            id: iconSearchInput
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamily
            font.pixelSize: 12
            color: root.colors ? root.colors.surfaceText : "#ddd"
            clip: true
            selectByMouse: true

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              text: " search category..."
              font.family: Style.fontFamilyNerdIcons
              font.pixelSize: 11
              color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.2)
              visible: !parent.text && !parent.activeFocus
            }
          }
        }

        Item { width: 12; height: 1 }

        Rectangle {
          width: 120
          height: 30
          radius: 6
          color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)
          border.width: manualIconInput.activeFocus ? 1 : 0
          border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
          anchors.verticalCenter: parent.verticalCenter

          TextInput {
            id: manualIconInput
            anchors.fill: parent
            anchors.leftMargin: 10; anchors.rightMargin: 10
            verticalAlignment: TextInput.AlignVCenter
            font.family: Style.fontFamilyNerdIcons
            font.pixelSize: 14
            color: root.colors ? root.colors.tertiary : "#8bceff"
            clip: true
            selectByMouse: true

            Text {
              anchors.fill: parent
              verticalAlignment: Text.AlignVCenter
              text: "paste glyph"
              font.family: Style.fontFamily
              font.pixelSize: 10
              color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.25) : Qt.rgba(1, 1, 1, 0.2)
              visible: !parent.text && !parent.activeFocus
            }
          }
        }

        Rectangle {
          width: applyManualLabel.implicitWidth + 16
          height: 30
          radius: 6
          color: applyManualMouse.containsMouse
            ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.2))
            : (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15) : Qt.rgba(1, 1, 1, 0.1))
          anchors.verticalCenter: parent.verticalCenter
          visible: manualIconInput.text !== ""

          Text {
            id: applyManualLabel
            anchors.centerIn: parent
            text: "APPLY"
            font.family: Style.fontFamily
            font.pixelSize: 10
            font.weight: Font.Bold
            color: root.colors ? root.colors.primary : "#4fc3f7"
          }

          MouseArea {
            id: applyManualMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              var key = root.panel._iconPickerTargetKey
              if (key && manualIconInput.text) {
                if (!root.panel.appsData[key]) root.panel.appsData[key] = {}
                root.panel.appsData[key].icon = manualIconInput.text
                root.panel.hasUnsavedChanges = true
                root.panel.appsDataChanged()
              }
              root.panel._iconPickerVisible = false
              manualIconInput.text = ""
            }
          }
        }
      }

      Flickable {
        width: parent.width
        height: parent.height - 52
        contentHeight: iconCategoryColumn.implicitHeight
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Column {
          id: iconCategoryColumn
          width: parent.width
          spacing: 14

          Repeater {
            model: root.iconCategories

            Column {
              width: parent.width
              spacing: 6
              visible: {
                if (!iconSearchInput.text) return true
                return modelData.name.toLowerCase().indexOf(iconSearchInput.text.toLowerCase()) >= 0
              }

              Text {
                text: modelData.name
                font.family: Style.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.8
                color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.7) : Qt.rgba(0.3, 0.75, 0.97, 0.7)
                leftPadding: 2
              }

              Flow {
                width: parent.width
                spacing: 4

                Repeater {
                  model: modelData.icons

                  Rectangle {
                    width: 38; height: 38
                    radius: 6
                    color: iconCellMouse.containsMouse
                      ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.25) : Qt.rgba(1, 1, 1, 0.15))
                      : (root.colors ? Qt.rgba(root.colors.surfaceVariant.r, root.colors.surfaceVariant.g, root.colors.surfaceVariant.b, 0.25) : Qt.rgba(1, 1, 1, 0.05))
                    border.width: iconCellMouse.containsMouse ? 1 : 0
                    border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)

                    Text {
                      anchors.centerIn: parent
                      text: modelData
                      font.family: Style.fontFamilyNerdIcons
                      font.pixelSize: 20
                      color: iconCellMouse.containsMouse
                        ? (root.colors ? root.colors.primary : "#4fc3f7")
                        : (root.colors ? root.colors.surfaceText : "#ddd")
                    }

                    MouseArea {
                      id: iconCellMouse
                      anchors.fill: parent
                      hoverEnabled: true
                      cursorShape: Qt.PointingHandCursor
                      onClicked: {
                        var key = root.panel._iconPickerTargetKey
                        if (key) {
                          if (!root.panel.appsData[key]) root.panel.appsData[key] = {}
                          root.panel.appsData[key].icon = modelData
                          root.panel.hasUnsavedChanges = true
                          root.panel.appsDataChanged()
                        }
                        root.panel._iconPickerVisible = false
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}

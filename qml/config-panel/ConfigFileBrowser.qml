import QtQuick
import ".."

Rectangle {
  id: root
  property var panel
  property var colors

  anchors.fill: parent
  color: Qt.rgba(0, 0, 0, 0.85)
  visible: panel._fileBrowserVisible
  z: 101

  MouseArea {
    anchors.fill: parent
    onClicked: root.panel._fileBrowserVisible = false
  }

  Rectangle {
    width: 800
    height: 560
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
          text: "󰉋 SELECT IMAGE"
          font.family: Style.fontFamilyNerdIcons
          font.pixelSize: 16
          font.weight: Font.Bold
          font.letterSpacing: 1.0
          color: root.colors ? root.colors.primary : "#4fc3f7"
          anchors.verticalCenter: parent.verticalCenter
        }

        Item { width: 1; height: 1 }

        Rectangle {
          width: fbCloseLbl.implicitWidth + 16
          height: 28
          radius: 6
          color: fbCloseMouse.containsMouse
            ? (root.colors ? Qt.rgba(root.colors.error.r, root.colors.error.g, root.colors.error.b, 0.15) : Qt.rgba(1, 0.3, 0.3, 0.15))
            : "transparent"
          anchors.verticalCenter: parent.verticalCenter

          Text {
            id: fbCloseLbl
            anchors.centerIn: parent
            text: "✕"
            font.family: Style.fontFamily
            font.pixelSize: 14
            font.weight: Font.Bold
            color: root.colors ? root.colors.error : "#ff6b6b"
          }

          MouseArea {
            id: fbCloseMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.panel._fileBrowserVisible = false
          }
        }
      }

      Rectangle {
        width: parent.width
        height: 34
        radius: 6
        color: root.colors ? Qt.rgba(root.colors.surfaceContainer.r, root.colors.surfaceContainer.g, root.colors.surfaceContainer.b, 0.6) : Qt.rgba(0.15, 0.15, 0.2, 0.6)

        Row {
          anchors.fill: parent
          anchors.leftMargin: 10
          anchors.rightMargin: 10
          spacing: 4

          Text {
            text: "󰉖"
            font.family: Style.fontFamilyNerdIcons
            font.pixelSize: 14
            color: root.colors ? root.colors.primary : "#4fc3f7"
            anchors.verticalCenter: parent.verticalCenter
          }

          Repeater {
            model: {
              var dir = root.panel._fileBrowserCurrentDir
              if (!dir) return []
              var parts = dir.split("/").filter(function(p) { return p.length > 0 })
              var crumbs = []
              var acc = ""
              for (var i = 0; i < parts.length; i++) {
                acc += "/" + parts[i]
                crumbs.push({ label: parts[i], path: acc })
              }
              return crumbs
            }

            Row {
              spacing: 4
              anchors.verticalCenter: parent ? parent.verticalCenter : undefined

              Text {
                text: "/"
                font.family: Style.fontFamily
                font.pixelSize: 11
                color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
                anchors.verticalCenter: parent.verticalCenter
                visible: index > 0
              }

              Text {
                text: modelData.label
                font.family: Style.fontFamily
                font.pixelSize: 11
                font.weight: index === (root.panel._fileBrowserCurrentDir.split("/").filter(function(p) { return p.length > 0 }).length - 1) ? Font.Bold : Font.Normal
                color: crumbMouse.containsMouse
                  ? (root.colors ? root.colors.primary : "#4fc3f7")
                  : (root.colors ? root.colors.tertiary : "#8bceff")
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                  id: crumbMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.panel._fileBrowserListDir(modelData.path)
                }
              }
            }
          }
        }
      }

      Flickable {
        id: fbFlickable
        width: parent.width
        height: parent.height - 90
        contentWidth: width
        contentHeight: fbGridCol.implicitHeight + 10
        clip: true
        flickableDirection: Flickable.VerticalFlick
        boundsBehavior: Flickable.StopAtBounds

        Rectangle {
          visible: fbFlickable.contentHeight > fbFlickable.height
          anchors.right: parent.right
          anchors.rightMargin: -8
          y: fbFlickable.visibleArea.yPosition * fbFlickable.height
          width: 4
          height: Math.max(20, fbFlickable.visibleArea.heightRatio * fbFlickable.height)
          radius: 2
          color: root.colors ? root.colors.primary : "#fff"
          opacity: 0.5
          z: 10
        }

        Column {
          id: fbGridCol
          width: parent.width
          spacing: 4

          Flow {
            width: parent.width
            spacing: 4
            visible: {
              for (var i = 0; i < root.panel._fileBrowserEntries.length; i++) {
                if (root.panel._fileBrowserEntries[i].isDir) return true
              }
              return false
            }

            Repeater {
              model: root.panel._fileBrowserEntries.filter(function(e) { return e.isDir })

              Rectangle {
                width: dirLabel.implicitWidth + 36
                height: 30
                radius: 6
                color: dirMouse.containsMouse
                  ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.15) : Qt.rgba(1, 1, 1, 0.1))
                  : (root.colors ? Qt.rgba(root.colors.surfaceVariant.r, root.colors.surfaceVariant.g, root.colors.surfaceVariant.b, 0.25) : Qt.rgba(1, 1, 1, 0.05))
                border.width: dirMouse.containsMouse ? 1 : 0
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)

                Row {
                  id: dirLabel
                  anchors.centerIn: parent
                  spacing: 6

                  Text {
                    text: modelData.name === ".." ? "󰁍" : "󰉋"
                    font.family: Style.fontFamilyNerdIcons
                    font.pixelSize: 14
                    color: root.colors ? root.colors.primary : "#4fc3f7"
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: modelData.name === ".." ? "UP" : modelData.name
                    font.family: Style.fontFamily
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    color: root.colors ? root.colors.tertiary : "#8bceff"
                    anchors.verticalCenter: parent.verticalCenter
                    maximumLineCount: 1
                    elide: Text.ElideRight
                  }
                }

                MouseArea {
                  id: dirMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: {
                    if (modelData.name === "..") {
                      var parts = root.panel._fileBrowserCurrentDir.split("/")
                      parts.pop()
                      var parent_dir = parts.join("/")
                      if (!parent_dir) parent_dir = "/"
                      root.panel._fileBrowserListDir(parent_dir)
                    } else {
                      root.panel._fileBrowserListDir(root.panel._fileBrowserCurrentDir + "/" + modelData.name)
                    }
                  }
                }
              }
            }
          }

          Rectangle {
            width: parent.width
            height: 1
            color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.1) : Qt.rgba(1, 1, 1, 0.05)
            visible: {
              var hasDirs = false, hasFiles = false
              for (var i = 0; i < root.panel._fileBrowserEntries.length; i++) {
                if (root.panel._fileBrowserEntries[i].isDir) hasDirs = true
                else hasFiles = true
              }
              return hasDirs && hasFiles
            }
          }

          Flow {
            width: parent.width
            spacing: 6

            Repeater {
              model: root.panel._fileBrowserEntries.filter(function(e) { return !e.isDir })

              Rectangle {
                width: 140
                height: 120
                radius: 8
                color: imgMouse.containsMouse
                  ? (root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.2) : Qt.rgba(1, 1, 1, 0.12))
                  : (root.colors ? Qt.rgba(root.colors.surfaceVariant.r, root.colors.surfaceVariant.g, root.colors.surfaceVariant.b, 0.2) : Qt.rgba(1, 1, 1, 0.04))
                border.width: imgMouse.containsMouse ? 1 : 0
                border.color: root.colors ? Qt.rgba(root.colors.primary.r, root.colors.primary.g, root.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.3)
                clip: true

                Image {
                  anchors.fill: parent
                  anchors.margins: 3
                  source: "file://" + root.panel._fileBrowserCurrentDir + "/" + modelData.name
                  fillMode: Image.PreserveAspectCrop
                  asynchronous: true
                  smooth: true
                  sourceSize.width: 280
                  sourceSize.height: 240
                }

                Rectangle {
                  anchors.bottom: parent.bottom
                  anchors.left: parent.left
                  anchors.right: parent.right
                  height: 22
                  color: Qt.rgba(0, 0, 0, 0.7)
                  radius: 0

                  Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 0
                    radius: parent.parent.radius
                    color: parent.color
                    visible: false
                  }

                  Text {
                    anchors.fill: parent
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    verticalAlignment: Text.AlignVCenter
                    text: modelData.name
                    font.family: Style.fontFamily
                    font.pixelSize: 9
                    color: root.colors ? root.colors.surfaceText : "#ccc"
                    elide: Text.ElideMiddle
                  }
                }

                MouseArea {
                  id: imgMouse
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.panel._fileBrowserSelect(root.panel._fileBrowserCurrentDir + "/" + modelData.name)
                }
              }
            }
          }

          Text {
            visible: {
              for (var i = 0; i < root.panel._fileBrowserEntries.length; i++) {
                if (!root.panel._fileBrowserEntries[i].isDir) return false
              }
              return root.panel._fileBrowserEntries.length > 0
            }
            text: "No images in this directory"
            font.family: Style.fontFamily
            font.pixelSize: 12
            color: root.colors ? Qt.rgba(root.colors.surfaceText.r, root.colors.surfaceText.g, root.colors.surfaceText.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
            topPadding: 20
            anchors.horizontalCenter: parent.horizontalCenter
          }
        }
      }
    }
  }
}

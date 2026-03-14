import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Controls
import QtQuick.Shapes
import QtMultimedia
import ".."

// Wallpaper picker with parallelogram slices, ollama AI tagging, color/tag/type filtering
Scope {
  id: wallpaperSelector

  // External bindings
  property var colors
  property bool showing: false
  property alias selectedColorFilter: service.selectedColorFilter


  property string mainMonitor: Config.mainMonitor


  signal wallpaperChanged()


  function resetScroll() {
    wallpaperSelector.lastContentX = 0
    wallpaperSelector.lastIndex = 0
    sliceListView.currentIndex = 0
    if (service.filteredModel.count > 0)
      sliceListView.positionViewAtIndex(0, ListView.Beginning)
  }


  WallpaperSelectorService {
    id: service
    scriptsDir: Config.scriptsDir
    homeDir: Config.homeDir
    wallpaperDir: Config.wallpaperDir
    cacheBaseDir: Config.cacheDir
    weDir: Config.weDir
    weAssetsDir: Config.weAssetsDir
    ollamaStatusPollMs: Config.ollamaStatusPollMs
    showing: wallpaperSelector.showing
    onModelUpdated: {
      if (service.filteredModel.count > 0) {
        sliceListView.currentIndex = 0
        sliceListView.positionViewAtIndex(0, ListView.Beginning)
      }
    }
    onWallpaperApplied: wallpaperSelector.wallpaperChanged()
  }

  onShowingChanged: {
    if (showing) {
      service.startCacheCheck()
      cardShowTimer.restart()
    } else {
      cardVisible = false
    }
  }


  Timer {
    id: cardShowTimer
    interval: 50
    onTriggered: wallpaperSelector.cardVisible = true
  }



  Timer {
    id: focusTimer
    interval: 50
    onTriggered: sliceListView.forceActiveFocus()
  }


  // Slice geometry constants
  property int sliceWidth: 135
  property int expandedWidth: 924
  property int sliceHeight: 520
  property int skewOffset: 35
  property int sliceSpacing: -22


  property int cardWidth: 1600
  property int topBarHeight: 50
  property bool tagCloudVisible: false
  property int tagCloudHeight: tagCloudVisible ? 120 : 0
  property int cardHeight: sliceHeight + topBarHeight + tagCloudHeight + 60


  property real lastContentX: 0
  property int lastIndex: 0


  property bool cardVisible: false



  // Right-click context menu state
  property string contextMenuName: ""
  property string contextMenuType: ""
  property string contextMenuWeId: ""
  property string contextMenuPath: ""
  property real contextMenuX: 0
  property real contextMenuY: 0
  property bool contextMenuVisible: false


  // Full-screen overlay panel
  PanelWindow {
    id: selectorPanel

    screen: Quickshell.screens.find(s => s.name === wallpaperSelector.mainMonitor) ?? Quickshell.screens[0]

    anchors {
      top: true
      bottom: true
      left: true
      right: true
    }
    margins {
      top: 0
      bottom: 0
      left: 0
      right: 0
    }

    visible: wallpaperSelector.showing
    color: "transparent"

    WlrLayershell.namespace: "wallpaper-selector-parallel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: wallpaperSelector.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore


    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      opacity: wallpaperSelector.cardVisible ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }
    }


    MouseArea {
      anchors.fill: parent
      onClicked: wallpaperSelector.showing = false
    }


  // Card container with fade-in
  Item {
    id: cardContainer
    width: wallpaperSelector.cardWidth
    height: wallpaperSelector.cardHeight
    anchors.centerIn: parent
    visible: wallpaperSelector.cardVisible


    opacity: 0
    property bool animateIn: wallpaperSelector.cardVisible

    onAnimateInChanged: {
      fadeInAnim.stop()
      if (animateIn) {
        opacity = 0
        fadeInAnim.start()
        focusTimer.restart()
      }
    }

    NumberAnimation {
      id: fadeInAnim
      target: cardContainer
      property: "opacity"
      from: 0; to: 1
      duration: 400
      easing.type: Easing.OutCubic
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }


    // Ollama analysis status indicator (top-right)
    Rectangle {
      id: ollamaStatusIndicator
      anchors.top: parent.top
      anchors.right: parent.right
      anchors.topMargin: 8
      anchors.rightMargin: 8
      z: 100

      visible: service.ollamaActive
      opacity: service.ollamaActive ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 200 } }

      width: Math.max(ollamaStatusRow.width + 20, ollamaLogText.width + 20)
      height: service.ollamaLogLine ? 44 : 28
      radius: height / 2
      color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceContainer.r, wallpaperSelector.colors.surfaceContainer.g, wallpaperSelector.colors.surfaceContainer.b, 0.9) : Qt.rgba(0.1, 0.12, 0.18, 0.9)

      layer.enabled: false

      Column {
        anchors.centerIn: parent
        spacing: 2

        Row {
          id: ollamaStatusRow
          anchors.horizontalCenter: parent.horizontalCenter
          spacing: 6

          Text {
            text: "󰔟"
            font.family: Style.fontFamilyNerdIcons
            font.pixelSize: 14
            color: wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#8BC34A"
            RotationAnimation on rotation {
              from: 0; to: 360; duration: 1000
              loops: Animation.Infinite
              running: service.ollamaActive
            }
          }

          Text {
            text: {
              var status = "ANALYZING"
              var progress = ""
              if (service.ollamaTotalThumbs > 0) {
                progress = " " + service.ollamaTaggedCount + "/" + service.ollamaTotalThumbs
              }
              var eta = service.ollamaEta
              if (eta && eta !== "") return status + progress + " (" + eta + ")"
              return status + progress
            }
            font.family: Style.fontFamily
            font.pixelSize: 11
            font.weight: Font.Medium
            font.letterSpacing: 0.5
            color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
          }
        }

        Text {
          id: ollamaLogText
          anchors.horizontalCenter: parent.horizontalCenter
          text: service.ollamaLogLine
          visible: service.ollamaLogLine !== ""
          font.family: Style.fontFamilyCode
          font.pixelSize: 9
          color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceText.r, wallpaperSelector.colors.surfaceText.g, wallpaperSelector.colors.surfaceText.b, 0.6) : Qt.rgba(1, 1, 1, 0.5)
          elide: Text.ElideMiddle
          maximumLineCount: 1
        }
      }
    }


  // Card contents (filter bar, tag cloud, context menu, progress)
  Item {
    id: backgroundRect
    anchors.fill: parent

    // Top filter bar background pill
    Rectangle {
      id: filterBarBg
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.topMargin: 10
      width: topFilterBar.width + 30
      height: topFilterBar.height + 14
      radius: height / 2
      color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceContainer.r,
                                                 wallpaperSelector.colors.surfaceContainer.g,
                                                 wallpaperSelector.colors.surfaceContainer.b, 0.85)
                                      : Qt.rgba(0.1, 0.12, 0.18, 0.85)
      z: 10
    }

    // Top filter bar (type, color dots, sort, count)
    Row {
      id: topFilterBar
      anchors.centerIn: filterBarBg
      spacing: 20
      z: 11


      Row {
        id: typeFilterRow
        spacing: 4

        Repeater {
          model: [
            { type: "", icon: "󰄶", label: "All" },
            { type: "static", icon: "󰋩", label: "Pic" },
            { type: "video", icon: "󰕧", label: "Vid" },
            { type: "we", icon: "󰖔", label: "WE" }
          ]

          Rectangle {
            width: 32
            height: 24
            radius: 4
            property bool isSelected: service.selectedTypeFilter === modelData.type
            property bool isHovered: typeMouseArea.containsMouse

            color: isSelected
              ? (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7")
              : (isHovered
                ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceVariant.r, wallpaperSelector.colors.surfaceVariant.g, wallpaperSelector.colors.surfaceVariant.b, 0.5) : Qt.rgba(1, 1, 1, 0.15))
                : "transparent")

            border.width: isSelected ? 0 : 1
            border.color: isHovered ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)) : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              font.pixelSize: 14
              font.family: Style.fontFamilyNerdIcons
              color: parent.isSelected
                ? (wallpaperSelector.colors ? wallpaperSelector.colors.primaryText : "#000")
                : (wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff")
            }

            MouseArea {
              id: typeMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (parent.isSelected) {
                  service.selectedTypeFilter = ""
                } else {
                  service.selectedTypeFilter = modelData.type
                }
              }
            }

            ToolTip {
              visible: typeMouseArea.containsMouse
              text: modelData.label
              delay: 500
            }
          }
        }
      }


      Rectangle {
        width: 1; height: 20
        color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
      }


      // Color hue filter (parallelogram dots)
      Row {
        id: colorDotsRow
        spacing: -5

        Repeater {
          model: 13

          Item {
            width: 38; height: 20
            readonly property int filterValue: index < 12 ? index : 99
            readonly property bool isSelected: service.selectedColorFilter === filterValue
            readonly property color shapeColor: index === 12 ? "#777" : Qt.hsla(index / 12.0, 0.7, 0.5, 1.0)
            readonly property color shadowColor: index === 12 ? "#555" : Qt.hsla(index / 12.0, 0.8, 0.3, 1.0)

            Canvas {
              id: colorCanvas
              anchors.centerIn: parent
              width: parent.width; height: parent.height
              scale: parent.isSelected ? 1.15 : 1.0
              Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutBack } }

              property color fillColor: parent.shapeColor
              property color borderColor: index === 12 ? "#aaa" : Qt.hsla(index / 12.0, 0.7, 0.75, 1.0)
              property color dropShadowColor: parent.shadowColor
              property real fillOpacity: parent.isSelected ? 1.0 : 0.6
              property bool showShadow: parent.isSelected

              onFillColorChanged: requestPaint()
              onFillOpacityChanged: requestPaint()
              onShowShadowChanged: requestPaint()

              onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var skew = 15
                if (showShadow) {
                  ctx.globalAlpha = 0.6
                  ctx.fillStyle = dropShadowColor
                  ctx.beginPath()
                  ctx.moveTo(skew + 3, 2 + 3)
                  ctx.lineTo(width + 3, 2 + 3)
                  ctx.lineTo(width - skew + 3, 18 + 3)
                  ctx.lineTo(0 + 3, 18 + 3)
                  ctx.closePath()
                  ctx.fill()
                }
                ctx.globalAlpha = fillOpacity
                ctx.fillStyle = fillColor
                ctx.beginPath()
                ctx.moveTo(skew, 2)
                ctx.lineTo(width, 2)
                ctx.lineTo(width - skew, 18)
                ctx.lineTo(0, 18)
                ctx.closePath()
                ctx.fill()
                ctx.globalAlpha = fillOpacity
                ctx.strokeStyle = borderColor
                ctx.lineWidth = 1.5
                ctx.stroke()
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                if (parent.isSelected) {
                  service.selectedColorFilter = -1
                } else {
                  service.selectedColorFilter = parent.filterValue
                }
              }
            }
          }
        }
      }


      Rectangle {
        width: 1; height: 20
        color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.2)
      }


      Row {
        spacing: 4
        anchors.verticalCenter: parent.verticalCenter

        Repeater {
          model: [
            { mode: "date", icon: "󰃰", label: "Newest" },
            { mode: "color", icon: "󰏘", label: "Color" }
          ]

          Rectangle {
            width: 32; height: 24; radius: 4
            property bool isSelected: service.sortMode === modelData.mode
            property bool isHovered: sortMouseArea.containsMouse

            color: isSelected
              ? (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7")
              : (isHovered
                ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceVariant.r, wallpaperSelector.colors.surfaceVariant.g, wallpaperSelector.colors.surfaceVariant.b, 0.5) : Qt.rgba(1, 1, 1, 0.15))
                : "transparent")

            border.width: isSelected ? 0 : 1
            border.color: isHovered ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)) : "transparent"

            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Text {
              anchors.centerIn: parent
              text: modelData.icon
              font.pixelSize: 14
              font.family: Style.fontFamilyNerdIcons
              color: parent.isSelected
                ? (wallpaperSelector.colors ? wallpaperSelector.colors.primaryText : "#000")
                : (wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff")
            }

            MouseArea {
              id: sortMouseArea
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                service.sortMode = modelData.mode
                service.updateFilteredModel()
              }
            }

            ToolTip {
              visible: sortMouseArea.containsMouse
              text: modelData.label
              delay: 500
            }
          }
        }
      }


      Text {
        text: service.filteredModel.count + (service.filteredModel.count !== service.wallpaperModel.count ? "/" + service.wallpaperModel.count : "")
        font.family: Style.fontFamily
        font.pixelSize: 11
        font.weight: Font.Medium
        color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceText.r, wallpaperSelector.colors.surfaceText.g, wallpaperSelector.colors.surfaceText.b, 0.5) : Qt.rgba(1, 1, 1, 0.4)
        anchors.verticalCenter: parent.verticalCenter
      }
    }


    // Tag cloud panel (toggled with Shift+Down)
    Rectangle {
      id: tagCloudBg
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.margins: 10
      anchors.bottomMargin: 8
      height: wallpaperSelector.tagCloudVisible ? wallpaperSelector.tagCloudHeight + 4 : 0
      visible: wallpaperSelector.tagCloudVisible
      radius: 16
      color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceContainer.r,
                                                 wallpaperSelector.colors.surfaceContainer.g,
                                                 wallpaperSelector.colors.surfaceContainer.b, 0.85)
                                      : Qt.rgba(0.1, 0.12, 0.18, 0.85)

      Behavior on height { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
    }


    Flickable {
      id: tagCloudFlickable
      anchors.fill: tagCloudBg
      anchors.margins: 8
      visible: wallpaperSelector.tagCloudVisible
      opacity: wallpaperSelector.tagCloudVisible ? 1.0 : 0.0
      clip: true
      contentWidth: width
      contentHeight: tagCloudRow.implicitHeight
      flickableDirection: Flickable.VerticalFlick
      boundsBehavior: Flickable.StopAtBounds

      Behavior on opacity { NumberAnimation { duration: 200 } }
      z: 11

      Rectangle {
        visible: tagCloudFlickable.contentHeight > tagCloudFlickable.height
        anchors.right: parent.right
        anchors.rightMargin: 2
        y: tagCloudFlickable.visibleArea.yPosition * tagCloudFlickable.height
        width: 4
        height: tagCloudFlickable.visibleArea.heightRatio * tagCloudFlickable.height
        radius: 2
        color: wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#fff"
        opacity: 0.5
      }

      Flow {
        id: tagCloudRow
        width: parent.width - 10
        spacing: 8

        Repeater {
          model: service.popularTags

          Rectangle {
            id: tagChip
            width: tagText.width + 16
            height: 26
            radius: 4
            property bool isSelected: service.selectedTags.indexOf(modelData.tag) !== -1
            property bool isHovered: tagMouse.containsMouse

            color: isSelected
              ? (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7")
              : (isHovered
                ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceVariant.r, wallpaperSelector.colors.surfaceVariant.g, wallpaperSelector.colors.surfaceVariant.b, 0.5) : "#444")
                : "transparent")

            border.width: isSelected ? 0 : 1
            border.color: isSelected ? "transparent" : (isHovered ? (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)) : (wallpaperSelector.colors ? wallpaperSelector.colors.outline : Qt.rgba(1, 1, 1, 0.15)))

            Behavior on color { ColorAnimation { duration: 100 } }
            Behavior on border.color { ColorAnimation { duration: 100 } }

            Text {
              id: tagText
              anchors.centerIn: parent
              text: modelData.tag.toUpperCase()
              color: tagChip.isSelected
                ? (wallpaperSelector.colors ? wallpaperSelector.colors.primaryText : "#000")
                : (wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff")
              font.family: Style.fontFamily
              font.pixelSize: 11
              font.weight: tagChip.isSelected ? Font.Bold : Font.Medium
              font.letterSpacing: 0.5
            }

            MouseArea {
              id: tagMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                var tags = service.selectedTags.slice()
                var idx = tags.indexOf(modelData.tag)
                if (idx !== -1) {
                  tags.splice(idx, 1)
                } else {
                  tags.push(modelData.tag)
                }
                service.selectedTags = tags
                service.updateFilteredModel()
              }
            }
          }
        }
      }
    }




    // Cache loading progress bar
    Rectangle {
      id: progressContainer
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottomMargin: 30
      width: 400
      height: 40
      radius: 20
      color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceContainer.r, wallpaperSelector.colors.surfaceContainer.g, wallpaperSelector.colors.surfaceContainer.b, 0.9) : Qt.rgba(0, 0, 0, 0.8)
      visible: service.cacheLoading
      opacity: service.cacheLoading ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 200 } }

      Rectangle {
        id: progressBg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 16
        height: 4
        radius: 2
        color: Qt.rgba(1, 1, 1, 0.1)

        Rectangle {
          anchors.left: parent.left
          anchors.top: parent.top
          anchors.bottom: parent.bottom
          radius: 2
          width: service.cacheTotal > 0
            ? parent.width * (service.cacheProgress / service.cacheTotal)
            : 0
          color: wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7"
          Behavior on width { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
        }
      }

      Text {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -12
        text: service.cacheTotal > 0
          ? "LOADING WALLPAPERS... " + service.cacheProgress + " / " + service.cacheTotal
          : "SCANNING..."
        color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
        font.family: Style.fontFamily
        font.pixelSize: 12
        font.weight: Font.Medium
        font.letterSpacing: 0.5
      }
    }
  }
  }


    // Horizontal parallelogram slice list view
    ListView {
      id: sliceListView

      anchors.top: cardContainer.top
      anchors.topMargin: wallpaperSelector.topBarHeight + 15
      anchors.bottom: cardContainer.bottom
      anchors.bottomMargin: (wallpaperSelector.tagCloudVisible ? wallpaperSelector.tagCloudHeight : 0) + 20

      anchors.horizontalCenter: parent.horizontalCenter
      property int visibleCount: 12
      width: wallpaperSelector.expandedWidth + (visibleCount - 1) * (wallpaperSelector.sliceWidth + wallpaperSelector.sliceSpacing)

      orientation: ListView.Horizontal
      model: service.filteredModel
      clip: false
      spacing: wallpaperSelector.sliceSpacing

      flickDeceleration: 1500
      maximumFlickVelocity: 3000
      boundsBehavior: Flickable.StopAtBounds
      cacheBuffer: wallpaperSelector.expandedWidth * 4

      visible: wallpaperSelector.cardVisible

      property bool keyboardNavActive: false
      property real lastMouseX: -1
      property real lastMouseY: -1

      highlightFollowsCurrentItem: true
      highlightMoveDuration: 350
      highlight: Item {}

      preferredHighlightBegin: (width - wallpaperSelector.expandedWidth) / 2
      preferredHighlightEnd: (width + wallpaperSelector.expandedWidth) / 2
      highlightRangeMode: ListView.StrictlyEnforceRange

      header: Item { width: (sliceListView.width - wallpaperSelector.expandedWidth) / 2; height: 1 }
      footer: Item { width: (sliceListView.width - wallpaperSelector.expandedWidth) / 2; height: 1 }

      focus: wallpaperSelector.showing
      onVisibleChanged: {
        if (visible) forceActiveFocus()
      }

      Connections {
        target: wallpaperSelector
        function onShowingChanged() {
          if (!wallpaperSelector.showing) {
            wallpaperSelector.lastContentX = sliceListView.contentX
            wallpaperSelector.lastIndex = sliceListView.currentIndex
          } else {
            sliceListView.forceActiveFocus()
          }
        }
      }
      onCountChanged: {
        if (count > 0 && wallpaperSelector.showing) {
          contentX = wallpaperSelector.lastContentX
          currentIndex = Math.min(wallpaperSelector.lastIndex, count - 1)
        }
      }

      MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        onWheel: function(wheel) {

          var step = 1
          if (wheel.angleDelta.y > 0 || wheel.angleDelta.x > 0) {
            sliceListView.currentIndex = Math.max(0, sliceListView.currentIndex - step)
          } else if (wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0) {
            sliceListView.currentIndex = Math.min(service.filteredModel.count - 1, sliceListView.currentIndex + step)
          }
        }
        onPressed: function(mouse) { mouse.accepted = false }
        onReleased: function(mouse) { mouse.accepted = false }
        onClicked: function(mouse) { mouse.accepted = false }
      }

      Timer {
        id: wheelDebounce
        interval: 400
        onTriggered: {
          var centerX = sliceListView.contentX + sliceListView.width / 2
          var nearest = sliceListView.indexAt(centerX, sliceListView.height / 2)
          if (nearest >= 0) sliceListView.currentIndex = nearest
        }
      }

      Keys.onEscapePressed: wallpaperSelector.showing = false
      Keys.onReturnPressed: {
        if (currentIndex >= 0 && currentIndex < service.filteredModel.count) {
          const item = service.filteredModel.get(currentIndex)
          if (item.type === "we") {
            service.applyWE(item.weId)
          } else if (item.type === "video") {
            service.applyVideo(item.path)
          } else {
            service.applyStatic(item.path)
          }
        }
      }
      Keys.onPressed: function(event) {

        if (event.modifiers & Qt.ShiftModifier) {
          if (event.key === Qt.Key_Down) {
            wallpaperSelector.tagCloudVisible = !wallpaperSelector.tagCloudVisible
            if (!wallpaperSelector.tagCloudVisible) {
              service.selectedTags = []
              service.updateFilteredModel()
            }
            event.accepted = true
            return
          } else if (event.key === Qt.Key_Left) {
            if (service.selectedColorFilter === -1) {
              service.selectedColorFilter = 99
            } else if (service.selectedColorFilter === 99) {
              service.selectedColorFilter = 11
            } else if (service.selectedColorFilter === 0) {
              service.selectedColorFilter = 99
            } else {
              service.selectedColorFilter--
            }
            event.accepted = true
            return
          } else if (event.key === Qt.Key_Right) {
            if (service.selectedColorFilter === -1) {
              service.selectedColorFilter = 0
            } else if (service.selectedColorFilter === 11) {
              service.selectedColorFilter = 99
            } else if (service.selectedColorFilter === 99) {
              service.selectedColorFilter = 0
            } else {
              service.selectedColorFilter++
            }
            event.accepted = true
            return
          }
        }
        if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
          keyboardNavActive = true
        }

        if (event.key === Qt.Key_Left && !(event.modifiers & Qt.ShiftModifier)) {
          if (currentIndex > 0) {
            currentIndex--
          }
          event.accepted = true
          return
        }

        if (event.key === Qt.Key_Right && !(event.modifiers & Qt.ShiftModifier)) {
          if (currentIndex < service.filteredModel.count - 1) {
            currentIndex++
          }
          event.accepted = true
          return
        }
      }

      // Parallelogram slice delegate
      delegate: Item {
        id: delegateItem

        width: isCurrent ? wallpaperSelector.expandedWidth : wallpaperSelector.sliceWidth
        height: sliceListView.height
        property bool isCurrent: ListView.isCurrentItem
        property bool isHovered: itemMouseArea.containsMouse

        z: isCurrent ? 100 : (isHovered ? 90 : 50 - Math.min(Math.abs(index - sliceListView.currentIndex), 50))

        property real viewX: x - sliceListView.contentX
        property real fadeZone: wallpaperSelector.sliceWidth * 1.5
        property real edgeOpacity: {
          if (fadeZone <= 0) return 1.0
          var center = viewX + width * 0.5

          var leftFade = Math.min(1.0, Math.max(0.0, center / fadeZone))
          var rightFade = Math.min(1.0, Math.max(0.0, (sliceListView.width - center) / fadeZone))
          return Math.min(leftFade, rightFade)
        }
        opacity: edgeOpacity
        Behavior on width {
          NumberAnimation { duration: 200; easing.type: Easing.OutQuad }
        }


        containmentMask: Item {
          id: hitMask
          function contains(point) {
            var w = delegateItem.width
            var h = delegateItem.height
            var sk = wallpaperSelector.skewOffset
            if (h <= 0 || w <= 0) return false


            var leftX = sk * (1.0 - point.y / h)


            var rightX = w - sk * (point.y / h)
            return point.x >= leftX && point.x <= rightX && point.y >= 0 && point.y <= h
          }
        }

        Canvas {
          id: shadowCanvas
          z: -1
          anchors.fill: parent
          anchors.margins: -10
          property real shadowOffsetX: delegateItem.isCurrent ? 4 : 2
          property real shadowOffsetY: delegateItem.isCurrent ? 10 : 5
          property real shadowAlpha: delegateItem.isCurrent ? 0.6 : 0.4
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()
          onShadowAlphaChanged: requestPaint()
          onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            var ox = 10
            var oy = 10
            var w = delegateItem.width
            var h = delegateItem.height
            var sk = wallpaperSelector.skewOffset
            var sx = shadowOffsetX
            var sy = shadowOffsetY
            var layers = [
              { dx: sx, dy: sy, alpha: shadowAlpha * 0.5 },
              { dx: sx * 0.6, dy: sy * 0.6, alpha: shadowAlpha * 0.3 },
              { dx: sx * 1.4, dy: sy * 1.4, alpha: shadowAlpha * 0.2 }
            ]
            for (var i = 0; i < layers.length; i++) {
              var l = layers[i]
              ctx.globalAlpha = l.alpha
              ctx.fillStyle = "#000000"
              ctx.beginPath()
              ctx.moveTo(ox + sk + l.dx, oy + l.dy)
              ctx.lineTo(ox + w + l.dx, oy + l.dy)
              ctx.lineTo(ox + w - sk + l.dx, oy + h + l.dy)
              ctx.lineTo(ox + l.dx, oy + h + l.dy)
              ctx.closePath()
              ctx.fill()
            }
          }
        }

        Item {
          id: imageContainer
          anchors.fill: parent
          Image {
            id: thumbImage
            anchors.fill: parent
            source: "file://" + model.thumb
            fillMode: Image.PreserveAspectCrop
            smooth: true
            asynchronous: true
            sourceSize.width: wallpaperSelector.expandedWidth
            sourceSize.height: wallpaperSelector.sliceHeight
          }

          Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, delegateItem.isCurrent ? 0 : (delegateItem.isHovered ? 0.15 : 0.4))
            Behavior on color { ColorAnimation { duration: 200 } }
          }
          layer.enabled: true
          layer.smooth: true
          layer.samples: 4
          layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ShaderEffectSource {
              sourceItem: Item {
                width: imageContainer.width
                height: imageContainer.height
                layer.enabled: true
                layer.smooth: true
                layer.samples: 8
                Shape {
                  anchors.fill: parent
                  antialiasing: true
                  preferredRendererType: Shape.CurveRenderer
                  ShapePath {
                    fillColor: "white"
                    strokeColor: "transparent"
                    startX: wallpaperSelector.skewOffset
                    startY: 0
                    PathLine { x: delegateItem.width; y: 0 }
                    PathLine { x: delegateItem.width - wallpaperSelector.skewOffset; y: delegateItem.height }
                    PathLine { x: 0; y: delegateItem.height }
                    PathLine { x: wallpaperSelector.skewOffset; y: 0 }
                  }
                }
              }
            }
            maskThresholdMin: 0.3
            maskSpreadAtMin: 0.3
          }
        }

        // Video preview (plays after 300ms hover on current)
        property string videoPath: model.videoFile ? model.videoFile : ""
        property bool hasVideo: videoPath.length > 0
        property bool videoActive: false

        onIsCurrentChanged: {
          if (isCurrent && hasVideo) {
            videoDelayTimer.restart()
          } else {
            videoDelayTimer.stop()
            videoActive = false
          }
        }

        Timer {
          id: videoDelayTimer
          interval: 300
          onTriggered: delegateItem.videoActive = true
        }

        Loader {
          id: videoLoader
          anchors.fill: parent
          active: delegateItem.videoActive
          property bool isPlaying: active && status === Loader.Ready

          sourceComponent: Item {
            anchors.fill: parent

            Video {
              id: videoElement
              anchors.fill: parent
              source: "file://" + delegateItem.videoPath
              fillMode: VideoOutput.PreserveAspectCrop
              loops: MediaPlayer.Infinite
              muted: true
              Component.onCompleted: play()
            }

            layer.enabled: true
            layer.smooth: true
            layer.samples: 4
            layer.effect: MultiEffect {
              maskEnabled: true
              maskSource: ShaderEffectSource {
                sourceItem: Item {
                  width: delegateItem.width
                  height: delegateItem.height
                  layer.enabled: true
                  layer.smooth: true
                  Shape {
                    anchors.fill: parent
                    antialiasing: true
                    preferredRendererType: Shape.CurveRenderer
                    ShapePath {
                      fillColor: "white"
                      strokeColor: "transparent"
                      startX: wallpaperSelector.skewOffset
                      startY: 0
                      PathLine { x: delegateItem.width; y: 0 }
                      PathLine { x: delegateItem.width - wallpaperSelector.skewOffset; y: delegateItem.height }
                      PathLine { x: 0; y: delegateItem.height }
                      PathLine { x: wallpaperSelector.skewOffset; y: 0 }
                    }
                  }
                }
              }
              maskThresholdMin: 0.3
              maskSpreadAtMin: 0.3
            }
          }
        }

        Shape {
          id: glowBorder
          anchors.fill: parent
          antialiasing: true
          preferredRendererType: Shape.CurveRenderer
          opacity: 1.0
          ShapePath {
            fillColor: "transparent"
            strokeColor: delegateItem.isCurrent
              ? (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#8BC34A")
              : (delegateItem.isHovered
                ? Qt.rgba(wallpaperSelector.colors ? wallpaperSelector.colors.primary.r : 0.5, wallpaperSelector.colors ? wallpaperSelector.colors.primary.g : 0.76, wallpaperSelector.colors ? wallpaperSelector.colors.primary.b : 0.29, 0.4)
                : Qt.rgba(0, 0, 0, 0.6))
            Behavior on strokeColor { ColorAnimation { duration: 200 } }
            strokeWidth: delegateItem.isCurrent ? 3 : 1
            startX: wallpaperSelector.skewOffset
            startY: 0
            PathLine { x: delegateItem.width; y: 0 }
            PathLine { x: delegateItem.width - wallpaperSelector.skewOffset; y: delegateItem.height }
            PathLine { x: 0; y: delegateItem.height }
            PathLine { x: wallpaperSelector.skewOffset; y: 0 }
          }
        }

        Rectangle {
          id: videoIndicator
          anchors.top: parent.top
          anchors.topMargin: 10
          anchors.right: parent.right
          anchors.rightMargin: 10
          width: 22
          height: 22
          radius: 11
          color: delegateItem.videoActive ? (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7") : Qt.rgba(0, 0, 0, 0.7)
          border.width: 1
          border.color: delegateItem.videoActive
            ? "transparent"
            : (wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.6) : Qt.rgba(1, 1, 1, 0.4))
          visible: delegateItem.hasVideo
          z: 10

          Behavior on color { ColorAnimation { duration: 200 } }

          Text {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: 1
            text: "▶"
            font.pixelSize: 9
            color: delegateItem.videoActive
              ? (wallpaperSelector.colors ? wallpaperSelector.colors.primaryText : "#000")
              : (wallpaperSelector.colors ? wallpaperSelector.colors.primary : "#4fc3f7")
          }
        }

        Rectangle {
          id: nameLabel
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 40
          anchors.horizontalCenter: parent.horizontalCenter
          width: nameText.width + 24
          height: 32
          radius: 6
          color: Qt.rgba(0, 0, 0, 0.75)
          border.width: 1
          border.color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.5) : Qt.rgba(1, 1, 1, 0.2)
          visible: delegateItem.isCurrent
          opacity: delegateItem.isCurrent ? 1 : 0
          Behavior on opacity { NumberAnimation { duration: 200 } }
          Text {
            id: nameText
            anchors.centerIn: parent
            text: model.name.replace(/\.[^/.]+$/, "").toUpperCase()
            font.family: Style.fontFamily
            font.pixelSize: 12
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
            elide: Text.ElideMiddle
            maximumLineCount: 1
            width: Math.min(implicitWidth, delegateItem.width - 60)
          }
        }

        Rectangle {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 8
          anchors.right: parent.right
          anchors.rightMargin: wallpaperSelector.skewOffset + 8
          width: typeBadgeText.width + 8
          height: 16
          radius: 4
          color: Qt.rgba(0, 0, 0, 0.75)
          border.width: 1
          border.color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
          z: 10

          Text {
            id: typeBadgeText
            anchors.centerIn: parent
            text: model.type === "static" ? "PIC" : ((model.type === "video" || model.videoFile) ? "VID" : "WE")
            font.family: Style.fontFamily
            font.pixelSize: 9
            font.weight: Font.Bold
            font.letterSpacing: 0.5
            color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
          }
        }

        // Matugen color preview dots (bottom-left of selected slice)
        Row {
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 12
          anchors.left: parent.left
          anchors.leftMargin: wallpaperSelector.skewOffset + 8
          spacing: 6
          visible: delegateItem.isCurrent && wallpaperColors !== undefined
          property var wallpaperColors: {
            var key = model.weId ? model.weId : model.thumb.split("/").pop().replace(/\.[^/.]+$/, "")
            return service.matugenDb[key]
          }
          Rectangle {
            width: 14; height: 14; radius: 7
            color: parent.wallpaperColors ? parent.wallpaperColors.primary : "#888"
            border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.5)
            visible: parent.wallpaperColors !== undefined
          }
          Rectangle {
            width: 14; height: 14; radius: 7
            color: parent.wallpaperColors ? parent.wallpaperColors.secondary : "#666"
            border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.5)
            visible: parent.wallpaperColors !== undefined
          }
          Rectangle {
            width: 14; height: 14; radius: 7
            color: parent.wallpaperColors ? parent.wallpaperColors.tertiary : "#444"
            border.width: 1; border.color: Qt.rgba(0, 0, 0, 0.5)
            visible: parent.wallpaperColors !== undefined
          }
        }

        // Mouse interaction (hover, click to apply, right-click context menu)
        MouseArea {
          id: itemMouseArea
          anchors.fill: parent
          hoverEnabled: true
          acceptedButtons: Qt.LeftButton | Qt.RightButton
          cursorShape: Qt.PointingHandCursor
          onPositionChanged: function(mouse) {
            var globalPos = mapToItem(sliceListView, mouse.x, mouse.y)
            var dx = Math.abs(globalPos.x - sliceListView.lastMouseX)
            var dy = Math.abs(globalPos.y - sliceListView.lastMouseY)
            if (dx > 2 || dy > 2) {
              sliceListView.lastMouseX = globalPos.x
              sliceListView.lastMouseY = globalPos.y
              sliceListView.keyboardNavActive = false
              sliceListView.currentIndex = index
            }
          }
          onClicked: function(mouse) {
            if (mouse.button === Qt.RightButton) {
              var pos = mapToItem(selectorPanel.contentItem, mouse.x, mouse.y)
              wallpaperSelector.contextMenuName = model.name
              wallpaperSelector.contextMenuType = model.type
              wallpaperSelector.contextMenuWeId = model.weId || ""
              wallpaperSelector.contextMenuPath = model.path || ""
              wallpaperSelector.contextMenuX = pos.x
              wallpaperSelector.contextMenuY = pos.y
              wallpaperSelector.contextMenuVisible = true
            } else {

              if (delegateItem.isCurrent) {
                if (model.type === "we") {
                  service.applyWE(model.weId)
                } else if (model.type === "video") {
                  service.applyVideo(model.path)
                } else {
                  service.applyStatic(model.path)
                }
              } else {
                sliceListView.currentIndex = index
              }
            }
          }
        }
    }
    }

    // Dismiss overlay (behind context menu, above everything else)
    MouseArea {
      anchors.fill: parent
      visible: wallpaperSelector.contextMenuVisible
      z: 199
      onClicked: wallpaperSelector.contextMenuVisible = false
    }

    // Right-click context menu (delete, view on Steam)
    Rectangle {
      id: contextMenu
      visible: wallpaperSelector.contextMenuVisible
      x: Math.min(wallpaperSelector.contextMenuX, parent.width - width - 10)
      y: Math.min(wallpaperSelector.contextMenuY, parent.height - height - 10)
      width: 220
      height: contextMenuColumn.height + 16
      radius: 12
      color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.surfaceContainer.r, wallpaperSelector.colors.surfaceContainer.g, wallpaperSelector.colors.surfaceContainer.b, 0.95) : "#2a2a2a"
      border.width: 1
      border.color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.3) : Qt.rgba(1, 1, 1, 0.15)
      z: 200

      MouseArea {
        anchors.fill: parent
      }

      Column {
        id: contextMenuColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 8
        spacing: 4

        Text {
          width: parent.width
          text: wallpaperSelector.contextMenuName.toUpperCase()
          color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
          font.family: Style.fontFamily
          font.pixelSize: 13
          font.weight: Font.Bold
          font.letterSpacing: 0.5
          elide: Text.ElideMiddle
          horizontalAlignment: Text.AlignLeft
          leftPadding: 8
          topPadding: 4
          bottomPadding: 8
        }

        Rectangle {
          width: parent.width; height: 1
          color: Qt.rgba(1, 1, 1, 0.1)
        }

        Rectangle {
          width: parent.width; height: 36
          color: deleteHover.containsMouse ? Qt.rgba(wallpaperSelector.colors ? wallpaperSelector.colors.primary.r : 1, wallpaperSelector.colors ? wallpaperSelector.colors.primary.g : 0.3, wallpaperSelector.colors ? wallpaperSelector.colors.primary.b : 0.3, 0.2) : "transparent"
          border.width: deleteHover.containsMouse ? 1 : 0
          border.color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
          Behavior on color { ColorAnimation { duration: 100 } }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            spacing: 10
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "🗑"; font.pixelSize: 14
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "DELETE LOCALLY"
              color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
              font.family: Style.fontFamily
              font.pixelSize: 12
              font.weight: Font.Medium
              font.letterSpacing: 0.5
            }
          }

          MouseArea {
            id: deleteHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              service.deleteWallpaperItem(
                wallpaperSelector.contextMenuType,
                wallpaperSelector.contextMenuName,
                wallpaperSelector.contextMenuWeId
              )
              wallpaperSelector.contextMenuVisible = false
            }
          }
        }

        Rectangle {
          visible: wallpaperSelector.contextMenuType === "we"
          width: parent.width; height: 36
          color: unsubHover.containsMouse ? Qt.rgba(wallpaperSelector.colors ? wallpaperSelector.colors.primary.r : 1, wallpaperSelector.colors ? wallpaperSelector.colors.primary.g : 0.5, wallpaperSelector.colors ? wallpaperSelector.colors.primary.b : 0, 0.2) : "transparent"
          border.width: unsubHover.containsMouse ? 1 : 0
          border.color: wallpaperSelector.colors ? Qt.rgba(wallpaperSelector.colors.primary.r, wallpaperSelector.colors.primary.g, wallpaperSelector.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2)
          Behavior on color { ColorAnimation { duration: 100 } }

          Row {
            anchors.fill: parent
            anchors.leftMargin: 8
            spacing: 10
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "☁"; font.pixelSize: 14
            }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: "VIEW ON STEAM"
              color: wallpaperSelector.colors ? wallpaperSelector.colors.tertiary : "#8bceff"
              font.family: Style.fontFamily
              font.pixelSize: 12
              font.weight: Font.Medium
              font.letterSpacing: 0.5
            }
          }

          MouseArea {
            id: unsubHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              service.openSteamPage(wallpaperSelector.contextMenuWeId)
              wallpaperSelector.contextMenuVisible = false
            }
          }
        }
      }
    }

  }
}

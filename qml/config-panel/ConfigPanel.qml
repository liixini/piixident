import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Shapes
import ".."

Scope {
  id: configPanel

  property var colors
  property bool showing: false
  property string mainMonitor: Config.mainMonitor

  property int currentSection: 0
  property var sections: [
    { icon: "󰒓", label: "GENERAL" },
    { icon: "󰎛", label: "BAR" },
    { icon: "󰕰", label: "COMPONENTS" },
    { icon: "󰌹", label: "INTEGRATIONS" },
    { icon: "󰀻", label: "APPS" },
    { icon: "󰔟", label: "INTERVALS" }
  ]

  property int cardWidth: 1300
  property int cardHeight: 720
  property int topBarHeight: 56
  property int skewOffset: 20
  property bool cardVisible: false
  property bool hasUnsavedChanges: false

  property bool _iconPickerVisible: false
  property string _iconPickerTargetKey: ""

  property bool _fileBrowserVisible: false
  property string _fileBrowserTargetKey: ""
  property string _fileBrowserCurrentDir: ""
  property var _fileBrowserEntries: []

  property var configData: ({})
  property var appsData: ({})
  property var _appKeys: []
  property string _appSearchFilter: ""

  FileView {
    id: configFile
    path: Config.configDir + "/data/config.json"
    preload: true
    watchChanges: true
    onFileChanged: {
      configFile.reload()
      if (!configPanel.hasUnsavedChanges) configPanel._loadConfigData()
    }
  }

  FileView {
    id: appsFile
    path: Config.configDir + "/data/apps.json"
    preload: true
    watchChanges: true
    onFileChanged: {
      appsFile.reload()
      if (!configPanel.hasUnsavedChanges) configPanel._loadAppsData()
    }
  }

  function _loadConfigData() {
    var text = configFile.text().trim()
    if (!text) return
    try {
      configData = JSON.parse(text)
      configDataChanged()
    } catch (e) {
      console.log("ConfigPanel: Failed to parse config.json:", e)
    }
  }

  function _loadAppsData() {
    var text = appsFile.text().trim()
    if (!text) return
    try {
      appsData = JSON.parse(text)
      appsDataChanged()
      _updateAppKeys()
    } catch (e) {
      console.log("ConfigPanel: Failed to parse apps.json:", e)
    }
  }

  function _updateAppKeys() {
    var keys = Object.keys(appsData).filter(function(k) { return !k.startsWith("_") })
    if (JSON.stringify(keys) !== JSON.stringify(_appKeys)) {
      _appKeys = keys
    }
  }

  function _openFileBrowser(appKey) {
    _fileBrowserTargetKey = appKey
    _fileBrowserCurrentDir = Config.homeDir
    _fileBrowserVisible = true
    _fileBrowserListDir(_fileBrowserCurrentDir)
  }

  function _fileBrowserListDir(dir) {
    _fileBrowserCurrentDir = dir
    _fileBrowserEntries = []
    _dirListProcess.command = ["bash", "-c",
      "cd " + JSON.stringify(dir) + " && printf '%s\\n' */ *.{png,jpg,jpeg,webp,gif,bmp,PNG,JPG,JPEG,WEBP,GIF,BMP} 2>/dev/null | sort -f"
    ]
    _dirListProcess.running = true
  }

  function _fileBrowserSelect(path) {
    var home = Config.homeDir
    var display = path
    if (display.startsWith(home)) display = "~" + display.substring(home.length)
    if (!appsData[_fileBrowserTargetKey]) appsData[_fileBrowserTargetKey] = {}
    appsData[_fileBrowserTargetKey].background = display
    hasUnsavedChanges = true
    appsDataChanged()
    _fileBrowserVisible = false
  }

  function openIconPicker(appKey) {
    _iconPickerTargetKey = appKey
    _iconPickerVisible = true
    iconPicker.focusSearch()
  }

  Process {
    id: _dirListProcess
    property string rawOutput: ""
    command: ["bash", "-c", "true"]
    onRunningChanged: if (running) rawOutput = ""
    stdout: SplitParser {
      onRead: line => {
        if (line.trim() !== "" && !line.includes("*")) {
          _dirListProcess.rawOutput += line.trim() + "\n"
        }
      }
    }
    onExited: {
      var lines = _dirListProcess.rawOutput.split("\n").filter(function(l) { return l.length > 0 })
      var entries = []
      entries.push({ name: "..", isDir: true })
      for (var i = 0; i < lines.length; i++) {
        var name = lines[i]
        var isDir = name.endsWith("/")
        if (isDir) name = name.slice(0, -1)
        if (name === "." || name === "..") continue
        entries.push({ name: name, isDir: isDir })
      }
      configPanel._fileBrowserEntries = entries
    }
  }

  function saveAll() {
    try {
      configFile.setText(JSON.stringify(configData, null, 2) + "\n")
      appsFile.setText(JSON.stringify(appsData, null, 2) + "\n")
      hasUnsavedChanges = false
    } catch (e) {
      console.log("ConfigPanel: Failed to save:", e)
    }
  }

  function discardChanges() {
    _loadConfigData()
    _loadAppsData()
    hasUnsavedChanges = false
  }

  function setNested(obj, keys, value) {
    var o = obj
    for (var i = 0; i < keys.length - 1; i++) {
      if (o[keys[i]] === undefined || o[keys[i]] === null || typeof o[keys[i]] !== "object") {
        o[keys[i]] = {}
      }
      o = o[keys[i]]
    }
    o[keys[keys.length - 1]] = value
    hasUnsavedChanges = true
  }

  function getNested(obj, keys, fallback) {
    var o = obj
    for (var i = 0; i < keys.length; i++) {
      if (o === undefined || o === null || typeof o !== "object") return fallback
      o = o[keys[i]]
    }
    return (o !== undefined && o !== null) ? o : fallback
  }

  onShowingChanged: {
    if (showing) {
      _loadConfigData()
      _loadAppsData()
      cardShowTimer.restart()
    } else {
      cardVisible = false
    }
  }

  Timer {
    id: cardShowTimer
    interval: 50
    onTriggered: configPanel.cardVisible = true
  }

  Timer {
    id: focusTimer
    interval: 50
    onTriggered: panelContent.forceActiveFocus()
  }

  PanelWindow {
    id: panelWindow

    screen: Quickshell.screens.find(s => s.name === configPanel.mainMonitor) ?? Quickshell.screens[0]

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

    visible: configPanel.showing
    color: "transparent"

    WlrLayershell.namespace: "config-panel"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: configPanel.showing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Qt.rgba(0, 0, 0, 0.5)
      opacity: configPanel.cardVisible ? 1 : 0
      Behavior on opacity { NumberAnimation { duration: 300 } }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {
        if (configPanel.hasUnsavedChanges) return
        configPanel.showing = false
      }
    }

    Item {
      id: cardContainer
      width: configPanel.cardWidth
      height: configPanel.cardHeight
      anchors.centerIn: parent
      visible: configPanel.cardVisible

      opacity: 0
      property bool animateIn: configPanel.cardVisible

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

      Rectangle {
        anchors.fill: parent
        radius: 20
        color: configPanel.colors ? Qt.rgba(configPanel.colors.surface.r, configPanel.colors.surface.g, configPanel.colors.surface.b, 0.88) : Qt.rgba(0.1, 0.06, 0.05, 0.88)
        border.width: 1
        border.color: configPanel.colors ? Qt.rgba(configPanel.colors.primary.r, configPanel.colors.primary.g, configPanel.colors.primary.b, 0.15) : Qt.rgba(1, 1, 1, 0.1)
      }

      Row {
        id: tabRow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 14
        spacing: -configPanel.skewOffset
        z: 11

        Repeater {
          model: configPanel.sections

          Item {
            width: tabCanvas.width
            height: 34
            z: isSelected ? 10 : (isHovered ? 5 : 1)
            property bool isSelected: configPanel.currentSection === index
            property bool isHovered: tabMouse.containsMouse

            Canvas {
              id: tabCanvas
              anchors.centerIn: parent
              width: tabLabel.implicitWidth + 52 + configPanel.skewOffset
              height: 30

              property color fillColor: parent.isSelected
                ? (configPanel.colors ? configPanel.colors.primary : "#4fc3f7")
                : (parent.isHovered
                  ? (configPanel.colors ? Qt.rgba(configPanel.colors.surfaceVariant.r, configPanel.colors.surfaceVariant.g, configPanel.colors.surfaceVariant.b, 0.5) : Qt.rgba(1, 1, 1, 0.15))
                  : (configPanel.colors ? Qt.rgba(configPanel.colors.surfaceContainer.r, configPanel.colors.surfaceContainer.g, configPanel.colors.surfaceContainer.b, 0.7) : Qt.rgba(0.1, 0.12, 0.18, 0.7)))
              property color strokeColor: parent.isSelected
                ? (configPanel.colors ? Qt.rgba(configPanel.colors.primary.r, configPanel.colors.primary.g, configPanel.colors.primary.b, 0.6) : Qt.rgba(1, 1, 1, 0.3))
                : (parent.isHovered
                  ? (configPanel.colors ? Qt.rgba(configPanel.colors.primary.r, configPanel.colors.primary.g, configPanel.colors.primary.b, 0.4) : Qt.rgba(1, 1, 1, 0.2))
                  : (configPanel.colors ? Qt.rgba(configPanel.colors.outline.r, configPanel.colors.outline.g, configPanel.colors.outline.b, 0.2) : Qt.rgba(1, 1, 1, 0.08)))

              onFillColorChanged: requestPaint()
              onStrokeColorChanged: requestPaint()
              onWidthChanged: requestPaint()

              onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var sk = configPanel.skewOffset
                ctx.globalAlpha = 1.0
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

            Row {
              id: tabLabel
              anchors.centerIn: tabCanvas
              spacing: 8

              Text {
                text: modelData.icon
                font.family: Style.fontFamilyNerdIcons
                font.pixelSize: 14
                color: parent.parent.isSelected
                  ? (configPanel.colors ? configPanel.colors.primaryText : "#000")
                  : (configPanel.colors ? configPanel.colors.tertiary : "#8bceff")
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: modelData.label
                font.family: Style.fontFamily
                font.pixelSize: 11
                font.weight: Font.Bold
                font.letterSpacing: 0.5
                color: parent.parent.isSelected
                  ? (configPanel.colors ? configPanel.colors.primaryText : "#000")
                  : (configPanel.colors ? configPanel.colors.tertiary : "#8bceff")
                anchors.verticalCenter: parent.verticalCenter
              }
            }

            MouseArea {
              id: tabMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: configPanel.currentSection = index
            }
          }
        }
      }

      Text {
        text: "● UNSAVED"
        font.family: Style.fontFamily
        font.pixelSize: 10
        font.weight: Font.Medium
        font.letterSpacing: 0.5
        color: configPanel.colors ? configPanel.colors.error : "#ff6b6b"
        visible: configPanel.hasUnsavedChanges
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 24
        z: 12
      }

      Item {
        id: panelContent
        anchors.top: parent.top
        anchors.topMargin: configPanel.topBarHeight + 12
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: footerBar.top
        anchors.leftMargin: 30
        anchors.rightMargin: 30
        anchors.bottomMargin: 8

        focus: configPanel.showing
        Keys.onEscapePressed: {
          if (configPanel._fileBrowserVisible) {
            configPanel._fileBrowserVisible = false
          } else if (configPanel._iconPickerVisible) {
            configPanel._iconPickerVisible = false
          } else {
            configPanel.showing = false
          }
        }

        Flickable {
          id: contentFlickable
          anchors.fill: parent
          contentWidth: width
          contentHeight: contentColumn.implicitHeight + 20
          clip: true
          flickableDirection: Flickable.VerticalFlick
          boundsBehavior: Flickable.StopAtBounds

          Column {
            id: contentColumn
            width: parent.width - 20
            spacing: 10

            ConfigGeneralSection {
              width: parent.width
              visible: configPanel.currentSection === 0
              panel: configPanel
              colors: configPanel.colors
            }

            ConfigBarSection {
              width: parent.width
              visible: configPanel.currentSection === 1
              panel: configPanel
              colors: configPanel.colors
            }

            ConfigComponentsSection {
              width: parent.width
              visible: configPanel.currentSection === 2
              panel: configPanel
              colors: configPanel.colors
            }

            ConfigIntegrationsSection {
              width: parent.width
              visible: configPanel.currentSection === 3
              panel: configPanel
              colors: configPanel.colors
            }

            ConfigAppsSection {
              width: parent.width
              visible: configPanel.currentSection === 4
              panel: configPanel
              colors: configPanel.colors
            }

            ConfigIntervalsSection {
              width: parent.width
              visible: configPanel.currentSection === 5
              panel: configPanel
              colors: configPanel.colors
            }
          }
        }

        Rectangle {
          visible: contentFlickable.contentHeight > contentFlickable.height
          anchors.right: parent.right
          anchors.rightMargin: 2
          y: contentFlickable.visibleArea.yPosition * contentFlickable.height
          width: 4
          height: Math.max(20, contentFlickable.visibleArea.heightRatio * contentFlickable.height)
          radius: 2
          color: configPanel.colors ? configPanel.colors.primary : "#fff"
          opacity: 0.5
          z: 100
        }
      }

      ConfigFooter {
        id: footerBar
        panel: configPanel
        colors: configPanel.colors
      }

      ConfigIconPicker {
        id: iconPicker
        panel: configPanel
        colors: configPanel.colors
      }

      ConfigFileBrowser {
        panel: configPanel
        colors: configPanel.colors
      }
    }
  }
}

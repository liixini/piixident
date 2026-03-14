// Imports
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import Quickshell.Widgets
import Quickshell.Bluetooth
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import Qt.labs.platform
import "qml"
import "qml/bar"

ShellRoot {
  id: root

  property string homeDir: Config.homeDir

  // IPC command listener (reads from FIFO pipe)
  // Supports: lock, powermenu, launcher, toggleBar, wallpaper,
  //   smarthome, switcherOpen/Next/Prev/Confirm/Cancel/Close,
  //   notifications
  Process {
    id: ipcListener
    running: true
    command: [Config.scriptsDir + "/bash/ipc-listener"]
    onExited: ipcRestartTimer.start()
    stdout: SplitParser {
      onRead: message => {
        var cmd = message.trim()
        console.log("IPC received:", cmd)
        if (cmd === "lock") {
          if (root.lockscreenInstance) root.lockscreenInstance.showing = true
        } else if (cmd === "powermenu") {
          if (root.powerMenuInstance) root.powerMenuInstance.showing = !root.powerMenuInstance.showing
        } else if (cmd === "launcher" || cmd === "applauncher") {
          if (root.appLauncherInstance) root.appLauncherInstance.showing = !root.appLauncherInstance.showing
        } else if (cmd === "toggleBar") {
          root.barVisible = !root.barVisible
        } else if (cmd === "wallpaper") {
          if (root.wallpaperSelectorInstance) {
            if (!root.wallpaperSelectorInstance.showing) {
              root.wallpaperSelectorInstance.selectedColorFilter = -1
              root.wallpaperSelectorInstance.resetScroll()
            }
            root.wallpaperSelectorInstance.showing = !root.wallpaperSelectorInstance.showing
          }
        } else if (cmd === "smarthome") {
          if (root.smartHomeInstance) root.smartHomeInstance.toggle()
        } else if (cmd === "switcherOpen") {
          if (root.windowSwitcherInstance) root.windowSwitcherInstance.open()
        } else if (cmd === "switcherNext") {
          if (root.windowSwitcherInstance) {
            if (!root.windowSwitcherInstance.showing) {
              root.windowSwitcherInstance.open()
            } else {
              root.windowSwitcherInstance.next()
            }
          }
        } else if (cmd === "switcherPrev") {
          if (root.windowSwitcherInstance) {
            if (!root.windowSwitcherInstance.showing) {
              root.windowSwitcherInstance.open()
            } else {
              root.windowSwitcherInstance.prev()
            }
          }
        } else if (cmd === "switcherConfirm") {
          if (root.windowSwitcherInstance) root.windowSwitcherInstance.confirm()
        } else if (cmd === "switcherCancel") {
          if (root.windowSwitcherInstance) root.windowSwitcherInstance.cancel()
        } else if (cmd === "switcherClose") {
          if (root.windowSwitcherInstance) root.windowSwitcherInstance.closeSelected()
        } else if (cmd === "notifications") {
          if (root.notificationInstance) root.notificationInstance.toggleCenter()
        }
      }
    }
  }

  // IPC auto-restart (reconnect after 1s if pipe closes)
  Timer {
    id: ipcRestartTimer
    interval: 1000
    onTriggered: ipcListener.running = true
  }

  // Notification server
  NotificationServer {
    id: notificationServer
    bodySupported: true
    bodyMarkupSupported: true
    imageSupported: true
    actionsSupported: true
    keepOnReload: true

    onNotification: notification => {

      var app = (notification.appName || "").toLowerCase()
      var summary = (notification.summary || "").toLowerCase()
      if ((app === "niri" || app === "hyprland" || app === "sway") && summary.indexOf("screenshot") !== -1) {
        notification.dismiss()
        return
      }
      notification.tracked = true
    }
  }


  // Tracked notification state
  property var notifications: notificationServer.trackedNotifications
  property int notificationCount: notifications ? notifications.values.length : 0
  property bool hasNotifications: notificationCount > 0

  // Color theme (loaded from matugen-generated palette)
  Colors {
    id: colors
  }


  // MPRIS music player detection - uses preferred player if active
  property var activePlayer: {
    if (!Mpris.players) return null
    let preferredPlaying = null
    let preferredAny = null
    let fallbackPlaying = null
    let fallbackAny = null
    for (let i = 0; i < Mpris.players.values.length; i++) {
      let player = Mpris.players.values[i]
      if (!player) continue
      let id = (player.identity || "").toLowerCase()

      let preferred = Config.preferredPlayer.toLowerCase()
      if (id.includes(preferred)) {
        if (player.isPlaying) preferredPlaying = player
        else if (!preferredAny) preferredAny = player
      }

      if (player.isPlaying && !fallbackPlaying) fallbackPlaying = player
      if (!fallbackAny) fallbackAny = player
    }

    return preferredPlaying || fallbackPlaying || preferredAny || fallbackAny
  }


  // Bar appearance
  property color barBackground: Qt.rgba(colors.background.r, colors.background.g, colors.background.b, 0.4)
  property color pillBackground: Qt.rgba(colors.surfaceVariant.r, colors.surfaceVariant.g, colors.surfaceVariant.b, 0.4)

  // Bar visibility state (persisted to cache file)
  property bool barVisible: true
  property bool stateLoaded: false

  FileView {
    id: barStateFile
    path: Config.cacheDir + "/bar-state"
    preload: true
    onFileChanged: {
      if (!root.stateLoaded) {
        var text = barStateFile.text().trim()
        if (text) root.barVisible = (text === "true")
        root.stateLoaded = true
      }
    }
  }


  // Load saved bar state on startup
  Component.onCompleted: {
    var text = barStateFile.text().trim()
    if (text) {
      root.barVisible = (text === "true")
      root.stateLoaded = true
    }
  }

  // Persist bar state on change
  onBarVisibleChanged: {
    if (root.stateLoaded) {
      barStateFile.setText(root.barVisible ? "true" : "false")
    }
  }

  // Lazy-loaded UI components (activated by Config flags)
  Loader {
    id: wallpaperSelectorLoader
    active: Config.wallpaperSelectorEnabled
    source: "qml/wallpaper/WallpaperSelector.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: appLauncherLoader
    active: Config.appLauncherEnabled
    source: "qml/launcher/AppLauncher.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: lockscreenLoader
    active: Config.lockscreenEnabled
    source: "qml/lock/Lockscreen.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: powerMenuLoader
    active: Config.powerMenuEnabled
    source: "qml/power/PowerMenu.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: windowSwitcherLoader
    active: Config.windowSwitcherEnabled
    source: "qml/switcher/WindowSwitcher.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: smartHomeLoader
    active: Config.smartHomeEnabled
    source: "qml/smarthome/SmartHome.qml"
    onLoaded: item.colors = Qt.binding(() => colors)
  }

  Loader {
    id: notificationLoader
    active: Config.notificationsEnabled
    source: "qml/notifications/NotificationPopup.qml"
    onLoaded: {
      item.colors = Qt.binding(() => colors)
      item.notifications = Qt.binding(() => root.notifications)
      item.barVisible = Qt.binding(() => root.barVisible)
    }
  }

  // Component instance references (null until loaded)
  property var wallpaperSelectorInstance: wallpaperSelectorLoader.item ?? null
  property var appLauncherInstance: appLauncherLoader.item ?? null
  property var lockscreenInstance: lockscreenLoader.item ?? null
  property var powerMenuInstance: powerMenuLoader.item ?? null
  property var windowSwitcherInstance: windowSwitcherLoader.item ?? null
  property var smartHomeInstance: smartHomeLoader.item ?? null
  property var notificationInstance: notificationLoader.item ?? null

  // System clock and audio sink tracking
  SystemClock {
    id: clock
    precision: SystemClock.Seconds
  }

  PwObjectTracker {
    objects: [Pipewire.defaultAudioSink]
  }


  // System stats (single long-running process)
  // Format: cpu:N|mem:N|gpu:N|ct:N|gt:N|st:USAGE|USED|TOTAL|AVAIL
  property real cpuUsage: 0
  property real memUsage: 0
  property real gpuUsage: 0
  property real cpuTemp: 0
  property real gpuTemp: 0
  property real storageUsage: 0
  property string storageUsed: "0G"
  property string storageTotal: "0G"
  property string storageAvail: "0G"

  Process {
    id: sysStatsProcess
    command: [Config.scriptsDir + "/bash/system-stats"]
    running: Config.barEnabled
    onExited: sysStatsRestart.start()
    stdout: SplitParser {
      onRead: line => {

        var parts = line.trim().split("|")
        for (var i = 0; i < parts.length; i++) {
          var kv = parts[i].split(":")
          if (kv.length < 2) continue
          var key = kv[0]
          var val = kv.slice(1).join(":")
          if (key === "cpu") root.cpuUsage = parseFloat(val) || 0
          else if (key === "mem") root.memUsage = parseFloat(val) || 0
          else if (key === "gpu") root.gpuUsage = parseFloat(val) || 0
          else if (key === "ct") root.cpuTemp = parseFloat(val) || 0
          else if (key === "gt") root.gpuTemp = parseFloat(val) || 0
          else if (key === "st") {

            root.storageUsage = parseFloat(val) || 0
            if (i + 1 < parts.length) root.storageUsed = parts[i + 1] || "0G"
            if (i + 2 < parts.length) root.storageTotal = parts[i + 2] || "0G"
            if (i + 3 < parts.length) root.storageAvail = parts[i + 3] || "0G"
            break
          }
        }
      }
    }
  }
  Timer {
    id: sysStatsRestart
    interval: 2000
    onTriggered: sysStatsProcess.running = true
  }


  // Workspace/window event stream (niri IPC subscription)
  property var wmWorkspaces: []
  property int wmActiveWorkspace: 0

  Process {
    id: wmEventStream
    command: [Config.scriptsDir + "/bash/wm-action", "event-stream"]
    running: true
    onExited: wmRestart.start()
    stdout: SplitParser {
      onRead: line => {
        try {
          var ev = JSON.parse(line)

          if (ev.WorkspacesChanged) {
            var wsList = ev.WorkspacesChanged.workspaces

            var screenName = Config.mainMonitor
            var workspaces = []
            var activeWs = 0
            for (var i = 0; i < wsList.length; i++) {
              var ws = wsList[i]
              if (ws.output === screenName) {
                workspaces.push({ id: ws.id, idx: ws.idx, windows: 0 })
                if (ws.is_active) activeWs = ws.id
              }
            }

            if (root._wmWindows) {
              for (var w = 0; w < root._wmWindows.length; w++) {
                var wid = root._wmWindows[w].workspace_id
                for (var j = 0; j < workspaces.length; j++) {
                  if (workspaces[j].id === wid) {
                    workspaces[j].windows++
                    break
                  }
                }
              }
            }
            root.wmWorkspaces = workspaces
            root.wmActiveWorkspace = activeWs
          }

          if (ev.WindowsChanged) {
            root._wmWindows = ev.WindowsChanged.windows

            var updated = root.wmWorkspaces.slice()
            for (var k = 0; k < updated.length; k++) updated[k] = Object.assign({}, updated[k], { windows: 0 })
            for (var m = 0; m < root._wmWindows.length; m++) {
              var wsId = root._wmWindows[m].workspace_id
              for (var n = 0; n < updated.length; n++) {
                if (updated[n].id === wsId) { updated[n].windows++; break }
              }
            }
            root.wmWorkspaces = updated
          }

          if (ev.WindowOpenedOrChanged) {
            var win = ev.WindowOpenedOrChanged.window
            if (root._wmWindows) {
              var found = false
              var newList = []
              for (var p = 0; p < root._wmWindows.length; p++) {
                if (root._wmWindows[p].id === win.id) {
                  newList.push(win)
                  found = true
                } else {
                  newList.push(root._wmWindows[p])
                }
              }
              if (!found) newList.push(win)
              root._wmWindows = newList
              root._recountWindows()
            }
          }

          if (ev.WindowClosed) {
            var closedId = ev.WindowClosed.id
            if (root._wmWindows) {
              root._wmWindows = root._wmWindows.filter(function(w) { return w.id !== closedId })
              root._recountWindows()
            }
          }
        } catch (e) {

        }
      }
    }
  }
  Timer {
    id: wmRestart
    interval: 2000
    onTriggered: wmEventStream.running = true
  }

  // Internal window cache (recount windows per workspace)
  property var _wmWindows: []
  function _recountWindows() {
    var updated = wmWorkspaces.slice()
    for (var i = 0; i < updated.length; i++)
      updated[i] = Object.assign({}, updated[i], { windows: 0 })
    for (var j = 0; j < _wmWindows.length; j++) {
      var wsId = _wmWindows[j].workspace_id
      for (var k = 0; k < updated.length; k++) {
        if (updated[k].id === wsId) { updated[k].windows++; break }
      }
    }
    wmWorkspaces = updated
  }


  // Weather data (fetched from wttr.in)
  property string weatherCity: Config.weatherCity
  property string weatherTemp: "--"
  property string weatherDesc: ""
  property var weatherForecast: []
  property var weatherParts: []

  Process {
    id: weatherProcess
    command: ["curl", "-s", "wttr.in/" + root.weatherCity + "?format=j1"]
    running: Config.weatherEnabled
    onRunningChanged: {
      if (running) root.weatherParts = []
    }
    onExited: {
      weatherTimer.start()
      if (root.weatherParts.length === 0) return

      try {
        let json = JSON.parse(root.weatherParts.join(""))

        if (json.current_condition && json.current_condition[0]) {
          let curr = json.current_condition[0]
          root.weatherTemp = curr.temp_C + "°"
          root.weatherDesc = curr.weatherDesc[0].value
        }

        if (json.weather) {
          let forecast = []
          for (let i = 0; i < Math.min(3, json.weather.length); i++) {
            let day = json.weather[i]
            let date = new Date(day.date)
            let dayName = i === 0 ? "Today" : date.toLocaleDateString('en-US', {weekday: 'short'})
            forecast.push({
              day: dayName,
              high: day.maxtempC + "°",
              low: day.mintempC + "°",
              desc: day.hourly[4].weatherDesc[0].value.trim()
            })
          }
          root.weatherForecast = forecast
        }
      } catch (e) {
        console.log("Weather parse error:", e)
      }
    }
    stdout: SplitParser {
      splitMarker: ""
      onRead: data => {
        root.weatherParts.push(data)
      }
    }
  }
  Timer {
    id: weatherTimer
    interval: Config.weatherPollMs
    onTriggered: weatherProcess.running = true
  }


  // Top bar instantiation
  property string barTheme: "minimal"

  TopBar {
    id: minimalBar
    visible: Config.barEnabled && root.barTheme === "minimal" && !(root.lockscreenInstance && root.lockscreenInstance.showing)
    colors: colors
    clock: clock
    barVisible: root.barVisible
    activePlayer: root.activePlayer
    cpuUsage: root.cpuUsage
    memUsage: root.memUsage
    gpuUsage: root.gpuUsage
    cpuTemp: root.cpuTemp
    gpuTemp: root.gpuTemp
    weatherDesc: root.weatherDesc
    weatherTemp: root.weatherTemp
    weatherCity: root.weatherCity
    weatherForecast: root.weatherForecast
  }
}

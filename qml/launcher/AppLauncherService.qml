import Quickshell.Io
import QtQuick

QtObject {
  id: service

  // External bindings
  required property string scriptsDir
  required property string homeDir
  required property string cacheDir
  required property string configDir
  required property string terminal

  property string cacheFile: cacheDir + "/app-launcher/list.jsonl"

  // Search and filter state
  property string searchText: ""
  property string sourceFilter: ""

  // Cache loading state
  property bool cacheLoading: false
  property int cacheProgress: 0
  property int cacheTotal: 0

  // Data models
  property var appModel: ListModel {}
  property var filteredModel: ListModel {}

  // Signals to view for scroll management
  signal modelUpdated()

  // Frequency-based search ranking
  property string freqCachePath: cacheDir + "/app-launcher/freq.json"
  property var freqData: ({})

  property var _freqFile: FileView {
    path: service.freqCachePath
    preload: true
  }

  function loadFreqData() {
    try {
      service.freqData = JSON.parse(_freqFile.text())
    } catch (e) {
      service.freqData = {}
    }
  }

  function saveFreqData() {
    _freqFile.setText(JSON.stringify(freqData))
  }

  function recordSelection(appName) {
    var query = searchText.toLowerCase().trim()
    if (query === "") return

    var fd = freqData
    for (var len = 2; len <= query.length; len++) {
      var prefix = query.substring(0, len)
      if (!fd[prefix]) fd[prefix] = {}
      if (!fd[prefix][appName]) fd[prefix][appName] = 0
      fd[prefix][appName] += 1
    }
    freqData = fd
    saveFreqData()
  }

  function getFreqScore(appName) {
    var query = searchText.toLowerCase().trim()
    if (query === "" || !freqData[query]) return 0
    return freqData[query][appName] || 0
  }

  // Filter apps by search text and source, sort by frequency score
  function updateFilteredModel() {
    var query = searchText.toLowerCase()
    var sf = sourceFilter
    var results = []
    for (var i = 0; i < appModel.count; i++) {
      var item = appModel.get(i)
      if (item.hidden) continue
      if (query !== "" &&
          item.name.toLowerCase().indexOf(query) === -1 &&
          item.categories.toLowerCase().indexOf(query) === -1 &&
          item.displayName.toLowerCase().indexOf(query) === -1 &&
          item.tags.toLowerCase().indexOf(query) === -1)
        continue
      if (sf === "steam" && item.source !== "steam") continue
      if (sf === "desktop" && item.source !== "desktop") continue
      if (sf === "game" && item.categories.indexOf("Game") === -1) continue
      results.push({
        name: item.name,
        exec: item.exec,
        icon: item.icon,
        thumb: item.thumb,
        iconPath: item.iconPath,
        categories: item.categories,
        source: item.source,
        steamAppId: item.steamAppId,
        terminal: item.terminal,
        background: item.background,
        customIcon: item.customIcon,
        displayName: item.displayName,
        tags: item.tags
      })
    }

    if (query !== "") {
      var freqMap = freqData[query] || {}
      results.sort(function(a, b) {
        var freqA = freqMap[a.name] || 0
        var freqB = freqMap[b.name] || 0
        if (freqA !== freqB) return freqB - freqA
        return a.name.toLowerCase().localeCompare(b.name.toLowerCase())
      })
    }

    if (results.length === filteredModel.count) {
      var same = true
      for (var k = 0; k < results.length; k++) {
        if (results[k].name !== filteredModel.get(k).name) {
          same = false
          break
        }
      }
      if (same) {
        for (var u = 0; u < results.length; u++) {
          var r = results[u]
          var f = filteredModel.get(u)
          if (f.background !== r.background) filteredModel.setProperty(u, "background", r.background)
          if (f.displayName !== r.displayName) filteredModel.setProperty(u, "displayName", r.displayName)
          if (f.customIcon !== r.customIcon) filteredModel.setProperty(u, "customIcon", r.customIcon)
          if (f.thumb !== r.thumb) filteredModel.setProperty(u, "thumb", r.thumb)
          if (f.tags !== r.tags) filteredModel.setProperty(u, "tags", r.tags)
        }
        return
      }
    }

    filteredModel.clear()
    for (var j = 0; j < results.length; j++) {
      filteredModel.append(results[j])
    }
    modelUpdated()
  }

  onSearchTextChanged: updateFilteredModel()
  onSourceFilterChanged: updateFilteredModel()

  // Launch an app, record selection for search ranking
  property var _appRunner: Process { command: ["true"] }

  function launchApp(appExec, isTerminal, appName) {
    if (appName) recordSelection(appName)
    var cmd = appExec
    if (isTerminal) cmd = service.terminal + " " + cmd
    _appRunner.command = ["setsid", "-f", "sh", "-c", cmd]
    _appRunner.running = true
  }

  // Cache builder process
  property var _buildCache: Process {
    id: buildCache
    command: ["python3", service.scriptsDir + "/python/build-app-cache"]
    running: false
    onRunningChanged: {
      if (running) {
        service.cacheLoading = true
        service.cacheProgress = 0
        service.cacheTotal = 0
      }
    }
    stdout: SplitParser {
      onRead: line => {
        if (line.startsWith("progress:")) {
          const parts = line.split(":")
          if (parts.length === 3) {
            service.cacheProgress = parseInt(parts[1])
            service.cacheTotal = parseInt(parts[2])
          }
        }
      }
    }
    onExited: {
      service.cacheLoading = false
      service.appModel.clear()
      loadApps.running = true
    }
  }

  // JSONL cache loader process
  property var _loadApps: Process {
    id: loadApps
    command: ["bash", "-c",
      "if [ -f '" + service.cacheFile + "' ]; then cat '" + service.cacheFile + "'; fi"
    ]
    running: false
    onRunningChanged: {
      if (!running) {
        service.updateFilteredModel()
      }
    }
    stdout: SplitParser {
      onRead: line => {
        try {
          var obj = JSON.parse(line)
          service.appModel.append({
            name: obj.name || "",
            exec: obj.exec || "",
            icon: obj.icon || "",
            thumb: obj.thumb || "",
            iconPath: obj.iconPath || "",
            categories: obj.categories || "",
            source: obj.source || "desktop",
            steamAppId: obj.steamAppId || "",
            terminal: obj.terminal || false,
            background: obj.background || "",
            customIcon: obj.customIcon || "",
            displayName: obj.displayName || "",
            hidden: obj.hidden || false,
            tags: obj.tags || ""
          })
        } catch (e) {}
      }
    }
    onExited: {
      service.updateFilteredModel()
    }
  }

  // Desktop file watcher
  property var _desktopWatcher: Process {
    id: desktopWatcher
    running: true
    command: ["bash", "-c",
      "dirs=(); for d in /usr/share/applications " +
      "\"$HOME/.local/share/applications\" " +
      "/var/lib/flatpak/exports/share/applications " +
      "\"$HOME/.local/share/flatpak/exports/share/applications\"; do " +
      "[ -d \"$d\" ] && dirs+=(\"$d\"); done; " +
      "[ ${#dirs[@]} -eq 0 ] && exit 1; " +
      "exec inotifywait -m -r -e create,delete,modify,moved_to,moved_from " +
      "--include '\\.desktop$' \"${dirs[@]}\""
    ]
    stdout: SplitParser {
      onRead: line => {
        desktopWatcherDebounce.restart()
      }
    }
    onExited: desktopWatcherRestart.start()
  }

  property var _desktopWatcherRestart: Timer {
    id: desktopWatcherRestart
    interval: 5000
    onTriggered: desktopWatcher.running = true
  }

  property var _appsJsonWatcher: FileView {
    path: service.configDir + "/data/apps.json"
    preload: true
    watchChanges: true
    onFileChanged: reload()
    onLoaded: service._applyAppsConfig()
  }

  function _applyAppsConfig() {
    var text = _appsJsonWatcher.text().trim()
    if (!text || appModel.count === 0) return
    try {
      var data = JSON.parse(text)
    } catch (e) { return }

    // Build lookup: lowercase key → config object
    var configMap = {}
    for (var k in data) {
      if (k.startsWith("_")) continue
      var v = data[k]
      if (typeof v === "string")
        configMap[k.toLowerCase()] = v ? { background: v } : {}
      else if (typeof v === "object" && v !== null)
        configMap[k.toLowerCase()] = v
    }

    var home = service.homeDir
    function resolve(p) { return p ? p.replace("~", home) : "" }

    // Patch each model entry in-place
    for (var i = 0; i < appModel.count; i++) {
      var item = appModel.get(i)
      var conf = _findAppConfig(item.name, configMap)
      var bg = resolve(conf.background || "")
      var dn = conf.displayName || ""
      var ci = conf.icon || ""
      var tags = conf.tags || ""
      var hidden = !!conf.hidden

      if (item.background !== bg) appModel.setProperty(i, "background", bg)
      if (item.displayName !== dn) appModel.setProperty(i, "displayName", dn)
      if (item.customIcon !== ci) appModel.setProperty(i, "customIcon", ci)
      if (item.tags !== tags) appModel.setProperty(i, "tags", tags)
      if (item.hidden !== hidden) appModel.setProperty(i, "hidden", hidden)
    }
    updateFilteredModel()
  }
  
  function _findAppConfig(name, configMap) {
    var lower = name.toLowerCase()
    if (configMap[lower]) return configMap[lower]
    for (var key in configMap) {
      if (lower.indexOf(key) !== -1) return configMap[key]
    }
    return {}
  }

  property var _desktopWatcherDebounce: Timer {
    id: desktopWatcherDebounce
    interval: 2000
    onTriggered: {
      if (!buildCache.running) {
        buildCache.running = true
      }
    }
  }

  // Start initial load or rebuild
  function start() {
    if (service.appModel.count === 0) {
      buildCache.running = true
    } else {
      updateFilteredModel()
    }
  }
}

import QtQuick
import ".."

Column {
  id: root
  property var panel
  property var colors
  width: parent.width
  spacing: 8

  ConfigSectionTitle { text: "SHELL COMPONENTS"; colors: root.colors }

  ConfigToggle {
    label: "App launcher"
    checked: panel.getNested(panel.configData, ["components", "appLauncher"], true)
    onToggled: v => { panel.setNested(panel.configData, ["components", "appLauncher"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Wallpaper selector"
    checked: {
      var ws = panel.getNested(panel.configData, ["components", "wallpaperSelector"], undefined)
      return ws !== false && ws?.enabled !== false
    }
    onToggled: v => { panel.setNested(panel.configData, ["components", "wallpaperSelector", "enabled"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Wallpaper color dots"
    checked: panel.getNested(panel.configData, ["components", "wallpaperSelector", "showColorDots"], true)
    onToggled: v => { panel.setNested(panel.configData, ["components", "wallpaperSelector", "showColorDots"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Window switcher"
    checked: panel.getNested(panel.configData, ["components", "windowSwitcher"], true)
    onToggled: v => { panel.setNested(panel.configData, ["components", "windowSwitcher"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Power menu"
    checked: {
      var pm = panel.getNested(panel.configData, ["components", "powerMenu"], undefined)
      return pm !== false && pm?.enabled !== false
    }
    onToggled: v => { panel.setNested(panel.configData, ["components", "powerMenu", "enabled"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Notifications"
    checked: panel.getNested(panel.configData, ["components", "notifications"], true)
    onToggled: v => { panel.setNested(panel.configData, ["components", "notifications"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Lock screen (WIP)"
    checked: panel.getNested(panel.configData, ["components", "lockscreen"], false)
    onToggled: v => { panel.setNested(panel.configData, ["components", "lockscreen"], v); panel.configDataChanged() }
    colors: root.colors
  }
  ConfigToggle {
    label: "Smart home (WIP)"
    checked: panel.getNested(panel.configData, ["components", "smartHome"], false)
    onToggled: v => { panel.setNested(panel.configData, ["components", "smartHome"], v); panel.configDataChanged() }
    colors: root.colors
  }
}

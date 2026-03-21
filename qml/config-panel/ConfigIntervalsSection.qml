import QtQuick
import ".."

Column {
  id: root
  property var panel
  property var colors
  width: parent.width
  spacing: 8

  ConfigSectionTitle { text: "POLLING INTERVALS"; colors: root.colors }

  Repeater {
    model: [
      { key: "weatherPollMs",      label: "Weather poll (ms)",        fallback: 600000 },
      { key: "wifiPollMs",          label: "WiFi poll (ms)",           fallback: 10000 },
      { key: "smartHomePollMs",     label: "Smart home poll (ms)",     fallback: 5000 },
      { key: "ollamaStatusPollMs",  label: "Ollama status poll (ms)",  fallback: 5000 },
      { key: "notificationExpireMs", label: "Notification expire (ms)", fallback: 8000 }
    ]

    ConfigNumberField {
      label: modelData.label
      value: panel.getNested(panel.configData, ["intervals", modelData.key], modelData.fallback)
      onEdited: v => { panel.setNested(panel.configData, ["intervals", modelData.key], v); panel.configDataChanged() }
      colors: root.colors
    }
  }
}

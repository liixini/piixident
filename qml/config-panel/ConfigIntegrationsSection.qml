import QtQuick
import ".."

Column {
  id: root
  property var panel
  property var colors
  width: parent.width
  spacing: 8

  ConfigSectionTitle { text: "THEME INTEGRATIONS"; colors: root.colors }

  Repeater {
    model: [
      { key: "kitty",        label: "Kitty" },
      { key: "kde",          label: "KDE color scheme" },
      { key: "vscode",       label: "VS Code" },
      { key: "vesktop",      label: "Vesktop" },
      { key: "zen",          label: "Zen Browser" },
      { key: "spicetify",    label: "Spicetify color" },
      { key: "spicetifyCss", label: "Spicetify CSS" },
      { key: "yazi",         label: "Yazi" },
      { key: "qt6ct",        label: "Qt6ct" }
    ]

    ConfigTextField {
      label: modelData.label
      value: panel.getNested(panel.configData, ["integrations", modelData.key], "")
      onEdited: v => { panel.setNested(panel.configData, ["integrations", modelData.key], v); panel.configDataChanged() }
      colors: root.colors
    }
  }
}

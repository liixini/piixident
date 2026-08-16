import QtQuick
import Quickshell
import Quickshell.Io


QtObject {
    id: colors

    component Fade: ColorAnimation {
        duration: 180
        easing.type: Easing.InOutQuad
    }

    property bool animate: false


    readonly property string wallCacheDir: Quickshell.env("SKWD_WALL_CACHE")
        || (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/skwd-wall"

    property string colorFilePath: wallCacheDir + "/colors.json"

    property var colorFileView: FileView {
        path: colors.colorFilePath
        watchChanges: true
        preload: true
        onFileChanged: reload()
        onLoaded: colors._applyColors()
    }

    function _applyColors() {
        var text = colorFileView.text().trim()
        if (!text) return
        try {
            var d = JSON.parse(text)
            colors.primary = d.primary ?? "#ffb4ab"
            colors.primaryText = d.primaryText ?? "#690005"
            colors.primaryContainer = d.primaryContainer ?? "#b12723"
            colors.primaryContainerText = d.primaryContainerText ?? "#ffffff"
            colors.primaryForeground = d.onPrimary ?? "#690005"
            colors.secondary = d.secondary ?? "#ffb4ab"
            colors.secondaryText = d.secondaryText ?? "#5b1915"
            colors.secondaryContainer = d.secondaryContainer ?? "#792f29"
            colors.secondaryContainerText = d.secondaryContainerText ?? "#ffd7d2"
            colors.tertiary = d.tertiary ?? "#8bceff"
            colors.tertiaryText = d.tertiaryText ?? "#00344e"
            colors.tertiaryContainer = d.tertiaryContainer ?? "#006390"
            colors.tertiaryContainerText = d.tertiaryContainerText ?? "#ffffff"
            colors.background = d.background ?? "#1d100e"
            colors.backgroundText = d.backgroundText ?? "#f7ddd9"
            colors.surface = d.surface ?? "#1d100e"
            colors.surfaceText = d.surfaceText ?? "#f7ddd9"
            colors.surfaceVariant = d.surfaceVariant ?? "#5a413e"
            colors.surfaceVariantText = d.surfaceVariantText ?? "#e2beba"
            colors.surfaceContainer = d.surfaceContainer ?? "#2c1f1d"
            colors.error = d.error ?? "#ffb4ab"
            colors.errorText = d.errorText ?? "#690005"
            colors.errorContainer = d.errorContainer ?? "#93000a"
            colors.errorContainerText = d.errorContainerText ?? "#ffdad6"
            colors.outline = d.outline ?? "#a98986"
            colors.shadow = d.shadow ?? "#000000"
            colors.inverseSurface = d.inverseSurface ?? "#f7ddd9"
            colors.inverseSurfaceText = d.inverseSurfaceText ?? "#3d2c2b"
            colors.inversePrimary = d.inversePrimary ?? "#b32824"
            colors.animate = true
            console.log("Colors: Loaded colors successfully")
        } catch (e) {
            console.log("Colors: Error parsing colors.json:", e)
        }
    }


    property color primary: "#ffb4ab"
    property color primaryText: "#690005"
    property color primaryContainer: "#b12723"
    property color primaryContainerText: "#ffffff"
    property color primaryForeground: "#690005"

    Behavior on primary { enabled: colors.animate; Fade {} }
    Behavior on primaryText { enabled: colors.animate; Fade {} }
    Behavior on primaryContainer { enabled: colors.animate; Fade {} }
    Behavior on primaryContainerText { enabled: colors.animate; Fade {} }
    Behavior on primaryForeground { enabled: colors.animate; Fade {} }


    property color secondary: "#ffb4ab"
    property color secondaryText: "#5b1915"
    property color secondaryContainer: "#792f29"
    property color secondaryContainerText: "#ffd7d2"

    Behavior on secondary { enabled: colors.animate; Fade {} }
    Behavior on secondaryText { enabled: colors.animate; Fade {} }
    Behavior on secondaryContainer { enabled: colors.animate; Fade {} }
    Behavior on secondaryContainerText { enabled: colors.animate; Fade {} }


    property color tertiary: "#8bceff"
    property color tertiaryText: "#00344e"
    property color tertiaryContainer: "#006390"
    property color tertiaryContainerText: "#ffffff"

    Behavior on tertiary { enabled: colors.animate; Fade {} }
    Behavior on tertiaryText { enabled: colors.animate; Fade {} }
    Behavior on tertiaryContainer { enabled: colors.animate; Fade {} }
    Behavior on tertiaryContainerText { enabled: colors.animate; Fade {} }


    property color background: "#1d100e"
    property color backgroundText: "#f7ddd9"
    property color surface: "#1d100e"
    property color surfaceText: "#f7ddd9"
    property color surfaceVariant: "#5a413e"
    property color surfaceVariantText: "#e2beba"
    property color surfaceContainer: "#2c1f1d"

    Behavior on background { enabled: colors.animate; Fade {} }
    Behavior on backgroundText { enabled: colors.animate; Fade {} }
    Behavior on surface { enabled: colors.animate; Fade {} }
    Behavior on surfaceText { enabled: colors.animate; Fade {} }
    Behavior on surfaceVariant { enabled: colors.animate; Fade {} }
    Behavior on surfaceVariantText { enabled: colors.animate; Fade {} }
    Behavior on surfaceContainer { enabled: colors.animate; Fade {} }


    property color error: "#ffb4ab"
    property color errorText: "#690005"
    property color errorContainer: "#93000a"
    property color errorContainerText: "#ffdad6"

    Behavior on error { enabled: colors.animate; Fade {} }
    Behavior on errorText { enabled: colors.animate; Fade {} }
    Behavior on errorContainer { enabled: colors.animate; Fade {} }
    Behavior on errorContainerText { enabled: colors.animate; Fade {} }


    property color outline: "#a98986"
    property color shadow: "#000000"
    property color inverseSurface: "#f7ddd9"
    property color inverseSurfaceText: "#3d2c2b"
    property color inversePrimary: "#b32824"

    Behavior on outline { enabled: colors.animate; Fade {} }
    Behavior on shadow { enabled: colors.animate; Fade {} }
    Behavior on inverseSurface { enabled: colors.animate; Fade {} }
    Behavior on inverseSurfaceText { enabled: colors.animate; Fade {} }
    Behavior on inversePrimary { enabled: colors.animate; Fade {} }
}

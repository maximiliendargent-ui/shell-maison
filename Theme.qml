// Couleurs (menu/colors.json, généré par Noctalia à partir du fond d'écran), police et courbes partagées
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: theme

    readonly property string font: "Maple Mono NF"
    // Courbes d'animation reprises de zanlior/saneaspect-quickshellbar
    readonly property var openCurve: [.05, .9, .1, 1.02, 1, 1]
    readonly property var closeCurve: [.4, 0, .2, 1, 1, 1]

    property var c: ({
        surface: "#1b211f", surface_container: "#252b2a", surface_container_high: "#303634",
        surface_container_highest: "#3a403e", on_surface: "#dde4e1", on_surface_variant: "#bec9c5",
        primary: "#83d5c6", on_primary: "#003731", outline: "#899390", outline_variant: "#3f4946",
        error: "#ffb4ab", on_error: "#690005"
    })

    FileView {
        path: Quickshell.env("HOME") + "/.config/quickshell/menu/colors.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try { theme.c = Object.assign({}, theme.c, JSON.parse(text())) } catch (e) {}
        }
    }

    // Codes météo WMO → icône (Nerd Font) et texte
    function weather(code, day) {
        if (code === 0) return day ? ["\u{f0599}", "Ciel dégagé"] : ["\u{f0594}", "Ciel dégagé"]
        if (code <= 2) return day ? ["\u{f0595}", "Peu nuageux"] : ["\u{f0f31}", "Peu nuageux"]
        if (code === 3) return ["\u{f0590}", "Couvert"]
        if (code <= 48) return ["\u{f0591}", "Brouillard"]
        if (code <= 57) return ["\u{f0597}", "Bruine"]
        if (code <= 67 || (code >= 80 && code <= 82)) return ["\u{f0596}", "Pluie"]
        if (code <= 77 || code === 85 || code === 86) return ["\u{f0598}", "Neige"]
        return ["\u{f0593}", "Orage"]
    }
}

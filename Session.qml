// Onglet Session : verrouiller, veille, déconnexion, redémarrer, Windows, éteindre.
// Les actions qui ferment la session demandent un second clic (la tuile passe en rouge 3 s).
import QtQuick
import Quickshell

Grid {
    id: session
    columns: 3
    spacing: 10
    readonly property real cell: (width - 20) / 3
    property string armed: ""  // action en attente de confirmation
    Timer { id: disarm; interval: 3000; onTriggered: session.armed = "" }

    Repeater {
        model: [
            { id: "lock", icon: "\u{f033e}", label: "Verrouiller", cmd: ["qs", "-c", "shell-maison", "ipc", "call", "lock", "lock"] },
            { id: "sleep", icon: "\u{f04b2}", label: "Veille", cmd: ["systemctl", "suspend-then-hibernate"] },
            { id: "logout", icon: "\u{f0343}", label: "Déconnexion", cmd: ["sh", "-c", "uwsm check is-active && exec uwsm stop; exec loginctl terminate-session \"$XDG_SESSION_ID\""], confirm: true },
            { id: "reboot", icon: "\u{f0709}", label: "Redémarrer", cmd: ["systemctl", "reboot"], confirm: true },
            { id: "windows", icon: "\u{f05b3}", label: "Windows", cmd: [Quickshell.env("HOME") + "/.local/bin/reboot-windows"], confirm: true },
            { id: "off", icon: "\u{f0425}", label: "Éteindre", cmd: ["systemctl", "poweroff"], confirm: true }
        ]
        Tile {
            required property var modelData
            readonly property bool asking: session.armed === modelData.id
            width: session.cell; height: 76
            icon: modelData.icon
            label: asking ? "Confirmer ?" : modelData.label
            alert: asking
            onClicked: {
                if (modelData.confirm && !asking) { session.armed = modelData.id; disarm.restart(); return }
                session.armed = ""
                Quickshell.execDetached(modelData.cmd)
            }
        }
    }
}

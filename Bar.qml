// Barre verticale à gauche : espaces de travail (chiffres), heure, Wallhaven,
// Claude, mises à jour. Masquée : elle sort quand la souris touche le bord gauche (ou un instant au
// changement d'espace) et rentre quand la souris s'en va. Ne réserve pas de place aux fenêtres.
// Absente sur l'espace gaming et par-dessus une fenêtre en plein écran.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: bar

    readonly property string home: Quickshell.env("HOME")
    readonly property int size: 44

    readonly property bool hidden: {
        const ws = Hyprland.focusedWorkspace
        return off || !ws || ws.name === "gaming" || ws.hasFullscreen
    }
    // Masquée tout à fait : qs -c shell-maison ipc call bar toggle (Super + Shift + Espace)
    property bool off: false
    IpcHandler {
        target: "bar"
        function toggle(): void { bar.off = !bar.off }
    }

    // Essais : BAR_TEST=1 la garde sortie
    readonly property bool test: !!Quickshell.env("BAR_TEST")
    property bool shown: test
    // Un instant au changement d'espace, pour voir où on est
    readonly property int currentWs: Hyprland.focusedWorkspace ? Hyprland.focusedWorkspace.id : 0
    onCurrentWsChanged: if (!hover.hovered) { shown = true; hide.restart() }
    Timer { id: hide; interval: 1200; onTriggered: if (!hover.hovered && !bar.test) bar.shown = false }

    // Mises à jour : dépôts (checkupdates) + AUR (paru), relues toutes les 30 min
    property int updates: 0
    Process {
        id: checker
        command: ["sh", "-c", "{ checkupdates; paru -Qua; } 2>/dev/null | grep -c ."]
        stdout: StdioCollector { onStreamFinished: bar.updates = parseInt(text) || 0 }
    }
    Timer { interval: 30 * 60 * 1000; running: true; repeat: true; triggeredOnStart: true; onTriggered: checker.running = true }

    function run(args) { Quickshell.execDetached(args) }
    function goTo(ws) { run(["hyprctl", "eval", "hl.dispatch(hl.dsp.focus({ workspace = " + ws + " }))"]) }

    PanelWindow {
        visible: !bar.hidden
        anchors { left: true; top: true; bottom: true }
        exclusiveZone: 0
        implicitWidth: bar.size + 8
        color: "transparent"
        WlrLayershell.namespace: "shell-maison-bar"
        // Rentrée : seule une bande de 1 pixel au bord capte la souris
        mask: Region { item: bar.shown ? column : edge }

        Item { id: edge; width: 1; height: parent.height }

        HoverHandler {
            id: hover
            onHoveredChanged: {
                if (hovered) { hide.stop(); bar.shown = true }
                else hide.restart()
            }
        }

        Column {
            id: column
            anchors.verticalCenter: parent.verticalCenter
            x: bar.shown ? 4 : -width - 4
            Behavior on x { NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: bar.shown ? Theme.openCurve : Theme.closeCurve } }
            width: bar.size
            spacing: 6

            // Espaces de travail : ceux qui existent (1 à 9), l'actif en couleur ; clic pour y aller
            Rectangle {
                width: bar.size
                height: wsCol.implicitHeight + 8
                color: Theme.c.surface_container
                Column {
                    id: wsCol
                    anchors.centerIn: parent
                    spacing: 2
                    Repeater {
                        model: Hyprland.workspaces.values.filter(w => w.id >= 1 && w.id <= 9).sort((a, b) => a.id - b.id)
                        Rectangle {
                            required property var modelData
                            readonly property bool current: modelData.id === bar.currentWs
                            width: bar.size - 8; height: 30
                            color: current ? Theme.c.primary : wsMouse.containsMouse ? Theme.c.surface_container_high : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.id
                                color: parent.current ? Theme.c.on_primary : Theme.c.primary
                                font { family: Theme.font; pixelSize: 14; weight: 800 }
                            }
                            MouseArea { id: wsMouse; anchors.fill: parent; hoverEnabled: true; onClicked: bar.goTo(modelData.id) }
                        }
                    }
                }
            }

            // Heure, sur deux lignes
            Rectangle {
                width: bar.size; height: 50
                color: Theme.c.surface_container
                Text {
                    anchors.centerIn: parent
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 0.9
                    text: Qt.formatTime(Sys.now, "HH\nmm")
                    color: Theme.c.primary
                    font { family: Theme.font; pixelSize: 15; weight: 800 }
                }
            }

            // Boutons
            Repeater {
                model: [
                    { icon: "\u{f02e9}", tip: "Wallhaven", cmd: ["qs", "-c", "shell-maison", "ipc", "call", "wallhaven", "toggle"] },
                    { image: Qt.resolvedUrl("claude.svg"), tip: "Claude Code",
                      cmd: ["uwsm", "app", "--", "ghostty", "--working-directory=" + bar.home + "/.config", "-e", bar.home + "/.local/bin/claude"] },
                    { icon: "\u{f03d7}", tip: "Mises à jour", updates: true, cmd: [Quickshell.shellDir + "/bin/mises-a-jour"] }
                ]
                Rectangle {
                    required property var modelData
                    width: bar.size; height: modelData.updates && bar.updates ? 54 : 40
                    color: btnMouse.containsMouse ? Theme.c.surface_container_high : Theme.c.surface_container
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        Text {
                            visible: !!modelData.icon
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: modelData.icon || ""
                            color: Theme.c.primary
                            font { family: Theme.font; pixelSize: 18 }
                        }
                        // Icône image (SVG noir) peinte dans la couleur principale : la forme sert de masque
                        Item {
                            visible: !!modelData.image
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 18; height: 18
                            Image {
                                id: shape
                                anchors.fill: parent
                                source: modelData.image || ""
                                sourceSize { width: 36; height: 36 }
                                visible: false
                                layer.enabled: true
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: Theme.c.primary
                                layer.enabled: true
                                layer.effect: MultiEffect { maskEnabled: true; maskSource: shape }
                            }
                        }
                        Text {
                            visible: !!modelData.updates && bar.updates > 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: bar.updates
                            color: Theme.c.primary
                            font { family: Theme.font; pixelSize: 12; weight: 800 }
                        }
                    }
                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: bar.run(modelData.cmd)
                    }
                }
            }
        }
    }
}

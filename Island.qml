// Île façon saneAspect, avec toutes les fonctions du centre de contrôle de Noctalia.
// Repliée : pastille en haut au centre avec l'heure (et le morceau en cours).
// Au survol, elle se transforme en panneau à onglets : Accueil (heure, météo, lumière nocturne),
// Musique, Son, Système, Wi-Fi, Bluetooth, Météo, Calendrier ; bouton Réglages de Noctalia, bouton ⏻ = onglet Session.
// Repli quand la souris s'en va.
// Masquée sur l'espace gaming et par-dessus une fenêtre en plein écran.
// État partagé : Sys.qml ; couleurs : Theme.qml. Chargée par shell.qml.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: root

    // Essais : ISLAND_TEST=<onglet> ouvre l'île sur cet onglet et la garde ouverte
    readonly property string test: Quickshell.env("ISLAND_TEST") || ""
    Component.onCompleted: if (test) { tab = test; expanded = true }

    // Depuis un raccourci ou un script (island-open) :
    //   qs -c shell-maison ipc call island toggle <onglet>  ouvre sur l'onglet (ou referme), reste ouverte jusqu'à ce
    //                                                 que la souris passe dessus puis s'en aille
    //   qs -c shell-maison ipc call island peek <onglet>    ouvre, et se replie si la souris ne vient pas dessus (bords du haut)
    IpcHandler {
        target: "island"
        function toggle(tab: string): void {
            if (root.expanded && (!tab || root.tab === tab)) { root.expanded = false; return }
            root.tab = tab || "accueil"
            root.expanded = true
        }
        function peek(tab: string): void {
            if (root.hidden || root.expanded) return
            root.tab = tab || "accueil"
            root.expanded = true
            unvisited.restart()
        }
    }

    readonly property bool hidden: {
        if (test || expanded) return false  // ouverte au clavier : visible même en plein écran
        const ws = Hyprland.focusedWorkspace
        return !ws || ws.name === "gaming" || ws.hasFullscreen
    }

    property bool expanded: false
    property string tab: "accueil"
    onExpandedChanged: {
        Sys.active = expanded
        if (!expanded && !test) tab = "accueil"
    }

    readonly property var tabs: [
        { id: "accueil", icon: "\u{f02dc}", file: "Accueil.qml" },
        { id: "musique", icon: "\u{f075a}", file: "Musique.qml" },
        { id: "son", icon: "\u{f057e}", file: "Son.qml" },
        { id: "systeme", icon: "\u{f04c5}", file: "Systeme.qml" },
        { id: "wifi", icon: "\u{f05a9}", file: "Wifi.qml" },
        { id: "bluetooth", icon: "\u{f00af}", file: "Appareils.qml" },
        { id: "meteo", icon: "\u{f0595}", file: "Meteo.qml" },
        { id: "calendrier", icon: "\u{f00ed}", file: "Calendrier.qml" },
        { id: "session", file: "Session.qml" }  // bouton ⏻ à droite, pas d'icône dans la rangée
    ]

    PanelWindow {
        visible: !root.hidden
        anchors.top: true
        margins.top: 6  // laisse libre le bord actif du haut (centre de contrôle de Noctalia)
        exclusiveZone: 0
        implicitWidth: 620
        implicitHeight: 780
        color: "transparent"
        mask: Region { item: island }
        WlrLayershell.namespace: "island"
        WlrLayershell.layer: WlrLayer.Overlay  // au-dessus d'une fenêtre en plein écran
        // Clavier seulement une fois ouverte (mot de passe Wi-Fi)
        WlrLayershell.keyboardFocus: root.expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        // Repli différé : laisse le temps de revenir sur l'île
        Timer { id: collapse; interval: 400; onTriggered: root.expanded = false }
        // Ouverte par un bord actif : repli si la souris n'y arrive pas à temps
        Timer { id: unvisited; interval: 2000; onTriggered: root.expanded = false }

        Rectangle {
            id: island
            readonly property int maxContent: 640
            anchors.horizontalCenter: parent.horizontalCenter
            width: root.expanded ? 580 : pill.implicitWidth + 32
            height: root.expanded ? 18 + 36 + 14 + Math.min(page.implicitHeight, maxContent) + 18 : 34
            radius: root.expanded ? 31 : 17
            color: Theme.c.surface
            border.color: Theme.c.outline_variant
            clip: true

            Behavior on width { NumberAnimation { duration: root.expanded ? 260 : 190; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Theme.openCurve : Theme.closeCurve } }
            Behavior on height { NumberAnimation { duration: root.expanded ? 260 : 190; easing.type: Easing.BezierSpline; easing.bezierCurve: root.expanded ? Theme.openCurve : Theme.closeCurve } }
            Behavior on radius { NumberAnimation { duration: 200 } }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered) { collapse.stop(); unvisited.stop(); root.expanded = true }
                    else if (!root.test) collapse.restart()
                }
            }

            // Repliée : heure · morceau en cours
            Row {
                id: pill
                anchors.centerIn: parent
                spacing: 10
                opacity: root.expanded ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
                Text {
                    text: Qt.formatTime(Sys.now, "HH:mm")
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 14; bold: true }
                }
                Text {
                    visible: !!Sys.player
                    text: Sys.player && Sys.player.isPlaying ? "\u{f075a}" : "\u{f03e4}"
                    color: Theme.c.primary
                    font { family: Theme.font; pixelSize: 14 }
                }
                Text {
                    visible: !!Sys.player
                    width: Math.min(implicitWidth, 200)
                    elide: Text.ElideRight
                    text: Sys.player ? Sys.player.trackTitle : ""
                    color: Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 13 }
                }
            }

            // Ouverte : onglets + page
            Item {
                anchors { fill: parent; margins: 18 }
                opacity: root.expanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: root.expanded ? 220 : 100 } }

                Row {
                    id: bar
                    spacing: 4
                    Repeater {
                        model: root.tabs.filter(t => t.icon)
                        Rectangle {
                            required property var modelData
                            readonly property bool current: root.tab === modelData.id
                            width: 44; height: 36; radius: 18
                            color: current ? Theme.c.primary : (tabMouse.containsMouse ? Theme.c.surface_container_high : "transparent")
                            Behavior on color { ColorAnimation { duration: 150 } }
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: parent.current ? Theme.c.on_primary : Theme.c.on_surface
                                font { family: Theme.font; pixelSize: 17 }
                            }
                            MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.tab = modelData.id }
                        }
                    }
                }
                Row {
                    anchors.right: parent.right
                    spacing: 4
                    Repeater {
                        model: [
                            { icon: "\u{f0493}", cmd: ["noctalia", "msg", "settings-toggle"] },
                            { icon: "\u{f0425}", tab: "session" }
                        ]
                        Rectangle {
                            required property var modelData
                            readonly property bool current: root.tab === modelData.tab
                            width: 36; height: 36; radius: 18
                            color: current ? Theme.c.primary : btnMouse.containsMouse ? Theme.c.surface_container_high : "transparent"
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: parent.current ? Theme.c.on_primary : Theme.c.on_surface
                                font { family: Theme.font; pixelSize: 17 }
                            }
                            MouseArea {
                                id: btnMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (modelData.tab) { root.tab = modelData.tab; return }
                                    root.expanded = false
                                    Quickshell.execDetached(modelData.cmd)
                                }
                            }
                        }
                    }
                }

                Flickable {
                    anchors { top: bar.bottom; topMargin: 14; left: parent.left; right: parent.right; bottom: parent.bottom }
                    contentHeight: page.implicitHeight
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    Loader {
                        id: page
                        width: parent.width
                        active: root.expanded
                        source: root.tabs.find(t => t.id === root.tab).file
                        onLoaded: if (item.open) item.open.connect(t => root.tab = t)
                    }
                }
            }
        }
    }
}

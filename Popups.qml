// Bulles de notification en haut à droite, la plus récente en haut.
// Clic : action par défaut de l'appli puis fermeture ; × : fermer ; boutons : actions proposées.
// Disparaissent après 5 s (ou le délai demandé par l'appli), sauf les urgentes ; le survol met en pause.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Services.Notifications

Scope {
    PanelWindow {
        visible: Notifs.popups.length > 0 || !!Notifs.toast
        anchors { top: true; right: true }
        margins { top: 10; right: 10 }
        exclusiveZone: 0
        implicitWidth: 380
        implicitHeight: stack.implicitHeight
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-notifications"

        Column {
            id: stack
            width: parent.width
            spacing: 8

            // Message bref (Ne pas déranger…), aligné à droite
            Rectangle {
                visible: !!Notifs.toast
                anchors.right: parent.right
                width: toastText.implicitWidth + 32; height: 40; radius: 20
                color: Theme.c.primary
                Text {
                    id: toastText
                    anchors.centerIn: parent
                    text: Notifs.toast
                    color: Theme.c.on_primary
                    font { family: Theme.font; pixelSize: 13; bold: true }
                }
            }

            Repeater {
                model: Notifs.popups.slice(0, 5)
                Rectangle {
                    id: card
                    required property var modelData
                    readonly property var n: modelData
                    readonly property bool urgent: n.urgency === NotificationUrgency.Critical
                    width: stack.width
                    height: content.implicitHeight + 24
                    radius: 22
                    color: Theme.c.surface
                    border.color: urgent ? Theme.c.error : Theme.c.outline_variant

                    Timer {
                        running: !card.urgent && !hover.hovered
                        interval: card.n.expireTimeout > 0 ? card.n.expireTimeout : 5000
                        onTriggered: Notifs.hide(card.n)
                    }
                    HoverHandler { id: hover }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            const def = card.n.actions.find(a => a.identifier === "default")
                            if (def) def.invoke()
                            card.n.dismiss()
                        }
                    }

                    Row {
                        id: content
                        x: 14; y: 12
                        width: parent.width - 28
                        spacing: 12

                        // Image de la notification, sinon icône de l'appli
                        IconImage {
                            id: icon
                            width: 40; height: 40
                            visible: source != ""
                            source: card.n.image || (card.n.appIcon ? Quickshell.iconPath(card.n.appIcon, true) : "")
                        }
                        Column {
                            width: content.width - (icon.visible ? 52 : 0)
                            spacing: 3
                            Item {
                                width: parent.width; height: 16
                                Text {
                                    text: card.n.appName
                                    color: Theme.c.on_surface_variant
                                    font { family: Theme.font; pixelSize: 11 }
                                }
                                Text {
                                    anchors.right: parent.right
                                    text: "\u{f0156}"
                                    color: close.containsMouse ? Theme.c.primary : Theme.c.on_surface_variant
                                    font { family: Theme.font; pixelSize: 14 }
                                    MouseArea { id: close; anchors.fill: parent; anchors.margins: -6; hoverEnabled: true; onClicked: card.n.dismiss() }
                                }
                            }
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: card.n.summary
                                color: Theme.c.on_surface
                                font { family: Theme.font; pixelSize: 13; bold: true }
                            }
                            Text {
                                width: parent.width
                                visible: !!card.n.body
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                                textFormat: Text.PlainText
                                text: card.n.body
                                color: Theme.c.on_surface_variant
                                font { family: Theme.font; pixelSize: 12 }
                            }
                            // Actions proposées par l'appli (hors action par défaut, déclenchée par le clic)
                            Row {
                                spacing: 6
                                visible: card.n.actions.some(a => a.identifier !== "default")
                                topPadding: 4
                                Repeater {
                                    model: card.n.actions.filter(a => a.identifier !== "default")
                                    Rectangle {
                                        required property var modelData
                                        width: label.implicitWidth + 24; height: 28; radius: 14
                                        color: act.containsMouse ? Theme.c.primary : Theme.c.surface_container_high
                                        Text {
                                            id: label
                                            anchors.centerIn: parent
                                            text: modelData.text
                                            color: act.containsMouse ? Theme.c.on_primary : Theme.c.on_surface
                                            font { family: Theme.font; pixelSize: 12 }
                                        }
                                        MouseArea { id: act; anchors.fill: parent; hoverEnabled: true; onClicked: modelData.invoke() }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Agent Polkit : fenêtre de mot de passe quand une appli demande des droits (pkexec, Manager, mises à jour…).
// Entrée : valider ; Échap ou clic à côté : annuler. L'agent de Noctalia est coupé dans la session Maison
// (noctalia/noctalia/zz-maison.toml) : un seul agent peut exister par session.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit

Scope {
    id: root

    PolkitAgent { id: agent }
    readonly property var flow: agent.flow

    PanelWindow {
        visible: agent.isActive && !!root.flow
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-polkit"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        // Fond assombri : un clic annule
        Rectangle {
            anchors.fill: parent
            color: "#99000000"
            MouseArea { anchors.fill: parent; onClicked: root.flow.cancelAuthenticationRequest() }
        }

        Rectangle {
            anchors.centerIn: parent
            width: 440
            height: box.implicitHeight + 48
            radius: 31
            color: Theme.c.surface
            border.color: Theme.c.outline_variant
            MouseArea { anchors.fill: parent }  // n'annule pas en cliquant dans la fenêtre

            Column {
                id: box
                x: 24; y: 24
                width: parent.width - 48
                spacing: 14

                Row {
                    spacing: 12
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{f033e}"
                        color: Theme.c.primary
                        font { family: Theme.font; pixelSize: 26 }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Authentification requise"
                        color: Theme.c.on_surface
                        font { family: Theme.font; pixelSize: 16; bold: true }
                    }
                }
                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.flow ? root.flow.message : ""
                    color: Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 12 }
                }

                Rectangle {
                    width: parent.width; height: 44; radius: 22
                    color: Theme.c.surface_container_high
                    border.color: root.flow && root.flow.failed ? Theme.c.error : "transparent"
                    TextInput {
                        id: input
                        anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                        verticalAlignment: TextInput.AlignVCenter
                        echoMode: root.flow && root.flow.responseVisible ? TextInput.Normal : TextInput.Password
                        color: Theme.c.on_surface
                        font { family: Theme.font; pixelSize: 14 }
                        focus: true
                        enabled: !!root.flow && root.flow.isResponseRequired
                        onAccepted: if (root.flow) { root.flow.submit(text); text = "" }
                        Keys.onEscapePressed: if (root.flow) root.flow.cancelAuthenticationRequest()
                        Text {
                            visible: !input.text
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Mot de passe"
                            color: Theme.c.on_surface_variant
                            font: input.font
                        }
                    }
                }
                Text {
                    visible: !!root.flow && (root.flow.failed || !!root.flow.supplementaryMessage)
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: root.flow && root.flow.failed ? "Mot de passe incorrect" : root.flow ? root.flow.supplementaryMessage : ""
                    color: root.flow && (root.flow.failed || root.flow.supplementaryIsError) ? Theme.c.error : Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 12 }
                }

                Row {
                    anchors.right: parent.right
                    spacing: 10
                    Repeater {
                        model: [
                            { label: "Annuler", main: false },
                            { label: "Valider", main: true }
                        ]
                        Rectangle {
                            required property var modelData
                            width: 110; height: 40; radius: 20
                            color: modelData.main ? Theme.c.primary : (btn.containsMouse ? Theme.c.surface_container_highest : Theme.c.surface_container_high)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: modelData.main ? Theme.c.on_primary : Theme.c.on_surface
                                font { family: Theme.font; pixelSize: 13; bold: modelData.main }
                            }
                            MouseArea {
                                id: btn
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: {
                                    if (!root.flow) return
                                    if (modelData.main) { root.flow.submit(input.text); input.text = "" }
                                    else root.flow.cancelAuthenticationRequest()
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

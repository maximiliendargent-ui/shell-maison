// Onglet Wi-Fi : interrupteur, réseaux visibles ; clic = se connecter (mot de passe demandé si réseau inconnu protégé)
import QtQuick
import Quickshell
import qs.services
import qs.components

Column {
    id: tab
    spacing: 8
    property string asking: ""  // réseau dont on tape le mot de passe

    function connect(n) {
        if (n.inUse) return
        if (n.known) Sys.run(["nmcli", "connection", "up", "id", n.ssid])
        else if (!n.secure) Sys.run(["nmcli", "dev", "wifi", "connect", n.ssid])
        else { tab.asking = n.ssid; return }
        tab.asking = ""
    }

    Tile {
        width: parent.width; height: 48
        icon: Sys.wifi ? "\u{f05a9}" : "\u{f05aa}"
        label: Sys.wifi ? "Wi-Fi activé" : "Wi-Fi désactivé"
        on: Sys.wifi
        onClicked: Sys.toggleWifi()
    }

    Repeater {
        model: Sys.wifi ? Sys.networks : []
        Column {
            required property var modelData
            width: parent.width
            spacing: 6
            ListRow {
                width: parent.width
                icon: modelData.signal > 66 ? "\u{f0928}" : modelData.signal > 33 ? "\u{f0925}" : "\u{f091f}"
                label: modelData.ssid + (modelData.secure ? "  \u{f033e}" : "")
                detail: modelData.inUse ? "Connecté" : modelData.known ? "Enregistré" : modelData.signal + " %"
                active: modelData.inUse
                onClicked: tab.connect(modelData)
            }
            Rectangle {
                visible: tab.asking === modelData.ssid
                width: parent.width; height: 38; radius: 14
                color: Theme.c.surface_container_highest
                TextInput {
                    id: pass
                    anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: TextInput.Password
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 13 }
                    focus: parent.visible
                    onAccepted: {
                        Sys.run(["nmcli", "dev", "wifi", "connect", modelData.ssid, "password", text])
                        text = ""
                        tab.asking = ""
                    }
                    Text {
                        visible: !pass.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Mot de passe, puis Entrée"
                        color: Theme.c.on_surface_variant
                        font: pass.font
                    }
                }
            }
        }
    }
}

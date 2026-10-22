// Onglet Système : processeur, mémoire, carte graphique, disque (relus toutes les 2 s pendant l'affichage)
import QtQuick
import qs.services
import qs.components

Column {
    spacing: 12
    Component.onCompleted: Sys.monitoring = true
    Component.onDestruction: Sys.monitoring = false

    Repeater {
        model: [
            { icon: "\u{f061a}", label: "Processeur", value: Sys.cpu, detail: Math.round(Sys.cpu * 100) + " % · " + Math.round(Sys.cpuTemp) + " °C" },
            { icon: "\u{f035b}", label: "Mémoire", value: Sys.ram, detail: Sys.ramText },
            { icon: "\u{f08ae}", label: "Carte graphique", value: Sys.gpu, detail: Math.round(Sys.gpu * 100) + " % · " + Math.round(Sys.gpuTemp) + " °C" },
            { icon: "\u{f02ca}", label: "Disque /", value: Sys.disk, detail: Sys.diskText }
        ]
        Card {
            required property var modelData
            width: parent.width
            height: 62
            Text {
                id: ico
                x: 16; anchors.verticalCenter: parent.verticalCenter
                text: modelData.icon
                color: Theme.c.primary
                font { family: Theme.font; pixelSize: 22 }
            }
            Column {
                anchors { left: ico.right; leftMargin: 14; right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 6
                Item {
                    width: parent.width; height: 16
                    Text {
                        text: modelData.label
                        color: Theme.c.on_surface
                        font { family: Theme.font; pixelSize: 13 }
                    }
                    Text {
                        anchors.right: parent.right
                        text: modelData.detail
                        color: Theme.c.on_surface_variant
                        font { family: Theme.font; pixelSize: 12 }
                    }
                }
                Rectangle {
                    width: parent.width; height: 6; radius: 3
                    color: Theme.c.surface_container_highest
                    Rectangle {
                        height: parent.height; radius: 3
                        width: parent.width * Math.min(1, modelData.value)
                        color: modelData.value > .85 ? Theme.c.error : Theme.c.primary
                        Behavior on width { NumberAnimation { duration: 400 } }
                    }
                }
            }
        }
    }
}

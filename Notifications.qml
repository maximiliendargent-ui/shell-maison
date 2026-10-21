// Onglet Notifications de l'île : Ne pas déranger, historique (le plus récent en haut), tout effacer
import QtQuick

Column {
    spacing: 8

    Row {
        width: parent.width
        spacing: 10
        Tile {
            width: (parent.width - 10) / 2; height: 48
            icon: Notifs.dnd ? "\u{f009b}" : "\u{f009a}"
            label: "Ne pas déranger"
            on: Notifs.dnd
            onClicked: Notifs.toggleDnd()
        }
        Tile {
            width: (parent.width - 10) / 2; height: 48
            icon: "\u{f0a7a}"
            label: "Tout effacer"
            onClicked: Notifs.clearHistory()
        }
    }

    Text {
        visible: Notifs.history.length === 0
        text: "Aucune notification"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 12 }
    }

    Repeater {
        model: Notifs.history
        Card {
            required property var modelData
            width: parent.width
            height: col.implicitHeight + 20
            Column {
                id: col
                x: 14; y: 10
                width: parent.width - 28
                spacing: 2
                Item {
                    width: parent.width; height: 14
                    Text {
                        text: modelData.app
                        color: Theme.c.on_surface_variant
                        font { family: Theme.font; pixelSize: 11 }
                    }
                    Text {
                        anchors.right: parent.right
                        text: ago(modelData.time)
                        color: Theme.c.on_surface_variant
                        font { family: Theme.font; pixelSize: 11 }
                        function ago(t) {
                            const m = Math.floor((Sys.now - t) / 60000)
                            return m < 1 ? "à l'instant" : m < 60 ? "il y a " + m + " min"
                                : m < 1440 ? "il y a " + Math.floor(m / 60) + " h" : new Date(t).toLocaleDateString(Qt.locale("fr_FR"), "d MMM")
                        }
                    }
                }
                Text {
                    width: parent.width
                    elide: Text.ElideRight
                    text: modelData.summary
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 13; bold: true }
                }
                Text {
                    width: parent.width
                    visible: !!modelData.body
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                    text: modelData.body
                    color: Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 12 }
                }
            }
        }
    }
}

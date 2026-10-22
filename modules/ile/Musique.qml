// Onglet Musique : grande carte du lecteur, choix du lecteur s'il y en a plusieurs,
// puis volume de chaque son en cours (« Firefox — Netflix » : appli et titre de la page ou du flux)
import QtQuick
import qs.services
import qs.components

Column {
    spacing: 10

    MediaCard { width: parent.width; big: true }

    Repeater {
        model: Sys.players.length > 1 ? Sys.players : []
        ListRow {
            required property var modelData
            width: parent.width
            icon: modelData.isPlaying ? "\u{f040a}" : "\u{f03e4}"
            label: modelData.identity + " — " + modelData.trackTitle
            active: modelData === Sys.player
            onClicked: Sys.chosen = modelData
        }
    }

    Text {
        visible: Sys.streams.length > 0
        text: "Volume par source"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 12; bold: true }
    }
    Repeater {
        model: Sys.streams
        Column {
            required property var modelData
            readonly property string app: modelData.properties["application.name"] || modelData.description || modelData.name
            readonly property string media: modelData.properties["media.name"] || ""
            width: parent.width
            spacing: 4
            Text {
                width: parent.width
                elide: Text.ElideRight
                text: media && media !== app ? app + " — " + media : app
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 12 }
            }
            Level {
                width: parent.width
                icon: modelData.audio.muted ? "\u{f075f}" : "\u{f057e}"
                value: modelData.audio.volume
                dim: modelData.audio.muted
                onMoved: v => modelData.audio.volume = v
                onIconClicked: modelData.audio.muted = !modelData.audio.muted
            }
        }
    }
}

// Onglet Son : volumes sortie et micro, choix de la sortie (le volume par appli est dans l'onglet Musique)
import QtQuick
import Quickshell.Services.Pipewire

Column {
    spacing: 12

    Level {
        width: parent.width
        visible: !!Sys.sink && !!Sys.sink.audio
        icon: Sys.sink && Sys.sink.audio && Sys.sink.audio.muted ? "\u{f075f}" : "\u{f057e}"
        value: Sys.sink && Sys.sink.audio ? Sys.sink.audio.volume : 0
        dim: !!Sys.sink && !!Sys.sink.audio && Sys.sink.audio.muted
        onMoved: v => Sys.sink.audio.volume = v
        onIconClicked: Sys.sink.audio.muted = !Sys.sink.audio.muted
    }
    Level {
        width: parent.width
        visible: !!Sys.source && !!Sys.source.audio
        icon: Sys.source && Sys.source.audio && Sys.source.audio.muted ? "\u{f036d}" : "\u{f036c}"
        value: Sys.source && Sys.source.audio ? Sys.source.audio.volume : 0
        dim: !!Sys.source && !!Sys.source.audio && Sys.source.audio.muted
        onMoved: v => Sys.source.audio.volume = v
        onIconClicked: Sys.source.audio.muted = !Sys.source.audio.muted
    }

    Text {
        text: "Sortie"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 12; bold: true }
    }
    Repeater {
        model: Sys.sinks
        ListRow {
            required property var modelData
            width: parent.width
            icon: "\u{f04c3}"
            label: modelData.description || modelData.nickname || modelData.name
            active: modelData === Sys.sink
            onClicked: Pipewire.preferredDefaultAudioSink = modelData
        }
    }
}

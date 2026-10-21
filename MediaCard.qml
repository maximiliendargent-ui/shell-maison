// Carte musique : pochette, titres, précédent / lecture / suivant, progression (cliquable si le lecteur le permet)
import QtQuick

Card {
    id: card
    property var player: Sys.player
    property bool big: false
    readonly property int art: big ? 120 : 72

    height: art + 24

    Rectangle {
        id: artBox
        x: 12; anchors.verticalCenter: parent.verticalCenter
        width: card.art; height: card.art; radius: 16
        color: Theme.c.surface_container_highest
        clip: true
        Text {
            anchors.centerIn: parent
            text: "\u{f075a}"
            color: Theme.c.on_surface_variant
            font { family: Theme.font; pixelSize: card.art / 3 }
        }
        Image {
            anchors.fill: parent
            source: card.player ? card.player.trackArtUrl : ""
            fillMode: Image.PreserveAspectCrop
            sourceSize { width: 240; height: 240 }
        }
    }
    Column {
        anchors { left: artBox.right; leftMargin: 14; right: parent.right; rightMargin: 14; verticalCenter: parent.verticalCenter }
        spacing: card.big ? 6 : 3
        Text {
            width: parent.width; elide: Text.ElideRight
            text: card.player ? card.player.trackTitle : "Rien en lecture"
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: card.big ? 16 : 14; bold: true }
        }
        Text {
            width: parent.width; elide: Text.ElideRight
            text: card.player ? (card.player.trackArtist || card.player.identity) : ""
            color: Theme.c.on_surface_variant
            font { family: Theme.font; pixelSize: 12 }
        }
        Row {
            spacing: 20
            Repeater {
                model: [
                    { icon: "\u{f04ae}", act: () => card.player.previous() },
                    { icon: "", act: () => card.player.togglePlaying() },
                    { icon: "\u{f04ad}", act: () => card.player.next() }
                ]
                Text {
                    required property var modelData
                    text: modelData.icon || (card.player && card.player.isPlaying ? "\u{f03e4}" : "\u{f040a}")
                    color: btn.containsMouse ? Theme.c.primary : Theme.c.on_surface
                    font { family: Theme.font; pixelSize: card.big ? 24 : 20 }
                    MouseArea {
                        id: btn
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (card.player) modelData.act()
                    }
                }
            }
        }
        Item {
            width: parent.width; height: 14
            visible: !!card.player && card.player.length > 0
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width; height: 3; radius: 2
                color: Theme.c.outline_variant
                Rectangle {
                    height: parent.height; radius: 2
                    color: Theme.c.primary
                    width: card.player && card.player.length > 0
                        ? parent.width * Math.min(1, card.player.position / card.player.length) : 0
                }
            }
            MouseArea {
                anchors.fill: parent
                enabled: !!card.player && card.player.canSeek
                onClicked: mouse => card.player.position = card.player.length * mouse.x / width
            }
        }
        Text {
            visible: card.big && !!card.player && card.player.length > 0
            text: card.player ? fmt(card.player.position) + " / " + fmt(card.player.length) : ""
            color: Theme.c.on_surface_variant
            font { family: Theme.font; pixelSize: 11 }
            function fmt(s) { s = Math.floor(s); return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0") }
        }
    }
    // La position MPRIS n'est pas signalée en continu : on la relit pendant la lecture
    Timer {
        running: Sys.active && !!card.player && card.player.isPlaying
        interval: 1000; repeat: true
        onTriggered: card.player.positionChanged()
    }
}

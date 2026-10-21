// Contenu de l'écran de verrouillage (Lock.qml), le même pour le vrai verrou et l'essai
import QtQuick
import QtQuick.Effects
import Quickshell

Item {
    id: content
    required property var host

    // Fond d'écran flouté et assombri
    Image {
        id: wall
        anchors.fill: parent
        source: content.host.wallpaper ? "file://" + content.host.wallpaper : ""
        fillMode: Image.PreserveAspectCrop
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: wall
        blurEnabled: true
        blur: 1
        blurMax: 64
        brightness: -0.25
    }

    // Heure, date, météo
    Column {
        anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.18 }
        spacing: 6
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(Sys.now, "HH:mm")
            color: Theme.c.primary
            font { family: Theme.font; pixelSize: 150; bold: true }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var w: Sys.weather ? Theme.weather(Sys.weather.current.weather_code, Sys.weather.current.is_day) : null
            text: Sys.now.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                + (w ? "   ·   " + w[0] + "  " + Math.round(Sys.weather.current.temperature_c) + " °C" : "")
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: 20 }
        }
    }

    // Musique en cours
    MediaCard {
        visible: !!Sys.player
        width: 460
        anchors { horizontalCenter: parent.horizontalCenter; bottom: pass.top; bottomMargin: 40 }
        color: Theme.c.surface
    }

    // Mot de passe
    Rectangle {
        id: pass
        width: 360; height: 52; radius: 26
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.16 }
        color: Theme.c.surface
        border.color: content.host.error ? Theme.c.error : Theme.c.outline_variant
        TextInput {
            id: input
            anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
            verticalAlignment: TextInput.AlignVCenter
            horizontalAlignment: TextInput.AlignHCenter
            echoMode: TextInput.Password
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: 16 }
            focus: true
            Component.onCompleted: forceActiveFocus()
            onAccepted: { content.host.submit(text); text = "" }
            Keys.onEscapePressed: { text = ""; if (content.host.testing) content.host.unlock() }
            Text {
                visible: !input.text
                anchors.centerIn: parent
                text: "\u{f033e}  " + Quickshell.env("USER")
                color: Theme.c.on_surface_variant
                font: input.font
            }
        }
    }
    Text {
        anchors { horizontalCenter: parent.horizontalCenter; top: pass.bottom; topMargin: 12 }
        text: content.host.error
        color: Theme.c.error
        font { family: Theme.font; pixelSize: 13 }
    }
}

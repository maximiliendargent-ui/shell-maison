// Onglet Accueil : heure, météo, profil, lumière nocturne
import QtQuick
import Quickshell
import Quickshell.Io

Column {
    id: home
    signal open(string tab)
    spacing: 14

    Item {
        width: parent.width
        height: 50
        Row {
            spacing: 14
            anchors.verticalCenter: parent.verticalCenter
            Text {
                text: Qt.formatTime(Sys.now, "HH:mm")
                color: Theme.c.primary
                font { family: Theme.font; pixelSize: 40; bold: true }
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: Sys.now.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 13 }
                }
                Text {
                    id: profile
                    text: Quickshell.env("USER") + "@" + host.trim() + " · allumé depuis " + Sys.uptimeText
                    color: Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 11 }
                    property string host: ""
                    FileView { path: "/etc/hostname"; onLoaded: profile.host = text() }
                }
            }
        }
        // Météo : clic → onglet Météo
        Row {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            spacing: 6
            visible: !!Sys.weather
            readonly property var w: Sys.weather ? Theme.weather(Sys.weather.current.weather_code, Sys.weather.current.is_day) : ["", ""]
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.w[0]
                color: Theme.c.primary
                font { family: Theme.font; pixelSize: 22 }
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Sys.weather ? Math.round(Sys.weather.current.temperature_c) + "°" : ""
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 18 }
            }
            TapHandler { onTapped: home.open("meteo") }
        }
    }

    Tile {
        width: parent.width; height: 52
        icon: "\u{f0594}"; label: "Lumière nocturne"; on: Sys.nightlight
        onClicked: { Sys.nightlight = !Sys.nightlight; Sys.run(["sh", "-c", "pkill -x hyprsunset || exec hyprsunset -t 4000"]) }
    }
}

// Onglet Météo : conditions actuelles et 7 jours (Open-Meteo, Sys.qml)
import QtQuick

Column {
    spacing: 12
    readonly property var w: Sys.weather

    Text {
        visible: !w
        text: "Météo indisponible"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 13 }
    }

    Card {
        visible: !!w
        width: parent.width
        height: 100
        readonly property var cur: w ? Theme.weather(w.current.weather_code, w.current.is_day) : ["", ""]
        Text {
            id: big
            x: 20; anchors.verticalCenter: parent.verticalCenter
            text: parent.cur[0]
            color: Theme.c.primary
            font { family: Theme.font; pixelSize: 48 }
        }
        Column {
            anchors { left: big.right; leftMargin: 18; verticalCenter: parent.verticalCenter }
            spacing: 2
            Text {
                text: w ? Math.round(w.current.temperature_c) + " °C · " + parent.parent.cur[1] : ""
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 18; bold: true }
            }
            Text {
                text: w ? "Ressenti " + Math.round(w.current.apparent_temperature_c) + " °C · humidité "
                    + w.current.relative_humidity_percent + " % · vent " + Math.round(w.current.wind_speed_kmh) + " km/h" : ""
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 11 }
            }
            Text {
                text: w ? w.location_name : ""
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 11 }
            }
        }
    }

    Repeater {
        model: w ? w.forecast_days : []
        Item {
            required property var modelData
            required property int index
            width: parent.width
            height: 26
            readonly property var icon: Theme.weather(modelData.weather_code, true)
            Text {
                width: 140
                anchors.verticalCenter: parent.verticalCenter
                text: index === 0 ? "Aujourd'hui"
                    : new Date(modelData.date_iso + "T12:00").toLocaleDateString(Qt.locale("fr_FR"), "dddd d")
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 13 }
            }
            Text {
                x: 150
                anchors.verticalCenter: parent.verticalCenter
                text: parent.icon[0] + "  " + parent.icon[1]
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 13 }
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: Math.round(modelData.temperature_min_c) + "° / " + Math.round(modelData.temperature_max_c) + "°"
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 13 }
            }
        }
    }
}

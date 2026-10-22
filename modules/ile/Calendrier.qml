// Onglet Calendrier : mois en cours (lundi en premier), flèches pour changer de mois, aujourd'hui en couleur
import QtQuick
import qs.services
import qs.components

Column {
    id: cal
    spacing: 10
    property int offset: 0  // mois affiché par rapport au mois en cours
    readonly property date first: new Date(Sys.now.getFullYear(), Sys.now.getMonth() + offset, 1)
    readonly property int lead: (first.getDay() + 6) % 7  // cases vides avant le 1er
    readonly property int days: new Date(first.getFullYear(), first.getMonth() + 1, 0).getDate()

    Item {
        width: parent.width; height: 28
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\u{f0141}"
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: 20 }
            TapHandler { onTapped: cal.offset-- }
        }
        Text {
            anchors.centerIn: parent
            text: cal.first.toLocaleDateString(Qt.locale("fr_FR"), "MMMM yyyy")
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: 15; bold: true }
            TapHandler { onTapped: cal.offset = 0 }
        }
        Text {
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            text: "\u{f0142}"
            color: Theme.c.on_surface
            font { family: Theme.font; pixelSize: 20 }
            TapHandler { onTapped: cal.offset++ }
        }
    }

    Grid {
        id: grid
        columns: 7
        readonly property real cell: cal.width / 7
        Repeater {
            model: ["lun", "mar", "mer", "jeu", "ven", "sam", "dim"]
            Text {
                required property string modelData
                width: grid.cell; height: 24
                horizontalAlignment: Text.AlignHCenter
                text: modelData
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 11 }
            }
        }
        Repeater {
            model: cal.lead + cal.days
            Item {
                required property int index
                readonly property int day: index - cal.lead + 1
                readonly property bool today: cal.offset === 0 && day === Sys.now.getDate()
                width: grid.cell; height: 38
                Rectangle {
                    anchors.centerIn: parent
                    width: 34; height: 34; radius: 17
                    visible: parent.today
                    color: Theme.c.primary
                }
                Text {
                    anchors.centerIn: parent
                    visible: parent.day > 0
                    text: parent.day
                    color: parent.today ? Theme.c.on_primary : Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 13; bold: parent.today }
                }
            }
        }
    }
}

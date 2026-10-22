// Ligne de liste cliquable (réseau, appareil, sortie audio) : icône, texte, détail à droite
import QtQuick
import qs.services

Rectangle {
    id: row
    property string icon
    property string label
    property string detail
    property bool active: false
    signal clicked()

    height: 40
    radius: 14
    color: active ? Theme.c.primary : (mouse.containsMouse ? Theme.c.surface_container_highest : "transparent")

    Text {
        id: ico
        x: 12; width: 22
        anchors.verticalCenter: parent.verticalCenter
        text: row.icon
        color: row.active ? Theme.c.on_primary : Theme.c.on_surface
        font { family: Theme.font; pixelSize: 16 }
    }
    Text {
        anchors { left: ico.right; leftMargin: 10; right: det.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        elide: Text.ElideRight
        text: row.label
        color: row.active ? Theme.c.on_primary : Theme.c.on_surface
        font { family: Theme.font; pixelSize: 13 }
    }
    Text {
        id: det
        anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
        text: row.detail
        color: row.active ? Theme.c.on_primary : Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 11 }
    }
    MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: row.clicked() }
}

// Tuile de raccourci : icône + texte, couleur principale quand elle est active
import QtQuick
import qs.services

Rectangle {
    id: tile
    property string icon
    property string label
    property bool on: false
    property bool alert: false  // demande de confirmation : rouge
    signal clicked()
    signal rightClicked()

    height: 64
    radius: 22
    color: alert ? Theme.c.error : on ? Theme.c.primary : (mouse.containsMouse ? Theme.c.surface_container_highest : Theme.c.surface_container_high)
    Behavior on color { ColorAnimation { duration: 150 } }

    Column {
        anchors.centerIn: parent
        width: parent.width - 12
        spacing: 2
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.icon
            color: tile.alert ? Theme.c.on_error : tile.on ? Theme.c.on_primary : Theme.c.on_surface
            font { family: Theme.font; pixelSize: 18 }
        }
        Text {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: tile.label
            color: tile.alert ? Theme.c.on_error : tile.on ? Theme.c.on_primary : Theme.c.on_surface_variant
            font { family: Theme.font; pixelSize: 11 }
        }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: event => event.button === Qt.RightButton ? tile.rightClicked() : tile.clicked()
    }
}

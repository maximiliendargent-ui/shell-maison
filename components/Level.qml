// Réglette (volume…) : clic ou glisser, molette ; icône cliquable à gauche
import QtQuick
import qs.services

Item {
    id: level
    property string icon
    property real value: 0      // 0..1
    property bool dim: false    // muet : réglette grisée
    signal moved(real value)
    signal iconClicked()

    implicitHeight: 26

    Text {
        id: ico
        width: 24
        anchors.verticalCenter: parent.verticalCenter
        text: level.icon
        color: Theme.c.on_surface
        font { family: Theme.font; pixelSize: 18 }
        MouseArea { anchors.fill: parent; onClicked: level.iconClicked() }
    }
    Rectangle {
        anchors { left: ico.right; leftMargin: 10; right: pct.left; rightMargin: 10; verticalCenter: parent.verticalCenter }
        height: 26; radius: 13
        color: Theme.c.surface_container_highest
        Rectangle {
            height: parent.height; radius: 13
            width: Math.max(height, parent.width * Math.min(1, level.value))
            color: level.dim ? Theme.c.outline : Theme.c.primary
        }
        MouseArea {
            anchors.fill: parent
            function set(x) { level.moved(Math.max(0, Math.min(1, x / width))) }
            onPressed: mouse => set(mouse.x)
            onPositionChanged: mouse => set(mouse.x)
            onWheel: wheel => level.moved(Math.max(0, Math.min(1, level.value + (wheel.angleDelta.y > 0 ? .05 : -.05))))
        }
    }
    Text {
        id: pct
        width: 40
        anchors { right: parent.right; verticalCenter: parent.verticalCenter }
        horizontalAlignment: Text.AlignRight
        text: Math.round(level.value * 100) + " %"
        color: Theme.c.on_surface_variant
        font { family: Theme.font; pixelSize: 12 }
    }
}

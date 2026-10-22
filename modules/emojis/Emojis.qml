// Sélecteur d'emojis : recherche (noms anglais : « heart », « smile »…), flèches pour choisir,
// Entrée ou clic pour copier dans le presse-papiers, Échap pour fermer.
// Ouvrir : qs -c shell-maison ipc call emojis toggle (Super + Ctrl + E, Super + .)
// Liste : assets/emojis.json, générée par bin/gen-emojis.py.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

Scope {
    id: picker

    property bool open: false
    property var all: []
    readonly property var shown: {
        const words = search.text.toLowerCase().split(/\s+/).filter(w => w)
        return words.length ? all.filter(e => words.every(w => e[1].includes(w))) : all
    }

    FileView {
        path: Quickshell.shellDir + "/assets/emojis.json"
        onLoaded: picker.all = JSON.parse(text())
    }

    IpcHandler {
        target: "emojis"
        function toggle(): void { picker.open = !picker.open }
    }

    function pick(e) {
        if (!e) return
        Quickshell.execDetached(["wl-copy", e[0]])
        open = false
    }
    onOpenChanged: if (open) { search.text = ""; grid.currentIndex = 0 }

    PanelWindow {
        visible: picker.open
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-emojis"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea { anchors.fill: parent; onClicked: picker.open = false }

        Rectangle {
            width: 560; height: 440
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: 60 }
            radius: 31
            color: Theme.c.surface
            border.color: Theme.c.outline_variant
            MouseArea { anchors.fill: parent }

            Rectangle {
                id: field
                x: 18; y: 18
                width: parent.width - 36; height: 44; radius: 22
                color: Theme.c.surface_container_high
                TextInput {
                    id: search
                    anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 14 }
                    focus: picker.open
                    onTextChanged: grid.currentIndex = 0
                    onAccepted: picker.pick(picker.shown[grid.currentIndex])
                    Keys.onEscapePressed: picker.open = false
                    Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                    Keys.onRightPressed: grid.moveCurrentIndexRight()
                    Keys.onUpPressed: grid.moveCurrentIndexUp()
                    Keys.onDownPressed: grid.moveCurrentIndexDown()
                    Text {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{f0349}  Rechercher un emoji (en anglais)"
                        color: Theme.c.on_surface_variant
                        font: search.font
                    }
                }
            }

            GridView {
                id: grid
                anchors { top: field.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: name.top
                          leftMargin: 18; rightMargin: 18; bottomMargin: 6 }
                clip: true
                cellWidth: width / 10; cellHeight: cellWidth
                model: picker.shown
                highlightMoveDuration: 0
                highlight: Rectangle { radius: 14; color: Theme.c.primary }
                delegate: Item {
                    required property var modelData
                    required property int index
                    width: grid.cellWidth; height: grid.cellHeight
                    Text {
                        anchors.centerIn: parent
                        text: modelData[0]
                        font.pixelSize: 28
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: grid.currentIndex = index
                        onClicked: picker.pick(modelData)
                    }
                }
            }
            Text {
                id: name
                anchors { left: parent.left; leftMargin: 24; bottom: parent.bottom; bottomMargin: 16 }
                text: picker.shown[grid.currentIndex] ? picker.shown[grid.currentIndex][1] : "Aucun résultat"
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 12 }
            }
        }
    }
}

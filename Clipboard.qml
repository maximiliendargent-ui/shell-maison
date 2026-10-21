// Historique du presse-papiers (cliphist, alimenté par wl-paste --watch, lancé par hypr/maison.lua).
// Recherche, flèches, Entrée ou clic : recopie l'élément ; Suppr : l'efface de l'historique ; Échap : ferme.
// Ouvrir : qs -c shell-maison ipc call clipboard toggle (Super + V)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: clip

    property bool open: false
    property var entries: []   // lignes « id<TAB>aperçu » de cliphist list, la plus récente en premier
    readonly property var shown: {
        const q = search.text.toLowerCase()
        return q ? entries.filter(e => e.toLowerCase().includes(q)) : entries
    }

    Process {
        id: lister
        command: ["cliphist", "list"]
        stdout: StdioCollector { onStreamFinished: clip.entries = text.split("\n").filter(l => l) }
    }

    IpcHandler {
        target: "clipboard"
        function toggle(): void { clip.open = !clip.open }
    }
    onOpenChanged: if (open) { search.text = ""; list.currentIndex = 0; lister.running = true }

    // L'id est passé en argument ($1), jamais collé dans la commande
    function pick(line) {
        if (!line) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist decode | wl-copy", "sh", line])
        open = false
    }
    function remove(line) {
        if (!line) return
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | cliphist delete", "sh", line])
        entries = entries.filter(e => e !== line)
    }

    PanelWindow {
        visible: clip.open
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-clipboard"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea { anchors.fill: parent; onClicked: clip.open = false }

        Rectangle {
            width: 600; height: 480
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
                    focus: clip.open
                    onTextChanged: list.currentIndex = 0
                    onAccepted: clip.pick(clip.shown[list.currentIndex])
                    Keys.onEscapePressed: clip.open = false
                    Keys.onUpPressed: list.decrementCurrentIndex()
                    Keys.onDownPressed: list.incrementCurrentIndex()
                    Keys.onDeletePressed: clip.remove(clip.shown[list.currentIndex])
                    Text {
                        visible: !search.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{f0349}  Rechercher dans le presse-papiers"
                        color: Theme.c.on_surface_variant
                        font: search.font
                    }
                }
            }

            ListView {
                id: list
                anchors { top: field.bottom; topMargin: 10; left: parent.left; right: parent.right; bottom: parent.bottom
                          leftMargin: 18; rightMargin: 18; bottomMargin: 18 }
                clip: true
                spacing: 2
                model: clip.shown
                highlightMoveDuration: 0
                highlight: Rectangle { radius: 14; color: Theme.c.primary }
                delegate: Item {
                    required property string modelData
                    required property int index
                    readonly property string preview: modelData.slice(modelData.indexOf("\t") + 1)
                    readonly property bool image: preview.startsWith("[[ binary data")
                    width: list.width; height: 40
                    Text {
                        anchors { fill: parent; leftMargin: 14; rightMargin: 14 }
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                        text: parent.image ? "\u{f02e9}  Image " + parent.preview.replace(/^\[\[ binary data |\]\]$/g, "") : parent.preview
                        color: list.currentIndex === index ? Theme.c.on_primary : Theme.c.on_surface
                        font { family: Theme.font; pixelSize: 13 }
                    }
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        onEntered: list.currentIndex = index
                        onClicked: clip.pick(modelData)
                    }
                }
                Text {
                    visible: list.count === 0
                    anchors.centerIn: parent
                    text: "Historique vide"
                    color: Theme.c.on_surface_variant
                    font { family: Theme.font; pixelSize: 13 }
                }
            }
        }
    }
}

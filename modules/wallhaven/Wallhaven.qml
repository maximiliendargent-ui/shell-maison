// Fonds d'écran Wallhaven : recherche (vide = les plus appréciés du mois), vignettes, page suivante en
// bas de la liste. Un clic télécharge dans ~/Pictures/Wallpapers et applique le fond (bin/fond) ;
// le panneau reste ouvert pour en essayer d'autres. Échap ou clic à côté pour fermer.
// Ouvrir : qs -c shell-maison ipc call wallhaven toggle (bouton de la barre)
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import qs.services
import qs.components

Scope {
    id: wh

    property bool open: false
    property var results: []
    property int page: 0
    property int lastPage: 1
    property bool loading: false
    property string status: ""
    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"

    IpcHandler {
        target: "wallhaven"
        function toggle(): void { wh.open = !wh.open }
    }
    onOpenChanged: if (open && !results.length) search(true)

    // SFW, toutes catégories, au moins la taille de l'écran
    function search(fresh) {
        if (loading || (!fresh && page >= lastPage)) return
        if (fresh) { results = []; page = 0; lastPage = 1 }
        loading = true
        status = ""
        const q = field.text.trim()
        const req = new XMLHttpRequest()
        req.open("GET", "https://wallhaven.cc/api/v1/search?categories=111&purity=100&atleast=1920x1080"
            + (q ? "&sorting=relevance&q=" + encodeURIComponent(q) : "&sorting=toplist&topRange=1M")
            + "&page=" + (page + 1))
        req.onreadystatechange = () => {
            if (req.readyState !== XMLHttpRequest.DONE) return
            loading = false
            try {
                const d = JSON.parse(req.responseText)
                results = results.concat(d.data)
                page = d.meta.current_page
                lastPage = d.meta.last_page
                if (!results.length) status = "Aucun résultat"
            } catch (e) { status = "Wallhaven ne répond pas" }
        }
        req.send()
    }

    function apply(w) {
        if (getter.running) return
        status = "Téléchargement de " + w.id + "…"
        const file = dir + "/" + w.path.split("/").pop()
        getter.command = ["sh", "-c", 'if [ ! -f "$1" ]; then curl -sf --max-time 60 -o "$1.part" "$2" && mv "$1.part" "$1" '
            + '|| { rm -f "$1.part"; exit 1; }; fi; exec "$3" "$1"',
            "sh", file, w.path, Quickshell.shellDir + "/bin/fond"]
        getter.running = true
    }
    Process {
        id: getter
        onExited: code => wh.status = code === 0 ? "Fond appliqué" : "Échec du téléchargement"
    }

    PanelWindow {
        visible: wh.open
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "transparent"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-wallhaven"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        MouseArea { anchors.fill: parent; onClicked: wh.open = false }

        Rectangle {
            width: 820; height: 600
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: 60 }
            radius: 31
            color: Theme.c.surface
            border.color: Theme.c.outline_variant
            MouseArea { anchors.fill: parent }

            Rectangle {
                id: box
                x: 18; y: 18
                width: parent.width - 36; height: 44; radius: 22
                color: Theme.c.surface_container_high
                TextInput {
                    id: field
                    anchors { fill: parent; leftMargin: 18; rightMargin: 18 }
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.c.on_surface
                    font { family: Theme.font; pixelSize: 14 }
                    focus: wh.open
                    onAccepted: wh.search(true)
                    Keys.onEscapePressed: wh.open = false
                    Text {
                        visible: !field.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "\u{f0349}  Rechercher sur Wallhaven (Entrée) — vide : les plus appréciés du mois"
                        color: Theme.c.on_surface_variant
                        font: field.font
                    }
                }
            }

            GridView {
                id: grid
                anchors { top: box.bottom; topMargin: 12; left: parent.left; right: parent.right; bottom: info.top
                          leftMargin: 18; rightMargin: 18; bottomMargin: 6 }
                clip: true
                cellWidth: width / 3; cellHeight: cellWidth * 2 / 3
                model: wh.results
                onAtYEndChanged: if (atYEnd && count) wh.search(false)
                delegate: Item {
                    required property var modelData
                    width: grid.cellWidth; height: grid.cellHeight
                    Rectangle {
                        anchors { fill: parent; margins: 5 }
                        radius: 14
                        color: Theme.c.surface_container
                        clip: true
                        Image {
                            anchors.fill: parent
                            source: modelData.thumbs.small
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "transparent"
                            border { width: 3; color: Theme.c.primary }
                            visible: mouse.containsMouse
                        }
                        Text {
                            anchors { right: parent.right; bottom: parent.bottom; margins: 8 }
                            visible: mouse.containsMouse
                            text: modelData.resolution
                            color: "white"
                            style: Text.Outline; styleColor: "black"
                            font { family: Theme.font; pixelSize: 11 }
                        }
                        MouseArea { id: mouse; anchors.fill: parent; hoverEnabled: true; onClicked: wh.apply(modelData) }
                    }
                }
            }
            Text {
                id: info
                anchors { left: parent.left; leftMargin: 24; bottom: parent.bottom; bottomMargin: 16 }
                text: wh.status || (wh.loading ? "Chargement…" : wh.results.length + " fonds, page " + wh.page + " sur " + wh.lastPage)
                color: Theme.c.on_surface_variant
                font { family: Theme.font; pixelSize: 12 }
            }
        }
    }
}

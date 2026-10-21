// OSD : pastille verticale à droite quand le volume de sortie change, ou quand on coupe le son ou le micro.
// Réagit à tout changement (touches, île, applis), disparaît après 1,5 s.
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: osd

    property string icon: ""
    property real value: 0
    property bool muted: false
    property bool shown: false

    readonly property var sinkAudio: Sys.sink ? Sys.sink.audio : null
    readonly property var sourceAudio: Sys.source ? Sys.source.audio : null

    // Pas d'OSD pour les valeurs lues au démarrage
    property bool ready: false
    Timer { running: true; interval: 2000; onTriggered: osd.ready = true }
    Timer { id: hide; interval: 1500; onTriggered: osd.shown = false }

    function showSink() {
        if (!ready || !sinkAudio) return
        muted = sinkAudio.muted
        value = sinkAudio.volume
        icon = muted ? "\u{f075f}" : value < .34 ? "\u{f057f}" : value < .67 ? "\u{f0580}" : "\u{f057e}"
        shown = true
        hide.restart()
    }
    function showSource() {
        if (!ready || !sourceAudio) return
        muted = sourceAudio.muted
        value = sourceAudio.volume
        icon = muted ? "\u{f036d}" : "\u{f036c}"
        shown = true
        hide.restart()
    }

    Connections {
        target: osd.sinkAudio
        function onVolumesChanged() { osd.showSink() }
        function onMutedChanged() { osd.showSink() }
    }
    Connections {
        target: osd.sourceAudio
        function onMutedChanged() { osd.showSource() }
    }

    PanelWindow {
        visible: osd.shown || pill.opacity > 0
        anchors.right: true
        margins.right: 16
        exclusiveZone: 0
        implicitWidth: 56
        implicitHeight: 240
        color: "transparent"
        mask: Region {}  // ne capte pas la souris
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-osd"

        Rectangle {
            id: pill
            anchors.fill: parent
            radius: width / 2
            color: Theme.c.surface
            border.color: Theme.c.outline_variant
            opacity: osd.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            Text {
                id: pct
                anchors { top: parent.top; topMargin: 16; horizontalCenter: parent.horizontalCenter }
                text: Math.round(osd.value * 100)
                color: Theme.c.on_surface
                font { family: Theme.font; pixelSize: 12; bold: true }
            }
            // Jauge verticale, remplie par le bas
            Rectangle {
                id: track
                anchors { top: pct.bottom; topMargin: 10; bottom: ico.top; bottomMargin: 12; horizontalCenter: parent.horizontalCenter }
                width: 10; radius: 5
                color: Theme.c.surface_container_highest
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width; radius: 5
                    height: parent.height * Math.min(1, osd.value)
                    color: osd.muted ? Theme.c.outline : Theme.c.primary
                    Behavior on height { NumberAnimation { duration: 120 } }
                }
            }
            Text {
                id: ico
                anchors { bottom: parent.bottom; bottomMargin: 16; horizontalCenter: parent.horizontalCenter }
                text: osd.icon
                color: osd.muted ? Theme.c.outline : Theme.c.primary
                font { family: Theme.font; pixelSize: 20 }
            }
        }
    }
}

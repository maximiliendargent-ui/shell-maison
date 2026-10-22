// Écran de connexion (greetd) : fond au hasard flouté, heure, date, mot de passe, choix de la session,
// redémarrer / éteindre. Même style que l'écran de verrouillage (LockContent.qml).
// Installé dans /etc/greetd/shell-maison par greeter/installer, lancé par greeter/start dans un Hyprland minimal.
// Essai dans la session (sans greetd, connexion simulée, Échap ferme) : GREETER_TEST=1 qs -p greeter/shell.qml
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Greetd

ShellRoot {
    id: root

    readonly property string user: "maximilien"
    readonly property string home: "/home/" + user
    readonly property bool testing: !!Quickshell.env("GREETER_TEST")
    readonly property string font: "Maple Mono NF"

    // Sessions proposées (fichiers de /usr/share/wayland-sessions), la première par défaut
    readonly property var allowed: ["hyprland-maison-uwsm-clean.desktop", "plasma.desktop"]
    property var sessions: []  // [{ name, exec }]
    property int session: 0

    property string wallpaper: ""
    property string error: ""
    property string typed: ""

    // Couleurs du bureau (générées par matugen à partir du fond), avec des valeurs de secours
    property var c: ({
        surface: "#1b211f", surface_container_high: "#303634", on_surface: "#dde4e1",
        on_surface_variant: "#bec9c5", primary: "#83d5c6", outline_variant: "#3f4946", error: "#ffb4ab"
    })
    FileView {
        path: root.home + "/.config/quickshell/menu/colors.json"
        onLoaded: { try { root.c = Object.assign({}, root.c, JSON.parse(text())) } catch (e) {} }
    }

    Process {
        running: true
        command: ["sh", "-c", "find " + root.home + "/Pictures/Wallpapers -maxdepth 1 -type f "
            + "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | shuf -n 1"]
        stdout: StdioCollector { onStreamFinished: root.wallpaper = text.trim() }
    }

    Process {
        running: true
        command: ["sh", "-c", "cd /usr/share/wayland-sessions && for f in " + root.allowed.join(" ")
            + "; do [ -f \"$f\" ] && printf '%s\\t%s\\n' \"$(sed -n 's/^Name=//p' \"$f\" | head -1)\" "
            + "\"$(sed -n 's/^Exec=//p' \"$f\" | head -1)\"; done"]
        stdout: StdioCollector {
            onStreamFinished: root.sessions = text.trim().split("\n").filter(l => l)
                .map(l => ({ name: l.split("\t")[0], exec: l.split("\t")[1] }))
        }
    }

    // Connexion : greetd demande le mot de passe (authMessage), puis lance la session choisie
    function submit(password) {
        if (!password || Greetd.state !== GreetdState.Inactive) return
        error = ""
        if (testing) { error = "Essai : connexion simulée (" + sessions[session].name + ")"; return }
        typed = password
        Greetd.createSession(user)
    }
    Connections {
        target: Greetd
        function onAuthMessage(message, isError, responseRequired, echoResponse) {
            if (responseRequired) { Greetd.respond(root.typed); root.typed = "" }
            else if (isError) root.error = message
        }
        function onAuthFailure(message) {
            root.typed = ""
            root.error = "Mot de passe incorrect"
            Greetd.cancelSession()
        }
        function onError(message) {
            root.typed = ""
            root.error = message
            Greetd.cancelSession()
        }
        function onReadyToLaunch() {
            Greetd.launch(["sh", "-c", root.sessions[root.session].exec], [], true)
        }
    }

    PanelWindow {
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore
        color: "black"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "shell-maison-greeter"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        Image {
            id: wall
            anchors.fill: parent
            source: root.wallpaper ? "file://" + root.wallpaper : ""
            fillMode: Image.PreserveAspectCrop
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: wall
            blurEnabled: true
            blur: 1
            blurMax: 64
            brightness: -0.25
        }

        SystemClock { id: clock; precision: SystemClock.Minutes }
        Column {
            anchors { horizontalCenter: parent.horizontalCenter; top: parent.top; topMargin: parent.height * 0.18 }
            spacing: 6
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "HH:mm")
                color: root.c.primary
                font { family: root.font; pixelSize: 150; bold: true }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: clock.date.toLocaleDateString(Qt.locale("fr_FR"), "dddd d MMMM")
                color: root.c.on_surface
                font { family: root.font; pixelSize: 20 }
            }
        }

        // Mot de passe
        Rectangle {
            id: pass
            width: 360; height: 52; radius: 26
            anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: parent.height * 0.16 }
            color: root.c.surface
            border.color: root.error ? root.c.error : root.c.outline_variant
            TextInput {
                id: input
                anchors { fill: parent; leftMargin: 24; rightMargin: 24 }
                verticalAlignment: TextInput.AlignVCenter
                horizontalAlignment: TextInput.AlignHCenter
                echoMode: TextInput.Password
                color: root.c.on_surface
                font { family: root.font; pixelSize: 16 }
                focus: true
                Component.onCompleted: forceActiveFocus()
                onAccepted: { root.submit(text); text = "" }
                Keys.onEscapePressed: { text = ""; if (root.testing) Qt.quit() }
                // Haut / bas : session précédente / suivante
                Keys.onUpPressed: root.session = (root.session + root.sessions.length - 1) % root.sessions.length
                Keys.onDownPressed: root.session = (root.session + 1) % root.sessions.length
                Text {
                    visible: !input.text
                    anchors.centerIn: parent
                    text: "\u{f0004}  " + root.user
                    color: root.c.on_surface_variant
                    font: input.font
                }
            }
        }
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; top: pass.bottom; topMargin: 12 }
            text: root.error
            color: root.c.error
            font { family: root.font; pixelSize: 13 }
        }

        // Session : clic pour passer à la suivante
        Text {
            anchors { horizontalCenter: parent.horizontalCenter; bottom: pass.top; bottomMargin: 16 }
            text: root.sessions.length ? "\u{f0379}  " + root.sessions[root.session].name : ""
            color: sessionMouse.containsMouse ? root.c.primary : root.c.on_surface_variant
            font { family: root.font; pixelSize: 14 }
            MouseArea {
                id: sessionMouse
                anchors { fill: parent; margins: -8 }
                hoverEnabled: true
                onClicked: root.session = (root.session + 1) % root.sessions.length
            }
        }

        // Redémarrer, éteindre
        Row {
            anchors { right: parent.right; bottom: parent.bottom; margins: 32 }
            spacing: 12
            Repeater {
                model: [
                    { icon: "\u{f0709}", cmd: ["systemctl", "reboot"] },
                    { icon: "\u{f0425}", cmd: ["systemctl", "poweroff"] }
                ]
                Rectangle {
                    required property var modelData
                    width: 48; height: 48; radius: 24
                    color: powerMouse.containsMouse ? root.c.surface_container_high : root.c.surface
                    Text {
                        anchors.centerIn: parent
                        text: modelData.icon
                        color: root.c.on_surface
                        font { family: root.font; pixelSize: 20 }
                    }
                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (!root.testing) Quickshell.execDetached(modelData.cmd)
                    }
                }
            }
        }
    }
}

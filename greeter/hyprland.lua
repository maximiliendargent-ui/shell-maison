-- Hyprland minimal de l'écran de connexion (lancé par /etc/greetd/shell-maison/start) : clavier belge,
-- Verr. Num., écran à 165 Hz, puis l'écran de connexion Quickshell ; Hyprland quitte quand il se ferme.
hl.config({
    input = { kb_layout = "be", numlock_by_default = true },
    misc = { disable_hyprland_logo = true, disable_splash_rendering = true },
    ecosystem = { no_update_news = true, no_donation_nag = true },
})

hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@165", position = "0x0", scale = "1" })

hl.on("hyprland.start", function ()
    hl.exec_cmd("sh -c 'qs -p /etc/greetd/shell-maison/shell.qml; hyprctl dispatch \"hl.dsp.exit()\"'")
end)

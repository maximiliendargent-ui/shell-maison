# shell-maison

Shell de bureau pour Hyprland écrit entièrement en [Quickshell](https://quickshell.org) (QML),
qui a remplacé [Noctalia](https://noctalia.dev) morceau par morceau, à la manière de saneAspect.

La config du reste du bureau (Hyprland, applis) est dans le dépôt `dotfiles`.
Ce dépôt ne contient que le nouveau shell.

## Lancer

C'est le shell du bureau : session **« Hyprland (Maison) »** de l'écran de connexion (`greeter/`). La config
Hyprland (dotfiles, `~/.config/hypr/config/`) le lance dans `autostart.lua` (shell, hypridle, awww + `bin/fond`,
cliphist) et branche ses raccourcis dans `binds.lua` (scripts de `bin/`, `qs -c shell-maison ipc call …`).

À la main : `ln -s ~/Projects/shell-maison ~/.config/quickshell/shell-maison` (une fois), puis `qs -c shell-maison`.

Essais : `ISLAND_TEST=meteo qs -c shell-maison` (île ouverte sur un onglet), `BAR_TEST=1 qs -c shell-maison`
(barre toujours sortie).

## Composants

| Fichier | Rôle | Remplace dans Noctalia |
|---|---|---|
| `shell.qml` | Assemble les composants | |
| `Bar.qml` | Barre à gauche, masquée : espaces de travail, heure, Wallhaven, Claude, mises à jour | Barre |
| `Island.qml` | Île en haut au centre : l'heure, s'ouvre au survol en panneau à onglets | Centre de contrôle, menu de session |
| `Accueil.qml` … `Session.qml` | Onglets de l'île : Accueil, Musique, Son, Système, Wi-Fi, Bluetooth (`Appareils.qml`), Météo, Calendrier, Notifications, Session | |
| `Notifs.qml` | Serveur de notifications, historique (`~/.local/state/shell-maison/notifications.json`), Ne pas déranger | Notifications |
| `Popups.qml` | Bulles de notification en haut à droite : actions, 5 s, survol = pause | |
| `Osd.qml` | Pastille verticale à droite quand le volume change ou qu'on coupe le son ou le micro (touches son sur `wpctl` dans `binds.lua`) | OSD |
| `Polkit.qml` | Fenêtre de mot de passe des applis (`pkexec`, Manager, mises à jour) | Agent Polkit |
| `Lock.qml`, `LockContent.qml`, `pam/lock` | Écran de verrouillage : fond flouté, horloge, date et météo, musique, mot de passe (pile PAM `pam/lock`, sans délai après un échec, limite faillock gardée). Essai sans risque : `qs -c shell-maison ipc call lock test` | Écran de verrouillage |
| `Emojis.qml` | Sélecteur d'emojis : recherche en anglais, Entrée copie (`emojis.json`, généré par `bin/gen-emojis.py`) | Lanceur `/emo` |
| `Clipboard.qml` | Historique du presse-papiers (cliphist), recherche, Suppr efface | Presse-papiers |
| `Sys.qml` | État partagé : musique (MPRIS, touches multimédia), son (PipeWire), Wi-Fi (nmcli), moniteurs, météo (Open-Meteo), lumière nocturne (hyprsunset) et veille bloquée (`systemd-inhibit`, respecté par hypridle) lancées par le shell (`ipc call system nightlight\|caffeine`) | Lumière nocturne, caféine |
| `Wallhaven.qml` | Fonds Wallhaven : recherche, vignettes, un clic télécharge dans `~/Pictures/Wallpapers` et applique (`bin/fond`) | Plugin Wallhaven |
| `bin/capture` | Captures `zone` ou `ecran` (grim, slurp) annotées dans satty : Entrée copie, Ctrl + S enregistre dans `~/Pictures/Screenshots` | Captures |
| `bin/mises-a-jour` | Mise à jour (paru, Flatpak) dans Ghostty : bouton de la barre, notification de `~/.local/bin/auto-update` | Plugin arch-updater |
| `Theme.qml` | Couleurs, police (Maple Mono NF), courbes d'animation | |
| `Card.qml`, `Tile.qml`, `Level.qml`, `ListRow.qml`, `MediaCard.qml` | Briques d'interface | |
| `bin/fond`, `couleurs/` | Fond d'écran (awww) et couleurs tirées du fond (matugen, `couleurs/matugen.toml`) : mêmes fichiers de sortie que les modèles de Noctalia (applis, bordures, menu, page d'accueil), couleurs de terminal remplacées par leurs équivalents Material. `fond <image>`, `fond` (au hasard, à la connexion), `fond get` ; le carrousel (`wallpicker`) l'appelle dans la session Maison | Fond d'écran, modèles de couleurs |
| `hypr/hypridle.conf` | Verrouillage après 10 min d'inactivité, écran éteint après 15 min, verrouillage avant la veille (hypridle, lancé par `autostart.lua`) | (rien : Noctalia n'avait pas de veille réglée) |
| `bin/island-open` | Ouvre l'île sur un onglet (raccourcis) | |

## Hors de ce dépôt

Session KDE (secours) : laissée telle quelle. Modèles de couleurs : copiés de Noctalia dans `couleurs/modeles/`.

## À faire

OSD de luminosité : sans objet sur l'écran HDMI actuel.

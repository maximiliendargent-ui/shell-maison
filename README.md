# shell-maison

Shell de bureau pour Hyprland écrit entièrement en [Quickshell](https://quickshell.org) (QML),
pour remplacer [Noctalia](https://noctalia.dev) morceau par morceau, à la manière de saneAspect.

Le bureau qui marche déjà (avec Noctalia) reste sauvegardé dans le dépôt `dotfiles`.
Ce dépôt ne contient que le nouveau shell.

## Lancer

Session **« Hyprland (Maison) »** à l'écran de connexion (`uwsm start -D Hyprland:maison`) : elle lit
`~/.config/uwsm/env-maison` (`SHELL_MAISON=1`), et `hyprland.lua` charge alors `hypr/maison.lua`, qui lance
`qs -c shell-maison`, masque la barre de Noctalia et branche les raccourcis sur l'île.
La session « Hyprland (Noctalia) » reste le bureau stable.

À la main : `ln -s ~/Projects/shell-maison ~/.config/quickshell/shell-maison` (une fois), puis `qs -c shell-maison`.

Essais : `ISLAND_TEST=meteo qs -c shell-maison` (île ouverte sur un onglet), `BAR_TEST=1 qs -c shell-maison`
(barre toujours sortie). Pendant les essais, masquer la barre de Noctalia : `noctalia msg bar-hide`
(`bar-show` pour la remettre).

## Composants

| Fichier | Rôle | Remplace dans Noctalia |
|---|---|---|
| `shell.qml` | Assemble les composants | |
| `Bar.qml` | Barre à gauche, masquée : espaces de travail, heure, Wallhaven, Claude, mises à jour | Barre |
| `Island.qml` | Île en haut au centre : l'heure, s'ouvre au survol en panneau à onglets | Centre de contrôle, menu de session |
| `Accueil.qml` … `Session.qml` | Onglets de l'île : Accueil, Musique, Son, Système, Wi-Fi, Bluetooth (`Appareils.qml`), Météo, Calendrier, Notifications, Session | |
| `Notifs.qml` | Serveur de notifications (repris à Noctalia au démarrage, qui le récupère si shell-maison s'arrête), historique (`~/.local/state/shell-maison/notifications.json`), Ne pas déranger | Notifications |
| `Popups.qml` | Bulles de notification en haut à droite : actions, 5 s, survol = pause | |
| `Sys.qml` | État partagé : musique (MPRIS), son (PipeWire), réseau, moniteurs, météo | |
| `Theme.qml` | Couleurs, police (Maple Mono NF), courbes d'animation | |
| `Card.qml`, `Tile.qml`, `Level.qml`, `ListRow.qml`, `MediaCard.qml` | Briques d'interface | |
| `hypr/maison.lua` | Réglages Hyprland de la session Maison : démarrage, raccourcis | |
| `bin/island-open` | Ouvre l'île sur un onglet (raccourcis) ; sans île, ouvre le panneau Noctalia équivalent | |

## Encore pris chez Noctalia

- Couleurs tirées du fond d'écran : `Theme.qml` lit `~/.config/quickshell/menu/colors.json`, généré par
  Noctalia (à remplacer par matugen).
- Météo : cache de Noctalia (`~/.cache/noctalia/weather.json`).
- Wi-Fi, Bluetooth, lumière nocturne, verrouillage : via `noctalia msg`.
- Boutons Wallhaven et mises à jour de la barre : panneaux des plugins Noctalia.

## À faire

OSD volume / luminosité, fond d'écran, couleurs (matugen),
écran de verrouillage, agent Polkit, lanceur et emojis, presse-papiers, captures.

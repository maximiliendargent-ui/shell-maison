# shell-maison

Shell de bureau pour Hyprland écrit entièrement en [Quickshell](https://quickshell.org) (QML),
pour remplacer [Noctalia](https://noctalia.dev) morceau par morceau, à la manière de saneAspect.

Le bureau qui marche déjà (avec Noctalia) reste sauvegardé dans le dépôt `dotfiles`.
Ce dépôt ne contient que le nouveau shell.

## Lancer

```fish
ln -s ~/Projects/shell-maison ~/.config/quickshell/shell-maison   # une seule fois
qs -c shell-maison
```

Essayer un onglet de l'île sans la survoler : `ISLAND_TEST=meteo qs -c shell-maison`.

## Composants

| Fichier | Rôle | Remplace dans Noctalia |
|---|---|---|
| `shell.qml` | Assemble les composants | |
| `Island.qml` | Île en haut au centre : l'heure, s'ouvre au survol en panneau à onglets | Centre de contrôle, menu de session |
| `Accueil.qml` … `Session.qml` | Onglets de l'île : Accueil, Musique, Son, Système, Wi-Fi, Bluetooth (`Appareils.qml`), Météo, Calendrier, Session | |
| `Sys.qml` | État partagé : musique (MPRIS), son (PipeWire), réseau, moniteurs, météo | |
| `Theme.qml` | Couleurs, police (Maple Mono NF), courbes d'animation | |
| `Card.qml`, `Tile.qml`, `Level.qml`, `ListRow.qml`, `MediaCard.qml` | Briques d'interface | |
| `bin/island-open` | Ouvre l'île sur un onglet (raccourcis) ; sans île, ouvre le panneau Noctalia équivalent | |

## Encore pris chez Noctalia

- Couleurs tirées du fond d'écran : `Theme.qml` lit `~/.config/quickshell/menu/colors.json`, généré par
  Noctalia (à remplacer par matugen).
- Météo : cache de Noctalia (`~/.cache/noctalia/weather.json`).
- Wi-Fi, Bluetooth, lumière nocturne, verrouillage : via `noctalia msg`.

## À faire

Barre, notifications et leur historique, OSD volume / luminosité, fond d'écran, couleurs (matugen),
écran de verrouillage, agent Polkit, lanceur et emojis, presse-papiers, captures.

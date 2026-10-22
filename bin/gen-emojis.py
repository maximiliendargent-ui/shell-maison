#!/usr/bin/env python3
"""Génère assets/emojis.json (caractère + nom anglais en minuscules) pour Emojis.qml, à partir de la base
Unicode de Python. À relancer après une mise à jour de Python pour avoir les nouveaux emojis."""
import json
import pathlib
import unicodedata

RANGES = [(0x1F300, 0x1F5FF), (0x1F600, 0x1F64F), (0x1F680, 0x1F6FF), (0x1F900, 0x1F9FF),
          (0x1FA70, 0x1FAFF), (0x2600, 0x26FF), (0x2700, 0x27BF)]

emojis = []
for start, end in RANGES:
    for cp in range(start, end + 1):
        name = unicodedata.name(chr(cp), "")
        if name:
            # U+FE0F : forme emoji (en couleur) pour les caractères affichés en texte par défaut
            emojis.append([chr(cp) + "\ufe0f", name.lower()])

out = pathlib.Path(__file__).resolve().parent.parent / "assets" / "emojis.json"
out.write_text(json.dumps(emojis, ensure_ascii=False))
print(len(emojis), "emojis →", out)

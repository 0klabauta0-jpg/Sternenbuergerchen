# Grafikpass R2 – Bildnachweis

Auftrag: `docs/tasks/GRAFIKPASS_R2_2026_11_14.md`

Native Godot-Aufnahmen (4.6.2, `gl_compatibility`, llvmpipe, 1280×720). Links
R1 (erster Commit des Branches), rechts R2. Gleiche Karte, Kamera, Bildgröße.
Keine Aufnahme aus dem Forward+-Renderer, keine Einheiten oder Schiffe im Bild.

| Bild | Inhalt |
|---|---|
| `images/01_gm01_pads_und_strasse.jpg` | GM01 Mittelzoom und Basis nah: erhöhte Pads, geteerte Straße |
| `images/02_station64_pads.jpg` | `station_outpost_64x64`: Pads als Deck auf Asphaltfeld |
| `images/03_satellit_trampelpfad_und_klippen.jpg` | `satellite_crash_site`: Trampelpfad, Klippenwände |
| `images/04_handelsposten_und_gm01_uebersicht.jpg` | `trade_outpost`, GM01 Übersicht |

## Sichtbares Ergebnis
- Pads haben Seitenfläche, Rampe, Bake und Beschriftung; Hexlinien liegen oben.
- Straße ist dunkler Asphalt mit hellem Randstein und runden Kurven.
- Sandstreifen haben einen unregelmäßigen Rand statt Hexstufen.
- Sonnenabgewandte Klippenwände sind rotbraun mit Blockfugen statt schwarz.
- `Ground_Mission02_128x128` (grün): 0 abweichende Pixel gegenüber R1.

## Verbleibende Abstände
- Stationswände unverändert (Kenney-Teile).
- Heimatbasis-Pads weiter bündig im Boden.
- Kein Geröll, kein Bewuchs außerhalb der GM01-Basis.

## Aufnahmen wiederholen
```
CAP_DIR=/abs/pfad CAP_SHOTS="gm01_mid|Ground_Mission01_32x32|-300|900|16;gm01_base|Ground_Mission01_32x32|150|560|7;gm01_overview|Ground_Mission01_32x32|0|768|32;station|station_outpost_64x64|obj|0|26;station_close|station_outpost_64x64|obj|0|13;satellite|satellite_crash_site|obj|0|26;satellite_close|satellite_crash_site|obj|0|12;trade|trade_outpost|obj|0|26;gm02|Ground_Mission02_128x128|obj|0|26" \
godot --path . --rendering-driver opengl3 --resolution 1280x720 -s scripts/tests/grafikpass_r1_capture.gd
```

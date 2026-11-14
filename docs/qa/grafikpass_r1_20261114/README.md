# Grafikpass R1 – Bildnachweis

Auftrag: `docs/tasks/GRAFIKPASS_R1_2026_11_14.md`

Alle Bilder sind native Godot-Aufnahmen (4.6.2, `gl_compatibility`, llvmpipe,
1280×720), links der Stand von `main` 03cdccc, rechts der Branch
`task/claude-grafikpass-r1-20261114`. Gleiche Karte, Kamera und Bildgröße.
Keine Aufnahme aus dem Forward+-Renderer.

| Bild | Inhalt |
|---|---|
| `images/01_gm01_uebersicht_und_mitte.jpg` | GM01, Kameragröße 32 und 16 |
| `images/02_gm01_basis_und_station64.jpg` | GM01 Basis nah (Größe 7), `station_outpost_64x64` |
| `images/03_handelsposten_und_satellit.jpg` | `trade_outpost`, `satellite_crash_site` |
| `images/04_station192_und_gm02_unveraendert.jpg` | `station_outpost_192x192`; `Ground_Mission02_128x128` als Kontrolle |
| `images/05_heimatbasis.jpg` | Heimatbasis über den Kampagnenstart |

## Sichtbares Ergebnis
- Boden: breite helle und dunkle Bahnen, Flächen dazwischen ruhig.
- Hexlinien: rostbraun statt fast schwarz, im Nahbild deutlich weniger hart.
- Felswände: gebrochene Flächen, dunkler Fuß; Formen wie zuvor.
- Gebäude auf GM01: cremefarbene Hülle, petrolfarbene Dächer.
- GM02 (grüne Karte): bis auf 21 Pixel Laufrauschen bildgleich zum Ausgangsstand.

## Verbleibende Abstände zur Referenz
- Kein Geröll, kein Bewuchs, keine Kleinobjekte außerhalb der GM01-Basis.
- Wege und Pads folgen weiter den Hexkanten.
- Stationswände und Heimatbasis-Module sind weiterhin kaltweiß.
- Kartenrand unverändert.

## Aufnahmen wiederholen
```
CAP_DIR=/abs/pfad CAP_SHOTS="gm01_overview|Ground_Mission01_32x32|0|768|32;gm01_mid|Ground_Mission01_32x32|-300|900|16;gm01_base|Ground_Mission01_32x32|150|560|7;station|station_outpost_64x64|obj|0|26;trade|trade_outpost|obj|0|26;satellite|satellite_crash_site|obj|0|26;station192|station_outpost_192x192|obj|0|26;gm02|Ground_Mission02_128x128|obj|0|26" \
godot --path . --rendering-driver opengl3 --resolution 1280x720 -s scripts/tests/grafikpass_r1_capture.gd
```

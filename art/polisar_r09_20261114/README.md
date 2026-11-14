# Polisar R09 – Station als Blender-Asset (14.11.2026)

Status: **Modellkandidat, im Spiel eingebunden, vom Nutzer noch nicht abgenommen.**
Im laufenden Spiel (Forward+/D3D12) ungeprüft; alle Bilder stammen aus Godot 4.6.2
mit OpenGL-Software-Renderer.

Der Bildname ist Polisar, die Code-ID bleibt `polisa`.

## Was das ist

Überarbeitung des R08-Layouts nach dem annotierten Zielbild des Nutzers
(`16_orbitalstation_r04.png`, KI-Zielkandidat, nicht freigegeben) und nach
`POLISAR_BLENDER_AUFTRAG.md`. Layout, Kartenzellen und Modell entstehen aus
derselben Quelle `layout.json`; Wände, Räume, Pads und Sperrflächen des Modells
liegen deshalb genau dort, wo die Karte sie führt.

| Datei | Zweck |
| --- | --- |
| `author_layout.py` → `layout.json` | editierbare Layoutfakten (Schema `polisa_authored_layout_v9`) |
| `build_candidate.py` → `layout_compiled.json` | Kartenzellen, Marker, Offline-Prüfungen (aus R08 übernommen und angepasst) |
| `tools/build_polisa_station.py` → `maps/polisa_station.json` | Produktionskarte |
| `build_station.py` → `blender/polisar_r09.blend`, `Assets/curated/polisar_r09_20261114/polisar_station.glb`, `model_manifest.json` | Blender-Quelle, Export, Messwerte und SHA-256 |
| `scripts/terrain/polisa_station_visual.gd` | lädt das GLB, setzt Beschriftungen, Rüstungsfiguren, Kartenrahmen |
| `capture_views.gd` | Prüfansichten mit dokumentierten Kameras |

Der Ordner `blender/` hat eine `.gdignore`, damit Godot die `.blend` nicht
importiert. Die JSON-Dateien liegen bewusst außerhalb, weil die Laufzeit
`layout_compiled.json` liest.

## Reproduzieren

```
python3 art/polisar_r09_20261114/author_layout.py
python3 tools/build_polisa_station.py
python3 art/polisar_r09_20261114/build_station.py        # braucht das bpy-Modul (Blender 5.3)
godot --headless --path . --import
godot --path . --rendering-driver opengl3 --resolution 1600x900 -s art/polisar_r09_20261114/capture_views.gd
```

## Koordinaten, Maßstab, Pivot

- Einheit: 1 Blender-Einheit = 1 Ebeneneinheit der Karte (Abstand benachbarter Hexzentren). Keine Meterangabe.
- Layout (x, z, hoch) → Blender (x, −z, hoch): Kartenebene XY, Z vertikal, Querachse entlang X, Ringebenen YZ.
- glTF-Export mit Y oben → Godot (x, hoch, z). Pivot = Layout-Ursprung auf der Deckebene, Skalierung 1, keine zusätzliche Drehung. Die Karte setzt das Modell auf `origin_plane [0, −70]`.
- Hexraster wie im R08-Compiler: `x = q + r/2`, `z = r·√3/2`.

## Änderungen gegenüber R08 (gemessen)

| Merkmal | R08 | R09 |
| --- | --- | --- |
| Ringradius | 28 | 34 |
| Ringmitte / Achse | beide y = −12, z = 19 | beide y = −2,2, z = 24 (im Modell gemessen, siehe unten) |
| Querachse | x = ±88 | x = ±104 |
| Dockköpfe | x = ±82, Klammern nach vorn | x = ±98, Kragen nach außen in Achsrichtung |
| Speichen / Streben | 5 Speichen | 8 Speichen, 4 Diagonalstreben vom Arm zum Ring, 4 kurze Innenstreben |
| Links | je ein Solarfeld beidseits (auch rechts) | zwei Solarflügel am linken Arm, hinter und vor der Achse |
| Rechts | Solarfelder | vier Tanks, zwei hinter und zwei vor der Achse, mit Sätteln und Leitungen |
| M-Pads | 12 × 12 | 10 × 8 |
| L-Pad | 16 × 24 | 14 × 12 |
| S-Pads | 8 × 6 | 8 × 6 (unverändert, siehe „Offen“) |
| Padfläche gesamt | 864 | 520 (−40 %) |
| Hub | 28 × 20 | 36 × 25 |
| Läden | 5 × (12 × 12) | 5 × (16 × 16) |
| Innenfläche (Hub + Läden) | 1280 | 2180 (+70 %) |
| Hintere Technik | Sperrzone innerhalb der Karte | Dekoration hinter der Kartengrenze (z < −20), ohne Zellen |
| Kartenzellen | 4486 | 5007 (2700 begehbar, eine zusammenhängende Fläche) |
| Dreiecke (sichtbar) | 23 388 | 45 680 |
| Mesh-Knoten / Flächen (Drawcalls) / Materialien | 10 / 28 / 26 | 10 / 108 / 44 |

Die Drawcall-Zahl steigt, weil jede der verlangten Baugruppen ein eigenes
Objekt mit eigenen Materialflächen ist. Im Spiel ist das nicht profiliert.

## Achsprüfung

`build_station.py` misst am fertigen Mesh (Werte in `model_manifest.json`):

- Achse (Endschleifen des durchgehenden Schaftzylinders): z = 24,0, hoch = −2,2
- Ring links und rechts (Hüllmaße): Mitte z = 24,0, hoch = −2,2, Außendurchmesser 68,0 in beiden Richtungen, Ringebene x = ∓50,0
- `ring_centres_on_axle: true`

Bild dazu: `docs/qa/polisar_windbruch_gm02_20261114/polisar_nachher_r09/06_kontrolle_entlang_x.jpg`
(orthografisch entlang X, Fadenkreuz auf der Achslinie).

## Collections der .blend

`01_Struktur_Innenbereich`, `02_Daecher`, `03_Pads`, `04_Ringe_Achse`
(Ring_Links, Ring_Rechts, Achse), `05_Solarfluegel_Links`,
`06_Treibstofftanks_Rechts`, `07_Grossschiff_Docks`, `08_Technik_Seiten`,
`09_Heck_Dekoration_nicht_begehbar`, `10_Hilfen_Entwurf_nicht_exportiert`.

Die Hilfen (Kartengrenze, freie Dock-Anflugvolumen, Schiffsproxies im
Hexmaßstab) sind Entwurf: nicht exportiert, keine Gameplay-Fakten. Die Dächer
sind exportiert, im Spiel aber ausgeblendet; eine Dachlogik gibt es nicht.

## Prüfansichten

`docs/qa/polisar_windbruch_gm02_20261114/` – `polisar_vorher_r08/` und
`polisar_nachher_r09/` mit identischen Kameras, Auflösung 1600 × 900 und Licht;
dazu zwei Vergleichsbilder. Kameras (yaw, pitch, Größe, Fokus lokal) stehen in
`capture_views.gd`. Bild 07 ist die echte Kartenansicht des Spiels.

## Quellen

- Eigene Modelle: alles in `build_station.py`. Rüstungsfiguren und Personenmodell sind vorhandene Projektmodelle.
- Native Ausgangsform: `art/polisa_r08_20261111/` (Layout, Compiler) und der R08-Stand von `scripts/terrain/polisa_station_visual.gd` (Git-Historie).
- KI-Zielbild `16_orbitalstation_r04.png`: nur Richtungsvorgabe, nicht freigegeben. Wo es sich selbst widerspricht (Ringgröße, Raster), gelten Auftrag und gemessene Geometrie.
- Externe Referenzen nur angesehen, nicht ins Repo übernommen: Nutzer-Topview Port Olisar, Nutzer-Screenshot Port Tressler, Port Olisar 2023 von **Hasgaha – https://hasgaha.com** (Quelle: https://robertsspaceindustries.com/community-hub/post/screenshots-of-port-olisar-over-the-years-03Z7D1CWw5L2H).

## Offen

- S-Pads sind nicht kleiner geworden. Die Cutlass füllt das 8 × 6-Deck fast aus; schon eine halbe Zelle Versatz schiebt ihre Standfläche auf nicht vorhandene Zellen. Die Padkante liegt deshalb in derselben Hexreihen-Phase wie in R08. Kleinere S-Pads bräuchten eine Entscheidung zur Schiffsgröße.
- Die Ringe reichen jetzt 32 Einheiten über die Deckebene. Bei gedrehter Kamera verdeckt der vordere Ring Teile der seitlichen Technik.
- Dockköpfe sind reine Geometrie mit benannten Anflugvolumen; es gibt keine Dockmechanik.
- Kartenrand, Docks, Solarflügel und Tanks haben keine Kollision für Schiffe; das war in R08 genauso.

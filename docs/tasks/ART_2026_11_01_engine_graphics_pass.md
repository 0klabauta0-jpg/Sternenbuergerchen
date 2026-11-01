# ART_2026_11_01_ENGINE - Erster nativer Grafikdurchgang

## Auftrag und bestaetigtes Ziel
Der Nutzer hat `01_rostwelt_landschaft.png`, `03_aussenposten_stilstudie.png`
und die vier Menschen in `02_menschen_stilstudie.png` ausdruecklich positiv
bestaetigt und den engine-technischen Grafikumbau beauftragt. Die drei Bilder
unter `docs/reports/assets/grafik-2026-11-01/` sind fuer diesen Durchgang die
zugeordneten Stilziele. Schiffsvorlagen sind weitere Vorschlaege, nicht mit
dieser Zustimmung automatisch freigegeben.

## Sinn und Umfang
Ein erster in Godot lauffaehiger, zusammenhaengender Ausschnitt mit heller
Rostlandschaft, Habitat/Werkstatt/Versorgung und vier unterscheidbaren Citizens
soll die Uebertragung von 2D nach 3D beweisen. Der bestehende 3D-Visualpfad
erhaelt einen isoliert schaltbaren Grafikstil; der normale Laufzeitpfad bleibt
verfuegbar. Editierbare Modelle, Exporte und native Ansichten gehoeren dazu.

## Architektur und Grenzen
- Basis bleibt der neue Branch von `integration/core-foundation` auf `3cae5a216`.
- Godot 4.6.2 des Integrationsstands; kein Enginewechsel.
- `TerrainMap3DView` ist Darstellung; `SimulationRoot`, Registries und Karten-
  daten bleiben Gameplay-Wahrheit.
- Grafikprofil, Materialien und dekorativer Hintergrund haben keine Navigation,
  Kollision, Deckungs- oder LOS-Wirkung. Keine per-frame Komplett-Rebuilds.
- Begehbare Flaechen und sichtbare Hindernisse muessen im Ausschnitt zusammen-
  passen. Nicht ueber unveraendert begehbare Tiles ein blickdichtes Haus legen.
- Keine globale Migration von 318 Bestandspfaden in diesem Startpaket.
- Spaetere Nutzerentscheidung: Hexfelder sind gesetzt. Die Topologiearbeit ist
  separat unter `HEX_2026_11_01_foundation.md` beauftragt und wird im neuen
  Grafik-Ausschnitt verwendet; der Grafikstil selbst besitzt weiterhin keinen
  Gameplay-State.

## Umsetzung und Dateien
- `scripts/terrain/frontier_art_profile.gd`: rein visuelle Palette/Licht/Shader.
- `scripts/terrain/terrain_map_3d_view.gd`: kleiner expliziter Profilanschluss.
- `Assets/curated/frontier_illustrated_20261101/`: eigene neue GLB-Familie.
- `art/frontier_illustrated_20261101/`: editierbare Quellen/Generator/QA.
- `scenes/tests/frontier_art_preview.tscn` und zugehoeriger Driver: nativer
  Referenzausschnitt mit Kamera/Zoom, Ansichten und Bewegungs-/Poseprobe.
- Enger Verifier: Profil bleibt rein visuell; neue Assets importieren mit
  stimmigen Bounds, Materialien, Orientierung und ggf. Rig/Animation.
- HTML um echte native Ergebnisse, Umfang, Quellen und offene Differenzen
  erweitern; Konzept und Runtime weiterhin getrennt kennzeichnen.

## Akzeptanz und lokale Pruefung
- Die drei bestaetigten 2D-Ziele werden beim Modellieren geoeffnet.
- Neue Asset-Familie mit klaren Formen und brauchbarem menschlichen Massstab;
  Modellquelle, GLB, Roh-QA und frisch importierte native Ansichten vorhanden.
- Native Gesamtansicht plus Nah-/Spielabstand und relevante Posen geoeffnet.
- Der Grafikstil kann ueber einen klaren Preview-/Profilpfad gestartet werden.
- Gepruefter Karten-/Navigationspfad bleibt vor/nach Profilwahl identisch.
- Neue Skripte kompilieren; passende bestehende 3D-/Navigation-Smokes pruefen.
- `git diff --check`; eigener Task-Commit/Push, keine Main-Integration.

## Risiken und offene Punkte
Der erste Ausschnitt ist ein Grafikdurchgang und keine komplette Content-
oder Gameplay-Abnahme. Figuren muessen im Spielabstand und bei Bewegung lesen;
eine statische Pose belegt kein fertiges Animationssystem. Der Wechsel auf Hex
waere eine eigene Architekturentscheidung mit Karten-, LOS-, Cover-, Auswahl-,
Formations-, Save- und Multiplayer-Migration, nicht nur ein anderes Gridbild.

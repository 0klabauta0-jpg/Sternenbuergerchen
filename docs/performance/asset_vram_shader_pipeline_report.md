# TASK_220 Asset VRAM Shader Pipeline Report

Stand: 2026-05-06

## Ziel
Dieser Bericht dokumentiert den Asset-Performance-Slice fuer Importgroesse, grobe VRAM-Schaetzung, GLB-Geometrie-/Materialzaehlung, erste Pipeline-Zaehler und Warmup-Kandidaten. Der Task importiert keine neuen Assets und aendert keine Gameplay-Wahrheit.

## Asset-Kataloge
Folgende Runtime-Kataloge enthalten jetzt ein `performance_budget` fuer TASK_220:

- `data/curated_asset_catalog.json`
- `data/weapon_fire_vfx_catalog.json`
- `data/comic_bubble_asset_catalog.json`

Die Budgets halten fest, dass Runtime-Pfade `res://` bleiben muessen, groessere Texturen und GLBs beobachtet werden und Warmup nur verdeckt ohne sichtbare Gameplay-Events passieren darf.

## Mess-Harness
`scripts/tests/asset_vram_shader_pipeline_harness.gd` sammelt die kuratierten Assets, Weapon-Fire-VFX und Comic-Bubble-Assets. Fuer Texturen werden Dateigroesse, Breite, Hoehe und eine konservative VRAM-Schaetzung `width * height * 4` erfasst. Fuer GLB-/PackedScene-Ressourcen werden Dateigroesse, Node-Anzahl, MeshInstance-Anzahl, Surface-Anzahl und eindeutige Materialien gezaehlt.

Der Harness prueft zusaetzlich:

- keine absoluten lokalen Benutzerpfade
- keine `file:///`-Runtime-Pfade
- ResourceLoader-Ladung aller gemessenen Katalogpfade
- groesste Textur und groesste GLB-Datei als Diagnose

## Pipeline
Die Pipeline-Probe instanziert `scenes/tests/mission_map_3d_render_spike.tscn`, wartet auf mehrere Frames und liest `TerrainMap3DView.get_render_snapshot()` aus. Dokumentiert werden Draw-Budget, Render-Budget, Transparenzbudget und Pipeline-Compilation-Zaehler fuer Canvas, Mesh, Surface, Draw und Specialization.

Diese Werte sind hardware- und driverabhaengig. Der Verifier prueft deshalb das Vorhandensein der Zaehler, nicht einen starren FPS- oder Millisekundenwert.

## Warmup
Warmup-Kandidaten sind derzeit:

- kurzlebige Muzzle-Flash-Texturen
- Comic-Bubble-Texturen
- kleine kuratierte UI-/Rank-/Particle-/Setpiece-Proben

Die Probe laedt eine begrenzte Auswahl verdeckt unter einem unsichtbaren `Node3D`. PackedScenes duerfen dort instanziert werden, erzeugen aber keine Combat-, Fire-, Bubble- oder Objective-Events. Der Verifier erwartet `visible_side_effect_count == 0`.

## Ampel
- Okay: `res://`-Pfadgrenzen, Katalog-Ladbarkeit, GLB-Geometriezaehlung, Textur-VRAM-Schaetzung.
- Beobachten: grosse PNGs, einzelne GLBs mit vielen Materialien, alpha-blended Bubble- und Muzzle-Flash-Flächen.
- Warmup: VFX, Bubbles und erste 3D-Renderprobe koennen bei sichtbarem Stutter verdeckt vorgeladen werden.
- Spaeter: Manuelle Godot Video-RAM-/Visual-Profiler-Messung mit echter GPU bleibt offen.

## Risiken
- Video-RAM- und Pipeline-Zaehler sind lokal unterschiedlich. Headless prueft reproduzierbare Struktur, nicht die finale Hardware-Aussage.
- Importkompression darf Pixel-/Comic-Lesbarkeit nicht blind verschlechtern.
- Warmup darf keine neue Runtime-Wahrheit oder sichtbare Gameplay-Events erzeugen.

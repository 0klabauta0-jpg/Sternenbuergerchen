# TASK_220 - Asset Import VRAM Shader Pipeline Stutter Pass

## Ziel
Neue Assets, GLBs, PNGs, Particles, Comic-Bubbles, Main-Menu-Bild, Rank-Badges, Space-Kit-Setpieces und Waffenmodelle sollen auf Importgroesse, VRAM, Materialanzahl, Transparenz und Shader-/Pipeline-Stutter geprueft werden.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_194 - Space Modular and Station Setpiece Import
- TASK_195 - UI Input and Cursor Asset Availability Pass
- TASK_196 - Rank and Particle Asset Subset Import
- TASK_197 - Curated Asset Catalog and Usage Mapping
- TASK_198 - Asset Import Gate and Visual Smoke
- TASK_199 - Main Menu Shell and Background Image
- TASK_205 - Weapon Fire VFX Muzzle Flash Particles
- TASK_209 - Comic Bubble Asset Catalog and Visual Contract
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
Viele neue Assetquellen sind geplant. Asset-Performance kippt selten durch eine einzelne Datei, sondern durch zu grosse Texturen, zu viele Materialvarianten, alpha-blended Overlays, viele einmalig instanzierte VFX und Pipeline-Kompilierung waehrend Gameplay.

## Umfang
1. Asset-Budget:
   - PNG-Abmessungen und Dateigroessen.
   - GLB-Mesh-/Materialanzahl.
   - VRAM-Schaetzung ueber Godot-Video-RAM-Tab oder Runtime-Monitore.
   - Maximalmengen aus Asset-Tasks pruefen.
2. Importregeln:
   - VRAM Compression fuer passende 3D-Texturen bewerten.
   - Pixel-art/kleine UI-Assets nicht sichtbar kaputt komprimieren.
   - Transparenz bewusst klein halten.
3. Material-/Shader-Reuse:
   - Gleiche Assets teilen Materialien, wo moeglich.
   - Keine duplizierten Materialvarianten pro Instanz ohne Nutzen.
4. Pipeline-Stutter:
   - Pipeline-Compilation-Monitore erfassen.
   - Muzzle-/Particle-/Bubble-/Dropship-/Weapon-Visuals frueh instanzieren oder warmupen, wenn Messung Stutter zeigt.
   - Warmup darf keine sichtbaren Gameplay-Events erzeugen.
5. Load-/Import-Gate:
   - Headless `--import`.
   - Loadbarkeit aller Katalogpfade.
   - Keine lokalen Benutzerpfade in Runtime.
6. Bericht:
   - Assetgruppen mit Ampel: okay, reduzieren, warmup, spaeter.

## Nicht-Ziele
- Kein kompletter Art-Rework.
- Kein Massenimport.
- Kein Verlust der pixeligen/Comic-Aesthetik durch blinde Kompression.
- Keine Gameplayevents fuer Warmup.

## Akzeptanzkriterien
- [x] Asset-Katalog enthaelt Performance-relevante Metadaten fuer groessere Gruppen.
- [x] VRAM-/Texture-/Material-/GLB-Zaehler sind dokumentiert.
- [x] Pipeline-Compilation-Zaehler werden beim ersten Missionslauf erfasst.
- [x] Warmup-Kandidaten sind belegt und side-effect-frei.
- [x] Alle Runtime-Pfade bleiben `res://`.
- [x] Ein TASK_220-Verifier prueft Import, Katalogbudgets, lokale Pfadgrenzen und Pipeline-Zaehler.

## Erwartete Dateien
- `docs/performance/asset_vram_shader_pipeline_report.md`
- `data/curated_asset_catalog.json`
- `data/weapon_fire_vfx_catalog.json`
- `data/comic_bubble_asset_catalog.json`
- `scripts/tests/asset_vram_shader_pipeline_harness.gd`
- `scripts/tests/task_220_asset_import_vram_shader_pipeline_stutter_pass.gd`
- `docs/tasks/TASK_220_asset_import_vram_shader_pipeline_stutter_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_220_asset_import_vram_shader_pipeline_stutter_pass.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_198_asset_import_gate_visual_smoke.gd`
- [ ] Manueller Godot Video-RAM-/Visual-Profiler-Check.
- [x] `git diff --check`

## Risiken
- Shader-/Pipeline-Stutter ist hardware- und driverabhaengig. Zaehler und reproduzierbare Szenen sind wichtiger als ein einzelner FPS-Wert.
- Zu harte Importkompression kann den Stil sichtbar beschaedigen.

## Umsetzung
- Kataloge enthalten `performance_budget`-Metadaten fuer Runtime-Pfade, Groessen-/VRAM-Grenzen und verdeckte Warmup-Policy.
- `AssetVRAMShaderPipelineHarness` misst 98 Katalog-Assets: 70 Texturen und 28 GLB-/PackedScene-Ressourcen.
- Texturen erhalten Dateigroesse, Dimensionen und grobe VRAM-Schaetzung; GLBs erhalten Datei-, Node-, Mesh-, Surface- und Materialzaehler.
- Die Render-Spike-Probe liest Draw-Budget, Transparenzbudget und Pipeline-Compilation-Zaehler aus `TerrainMap3DView.get_render_snapshot()`.
- Warmup laedt eine begrenzte Auswahl verdeckt und meldet `visible_side_effect_count == 0`.

## Naechster Schritt
TASK_221 prueft Multiplayer-Snapshots und Serialisierung.

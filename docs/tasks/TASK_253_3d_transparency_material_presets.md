# TASK_253 - 3D Transparency Material Presets

## Ziel
3D-Assets mit Transparenz sollen klare Material-Regeln bekommen, damit Vegetation, Zaeune, Decals, Hologramme und Effekte performant und konsistent dargestellt werden. Es entstehen Presets und eine kleine Benchmark-/Beispielszene fuer Godot 4.6.

## Status: GEPLANT

## Voraussetzung
- Bestehende 3D-Asset-/Materialpfade im Projekt
- Godot 4.6.x

## Kontext
- Alpha Scissor ist fuer harte Cutouts meist deutlich guenstiger und instancing-freundlicher.
- Alpha Hash ist ein Mittelweg fuer weichere Kanten.
- Alpha Blend bleibt fuer echte Halbtransparenz noetig, ist aber teurer und sorting-anfaelliger.
- Diese Regeln betreffen Rendering/Assets, nicht Gameplay-State.

## Umfang
1. Material-Preset-Vertrag definieren:
   - `cutout_scissor` fuer harte Kanten.
   - `dither_hash` fuer weiche Vegetation/Haare.
   - `true_blend` fuer Glas, Hologramm, Rauch, Energieeffekte.
2. Kleine Utility oder Doku-Helfer:
   - StandardMaterial3D-Presets programmatisch erzeugen oder als `.tres` ablegen.
   - Alpha-Threshold/Hash/Blend-Parameter dokumentieren.
3. Benchmark-/Beispielszene:
   - viele identische Quads/Sprites3D/MeshInstances.
   - Presets schnell umschaltbar.
   - manuelle Profiler-Hinweise fuer Frame-Time/Drawcalls/Artefakte.
4. Asset-Regeln dokumentieren:
   - wann Scissor, Hash oder Blend verwendet wird.
   - Blend nur fuer echte Halbtransparenz.
   - keine Gameplay-Kopplung.

## Nicht-Ziele
- Keine Rendering-Pipeline-Neuerfindung.
- Kein Shader-Komplettsystem.
- Kein Gameplay- oder Navigationseingriff.
- Keine automatische Konvertierung aller bestehenden Materialien.

## Architekturregeln
- Rendering-Presets bleiben Asset-/Darstellungsschicht.
- Keine Gameplay-Wahrheit in Materialien oder Szene-Callbacks.
- Keine grossen Asset-Massen im Repo ohne eigenen Content-Task.

## Akzeptanzkriterien
- [ ] Drei Presets sind im Projekt nutzbar oder dokumentiert reproduzierbar.
- [ ] Beispielszene zeigt Scissor, Hash und Blend nebeneinander.
- [ ] Doku nennt klare Einsatzregeln fuer Assetklassen.
- [ ] Bestehende Szenen starten unveraendert.

## Erwartetes Ergebnis
Transparente 3D-Assets bekommen eine einfache Performance-Leitplanke, bevor viele Props, Vegetation oder Cover-Objekte ins Projekt wandern.

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_253_verifier.gd`
- [ ] Manuelle Beispielszene oeffnen und Presets visuell pruefen.

## Dateien (voraussichtlich)
- `docs/rendering/3d_transparency_material_presets.md`
- `scripts/rendering/material_preset_factory.gd`
- `scenes/tests/transparent_material_benchmark.tscn`
- `scripts/tests/task_253_verifier.gd`

## Risiken
- Alpha-Blend kann Performance und Sorting verschlechtern. Deshalb muss Blend als Ausnahme dokumentiert bleiben.

# TASK_559 - Factory Colormap UID Loader Guard

## Status: IMPLEMENTIERT

## Ziel / Problem
Die aktuellen Frontier-Probe- und F6-Smokes laufen gruen, aber Godot meldet bei mehreren Factory-GLBs weiterhin laut:

`invalid UID: 'uid://dsxohkhemn17r' - using text path instead: 'res://Assets/curated/kenney/factory/models/Textures/colormap.png'`

Die Warnung ist funktional harmlos, macht Test- und Exportausgaben aber unnoetig laut und erschwert das Erkennen neuer echter Probleme.

## Sinnhaftigkeit / Ursache
TASK_524 hat bereits bestaetigt, dass die Factory-GLB-Quellen und `.import`-Textdateien keinen alten UID-Verweis mehr enthalten. Die aktuelle Ursache liegt im Godot-GLB-Ladepfad: `ResourceUID.create_id_for_path()` berechnet fuer den relativen Factory-Texturpfad genau die warnende UID, aber die lokale ResourceUID-Registry kennt diesen Pfad nicht. Dadurch faellt Godot beim Laden auf den Textpfad zurueck und warnt jedes Mal.

## Umfang
- `TerrainMap3DView` registriert vor dem Laden von Factory-GLBs die berechnete Factory-`Textures/colormap.png`-UID auf den bestehenden Texturpfad.
- Der Guard greift nur fuer Modelle unter `res://Assets/curated/kenney/factory/models/`.
- Kein Reimport, keine Asset-Skalierung, keine Gameplay- oder UI-Wahrheit.
- Neuer Verifier prueft, dass die deterministische Factory-Colormap-UID registriert wird und die zuvor lauten Factory-Modelle weiter laden.

## Nicht-Ziele
- Kein Umbenennen oder Neuimportieren der Factory-GLBs.
- Kein Entfernen der Factory-Assets.
- Kein Aendern von Materialfarben, Skalierung, Katalogdaten oder Map-Gameplay.
- Kein allgemeiner ResourceUID-Registry-Manager.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_524_export_warning_noise_cleanup.md`
- `docs/tasks/TASK_557_frontier_probe_multiplayer_f6_readability_pass.md`
- `docs/tasks/TASK_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.md`
- `scripts/terrain/terrain_map_3d_view.gd`

## Akzeptanzkriterien
- Die Factory-Colormap-UID aus `ResourceUID.create_id_for_path("res://Assets/curated/kenney/factory/models/Textures/colormap.png")` wird vor Factory-GLB-Loads registriert.
- Die vier bisher laut warnenden Modelle `detail-tank`, `building-a`, `chimney-medium` und `building-d` laden weiter als `PackedScene`.
- TASK_557 bleibt gruen und die alte `invalid UID`-Warnung erscheint im gezielten Smoke nicht mehr.
- `git diff --check` bleibt gruen.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_559_factory_colormap_uid_loader_guard.gd`
- `docs/tasks/TASK_559_factory_colormap_uid_loader_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_559_factory_colormap_uid_loader_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_557_frontier_probe_multiplayer_f6_readability_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Guard registriert eine Godot-ResourceUID fuer den Prozess, veraendert aber keine Assetquellen.
- Falls weitere externe GLB-Texturen mit aehnlichen UID-Luecken auftauchen, sollten sie als eigener Asset-Hygiene-Slice behandelt werden.
- Der naechste spielbare UI-Anschluss bleibt `TASK_560 - Frontier Probe Multiplayer F6 Visual Polish Follow-up`, sobald echte TASK_558-Notizen vorliegen.

# TASK_499 - Review Followup Architecture Cleanup

## Status
Implementiert im Arbeitsstand.

## Ziel / Problem
Der Review vom 2026-05-24 hat mehrere konkrete Drift- und Hotpath-Risiken benannt: eine tote `scenes/main.tscn`, einen Deep-SceneTree-Lookup im `SimulationRoot`-Snapshot-Audiopfad, uneindeutige map-only Mission-Catalog-Eintraege und eine leere `show_npc_thoughts`-InputMap-Bindung.

## Sinnhaftigkeit / Ursache
Die Befunde sind kleine, voneinander abgrenzbare Cleanup-Punkte. Sie reduzieren Fehlorientierung und Runtime-Hotpath-Risiko, ohne den grossen Legacy-Produktionspfad aus `scripts/tests/` in diesem Task anzufassen.

## Umfang
- `scenes/main.tscn` entfernen, weil sie unreferenziert ist und keine Script-Zuweisungen besitzt.
- `SimulationRoot._resolve_audio_event_bus()` auf exportierten NodePath, Kind-Node und direkte Parent-Sibling-Referenz begrenzen.
- Map-only Missionen im Homebase-Katalog explizit mit leerem `scenario_file_path` markieren.
- `show_npc_thoughts` als T-Hold im Projekt-InputMap-Eintrag hinterlegen.
- Einen Headless-Verifier fuer die Cleanup-Vertraege ergaenzen.

## Nicht-Ziele
- Keine Extraktion des `MissionCombatLoopDriver`.
- Keine Verschiebung produktiver Legacy-Driver aus `scripts/tests/`.
- Keine neue Mission-Scenario-Datei fuer `frontier_probe` oder `wall_breach`.
- Kein UI-Refactor der Team-Editor-Snapshot-Helfer.

## Relevante Contracts / Dokumente
- `AGENTS.md`
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/runtime_script_layout_contract.md`
- `docs/dev/audio_event_contract.md`

## Akzeptanzkriterien
- `scenes/main.tscn` ist nicht mehr im Projekt vorhanden und `project.godot` startet weiter in `res://scenes/ui/main_menu.tscn`.
- `SimulationRoot` nutzt keinen `find_child("AudioEventBus", true, false)`-Deep-Scan mehr.
- `frontier_probe` und `wall_breach` enthalten einen expliziten `scenario_file_path`-Key.
- `show_npc_thoughts` hat im Projekt eine Default-Key-Bindung fuer `T`.
- Der neue Verifier prueft diese Punkte headless.

## Betroffene Dateien
- `project.godot`
- `scripts/core/simulation_root.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scenes/main.tscn`
- `scripts/tests/task_499_review_followup_architecture_cleanup.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_499_review_followup_architecture_cleanup.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der vormals offene `frontier_probe`-Map-Verweis auf `res://maps/new_map.json` wurde in TASK_500 auf die getrackte `res://maps/station_outpost_64x64.json` umgebogen.
- Audio-Bus-Deep-Scans existieren noch in UI-/Visual-Helfern und im Legacy-Driver. Dieser Task entfernt nur den Review-Hotpath im `SimulationRoot`.
- Die grosse Legacy-Extraktion aus `scripts/tests/` bleibt Folgearbeit.

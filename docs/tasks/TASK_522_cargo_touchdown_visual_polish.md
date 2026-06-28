## Status: IMPLEMENTIERT

# TASK_522 - Cargo Touchdown Visual Polish

## Ziel / Problem
TASK_519 liefert den Cargo-Frachter als read-only Runtime-Snapshot, aber der Spieler sieht im Missionsbild noch nicht klar, wo der Frachter landen soll, ob er durch AA geblockt ist, ob er inbound ist, gelandet ist oder wieder abfliegt.

## Sinnhaftigkeit / Ursache
Der Frontier-Probe-Slice soll praktisch spielbar werden: Luftabwehr ausschalten, Computer halten, Cargo anlanden lassen und Abflug decken. Ohne sichtbaren Cargo-Status bleibt der letzte Missionsschritt abstrakt und schwer zu testen.

## Umfang
- Cargo-Snapshot aus `MissionCargoTouchdownBridge` im bestehenden Mission-Dropship-/Air-Visualpfad lesen.
- Read-only Cargo-Visualeintrag fuer Zielmarker, Anfluglinie, Frachterkoerper und Statuslabel erzeugen.
- `TerrainMap3DView` liefert Cargo-spezifische Render-Snapshot-Zaehler fuer Tests.
- Laufenden HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Keine neue Flugphysik.
- Kein neues Cargo-Gameplay-System.
- Kein Multiplayer-Ownership-Rewrite.
- Keine UI-Gameplay-Wahrheit im HUD oder Renderer.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_519_cargo_touchdown_runtime_bridge.md`
- `docs/tasks/TASK_518_mission_scenario_runtime_gates.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/air_asset_threat_damage_contract.md`
- `docs/dev/combat_loop_authority_contract.md`
- `docs/dev/html_report_workbench_contract.md`

## Akzeptanzkriterien
- Blocked/pending Cargo zeigt mindestens den Ziel-/Touchdown-Marker, ohne Gameplay-State zu mutieren.
- Inbound/landed/departing Cargo zeigt einen sichtbaren Air-Visual-Eintrag und Statuslabel.
- Departed Cargo entfernt die aktive Cargo-Visualisierung.
- Render-Snapshot meldet Cargo-Visual-, LZ-, Approach- und Label-Zaehler.
- Bestehende Cargo-/Gate-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_522_cargo_touchdown_visual_polish.gd`
- `docs/tasks/TASK_522_cargo_touchdown_visual_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_522_cargo_touchdown_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_519_cargo_touchdown_runtime_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_518_mission_scenario_runtime_gates.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Frachter nutzt vorerst den bestehenden Air-/Dropship-Renderer statt ein eigenes final art-directed Cargo-Modell.
- Der manuelle FullHD-Sichttest bleibt sinnvoll, weil Headless nur Zaehler, Status und Render-Snapshot prueft.

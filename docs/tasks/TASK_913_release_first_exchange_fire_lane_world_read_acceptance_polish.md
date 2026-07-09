# TASK_913 - Release First Exchange Fire Lane World Read Acceptance Polish

## Ziel / Problem
TASK_912 hat den TASK_911-Fenster-/Manifest-Befund read-only bewertet. Der erste Feuerwechsel ist in #17/#18/#19 sichtbar, aber im Weltbild wird die Source-to-target-Fire-Lane noch nicht sicher als erste intuitive Bewegung gelesen.

## Sinnhaftigkeit / Ursache
TASK_910 hat Label, Halo und Marker bereits zurueckgenommen. Der Restbefund ist enger: Fire-Lane, Source-/Target-Anker und ruhigeres Label-/Halo-Cluster muessen im echten Fenster noch etwas staerker die Blickfuehrung uebernehmen, ohne Combat-, Damage-, Command- oder HUD-Wahrheit neu zu oeffnen.

## Umfang
- TASK_913 als naechsten Visual-Polish auf der bestehenden TASK_910-Kette aktivieren.
- Fire-Lane-Core und Source-to-target-Beziehung leicht staerken.
- Target-Halo, Welt-Fire-Label und Weltlinien weiter beruhigen.
- Source-/Target-Anker so anheben, dass sie Richtung tragen, aber keine grossen Marker-Scheiben werden.
- Controller-Snapshot und `TerrainMap3DView.get_render_snapshot()` read-only erweitern.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture in diesem Task.
- Kein weiterer CONTACT-FIRE-Text als Ersatz fuer bessere Weltlesbarkeit.
- Kein Bottom-HUD-Refactor.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_912_release_first_exchange_fire_lane_world_read_visual_findings.md`
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneWorldReadAcceptancePolish.build_snapshot()` akzeptiert TASK_912-Findings als Quelle.
- `TerrainMap3DView.get_render_snapshot()` meldet `task_913_release_first_exchange_fire_lane_world_read_acceptance_v1`.
- TASK_913 ist nur aktiv, wenn TASK_910 aktiv ist.
- Fire-Lane-Core ist staerker als TASK_910, die Guide-Lane bleibt weich, Target-Halo und Fire-Label treten weiter zurueck.
- Source-/Target-Anker sind staerker als TASK_910, bleiben aber klein genug fuer ein nicht-debughaftes Weltbild.
- Controller liefert `get_release_first_exchange_fire_lane_world_read_acceptance_polish_snapshot()` read-only.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_913_release_first_exchange_fire_lane_world_read_acceptance_polish.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_acceptance_polish.gd`
- `scripts/tests/task_913_release_first_exchange_fire_lane_world_read_acceptance_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_913_release_first_exchange_fire_lane_world_read_acceptance_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_912_release_first_exchange_fire_lane_world_read_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_910_release_first_exchange_fire_lane_world_read_micro_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_913 ist weiterhin kein echter Fensterbeweis. Der naechste Slice muss nach dem Polish wieder frisch recapturen und den Spielerblick bewerten.

## Naechster Schritt
TASK_914 - Release First Exchange Fire Lane World Read Acceptance Recapture.

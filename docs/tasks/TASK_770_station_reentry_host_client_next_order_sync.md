# TASK_770 - Station Reentry Host Client Next Order Sync

## Ziel / Problem
Nach TASK_769 ist der erste Station-Reentry-Missionsentscheid strukturell schnell und kompakt. Offen bleibt, ob Host und Client im Reentry-Fenster denselben naechsten Auftrag lesen: Next-Order, Route und Cue duerfen zwischen beiden Fenstern nicht auseinanderlaufen.

## Sinnhaftigkeit / Ursache
Der sichtbare Zwei-Fenster-Lauf bleibt manuell, aber der Contract davor soll Drift vermeiden. Host und Client brauchen denselben read-only Auftragstext, waehrend Peer-/Team-Kontext getrennt bleibt. Sonst wirkt der Flow im Multiplayer widerspruechlich, obwohl die lokalen Preview-Daten gruen sind.

## Umfang
- Neuer read-only Contract `StationReentryHostClientNextOrderSync`.
- Neuer Controller-Snapshot `get_station_reentry_host_client_next_order_sync_snapshot()`.
- Verifier prueft Gleichstand von Next-Order, Route, Cue, Peer-/Team-Kontext, Textbudgets und Read-only-Regeln.
- Reentry-Handbuchbericht markiert TASK_770 als aktuellen Host/Client-Sync-Schritt.

## Nicht-Ziele
- Kein echter Zwei-Fenster-Playtest und kein Netzwerk-Profiler.
- Kein neuer Multiplayer-Authority-Pfad.
- Kein UI-Rebuild, kein GO, kein Command-Queue-Commit.
- Kein automatisches Abhaken manueller Workbench-Checks.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_769_station_reentry_performance_feel_pass.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Snapshot bleibt `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_command = false`.
- Host und Client melden denselben sichtbaren Next-Order-Text.
- Host und Client melden dieselbe Station-Route und denselben Cue.
- Host- und Client-Peer-IDs bleiben unterscheidbar; Team-IDs sind vorhanden.
- Textbudgets bleiben kompakt.
- Snapshot meldet `ready_for_visible_host_client_playtest = true`, wenn alle Sync-Gates gruen sind.

## Betroffene Dateien
- `scripts/mission/station_reentry_host_client_next_order_sync.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_770_station_reentry_host_client_next_order_sync.gd`
- `docs/tasks/TASK_770_station_reentry_host_client_next_order_sync.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_770_station_reentry_host_client_next_order_sync.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_769_station_reentry_performance_feel_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_770 beweist den Contract-Gleichstand, nicht den echten sichtbaren Netzwerk-Lauf.
- Der manuelle Zwei-Fenster-Reentry-Export bleibt der naechste sinnvolle Schritt.

# TASK_883 - Release First Exchange Real Window HUD Source Sync Fix

## Ziel / Problem
TASK_882 hat den echten Fensterbefund festgehalten: Der finale Runtime-Trace liest CONTACT FIRE, aber der sichtbare Spielerblick zeigt #17/#18/#19 weiter zuerst `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE`.

TASK_883 synchronisiert die sichtbaren Real-Window-HUD-Quellen mit dem belegten finalen CONTACT-FIRE-Trace-Stand.

## Sinnhaftigkeit / Ursache
TASK_879 beweist, dass die TASK_876-Statusquelle im exportierten Runtime-Trace aktiv wird und final keine stale `NO_LOS`-/`CONTACT_PRESSURE`-Lesung mehr meldet. TASK_881/TASK_882 zeigen aber, dass der echte Fensterblick trotzdem anders liest. Der wahrscheinlichste Reibungspunkt ist damit nicht Combat, LOS oder VFX, sondern der sichtbare Surface-Pfad: Labeltext und Event-Log-Panel konsumieren den belegten CONTACT-FIRE-Stand nicht gemeinsam oder nicht spaet genug.

## Umfang
- Kleinen read-only Source-Sync-Helper fuer #17 Selected Fireteam, #18 Mission Control und #19 Event Log bauen.
- Bestehende TASK_876-/CONTACT-FIRE-Quelle verwenden.
- `get_command_feedback_snapshot()` nach dem Rohaufbau synchronisieren, damit Event-Log und Test-/Trace-Snapshots denselben Stand bekommen.
- `_refresh_tactical_event_log_panel()` mit dem synchronisierten Snapshot fuettern.
- Sichtbare #17/#18-Labels nach dem Runtime-Text-Polish erneut aus derselben Quelle binden.
- Snapshot-/Verifier-Pfad fuer TASK_883 bereitstellen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein LOS-/Pathfinding-/VFX-Tuning.
- Keine neuen Commands, FireEvents, DamageEvents, Movement-Events oder Multiplayer-Wahrheit.
- Kein neuer Export oder Capture in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_882_release_first_exchange_fire_visual_findings.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`
- `docs/tasks/TASK_876_release_first_exchange_visible_status_source_reconciliation.md`

## Akzeptanzkriterien
- TASK_883-Snapshot meldet aktive Source-Synchronisierung, wenn TASK_876-Statusquelle aktiv ist.
- #17 beginnt mit CONTACT FIRE.
- #18 beginnt mit CONTACT FIRE.
- #19 Event Log enthaelt CONTACT FIRE als erste/neueste Display-Zeile.
- `NO FIRE` steht nicht vor CONTACT FIRE in den primaeren HUD-Zeilen.
- Der Sync bleibt read-only und erzeugt keine Gameplay-Wahrheit.
- Bestehende TASK_876-/TASK_882-Regressionspfade bleiben gruen.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_real_window_hud_source_sync.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`
- `docs/tasks/TASK_883_release_first_exchange_real_window_hud_source_sync_fix.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_883_release_first_exchange_real_window_hud_source_sync_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_876_release_first_exchange_visible_status_source_reconciliation.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_882_release_first_exchange_fire_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_883 korrigiert den HUD-/Event-Log-Sync im Runtime-Pfad, ersetzt aber keinen echten Fensterbeweis. Nach dem Fix braucht es als naechsten sinnvollen Schritt einen frischen Real-Window-Recapture, um zu pruefen, ob der Spieler CONTACT FIRE, FireTrace, Impact und Zielbezug nun wirklich zuerst liest.

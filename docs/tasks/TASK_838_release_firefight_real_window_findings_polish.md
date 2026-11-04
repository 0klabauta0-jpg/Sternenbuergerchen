# TASK_838 - Release Firefight Real Window Findings Polish

## Ziel / Problem

Der echte TASK_837-Fensterbefund zeigt den ersten GO-/Firefight-Zustand stabil, aber #19 Event Log bleibt mit `NO EVENTS` stumm, obwohl Selected Fireteam und Mission Control bereits `NEXT/WHY`, `NO FIRE`, LOS/Range und Drop-Status melden.

## Sinnhaftigkeit / Ursache

Die Runtime- und HUD-Snapshots tragen die relevante Entscheidungslage, aber das Event-Log-Panel rendert nur echte deduplizierte Tactical-Events. Im ersten Release-Firefight kann dieser echte Log noch leer sein; dadurch wirkt das Spiel blockiert oder tot, obwohl die taktische Diagnose aktiv ist.

## Umfang

- Display-Fallback fuer #19 Event Log, wenn der echte TacticalEventLog leer ist.
- Fallback liest vorhandene Decision-/Combat-Snapshots und wird nur als Panel-Displaydaten ausgegeben.
- Stabiler Style-/Task-Marker fuer Verifier und Release-Abnahme.
- MetaLayer-Snapshot fuer TASK_838.

## Nicht-Ziele

- Kein neues Gameplay-Event.
- Kein Combat-, LOS-, Damage- oder AI-Rewrite.
- Keine Aenderung an `SimulationRoot.enqueue_command()`.
- Kein World-Label-Declutter; das bleibt Folgearbeit.

## Relevante Contracts / Dokumente

- `docs/tasks/TASK_837_release_first_go_firefight_real_window_review.md`
- `docs/tasks/TASK_836_release_firefight_command_matrix_visual_polish.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien

- Im ersten GO-/Firefight-Deep-Link zeigt #19 Event Log mindestens eine Statuszeile statt leerem `NO EVENTS`, wenn Decision-/Combat-Diagnostik aktiv ist.
- Der echte `TacticalEventLog` bleibt unveraendert; der Fallback lebt nur im read-only Command-Feedback-Snapshot.
- Snapshot meldet `ui_sets_gameplay_truth=false`, `creates_command=false`, `creates_fire_event=false`, `creates_damage_event=false`.
- Panel-Render-Signatur bleibt stabil und baut nicht pro Frame durch wechselnde IDs/Zeitstempel neu.
- Der Snapshot prüft die aktuelle Panel-Projektion einschließlich des
  TASK_883-Fallbacks. Das historische TASK_836-Layout bleibt als Diagnose
  verfügbar. Die Sichtbarkeit der aktuellen Log-Zeile entscheidet das Gate.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_838_release_firefight_real_window_findings_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script scripts/tests/task_838_release_firefight_real_window_findings_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_836_release_firefight_command_matrix_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte

- Der Fallback ist ein Lesbarkeitsnetz, kein Ersatz fuer echte Tactical-Events. Wenn spaeter mehr echte Kontakt-/ROE-Events erzeugt werden, soll der Fallback automatisch zuruecktreten.
- Der echte Fensterbefund zeigt ausserdem noch dichte World-Labels; das ist als Folge-Task `TASK_839 - Release Firefight World Label Declutter` geeignet.

# TASK_826 - Release Mission LZ Drop Next Step Cue

## Ziel / Problem
Im frischen Release-Build landet der Spieler nach `Einzelspieler -> Start Mission` korrekt in der Mission, sieht aber im linken Fireteam-/Command-Bereich `keine Einheiten aktiv`, obwohl das Fireteam noch im Dropship sitzt und der naechste Griff `LZ setzen -> Drop` ist.

## Sinnhaftigkeit / Ursache
TASK_811 prueft den Missionsstart vor LZ, TASK_812 prueft erst nach LZ und Drop. Der echte Screenshot zeigt die Reibung genau dazwischen: Technisch sind Payload, Dropship-Card und LZ-Button vorhanden, aber die prominentere Selected-Fireteam-Anzeige beschreibt den Zustand wie einen Fehler statt als naechsten Handlungsschritt.

## Umfang
- Selected-Fireteam-Status zeigt vor dem Drop einen kompakten `Naechster Griff`-Cue.
- Mission-Insertion-Snapshot exportiert denselben Cue als read-only Daten.
- MetaLayer-Release-Smoke prueft, dass der Cue nach `Start Mission` sichtbar ist.

## Nicht-Ziele
- Kein neuer Dropship-, LZ- oder Boarding-Commit-Pfad.
- Keine Aenderung an Gameplay-Wahrheit, Simulation oder Transportlogik.
- Kein neuer Screenshot-/Pixeltest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_811_station_reentry_release_candidate_mission_launch_actionability_smoke.md`
- `docs/tasks/TASK_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.md`
- `docs/tasks/TASK_825_release_first_go_recent_movement_trace.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Nach `Einzelspieler -> Start Mission` lautet der naechste sichtbare Schritt vor LZ sinngemaess `Naechster Griff: LZ auf der Karte setzen | danach Drop`.
- Der Selected-Fireteam-Status zeigt den Cue, obwohl noch keine Bodeneinheiten aktiv sind.
- Der Snapshot liefert `insertion_next_step_id = set_lz` und bleibt read-only.
- `Drop` bleibt vor LZ sichtbar, aber deaktiviert.
- Bestehende TASK_811/TASK_812-Smokes bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_826_release_mission_lz_drop_next_step_cue.gd`
- `docs/tasks/TASK_826_release_mission_lz_drop_next_step_cue.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_826_release_mission_lz_drop_next_step_cue.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_811_station_reentry_release_candidate_mission_launch_actionability_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_812_station_reentry_release_candidate_lz_drop_preview_actionability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Cue macht den Zwischenzustand bedienbar, ersetzt aber nicht den naechsten echten Fenster-Run mit LZ, Drop, Preview und GO. Falls der Screenshot danach noch gedrueckt wirkt, ist das UI-Layout selbst Folgearbeit.

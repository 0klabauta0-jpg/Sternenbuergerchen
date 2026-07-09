# TASK_972 - Release First Decision Loop Two Playability Smoke

## Ziel / Problem
TASK_971 macht den zweiten Griff lesbarer. Jetzt muss der kleine Ablauf als Spielzug belegbar werden: `2ND` sehen, zweiten Griff bestaetigen, `GO` separat ausfuehren und danach Feedback lesen.

## Sinnhaftigkeit / Ursache
Der Review-Fokus ist nicht nur, dass ein Button existiert, sondern dass ein Spieler den naechsten Griff versteht und ausfuehren kann. Dieser Task verbindet den TASK_971-Polish mit einer read-only Smoke-Evidence fuer `2ND -> GO -> Feedback`.

## Umfang
- Read-only Playability-Smoke-Analyzer fuer TASK_972.
- Pflichtchecks fuer `2ND`-Sichtbarkeit, Confirm, getrenntes `GO`, Post-GO-Feedback, Pre-GO-Grenze, HUD-read-only und Multiplayer-Grenze.
- Controller-Export in `get_command_feedback_snapshot()`.
- Routing zu `TASK_973 - Release First Decision Loop Two Real Window Recapture` bei bestandenem Smoke.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein automatisches `GO`.
- Keine Runtime-Mutation im Analyzer.
- Kein Real-Window-Capture in diesem Task.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_971_release_first_decision_loop_two_visual_polish.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_playability_smoke.gd`

## Akzeptanzkriterien
- Fehlende TASK_971-Source blockiert.
- Fehlende Trace-Evidence bleibt `needs_playability_smoke_run`.
- Fehlender `GO` oder fehlendes Feedback routet zurueck zu TASK_971.
- Vollstaendige Trace-Evidence meldet `loop_two_playability_smoke_passed`.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_playability_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_972_release_first_decision_loop_two_playability_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_972_release_first_decision_loop_two_playability_smoke.gd`
- Regressionen: TASK_971, TASK_970, TASK_969
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke bewertet Evidence, ersetzt aber noch keinen echten Fensterblick. `TASK_973 - Release First Decision Loop Two Real Window Recapture` sollte danach den sichtbaren Zustand im laufenden Build pruefen.

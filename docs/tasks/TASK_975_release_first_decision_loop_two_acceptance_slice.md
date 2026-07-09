# TASK_975 - Release First Decision Loop Two Acceptance Slice

## Ziel / Problem
TASK_974 kann einen sauberen zweiten Recapture-Blick akzeptieren. Dieser Task macht daraus einen kleinen Acceptance-Slice: Der zweite Griff soll als Ablauf `2ND -> GO -> Feedback` im Release-Player-Loop belegbar sein.

## Sinnhaftigkeit / Ursache
Ein sauberer Sichtbefund ist noch kein spielbarer Loop. Der Acceptance-Slice verbindet den Befund mit Ablauf-Evidence: Kontext bleibt erhalten, `2ND` wird bestaetigt, `GO` bleibt separat, danach erscheint Feedback, und die Spielerfragen sind beantwortet.

## Umfang
- Read-only Acceptance-Analyzer fuer TASK_975.
- Bewertung einer akzeptierten TASK_974-Source plus Ablauf-Trace.
- Pflichtchecks fuer Homebase-bis-Mission-Kontext, `2ND`, getrenntes `GO`, Post-GO-Feedback, Smoke-Zeile, Spielerfragen, HUD-read-only und Multiplayer-Grenze.
- Routing zu `TASK_976 - Release First Decision Loop Two Player Loop Extension` bei bestandenem Slice.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein automatisches `GO`.
- Kein UI-Polish in diesem Task.
- Keine Commands, Movement-, Combat-, Damage- oder Multiplayer-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_974_release_first_decision_loop_two_recapture_visual_findings.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_acceptance_slice.gd`

## Akzeptanzkriterien
- Fehlende oder nicht akzeptierte TASK_974-Source blockiert.
- Akzeptierte Source ohne Trace bleibt `needs_acceptance_slice_trace`.
- Regressiver Trace routet zu `TASK_975 - Release First Decision Loop Two Recapture Visual Polish`.
- Vollstaendige Trace-Evidence meldet `loop_two_acceptance_slice_passed`.
- Der Snapshot bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_acceptance_slice.gd`
- `scripts/tests/task_975_release_first_decision_loop_two_acceptance_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_975_release_first_decision_loop_two_acceptance_slice.gd`
- Regressionen: TASK_974, TASK_973, TASK_972
- `git diff --check`

## Risiken / offene Punkte
- Der Acceptance-Slice beweist den kleinen zweiten Loop ueber Evidence, erweitert aber noch nicht den naechsten Spielerinhalt. TASK_976 sollte den naechsten inhaltlichen Griff bauen.

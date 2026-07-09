# TASK_984 - Release First Decision Loop Two Player Loop Acceptance Slice

## Ziel / Problem
TASK_983 macht die vier Runtime-Choices `SECURE`, `PUSH`, `FLANK` und `RESET` lesbarer, beweist aber noch nicht, dass der Vier-Choice-Loop als kleiner Spielerablauf akzeptierbar ist.

Der Spieler soll nach dem gepolishen zweiten Loop klar erkennen koennen: Welche Wahl gibt es, was passiert beim Confirm, warum bleibt `GO` separat, und ob die HUD-/Multiplayer-Grenzen weiter sauber sind.

## Sinnhaftigkeit / Ursache
Ohne Acceptance-Slice bleibt der neue Loop eine Sammlung von Button-Specs. Fuer ein rundes kleines Spiel brauchen wir einen belegbaren Ablauf, der aus sichtbaren Choices, Confirm-Feedback, getrennter Ausfuehrung und klarer naechster Entscheidung besteht.

## Umfang
- Neuer read-only Acceptance-Service fuer TASK_984.
- Bewertung eines TASK_983-Visual-Polish-Snapshots plus Ablauf-Trace.
- Pflichtchecks fuer vier sichtbare Choices, GO-Trennung, Confirm-Feedback, keine Auto-Ausfuehrung, Spielerlesbarkeit, HUD-read-only und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neuer Command-Pfad.
- Kein automatisches `GO`.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.
- Kein neues Szenario und kein weiterer Player-Loop in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_983_release_first_decision_loop_two_player_loop_visual_polish.md`
- `docs/tasks/TASK_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_984 blockiert ehrlich, wenn die TASK_983-Quelle fehlt, nicht ready oder nicht read-only ist.
- Eine ready TASK_983-Quelle ohne Ablauf-Trace bleibt `needs_player_loop_acceptance_trace`.
- Ein regressiver Trace benennt fehlende Choice-, Confirm-, GO-, Lesbarkeits- oder Multiplayer-Grenzen und routet zurueck zu Visual Polish.
- Ein guter Trace setzt `player_loop_acceptance_slice_passed`, liefert eine kurze Acceptance-Zeile und empfiehlt den naechsten Szenario-/Outcome-Slice.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_acceptance_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_984_release_first_decision_loop_two_player_loop_acceptance_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_984_release_first_decision_loop_two_player_loop_acceptance_slice.gd`
- Regression: TASK_983, TASK_982, TASK_980
- `git diff --check`

## Risiken / offene Punkte
- TASK_984 akzeptiert den Choice-Loop als Ablauf, erzeugt aber noch kein neues Szenarioziel.
- Naechster sinnvoller Schritt: `TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice`.

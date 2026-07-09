# TASK_985 - Release First Decision Loop Two Player Loop Scenario Outcome Slice

## Ziel / Problem
TASK_984 akzeptiert den Vier-Choice-Loop als Bedienablauf, aber der Spieler bekommt daraus noch kein kleines Szenario-Ergebnis.

Der Loop soll nach einer akzeptierten Choice ein lesbares Outcome liefern: Welche Wahl wurde vorbereitet, was bedeutet das taktisch, welcher Mini-Erfolg oder welche Reibung ist sichtbar, und was ist der naechste Griff.

## Sinnhaftigkeit / Ursache
Ein Spielgriff fuehlt sich erst rund an, wenn er zu einem Ergebnis fuehrt. Ohne Outcome bleibt `SECURE/PUSH/FLANK/RESET` eine gute Bedienung, aber noch kein kleines Spielstueck.

## Umfang
- Neuer read-only Scenario-Outcome-Service fuer TASK_985.
- Bewertung eines bestandenen TASK_984-Acceptance-Slices plus Outcome-Trace.
- Pflichtchecks fuer gewaehlte Choice, sichtbare Outcome-Zeile, Mini-Zielzustand, naechsten Griff, Spielerlesbarkeit, HUD-read-only und Multiplayer-Grenze.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein Missionsabschluss-System.
- Kein Skill-/XP-System.
- Kein neuer Command-Pfad.
- Kein Combat-, Movement- oder Multiplayer-Rewrite.
- Kein echter Fenster-Capture; das ist Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_984_release_first_decision_loop_two_player_loop_acceptance_slice.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_985 blockiert ehrlich, wenn TASK_984 fehlt, nicht bestanden oder nicht read-only ist.
- Ein bestandener TASK_984-Slice ohne Outcome-Trace bleibt `needs_player_loop_outcome_trace`.
- Ein regressiver Outcome-Trace benennt fehlende Outcome-, Mini-Ziel-, Next-Step-, Lesbarkeits- oder Multiplayer-Grenzen.
- Ein guter Trace setzt `player_loop_scenario_outcome_ready`, liefert Outcome-Zeile, Result-Tag, Next-Step-Zeile und empfiehlt den Outcome-Real-Window-Capture.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_outcome_slice.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_985_release_first_decision_loop_two_player_loop_scenario_outcome_slice.gd`
- Regression: TASK_984, TASK_983, TASK_980
- `git diff --check`

## Risiken / offene Punkte
- TASK_985 erzeugt ein Outcome als Contract, aber noch keinen echten Fensterbeweis.
- Naechster sinnvoller Schritt: `TASK_986 - Release First Decision Loop Two Player Loop Outcome Real Window Capture`.

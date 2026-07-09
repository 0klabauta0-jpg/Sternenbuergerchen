# TASK_992 - Release First Decision Loop Two Player Loop Micro Objective Choice Hook

## Ziel / Problem
TASK_991 macht die naechsten Micro-Objectives sichtbar, aber daraus entsteht noch kein vorbereitbarer Spielergriff.

TASK_992 baut aus dem fokussierten Micro-Objective einen read-only Command-Draft fuer die bestehenden Confirm- und GO-Pfade.

## Sinnhaftigkeit / Ursache
Die Entscheidungsschleife fuehlt sich erst dann rund an, wenn ein sichtbarer naechster Griff auch als konkrete Wahl vorbereitet werden kann. Dieser Task bleibt bewusst vor der echten Runtime-Button-Bedienung und prueft nur den Contract.

## Umfang
- Neuer read-only Choice-Hook-Service fuer TASK_992.
- Bewertung einer bereiten TASK_991-Quelle.
- Auswahl der fokussierten oder explizit uebergebenen Micro-Objective.
- Mapping auf bestehende Command-Typen:
  - `SICHERN` -> `defend`
  - `DRUECKEN` -> `move`
  - `SAMMELN` -> `hold`
- Command-Draft mit `_issue_command` als Confirm-Pfad und `execute_selected_fireteam_orders` als bestehendem GO-Pfad.
- Controller-Snapshot und Command-Feedback-Export.
- Status-/Roadmap-/Contract-Update.

## Nicht-Ziele
- Kein neuer Runtime-Button.
- Kein automatischer Command-Confirm.
- Kein automatischer `GO`.
- Kein Movement-, Combat-, Damage- oder Multiplayer-Rewrite.
- Keine neue Command-Architektur.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_991_release_first_decision_loop_two_player_loop_micro_objective_hud_wiring.md`
- `docs/tasks/TASK_990_release_first_decision_loop_two_player_loop_next_micro_objective.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_992 blockiert ehrlich, wenn TASK_991 nicht bereit oder nicht read-only ist.
- Ein bereiter TASK_991-Snapshot erzeugt fuer die fokussierte Micro-Objective einen Command-Draft.
- `SICHERN`, `DRUECKEN` und `SAMMELN` mappen auf vorhandene Command-Typen.
- Der Draft nennt vorhandene Confirm-/GO-Pfade, fuehrt sie aber nicht aus.
- Unbekannte Objective-IDs blockieren ohne Draft.
- Controller exportiert TASK_992 im Command-Feedback.
- Snapshot und Controller-Export erzeugen keine UI-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_choice_hook.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_992_release_first_decision_loop_two_player_loop_micro_objective_choice_hook.gd`
- Regression: TASK_991, TASK_990, TASK_989
- `git diff --check`

## Risiken / offene Punkte
- TASK_992 erzeugt einen vorbereitenden Draft, aber noch keine echte klickbare Runtime-Auswahl.
- Naechster sinnvoller Schritt: `TASK_993 - Release First Decision Loop Two Player Loop Micro Objective Runtime Buttons`.

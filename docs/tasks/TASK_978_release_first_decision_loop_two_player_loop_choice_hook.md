# TASK_978 - Release First Decision Loop Two Player Loop Choice Hook

## Ziel / Problem
TASK_977 macht `SECURE`, `PUSH`, `FLANK` und `RESET` sichtbar, aber die Choices haben noch keinen sicheren Anschluss an vorhandene Befehlswege.

Der Spieler soll sehen koennen, welcher Befehl beim naechsten Schritt vorbereitet wuerde, ohne dass das HUD schon Commands erzeugt oder `GO` ausfuehrt.

## Sinnhaftigkeit / Ursache
Ein sichtbarer Choice-Chip ist erst dann spielbar verstaendlich, wenn klar ist, welcher bestehende Commander-Befehl dahinter liegt. Gleichzeitig darf dieser Schritt keine zweite Gameplay-Wahrheit im HUD erzeugen.

## Umfang
- Neuer read-only Choice-Hook-Service fuer TASK_978.
- Mapping der sichtbaren Choices:
  - `secure_area` -> `defend`
  - `push_objective` -> `move`
  - `flank_pressure` -> `flank`
  - `reset_spacing` -> `move`
- Command-Draft mit `confirm_action = _issue_command` und `execute_action = execute_selected_fireteam_orders`.
- Controller-Snapshot und Export in `get_command_feedback_snapshot()`.

## Nicht-Ziele
- Kein Button-Layout fuer die vier Choices.
- Kein automatisches Bestaetigen.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, kein Combat, kein Damage.
- Keine Multiplayer-Wahrheit und keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_977_release_first_decision_loop_two_player_loop_hud_wiring.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_978 blockiert ehrlich, wenn TASK_977 nicht aktiv/read-only ist.
- Eine gueltige Choice erzeugt einen read-only `command_draft`.
- Der Draft benennt vorhandene Pfade und haelt `GO` separat.
- Unbekannte Choices erzeugen keinen Draft.
- `get_command_feedback_snapshot()` exportiert den TASK_978-Snapshot, die Hook-Zeile und den Command-Draft.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_choice_hook.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_978_release_first_decision_loop_two_player_loop_choice_hook.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_978_release_first_decision_loop_two_player_loop_choice_hook.gd`
- Regression: TASK_977, TASK_976, TASK_975, TASK_974
- `git diff --check`

## Risiken / offene Punkte
- TASK_978 baut nur den read-only Choice-Hook. Die vier Choices sind noch nicht als Runtime-Buttons klickbar.
- Naechster sinnvoller Schritt: `TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons`.

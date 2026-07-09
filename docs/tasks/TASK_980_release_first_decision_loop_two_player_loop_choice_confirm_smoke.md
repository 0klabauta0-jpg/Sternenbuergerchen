# TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke

## Ziel / Problem
TASK_979 stellt `SECURE`, `PUSH`, `FLANK` und `RESET` als Runtime-Button-Spezifikationen bereit, aber es ist noch nicht belegt, dass ein Klick auf diese Choices nur den vorhandenen Command-Pfad vorbereitet und `GO` separat bleibt.

Der Spieler soll eine Choice bestaetigen koennen, Feedback sehen und danach bewusst `GO` druecken muessen.

## Sinnhaftigkeit / Ursache
Der zweite Spielerloop wird erst spielbar, wenn die vier sichtbaren Choices nicht nur beschriftet sind, sondern einen sicheren, konsistenten Bedienpfad haben. Gerade hier darf kein HUD-Pfad heimlich Movement ausloesen oder eine zweite Gameplay-Wahrheit speichern.

## Umfang
- Neuer read-only Smoke-Service fuer TASK_980.
- Controller-Callback fuer die TASK_979-Choice-Buttons.
- Trace-/Snapshot-Auswertung fuer:
  - Button gedrueckt
  - Confirm-Pfad vorhanden und aufgerufen
  - GO-Pfad vorhanden und weiterhin getrennt
  - kein Auto-GO beim Choice-Confirm
  - Post-Confirm-Feedback sichtbar
- Export in `get_command_feedback_snapshot()`.

## Nicht-Ziele
- Kein automatisches `GO`.
- Kein neuer Command-Resolver.
- Kein Combat-, Damage- oder Movement-Rewrite.
- Kein Real-Window-Capture; das ist Folgearbeit.
- Keine Multiplayer-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_980 blockiert ehrlich, wenn TASK_979 oder TASK_978 nicht aktiv/read-only sind.
- Gueltige TASK_979-Buttons ohne Trace bleiben `needs_choice_confirm_smoke`.
- Gueltiger Trace mit Choice-Press, Confirm-Erfolg, separatem GO und Feedback besteht.
- Trace mit Auto-GO oder fehlendem Feedback wird als Regression markiert.
- `MissionTacticalSandboxController` bietet einen Runtime-Callback fuer die Choice-Buttons und exportiert den TASK_980-Snapshot.
- Snapshot und Smoke erzeugen keine Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_choice_confirm_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_980_release_first_decision_loop_two_player_loop_choice_confirm_smoke.gd`
- Regression: TASK_979, TASK_978, TASK_977, TASK_976
- `git diff --check`

## Risiken / offene Punkte
- TASK_980 beweist den Choice-Confirm als Smoke, aber noch nicht den echten Fensterblick.
- Naechster sinnvoller Schritt: `TASK_981 - Release First Decision Loop Two Player Loop Real Window Capture`.

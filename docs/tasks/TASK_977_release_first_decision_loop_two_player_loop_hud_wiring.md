# TASK_977 - Release First Decision Loop Two Player Loop HUD Wiring

## Ziel / Problem
TASK_976 erzeugt nach einem akzeptierten zweiten Griff wieder eine echte naechste Spielerentscheidung, aber diese Optionen landen noch nicht in den gemeinsamen HUD-/Command-Feedback-Snapshots.

Der Spieler soll nach `2ND -> GO -> Feedback` nicht in einer Sackgasse stehen, sondern die naechsten vier Griffe `SECURE`, `PUSH`, `FLANK` und `RESET` als kurze, lesbare HUD-Zeilen bekommen.

## Sinnhaftigkeit / Ursache
Die Daten sind seit TASK_976 vorhanden, aber ohne HUD-Wiring bleiben sie fuer den sichtbaren Spielfluss abstrakt. Der naechste Schritt zum kleinen runden Spiel ist daher kein neues Combat-System, sondern ein klarer Anschluss an #17 Selected Fireteam, #18 Mission Control und `get_command_feedback_snapshot()`.

## Umfang
- Neuer read-only HUD-Wiring-Service fuer TASK_977.
- Controller-Methode fuer TASK_976-Extension-Snapshot.
- Controller-Methode fuer TASK_977-HUD-Wiring-Snapshot.
- Export in `get_command_feedback_snapshot()`.
- Kurze Zeilen fuer Selected Fireteam, Mission Control und Command Feedback.
- Vier read-only Choice-Chips fuer `SECURE`, `PUSH`, `FLANK`, `RESET`.

## Nicht-Ziele
- Keine Choice-Buttons ausfuehren.
- Kein automatisches `GO`.
- Keine Commands, kein Movement, kein Combat, kein Damage.
- Keine Multiplayer-Wahrheit und keine Shortcut-Aenderung.
- Keine Behauptung, dass ein nicht bestandener Acceptance-Slice aktiv spielbar ist.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_976_release_first_decision_loop_two_player_loop_extension.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_977 blockiert ehrlich, wenn TASK_976 nicht aktiv/read-only ist.
- Bei aktiver TASK_976-Quelle entstehen `selected_fireteam_line`, `mission_control_line`, `command_feedback_line` und vier `hud_choice_chips`.
- `get_command_feedback_snapshot()` exportiert den TASK_977-Snapshot und die kompakte HUD-Wiring-Zeile.
- Alle Daten bleiben read-only und erzeugen keine Commands, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_hud_wiring.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_977_release_first_decision_loop_two_player_loop_hud_wiring.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_977_release_first_decision_loop_two_player_loop_hud_wiring.gd`
- Regression: TASK_976, TASK_975, TASK_974, TASK_973
- `git diff --check`

## Risiken / offene Punkte
- TASK_977 macht die naechsten Choices sichtbar, aber noch nicht als ausfuehrbare Runtime-Auswahl bedienbar.
- Naechster sinnvoller Schritt: `TASK_978 - Release First Decision Loop Two Player Loop Choice Hook`.

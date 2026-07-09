# TASK_979 - Release First Decision Loop Two Player Loop Runtime Choice Buttons

## Ziel / Problem
TASK_978 erzeugt einen sicheren Command-Draft fuer `SECURE`, `PUSH`, `FLANK` oder `RESET`, aber im Runtime-HUD gibt es noch keine stabilen Button-Spezifikationen fuer diese vier naechsten Griffe.

Der Spieler soll die naechsten Choices als echte, kompakte Command-Slots lesen koennen, ohne dass dadurch schon `GO` ausgefuehrt oder Gameplay-Wahrheit im HUD gespeichert wird.

## Sinnhaftigkeit / Ursache
Die Entscheidungskette ist inzwischen lesbar und logisch anschlussfaehig. Der naechste Schritt zum runden kleinen Spiel ist ein sichtbarer Bedienrahmen: vier Buttons auf stabilen Slots, mit Choice-ID, Tooltip, Confirm-Pfad und klarer `GO separat`-Grenze.

## Umfang
- Neuer read-only Runtime-Choice-Buttons-Service fuer TASK_979.
- Vier stabile Button-Spezifikationen:
  - `CommandSlot08` = `SECURE`
  - `CommandSlot09` = `PUSH`
  - `CommandSlot10` = `FLANK`
  - `CommandSlot11` = `RESET`
- Controller-Snapshot und Export in `get_command_feedback_snapshot()`.
- Optionales Markieren der vorhandenen Button-Nodes mit TASK_979-Metadaten, wenn die Command-Matrix aktiv ist.

## Nicht-Ziele
- Kein finaler Klick-Smoke.
- Kein automatisches `GO`.
- Keine bestaetigte Order im Snapshot.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Wahrheit.
- Keine neuen Shortcut-Bindings.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_978_release_first_decision_loop_two_player_loop_choice_hook.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`

## Akzeptanzkriterien
- TASK_979 blockiert ehrlich, wenn TASK_978 oder TASK_977 nicht aktiv/read-only sind.
- Eine gueltige TASK_978-Quelle plus TASK_977-HUD-Wiring erzeugt vier Button-Spezifikationen.
- Alle Button-Specs nennen Slot, Text, Choice-ID, Press-Action und getrennten GO-Pfad.
- `get_command_feedback_snapshot()` exportiert TASK_979-Snapshot, Runtime-Button-Zeile und Button-Specs.
- Der Snapshot selbst erzeugt keine Commands und kein Movement.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_runtime_choice_buttons.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_979_release_first_decision_loop_two_player_loop_runtime_choice_buttons.gd`
- Regression: TASK_978, TASK_977, TASK_976, TASK_975
- `git diff --check`

## Risiken / offene Punkte
- TASK_979 macht die Runtime-Buttons spezifiziert und optisch vorbereitbar, aber der Klick-Confirm-Smoke ist noch offen.
- Naechster sinnvoller Schritt: `TASK_980 - Release First Decision Loop Two Player Loop Choice Confirm Smoke`.

# TASK_702 - Door Authority Compact HUD Surface

## Ziel / Problem
TASK_701 liefert bessere Door-Authority-Felder, aber die sichtbare Mission-Command-Zeile nutzt noch die laengere Summary. Der Spieler soll im HUD eine kurze, scanbare Door-Zeile sehen, waehrend Tooltip und Snapshots weiter Details liefern.

## Sinnhaftigkeit / Ursache
Die Polishing-Felder bringen erst Spielwert, wenn die sichtbaren Surfaces sie verwenden. Die Command-Feedback-Zeile ist ein stark frequentierter HUD-Ort; lange Door-Texte erhoehen dort Leselast und Overlap-Risiko.

## Umfang
- Sichtbare Door-Authority-Zeile im Mission-Command-Feedback nutzt `compact_line`.
- Fallback auf `summary_line`, falls alte Snapshots kein Compact-Feld haben.
- Command-Feedback-Snapshot exportiert die sichtbare Surface-Zeile separat.
- Verifier prueft ready/blocked/open Compact-Surface-Logik und Controller-Export.
- Status, Roadmap, Contract und aktuelles HTML-Handbuch werden aktualisiert.

## Nicht-Ziele
- Kein echter Host/Client-Fensterklicktest.
- Kein Layout-Redesign des Command-Panels.
- Keine Aenderung an Door-Commands, Runtime-State, TerrainRegistry oder Multiplayer-Authority.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_701_door_authority_feedback_polish.md`
- `docs/tasks/TASK_700_host_client_door_real_click_workbench.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `MissionTacticalSandboxController._build_visible_door_authority_command_line()` bevorzugt `compact_line`.
- Pending ohne nutzbare Door bleibt unsichtbar.
- Command-Feedback-Snapshot exportiert `mission_interaction_door_authority_visible_line`.
- Ready nutzt eine kurze `B->GO`-Zeile.
- Blocked/Open koennen kompakt dargestellt werden, ohne UI-Wahrheit zu setzen.
- TASK_701 und TASK_698 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_702_door_authority_compact_hud_surface.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_702_door_authority_compact_hud_surface.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_701_door_authority_feedback_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_698_door_authority_ui_feedback.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die echte FullHD-Lesbarkeit muss spaeter im Fenster geprueft werden; dieser Task macht nur die Surface-Zeile kompakter und testbar.
- Wenn der echte Sichtlauf weiter Overlap zeigt, braucht es danach Layout-/Positionierungs-Polish.

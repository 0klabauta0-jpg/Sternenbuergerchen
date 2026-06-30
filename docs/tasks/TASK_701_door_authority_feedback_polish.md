# TASK_701 - Door Authority Feedback Polish

## Ziel / Problem
Door-Breach ist technisch abgesichert, aber die sichtbare Statussprache ist noch zu technisch und nicht konsequent priorisiert. Der Spieler soll im Button, Tooltip und Command-Feedback schneller verstehen: bereit, GO erforderlich, Host akzeptiert, falsches Team blockiert oder Door offen.

## Sinnhaftigkeit / Ursache
TASK_698 bis TASK_700 haben Authority, UI-Feedback, Capture und Workbench getrennt. Jetzt lohnt ein kleiner Polish-Slice direkt am gemeinsamen read-only Feedback-Contract, damit alle sichtbaren Door-Feedback-Surfaces dieselbe kurze Sprache und dieselben naechsten Schritte nutzen.

## Umfang
- `MissionInteractionDoorMultiplayerAuthority.build_ui_feedback()` um kompakte Spielerfelder erweitern.
- Reject-Gruende in lesbare Spielerhinweise normalisieren.
- Tooltip-Zeilen nach Prioritaet sortieren: Status, naechste Aktion, Detail, Autoritaet.
- Button- und Command-Snapshots exportieren die neuen Felder read-only.
- Regressionen fuer ready, blocked, accepted und open.

## Nicht-Ziele
- Kein echter Zwei-Fenster-Klicktest.
- Kein neuer Door-Command-Pfad.
- Keine Aenderung an `SimulationRoot`, Netzwerkautoritaet, TerrainRegistry oder Runtime-Progress.
- Kein Layout- oder Skin-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_700_host_client_door_real_click_workbench.md`
- `docs/tasks/TASK_699_multiplayer_door_feedback_capture.md`
- `docs/tasks/TASK_698_door_authority_ui_feedback.md`

## Akzeptanzkriterien
- UI-Feedback liefert `player_hint`, `next_action`, `severity`, `compact_line` und `reject_reason_label`.
- Wrong-Team-Reject wird als Team-/Berechtigungsproblem lesbar, nicht nur als roher Contract-Key.
- State-Mutation-Reject wird als Client-/State-Mutation-Blocker lesbar.
- Ready/Accepted/Open bleiben kurz und nennen GO, Host oder Runtime Producer passend.
- Button-Snapshot exportiert die neuen Felder, ohne Gameplay-Wahrheit zu setzen.
- Bestehende TASK_698/TASK_699-Verifier bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_interaction_door_multiplayer_authority.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_701_door_authority_feedback_polish.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_701_door_authority_feedback_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_698_door_authority_ui_feedback.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_699_multiplayer_door_feedback_capture.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Host/Client-Klicklauf bleibt weiter manuell offen; dieser Task verbessert die erwartbare Lesbarkeit vor dem Sichtentscheid.
- Falls der spaetere Fensterlauf andere Platzprobleme zeigt, braucht es einen separaten Layout-/Visual-Polish-Slice.

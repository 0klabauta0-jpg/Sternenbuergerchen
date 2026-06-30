# TASK_698 - Door Authority UI Feedback

## Ziel / Problem
Door-Breach ist technisch autorisiert und gegen falsche Peers/State-Mutation abgesichert, aber der Spieler sieht im Command-Bereich noch nicht klar genug, ob der Door-Befehl lokal bereit, hostseitig akzeptiert oder durch Authority-Regeln blockiert waere.

## Sinnhaftigkeit / Ursache
TASK_697 beweist den technischen Pfad. Fuer angenehmes, multiplayerfaehiges Spielen braucht der HUD-/Command-Pfad eine kurze lesbare Zeile aus demselben Snapshot, damit Door-Bedienung nicht wie ein stummer Spezialfall wirkt.

## Umfang
- `MissionInteractionDoorMultiplayerAuthority` erzeugt einen kompakten UI-Readout aus dem read-only Authority-Snapshot.
- Der TacticalController exportiert `mission_interaction_door_authority_ui_feedback` im Command-Feedback-Snapshot.
- Der Door-Breach-Button bekommt Tooltip/Status aus diesem Feedback, ohne Gameplay-State zu setzen.
- Der Feedback-Text unterscheidet mindestens `ready`, `accepted`, `blocked`, `pending` und `open`.

## Nicht-Ziele
- Kein echter Zwei-Fenster-Sichttest.
- Kein neues Multiplayer-Protokoll.
- Kein Command-Commit im UI.
- Keine Door-/Terrain-Mutation ausserhalb des bestehenden Runtime Producers.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_697_door_interaction_multiplayer_authority_check.md`
- `docs/tasks/TASK_695_door_interaction_hud_button_shortcut.md`

## Akzeptanzkriterien
- Command-Feedback exportiert eine kurze Door-Authority-Zeile fuer UI/Reports.
- Door-Breach-Button-Tooltip nennt `B`, GO-Pflicht und Authority-/Teamhinweis.
- Host-Accept, Wrong-Team-Reject und State-Mutation-Reject koennen als unterschiedliche Readout-Zustaende dargestellt werden.
- Der Readout ist read-only und setzt keine Gameplay-Wahrheit.
- Bestehende Door-Hook-, Door-Visual- und Multiplayer-Authority-Tests bleiben gruen.

## Betroffene Dateien
- `scripts/mission/mission_interaction_door_multiplayer_authority.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_698_door_authority_ui_feedback.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_698_door_authority_ui_feedback.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_697_door_interaction_multiplayer_authority_check.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_695_door_interaction_hud_button_shortcut.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Host/Client-Fensterlauf bleibt weiterhin offen.
- Ohne echten Peer-Lauf ist die Anzeige technisch belegt, aber noch nicht menschlich sichtgetestet.

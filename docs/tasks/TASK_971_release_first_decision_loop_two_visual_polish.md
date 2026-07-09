# TASK_971 - Release First Decision Loop Two Visual Polish

## Ziel / Problem
TASK_970 kann Sichtreibung am zweiten Griff benennen, aber der Runtime-Pfad zeigt noch keine eigene Polish-Leseschicht fuer `2ND`, die klare `GO`-Trennung und das Feedback nach dem zweiten Griff.

## Sinnhaftigkeit / Ursache
Der Spieler soll nicht raten, ob `2ND` schon ausfuehrt oder nur den zweiten Griff bestaetigt. Der Button und die Command-Feedback-Zeile brauchen eine stabile, knappe Lesefassung: `2ND` bestaetigt, danach bleibt `GO` separat.

## Umfang
- Read-only Visual-Polish-Snapshot fuer TASK_971.
- Controller-Export in `get_command_feedback_snapshot()`.
- Tooltip, Mindestgroesse und Metadaten auf dem bestehenden `CommandSlot07`-Button.
- HUD-/Command-Feedback-Linie fuer `2ND ... | danach GO separat`.

## Nicht-Ziele
- Keine neue Command-Ausfuehrung.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutation.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_970_release_first_decision_loop_two_visual_findings.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `scripts/mission/release_first_decision_loop_two_visual_polish.gd`

## Akzeptanzkriterien
- Fehlende TASK_970-Source blockiert.
- Polish-Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.
- `button_text` bleibt kompakt `2ND`.
- Tooltip/HUD-Zeile nennen den zweiten Griff und `GO separat`.
- `MissionTacticalSandboxController` exportiert den TASK_971-Snapshot und die Linie im Command Feedback.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_971_release_first_decision_loop_two_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_971_release_first_decision_loop_two_visual_polish.gd`
- Regressionen: TASK_970, TASK_969, TASK_968
- `git diff --check`

## Risiken / offene Punkte
- TASK_971 verbessert Lesbarkeit und Feedback-Vertrag, beweist aber noch nicht den kompletten zweiten Griff im echten Spielablauf. `TASK_972 - Release First Decision Loop Two Playability Smoke` sollte den Playability-Smoke fuer `2ND -> GO -> Feedback` schneiden.

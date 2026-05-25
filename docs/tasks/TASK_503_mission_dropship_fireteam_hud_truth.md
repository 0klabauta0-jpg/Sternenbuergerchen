# TASK_503 - Mission Dropship Fireteam HUD Truth

## Ziel / Problem
Fireteams im Dropship duerfen im Mission-HUD links nicht wie Bodentrupps wirken, solange ihre Mitglieder noch embarked und nicht deployed sind.

## Ursache
Der Mission-Tactical-Controller liess versteckte, embarked Units in mehreren Fireteam-UI-Pfaden wieder zu. Dadurch konnten linke Mini-Cards und die ausgewaehlten Member-Karten aus einer Transport-Wahrheit anzeigen, obwohl der Contract sagt: embarked bleibt in der Dropship-Payloadkarte, deployed erscheint links als Bodentrupp.

## Umfang
- Fireteam-Mini-Cards zeigen nur Fireteams mit ground/deployed Units.
- Ausgewaehlte embarked Fireteams zeigen im Detailbereich nur den Hinweis "Fireteam im Dropship.", keine Member-Karten.
- Dropship-Payloadkarten bleiben unveraendert die Anzeige fuer embarked Fireteams.

## Nicht-Ziele
- Kein Rework der Dropship-Phasen.
- Kein neues Transportdatenmodell.
- Keine Layout-Neugestaltung der Mission-HUD-Panels.

## Relevante Contracts / Dokumente
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- Ein nur embarked Fireteam erscheint nicht in der linken Fireteam-Mini-Card-Liste.
- Ein nur embarked, ausgewaehltes Fireteam zeigt keine Member-Karten im `#17 SELECTED FIRETEAM`-Bereich.
- Nach Deployment erscheint dasselbe Fireteam wieder in der linken Fireteam-Liste.
- Mehrere Dropships behalten ihre eigenen Payloads, LZs und Fireteam-IDs.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_503_mission_dropship_fireteam_hud_truth.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
Die grosse Mission-Tactical-Datei bleibt Legacy-Bridge unter `scripts/tests/`. Dieser Task haertet nur die Anzeige-Wahrheit fuer Dropship/Fireteam-HUD und verschiebt keine Architekturgrenzen.

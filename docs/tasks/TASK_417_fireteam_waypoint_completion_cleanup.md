# TASK_417 - Fireteam Waypoint Completion Cleanup

## Ziel / Problem

Wenn ein Fireteam einen Waypoint erreicht und den dortigen Befehl ausgefuehrt hat, soll dieser Waypoint aus dem aktiven Plan entfernt werden. Danach kann das Team den naechsten Waypoint ohne haengenden Altpunkt abarbeiten.

## Sinn / Ursache

Der Mission-Tactical-Pfad aktiviert zwar Folge-Waypoints, laesst erledigte Waypoints aber als abgeschlossene Eintraege im Plan stehen. Das ist fuer den Playtest irritierend und kann Visuals, Zaehlungen und Folgeaktivierung schwer nachvollziehbar machen.

## Umfang

- Abgeschlossene Fireteam-Waypoints werden im Mission-Tactical-Pfad aus `FireteamOrderPlan.waypoints` entfernt.
- Nach dem Entfernen wird der naechste ausfuehrbare Waypoint anhand des neuen Indexes aktiviert.
- Leere Plaene werden abgeschlossen und fallen aus der Order-Visualisierung heraus.
- Defend-/Hold-Waypoints behalten die bestehende GO-Freigabe-Logik; beim Freigeben wird der alte Waypoint entfernt und der naechste aktiviert.
- Headless-Verifier fuer Indexverschiebung, Planabschluss und sichtbaren Snapshot ohne erledigte Waypoints.

## Nicht-Ziele

- Keine neue Waypoint-UI.
- Keine neue Command-Art und keine Aenderung an `SimulationRoot` als Runtime-Wahrheit.
- Keine Aenderung an AreaOrders.
- Keine Aenderung an Gegner-KI oder Combat-Entscheidungen.

## Relevante Contracts / Dokumente

- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/fireteam_runtime_execution_path_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_415_fireteam_runtime_execution_path_switch.md`
- `docs/tasks/TASK_416_fireteam_command_drill_map.md`

## Akzeptanzkriterien

- [x] Ein ausgefuehrter Waypoint wird aus dem Plan entfernt statt nur auf `completed` gesetzt.
- [x] Der naechste Waypoint wird nach der Entfernung mit dem korrekt verschobenen Index aktiviert.
- [x] Ein leerer Plan wird abgeschlossen und nicht mehr serialisiert.
- [x] Defend-/Hold-Fortsetzung per GO entfernt den freigegebenen Waypoint vor der naechsten Aktivierung.
- [x] Ein Verifier deckt Entfernung, Indexverschiebung, leeren Plan und Snapshot-Serialisierung ab.

## Betroffene Dateien

- `docs/tasks/TASK_417_fireteam_waypoint_completion_cleanup.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/reports/fireteam_command_drill_decision_guide.html`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`

## Lokale Pruefung

- [x] `godot_console.exe --headless --path . --script scripts/tests/task_417_fireteam_waypoint_completion_cleanup.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_416_fireteam_command_drill_map.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_415_fireteam_runtime_path_switch.gd`
- [x] `git diff --check`

## Risiken / offene Punkte

- Der Verifier prueft den Plan- und Serialisierungsvertrag headless. Der visuelle Godot-Fenster-Check bleibt sinnvoll, weil Waypoint-Label, Linien und Command-Bubbles zusammenspielen.

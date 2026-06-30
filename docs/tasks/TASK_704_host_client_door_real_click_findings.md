# TASK_704 - Host/Client Door Real Click Findings

## Ziel / Problem
TASK_700 stellt die Workbench fuer den echten Host-/Client-Door-Klicklauf bereit, und TASK_701 bis TASK_703 verbessern Sprache, HUD-Zeile und Button-Affordance. Es fehlt aber noch ein klares Findings-Gate, das technische Door-Evidence und offene menschliche Klickbeobachtung trennt.

## Sinnhaftigkeit / Ursache
Ohne Findings-Gate kann der Stand so wirken, als sei der Door-Multiplayer-Klicklauf schon spielerisch abgenommen. Tatsächlich sind Authority, Feedback und Buttonstatus technisch vorbereitet; der echte Zwei-Fenster-Eindruck bleibt offen. TASK_704 macht diese Grenze sichtbar und leitet den nächsten sinnvollen Polish ab.

## Umfang
- Neuer read-only Findings-Helper fuer Host/Client-Door-Real-Click.
- Neues Manifest `tmp/host_client_door_real_click_findings.json`.
- Auswertung von TASK_699-Capture und TASK_700-Workbench-Snapshot/Notizen.
- Trennung von technischen Fakten, offenen manuellen Checks und empfohlenem naechstem Schritt.
- Aktualisierung von Contract, Status, Roadmap und HTML-Handbuch.

## Nicht-Ziele
- Kein Klickbot und kein automatischer menschlicher Sichtentscheid.
- Kein neues Netzwerk-, Door-, Terrain- oder SimulationRoot-Verhalten.
- Kein UI-Commit von Door-State.
- Kein Layout-/Visual-Polish in diesem Task.
- Kein Behaupten eines bestandenen echten Host/Client-Playtests.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_699_multiplayer_door_feedback_capture.md`
- `docs/tasks/TASK_700_host_client_door_real_click_workbench.md`
- `docs/tasks/TASK_703_door_authority_button_affordance.md`
- `docs/reports/host_client_door_real_click_workbench_2026_06_30.html`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `MissionHostClientDoorRealClickFindings.build_snapshot()` liefert ein read-only Findings-Snapshot.
- Das Findings-Snapshot meldet `technical_path_gate = pass`, wenn die Door-Capture-Quelle pass ist.
- Das Findings-Snapshot meldet `manual_click_findings_gate = manual_still_open`, solange `manual_review_done = false`.
- Das Findings-Snapshot enthaelt belegte technische Findings fuer Host, Wrong-Team-Reject, State-Mutation-Reject und Door-Open.
- Das Findings-Snapshot enthaelt offene manuelle Beobachtungspunkte fuer Host-Fenster, Client-Fenster, Button, Shortcut, GO, Reject, Open-State und HUD-Lesbarkeit.
- `manual_review_required = true`, `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.
- Roadmap, Status, Contract und HTML-Handbuch nennen TASK_704 und den empfohlenen naechsten Schritt.

## Betroffene Dateien
- `scripts/mission/mission_host_client_door_real_click_findings.gd`
- `scripts/mission/mission_host_client_door_real_click_workbench.gd`
- `scripts/tests/task_704_host_client_door_real_click_findings.gd`
- `docs/tasks/TASK_704_host_client_door_real_click_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- `docs/reports/host_client_door_real_click_workbench_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_704_host_client_door_real_click_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_703_door_authority_button_affordance.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_700_host_client_door_real_click_workbench.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_704 beweist nicht den echten menschlichen Host/Client-Klicklauf. Es macht nur ehrlich sichtbar, welche technische Basis vorhanden ist, welche manuellen Beobachtungen fehlen und welcher Folge-Polish sinnvoll ist.

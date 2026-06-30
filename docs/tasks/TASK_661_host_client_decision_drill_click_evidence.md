# TASK_661 - Host Client Decision Drill Click Evidence

## Ziel / Problem
Nach TASK_660 ist der Frontier-Probe-Decision-Drill sichtbar und budgetiert. Der Multiplayer-Pfad hat bereits Authority-Reject, `BLOCK P2 wrong team` und `USE BRAVO`, aber der neue Decision-Drill-Gedanke ist noch nicht als Host/Client-Klicklauf vorbereitet.

## Sinnhaftigkeit / Ursache
Multiplayer muss fuer den Spieler nicht nur korrekt blockieren, sondern den naechsten sinnvollen Schritt anzeigen: falscher Peer-/Team-Kontext wird abgewiesen, der Client versteht `USE BRAVO`, wechselt in den richtigen Fireteam-Kontext und kann dort den gleichen Preview-/GO-Entscheidungsloop pruefen.

## Umfang
- Neues read-only Packet `tmp/host_client_decision_drill_click_evidence.json`.
- Packet verbindet TASK_629/TASK_650/TASK_651 Host/Client-Klickfeedback mit TASK_658/TASK_659/TASK_660 Decision-Drill.
- Manuelle Klickfolge: Peer 2 versucht Alpha, liest Blocker und `USE BRAVO`, wechselt Bravo, liest `NEXT AA`, prueft Preview/GO.
- Aktueller HTML-Handbuchbericht wird auf TASK_661 aktualisiert.

## Nicht-Ziele
- Kein automatisches Klicken in Godot-Fenstern.
- Kein neuer Multiplayer-Authority-Pfad.
- Kein neues Command-, Movement-, Objective-, Combat- oder HUD-System.
- Kein Anspruch, dass der echte Zwei-Fenster-Test erledigt ist.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md`
- `docs/tasks/TASK_650_host_client_click_feedback_followup.md`
- `docs/tasks/TASK_651_host_client_click_followup_evidence.md`
- `docs/tasks/TASK_660_decision_drill_snapshot_performance_budget.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Packet nutzt `schema = sternenbuergerchen.host_client_decision_drill_click_evidence.v1`.
- Packet nennt Peer 2 / Bravo, Alpha-Reject, `peer_team_mismatch`, `BLOCK P2 wrong team`, `USE BRAVO`.
- Packet nennt Decision-Drill-Schritte `NEXT AA`, Preview/Risk/GO und korrekten Bravo-Kontext.
- Manuelle Checks trennen falschen Kontext, sichtbaren Follow-up-Cue und richtigen Bravo-Decision-Drill.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true`, `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `docs/tasks/TASK_661_host_client_decision_drill_click_evidence.md`
- `scripts/tests/task_661_host_client_decision_drill_click_evidence.gd`
- `scripts/tests/task_660_decision_drill_snapshot_performance_budget.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_661_host_client_decision_drill_click_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_660_decision_drill_snapshot_performance_budget.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_651_host_client_click_followup_evidence.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das Packet ist Vorbereitung und Evidence, kein erledigter menschlicher Zwei-Fenster-Klicktest.
- Der naechste gute Schritt ist ein echtes Host/Client-Fenster-Capture oder ein kleiner Visual-Polish-Slice, falls der Cue im Bild zu leise ist.

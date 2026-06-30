# TASK_665 - Host Client Decision Drill Technical Click Guard

## Ziel / Problem
Der echte Host/Client-Klickbefund aus TASK_664 ist ohne manuellen Fensterlauf nicht belegbar. Trotzdem soll der Multiplayer-Decision-Drill nicht stehen bleiben: Der technische Kern hinter diesem Klicklauf muss abgesichert werden.

## Sinnhaftigkeit / Ursache
TASK_664 beschreibt die sichtbare Recheck-Folge. Die riskanten Stellen dahinter sind aber maschinell pruefbar: Peer 2 darf Alpha nicht kommandieren, `USE BRAVO` muss aus dem Authority-Reject ableitbar bleiben, der Client-Kontext muss `P2 BRAVO` zeigen und der Bravo-Decision-Drill muss Preview vor `GO` sowie Execution nach `GO` liefern.

## Umfang
- Headless-Guard fuer den technischen Klickpfad.
- Authority-Pfad: Peer 2 / Bravo wird akzeptiert, Peer 2 / Alpha wird mit `peer_team_mismatch` abgewiesen.
- Feedback-Pfad: `BLOCK P2 wrong team` und `USE BRAVO` bleiben aus dem Network-/Teamchip-Snapshot ableitbar.
- Review-Session-Pfad: Client-Fireteamkarten-Kontext bleibt `P2 BRAVO`.
- Decision-Drill-Pfad: Im Bravo-Kontext gibt es `NEXT AA`, Preview vor `GO` und Execution nach `GO`.
- Manifest unter `tmp/host_client_decision_drill_technical_click_guard.json`.

## Nicht-Ziele
- Kein echter menschlicher Fensterklick.
- Kein Klickbot und keine OS-/UI-Automation.
- Keine neue Peer-/Team-/Fireteam-Zuweisungslogik.
- Keine neue Movement-, Combat-, Objective- oder Multiplayer-Regel.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_622_host_client_command_authority_live_interaction_review.md`
- `docs/tasks/TASK_650_host_client_click_feedback_followup.md`
- `docs/tasks/TASK_658_frontier_probe_one_screen_player_decision_drill.md`
- `docs/tasks/TASK_664_host_client_decision_drill_real_click_recheck.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `task_665_host_client_decision_drill_technical_click_guard.gd` laeuft headless gruen.
- Das Manifest enthaelt Authority-, Feedback-, Review-Card- und Decision-Drill-Ergebnisse.
- Peer 2 / Bravo wird akzeptiert; Peer 2 / Alpha wird mit `peer_team_mismatch` abgewiesen.
- `USE BRAVO`, `P2 BRAVO`, `NEXT AA`, Preview und `GO`-Execution werden zusammen als technische Kette belegt.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Roadmap, Status, Contract und HTML-Handbuch empfehlen danach den echten Fensterbefund als TASK_666.

## Betroffene Dateien
- `scripts/tests/task_665_host_client_decision_drill_technical_click_guard.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`
- TASK_664-Doku/-Verifier-Follow-up-Verweis

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_665_host_client_decision_drill_technical_click_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_664_host_client_decision_drill_real_click_recheck.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_650_host_client_click_feedback_followup.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_658_frontier_probe_one_screen_player_decision_drill.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_665 beweist den technischen Pfad, nicht das Bediengefuehl. Der echte Zwei-Fenster-Klickbefund bleibt als TASK_666 offen.

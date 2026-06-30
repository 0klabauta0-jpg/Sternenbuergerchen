# TASK_666 - Host Client Decision Drill Real Click Findings

## Ziel / Problem
TASK_665 beweist den technischen Host/Client-Decision-Drill, aber das Bediengefuehl des echten Zwei-Fenster-Klicklaufs ist noch nicht als Befund gesichert. TASK_666 soll diese Luecke ehrlich dokumentieren: Welche Teile sind belegbar, welche bleiben menschlicher Sicht-/Klickentscheid, und was ist der naechste autonome Spielbarkeits-Schritt?

## Sinnhaftigkeit / Ursache
Ohne Findings-Gate kann der Projektstand so wirken, als sei Multiplayer bereits spielerisch geprueft. Tatsächlich sind Authority, `USE BRAVO`, `P2 BRAVO`, `NEXT AA`, Preview und GO technisch gruen, aber der menschliche Klicklauf ist weiterhin offen. Das muss im Report sichtbar sein, damit wir weder falsche Sicherheit erzeugen noch am falschen Punkt weiterpolieren.

## Umfang
- Neues Findings-Manifest `tmp/host_client_decision_drill_real_click_findings.json`.
- Verarbeitet TASK_664-Recheck, TASK_665-Technical-Guard und TASK_662-Real-Window-Capture.
- Trennt belegte technische Fakten von offenen menschlichen Beobachtungen.
- Aktualisiert Contract, Status, Roadmap und HTML-Handbuch.

## Nicht-Ziele
- Kein Klickbot.
- Kein Behaupten eines bestandenen menschlichen Klicktests.
- Keine neue Peer-/Team-/Fireteam-Zuweisungslogik.
- Keine neue Movement-, Combat-, Objective- oder Multiplayer-Regel.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_664_host_client_decision_drill_real_click_recheck.md`
- `docs/tasks/TASK_665_host_client_decision_drill_technical_click_guard.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `task_666_host_client_decision_drill_real_click_findings.gd` schreibt ein Findings-Manifest.
- Das Manifest meldet `technical_path_gate = pass`.
- Das Manifest meldet `real_capture_gate = review_ready`, wenn der Zwei-Fenster-Capture vorhanden ist.
- Das Manifest meldet `manual_click_findings_gate = manual_still_open`, solange kein menschlicher Klickbefund vorliegt.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Roadmap, Status, Contract und HTML-Handbuch markieren TASK_666 als erledigtes Findings-Gate und empfehlen als naechsten autonomen Schritt Mission-Interaction-Progress-Sichtbarkeit oder einen echten manuellen Fensterlauf.

## Betroffene Dateien
- `scripts/tests/task_666_host_client_decision_drill_real_click_findings.gd`
- `docs/tasks/TASK_666_host_client_decision_drill_real_click_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_666_host_client_decision_drill_real_click_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_665_host_client_decision_drill_technical_click_guard.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_664_host_client_decision_drill_real_click_recheck.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_666 ist ein Findings-Gate, kein bestandener menschlicher Multiplayer-Playtest. Der echte Zwei-Fenster-Klicklauf bleibt offen, kann aber jetzt klar vom technischen Pfad getrennt werden.

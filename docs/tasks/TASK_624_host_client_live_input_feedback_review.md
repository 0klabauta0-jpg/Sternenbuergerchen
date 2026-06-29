# TASK_624 - Host Client Live Input Feedback Review

## Problem
TASK_623 zeigt Accept-/Reject-Aktivitaet im Mission-Teamchip als `AUTH OK/RJ`, aber der Spieler muss den rohen Servergrund wie `peer_team_mismatch` noch uebersetzen. Fuer einen echten Host/Client-Klicklauf braucht es eine kurze menschliche Erklaerung, warum ein Befehl geblockt wurde.

## Ursache
Die Network-Command-Daten enthalten bereits `peer_id`, `reason`, `team_id`, `fireteam_id` und `command_type`. Der Presenter reicht diese Werte bisher technisch weiter, baut aber keinen spielbaren Feedbacksatz daraus.

## Umfang
- `MissionTeamChipPresenter.build_authority_visual_snapshot()` um lesbare Feedbackfelder erweitern.
- Bekannte Reject-Gruende in kurze Player-Texte uebersetzen.
- Zielkontext wie Team/Fireteam in den Detailtext aufnehmen.
- Tooltip und Snapshots behalten die rohen Reasons fuer Debugbarkeit.
- Reports/Handbuch auf TASK_624 fortschreiben.

## Nicht-Ziele
- Kein neuer Netcode.
- Keine neue Command-Retry-Logik.
- Kein automatischer GUI-Klicktest.
- Kein neues grosses Alert-/Toast-System.
- Keine UI- oder Gameplay-Wahrheit ausserhalb vorhandener Snapshots.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_623_host_client_authority_visual_findings.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Authority-Visual-Snapshot liefert `feedback_line`, `feedback_detail`, `last_reject_label`, `last_reject_target` und `input_feedback_ready`.
- `peer_team_mismatch` wird als kurzer Spielertext statt nur als Rohcode erklaert.
- Der Tooltip enthaelt Feedbacksatz, Detail und weiterhin den rohen Reject-Grund.
- Command-Feedback exportiert dieselben Felder read-only.
- TASK_623 bleibt als kompakter `AUTH OK/RJ`-Status erhalten.

## Betroffene Dateien
- `docs/tasks/TASK_624_host_client_live_input_feedback_review.md`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/task_624_host_client_live_input_feedback_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_624_host_client_live_input_feedback_review.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_623_host_client_authority_visual_findings.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_622_host_client_command_authority_live_interaction_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_624 verbessert die Sprache, aber prueft noch nicht echte Mausklick-Latenz oder Client-seitige Benutzerfuehrung.
- Wenn der echte Fensterlauf weiter unklar bleibt, ist der naechste Schritt ein kleiner sichtbarer Toast-/Bubble- oder Command-Panel-Finding-Slice.

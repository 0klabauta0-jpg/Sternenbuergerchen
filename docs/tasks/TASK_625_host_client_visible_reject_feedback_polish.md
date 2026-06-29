# TASK_625 - Host Client Visible Reject Feedback Polish

## Problem
TASK_624 erklaert Authority-Rejects im Tooltip und Snapshot, aber im echten Host/Client-Klicklauf kann das zu leise sein: Der Spieler sieht zwar `AUTH OK/RJ`, muss fuer den konkreten Grund aber weiterhin auf den Tooltip gehen.

## Ursache
Der vorhandene Teamchip zeigt den kompakten Authority-Zaehler sichtbar, waehrend der menschenlesbare Reject-Grund nur als Detailtext bereitsteht. Fuer Bediengefuehl braucht der erste Blick eine kurze Blocker-Zeile, ohne ein neues Alert-System oder UI-Wahrheit einzufuehren.

## Umfang
- Authority-Visual-Snapshot um einen kurzen sichtbaren Reject-Hinweis erweitern.
- Mission-Teamchip zeigt diesen Hinweis neben dem bestehenden `AUTH OK/RJ` an.
- Command-Feedback-Snapshot exportiert dieselben read-only Felder.
- Reports/Handbuch auf TASK_625 fortschreiben.

## Nicht-Ziele
- Kein neues Toast-/Notification-System.
- Kein Netcode-Umbau.
- Kein echter Zwei-Fenster-GUI-Klicktest.
- Keine neue Command-Retry- oder Auto-Focus-Logik.
- Keine UI-seitige Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_624_host_client_live_input_feedback_review.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `authority_visual` liefert `visible_feedback_text`, `visible_feedback_ready` und `attention_tone`.
- Bei `peer_team_mismatch` erscheint ein kurzer sichtbarer Text wie `BLOCK P2 wrong team`.
- Der bestehende `AUTH OK/RJ`-Status bleibt erhalten.
- Tooltip und Detail behalten den laengeren Zielkontext und den rohen Reject-Grund.
- Command-Feedback exportiert den sichtbaren Reject-Hinweis read-only.

## Betroffene Dateien
- `docs/tasks/TASK_625_host_client_visible_reject_feedback_polish.md`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/task_625_host_client_visible_reject_feedback_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_625_host_client_visible_reject_feedback_polish.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_624_host_client_live_input_feedback_review.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_623_host_client_authority_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_625 macht Rejects im HUD sichtbarer, ersetzt aber keinen echten Zwei-Fenster-Klicklauf mit Latenz-, Fokus- und Reaktionsbeobachtung.
- Falls der Hinweis immer noch zu leise ist, waere der naechste kleine Slice ein belegter Toast-/Bubble-/Panel-Finding-Test.

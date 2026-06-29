# TASK_623 - Host Client Authority Visual Findings

## Problem
TASK_622 belegt die Host-/Client-Authority technisch, aber im sichtbaren Zwei-Fenster-Lauf ist noch nicht klar genug, ob ein Spieler sofort sieht, dass ein Bravo-Befehl angenommen wurde, ein Alpha-Befehl abgelehnt wurde und welcher Servergrund dahinter steht.

## Ursache
Der Mission-Teamchip zeigt bereits Role/Peer/Team und die Team-Ownership. Die Network-Command-Accept-/Reject-Daten liegen in `SimulationRoot.get_network_command_contract_snapshot()`, werden im sichtbaren Chip aber noch nicht als kurzer Authority-Status formuliert.

## Umfang
- Bestehenden Mission-Teamchip um einen read-only Authority-Visual-Snapshot erweitern.
- Kurze sichtbare Anzeige fuer Accept-/Reject-Zaehler bauen.
- Letzten Reject-Grund nur kompakt und tooltip-tauglich anzeigen.
- `get_command_feedback_snapshot()` und `get_core_loop_host_client_feel_snapshot()` um diese Lesedaten erweitern.
- TASK_622-Report/Handbuch/Roadmap auf TASK_623 fortschreiben.

## Nicht-Ziele
- Kein neuer Netcode.
- Keine neue Lobby- oder Session-Wahrheit.
- Keine Gameplay-Mutation aus UI.
- Kein automatischer Zwei-Fenster-Klicktest.
- Kein neues grosses HUD-Panel.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/multiplayer_authority_command_contract.md`
- `docs/tasks/TASK_622_host_client_command_authority_live_interaction_review.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `MissionTeamChipPresenter.build_snapshot()` liefert `authority_visual` mit Schema `sternenbuergerchen.host_client_authority_visual.v1`.
- Der Snapshot meldet Accept-/Reject-Zaehler, letzten Reject-Grund und einen kompakten sichtbaren Text.
- Der Mission-Teamchip-Displaytext enthaelt bei vorhandener Authority-Aktivitaet einen `AUTH`-Hinweis.
- Der Tooltip nennt den letzten Reject-Grund, ohne die sichtbare Zeile aufzublaehen.
- Command-Feedback und Host/Client-Feel-Snapshot exportieren dieselben read-only Authority-Visual-Daten.
- Keine UI- oder Gameplay-Wahrheit wird gesetzt.

## Betroffene Dateien
- `docs/tasks/TASK_623_host_client_authority_visual_findings.md`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_623_host_client_authority_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_623_host_client_authority_visual_findings.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_622_host_client_command_authority_live_interaction_review.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_621_host_client_multiplayer_feel_review_bundle.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_623 macht den Authority-Status sichtbarer, ersetzt aber keinen echten Zwei-Fenster-Bediengefuehltest.
- Wenn der sichtbare Lauf weiterhin unklar ist, sollte TASK_624 konkrete UI-/Input-Findings aus einem echten Fensterlauf anwenden.

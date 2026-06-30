# TASK_650 - Host Client Click Feedback Followup

## Ziel / Problem
Der Host/Client-Klickpfad zeigt bereits `AUTH OK/RJ` und `BLOCK P2 wrong team`. Im echten Spielgefuehl fehlt aber noch die naechste Handlung: Was soll der Spieler nach dem geblockten Klick tun?

## Sinnhaftigkeit / Ursache
TASK_624/TASK_625 haben den Reject verstaendlich gemacht, TASK_626/TASK_629 haben den echten Klicklauf als Evidence-Pfad vorbereitet. Fuer Multiplayer-Spielbarkeit reicht ein Blocker-Text allein nicht aus; der Client braucht einen kurzen Follow-up-Hinweis wie `USE BRAVO`, ohne dass das HUD selbst Authority- oder Team-Wahrheit setzt.

## Umfang
- `MissionTeamChipPresenter` erweitert den read-only Authority-Visual-Snapshot um einen Follow-up-Hinweis.
- `peer_team_mismatch` erzeugt aus Peer-/Team-Kontext einen kurzen sichtbaren Hinweis und eine laengere Tooltip-Zeile.
- Der Mission-Teamchip darf den kurzen Hinweis neben `BLOCK ...` anzeigen.
- `MissionTacticalSandboxController.get_command_feedback_snapshot()` exportiert die neuen Felder read-only.
- Neuer Verifier prueft Presenter, dekorierten Teamchip und Command-Feedback-Snapshot.

## Nicht-Ziele
- Kein Netcode-Umbau.
- Keine automatische Command-Wiederholung.
- Kein neues Toast-/Notification-System.
- Kein echter Zwei-Fenster-GUI-Klicktest.
- Keine neue Peer-, Team-, Command-, Movement-, Combat- oder Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_624_host_client_live_input_feedback_review.md`
- `docs/tasks/TASK_625_host_client_visible_reject_feedback_polish.md`
- `docs/tasks/TASK_629_host_client_real_click_playtest_evidence_pass.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `authority_visual` liefert `visible_action_text`, `next_action_text`, `next_action_detail` und `next_action_ready`.
- Bei `peer_team_mismatch` mit Peer 2/Bravo erscheint `USE BRAVO`.
- Tooltip/Detail erklaert laenger, dass Peer 2 das eigene Bravo-Fireteam nutzen soll.
- Der bestehende `AUTH OK/RJ`-Status und `BLOCK P2 wrong team` bleiben erhalten.
- Command-Feedback exportiert die neuen Felder read-only.
- Kein neuer Gameplay-State und kein neuer Command entsteht.

## Betroffene Dateien
- `docs/tasks/TASK_650_host_client_click_feedback_followup.md`
- `scripts/mission/mission_team_chip_presenter.gd`
- `scripts/mission/mission_command_input_guard.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_650_host_client_click_feedback_followup.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_650_host_client_click_feedback_followup.gd`
- Regression: `godot_console.exe --headless --path . --script scripts/tests/task_625_host_client_visible_reject_feedback_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Hinweis ist ein kurzer HUD-Cue und ersetzt keinen echten Zwei-Fenster-Klicktest.
- Wenn `USE BRAVO` im echten Bild zu lang oder zu leise wirkt, braucht es danach einen belegten Visual-Polish-Slice.

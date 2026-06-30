# TASK_664 - Host Client Decision Drill Real Click Recheck

## Ziel / Problem
Nach TASK_663 ist der Peer-/Team-Kontext in den Fireteam-Mini-Cards sichtbar. Jetzt braucht der Host/Client-Decision-Drill ein kleines Recheck-Paket, das den echten Klicklauf nach diesem Fix klar beschreibt und alle erwarteten Sichtpunkte zusammenhaelt.

## Sinnhaftigkeit / Ursache
TASK_662 machte den Zwei-Fensterlauf capture-ready, TASK_663 verbesserte die Lesbarkeit in der eigentlichen Bedienflaeche. Ohne neuen Recheck-Anker waere unklar, ob der naechste manuelle Klicktest noch die alten Header-only-Erwartungen oder den neuen `P2 BRAVO`-Fireteamkartenanker prueft.

## Umfang
- Ein lokales Recheck-Manifest unter `tmp/host_client_decision_drill_real_click_recheck.json`.
- Der Recheck verbindet TASK_661-Klickpacket, TASK_662-Real-Capture und TASK_663-Fireteamkarten-Badge.
- Die erwartete Zwei-Fenster-Klickfolge bleibt manuell: Peer 2 klickt zuerst falsch, liest `BLOCK P2 wrong team`/`USE BRAVO`, wechselt zu Bravo, liest `NEXT AA`, prueft Preview und bestaetigt erst dann `GO`.
- Das Manifest markiert die Review-Bereitschaft, aber keinen erledigten menschlichen Sichtentscheid.

## Nicht-Ziele
- Kein Klickbot und keine automatische UI-Steuerung.
- Keine neue Peer-/Team-/Fireteam-Zuweisungslogik.
- Keine neuen Movement-, Combat-, Objective- oder Multiplayer-Regeln.
- Keine UI-seitige Gameplay-Wahrheit.
- Kein Behaupten, dass der manuelle Klicktest bereits bestanden ist.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_661_host_client_decision_drill_click_evidence.md`
- `docs/tasks/TASK_662_host_client_decision_drill_real_window_capture.md`
- `docs/tasks/TASK_663_host_client_decision_drill_visual_findings.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- `task_664_host_client_decision_drill_real_click_recheck.gd` schreibt ein Recheck-Manifest.
- Das Manifest referenziert die vorhandenen Capture-/Click-Artefakte und die TASK_663-Badge-Style-ID `host_client_fireteam_context_badge_v1`.
- Host- und Client-Erwartungen enthalten `P1 ALPHA` und `P2 BRAVO`.
- Der Recheck enthaelt die erwarteten Pflichtbeobachtungen fuer `USE BRAVO`, Bravo-Kontext, `NEXT AA`, Preview vor `GO` und sichtbares GO-Feedback.
- `manual_review_required = true`, `manual_review_done = false`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Bericht, Roadmap, Status und Contract nennen TASK_664 und empfehlen danach den echten Klickbefund als TASK_665.

## Betroffene Dateien
- `scripts/tests/task_664_host_client_decision_drill_real_click_recheck.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_664_host_client_decision_drill_real_click_recheck.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_663_host_client_decision_drill_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_662_host_client_decision_drill_real_window_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_652_current_state_handbook_refresh.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_664 ist ein Recheck-Anker, kein fertiger Klickbefund. Der eigentliche menschliche Zwei-Fenster-Klicklauf bleibt offen und sollte als TASK_665 mit konkreten Beobachtungen nachgezogen werden.

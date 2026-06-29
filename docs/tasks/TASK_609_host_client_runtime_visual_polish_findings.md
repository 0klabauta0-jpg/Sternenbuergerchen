# TASK_609 - Host Client Runtime Visual Polish Findings

## Ziel / Problem
TASK_608 erzeugt einen funktional gruenen Host/Client-Runtime-Capture, aber das PNG selbst ist zu stumm: Ohne HTML-Tabelle sieht man farbige Gate-Bloecke, aber nicht direkt, welche Runtime-Schritte belegt sind.

Ziel ist ein kleiner Visual-Polish-Findings-Slice, der den bestehenden Capture beschriftet und die Lesbarkeit im Manifest pruefbar macht.

## Sinnhaftigkeit / Ursache
Der laufende HTML-Bericht soll zwischendurch zeigen, was getan wurde und was offen ist. Dafuer muss das Bildartefakt auch allein eine grobe Aussage tragen: Transport, Authority, Guard, Snapshot, Host-F6, Client-F6 und Read-only-Grenze.

## Umfang
- TASK_608-Capture-Board bekommt Pixel-Labels fuer Header, linke Gates, Host/Snapshot-Zentrum, rechte Client-/F6-Gates und Footer.
- Manifest meldet `evidence_polish_task_id = TASK_609`.
- Manifest meldet `region_legend_present`, `callout_label_count` und `evidence_board_readability_gate`.
- HTML-Zwischenbericht zeigt die neuen TASK_609-Felder und nennt TASK_610 als naechsten echten Zwei-Fenster-Review.
- Neuer Verifier `scripts/tests/task_609_host_client_runtime_visual_polish_findings.gd`.

## Nicht-Ziele
- Kein neues Multiplayer-Verhalten.
- Kein echter Zwei-Fenster-/LAN-Test.
- Kein Mission-HUD-Layout-Fix.
- Keine Gameplay-, Peer-, Command-, Combat-, Objective-, Cargo- oder Movement-Wahrheit im Capture.
- Keine neue Render-Infrastruktur ausserhalb des vorhandenen Evidence-Board-Patterns.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_608_host_client_runtime_visual_capture.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- TASK_608-Verifier erzeugt weiterhin PNG/Manifest gruen.
- TASK_609-Verifier laeuft gruen.
- PNG enthaelt sichtbare Header-, Gate-, Zentrum-, Client- und Footer-Labels.
- Manifest enthaelt `evidence_polish_task_id = TASK_609`.
- Manifest enthaelt `region_legend_present = true`.
- Manifest enthaelt `callout_label_count >= 16`.
- Manifest enthaelt `evidence_board_readability_gate = pass`.
- Manifest und Bericht bleiben read-only und setzen `ui_sets_gameplay_truth = false`.
- HTML-Bericht exportiert die neuen TASK_609-Felder.
- Roadmap nennt TASK_610 als naechsten echten Zwei-Fenster-/Playtest-Notizen-Slice.

## Betroffene Dateien
- `scripts/tests/task_608_host_client_runtime_visual_capture.gd`
- `scripts/tests/task_609_host_client_runtime_visual_polish_findings.gd`
- `docs/tasks/TASK_609_host_client_runtime_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_608_host_client_runtime_visual_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_609_host_client_runtime_visual_polish_findings.gd`
- Regression: `task_607_two_instance_host_client_runtime_smoke.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das beschriftete Board bleibt ein Headless-Evidence-Board. Der echte Zwei-Fenster-/LAN-Eindruck ist weiter offen.
- TASK_610 sollte den realen Host/Client-Fensterlauf oder Screenshot-/Notiz-Workflow vorbereiten, statt wieder nur Headless zu pruefen.

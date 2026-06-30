# TASK_663 - Host Client Decision Drill Visual Findings

## Ziel / Problem
Der echte TASK_662-Zwei-Fenster-Capture zeigt, dass Host/Client-Rollen im oberen Mission-Header lesbar sind, der Fireteam-Bereich links aber nur `BLUE`/`GOLD` zeigt. Fuer den Decision-Drill ist das zu indirekt: Nach `USE BRAVO` muss Peer 2 im eigentlichen Bedienbereich sofort erkennen, in welchem Peer-/Team-Kontext er arbeitet.

## Sinnhaftigkeit / Ursache
Die Review-Session-Identitaet existiert bereits als read-only Header-/Teamchip-Badge. Sie wird jedoch nicht in den Fireteam-Mini-Cards wiederholt. Dadurch liegen der sichtbare Befehlskontext und die Bedienflaeche zu weit auseinander.

## Umfang
- Fireteam-Mini-Cards erhalten ein kurzes read-only Review-Session-Badge in der Statuszeile, z.B. `P2 BRAVO`.
- Das Badge wird aus `build_review_session_identity_snapshot()` abgeleitet.
- Snapshot-/Meta-Daten dokumentieren Style, Text, Sichtbarkeit und read-only-Grenzen.
- TASK_662-Capture-Artefakt und HTML-Handbuchbericht halten den Befund fest.

## Nicht-Ziele
- Kein automatischer Klickbot.
- Keine neue Peer-/Team-/Fireteam-Zuweisungslogik.
- Keine SimulationRoot-Mutation und keine UI-seitige Gameplay-Wahrheit.
- Kein Versuch, den gesamten Decision-Drill ohne menschlichen Klick als erledigt zu behaupten.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_662_host_client_decision_drill_real_window_capture.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Akzeptanzkriterien
- Fireteam-Statuskarten koennen `review_session_context_text` und `review_session_context_visible` liefern.
- Fuer Peer 2 / Team Bravo ist der kurze Kartenkontext `P2 BRAVO`.
- Die Mini-Card-Statuszeile enthaelt den Kontext vor Suppression/Movement/Position.
- Das Badge ist als `host_client_fireteam_context_badge_v1` markiert.
- Der Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.
- Der HTML-Bericht exportiert TASK_663-Findings und empfiehlt danach wieder den echten Zwei-Fenster-Klick/Sichtlauf.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_663_host_client_decision_drill_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_host_client_two_window_real_run.ps1 -Launch -CloseAfterCapture -WaitSeconds 8`
- `godot_console.exe --headless --path . --script scripts/tests/task_663_host_client_decision_drill_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_662_host_client_decision_drill_real_window_capture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_650_host_client_click_feedback_followup.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_663 verbessert die sichtbare Zuordnung im Fireteam-Bereich, ersetzt aber nicht den eigentlichen manuellen Klicklauf. Nach dem Fix sollte der echte Host/Client-Decision-Drill erneut im Fenster geprueft werden.

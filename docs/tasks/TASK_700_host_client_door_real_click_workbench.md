# TASK_700 - Host/Client Door Real Click Workbench

## Ziel / Problem
Door-Breach hat technische Host-/Client-Evidence, aber der echte menschliche Zwei-Fenster-Klicklauf ist noch offen. Wir brauchen eine klare Workbench, in der der Test reproduzierbar angeleitet und als JSON notiert werden kann.

## Sinnhaftigkeit / Ursache
TASK_699 macht Host-/Client-Door-Feedback vergleichbar, ersetzt aber keinen realen Bedienlauf. Der naechste sinnvolle Schritt ist nicht noch mehr Runtime-Code, sondern eine saubere Review-Schale fuer den menschlichen Klickbefund: Host, Client, falsches Team, GO, Reject-Feedback und Door-Open muessen sichtbar beurteilt werden.

## Umfang
- Read-only Snapshot fuer den Host/Client-Door-Real-Click-Workbench-Status.
- HTML-Workbench unter `docs/reports/` mit Pflichtchecks, Notizen, Entscheidung und `JSON exportieren`.
- Verifier prueft Task, Contract, Report, Snapshot und Manifest.
- Status, Roadmap und aktueller HTML-Arbeitsbericht werden aktualisiert.

## Nicht-Ziele
- Kein echter Zwei-Fenster-Test im Headless-Verifier.
- Kein neuer Multiplayer-Command-Pfad.
- Kein UI- oder Runtime-State-Commit.
- Kein visueller Polish ausserhalb der Workbench.

## Relevante Contracts / Dokumente
- `docs/dev/html_report_workbench_contract.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_699_multiplayer_door_feedback_capture.md`
- `docs/tasks/TASK_698_door_authority_ui_feedback.md`

## Akzeptanzkriterien
- Workbench existiert als file://-faehige HTML-Seite mit sichtbarem Button `JSON exportieren`.
- Snapshot meldet `manual_review_required = true` und `manual_review_done = false`, bis echte Notizen importiert/gesetzt werden.
- Pflichtchecks decken Host-Fenster, Client-Fenster, Door-Breach-Button, Shortcut, GO, Wrong-Team-Reject, Door-Open und HUD-Lesbarkeit ab.
- Workbench exportiert Notizen zu Host, Client, Reject, Door-Open, Timing und naechster Polish-Aktion.
- Kein Snapshot/Report setzt Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/mission_host_client_door_real_click_workbench.gd`
- `scripts/tests/task_700_host_client_door_real_click_workbench.gd`
- `docs/reports/host_client_door_real_click_workbench_2026_06_30.html`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_700_host_client_door_real_click_workbench.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_699_multiplayer_door_feedback_capture.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der eigentliche menschliche Zwei-Fenster-Klicklauf bleibt nach diesem Task bewusst offen, bis die Workbench ausgefuellt wurde.
- Falls der echte Test Reibung zeigt, ist danach gezielter Mission Door Feedback Polish sinnvoll.

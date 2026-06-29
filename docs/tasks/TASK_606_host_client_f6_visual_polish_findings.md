# TASK_606 - Host Client F6 Visual Polish Findings

## Ziel / Problem
TASK_605 hat den Host/Client-F6-Zustand als PNG/Manifest reviewbar gemacht. Das Manifest zeigte zwei konkrete Reibungen: Die `ACT`-Zeile war fuer den sichtbaren Host/Client-Blick zu lang, und der Selected-Fireteam-Status wurde im zusammengesetzten Snapshot doppelt ausgegeben.

Ziel ist ein kleiner, belegter Polish-Slice fuer bessere Scanbarkeit im F6-/Review-Kontext, ohne Objective-, Cargo-, Combat- oder Fireteam-Wahrheit in die UI zu verschieben.

## Sinnhaftigkeit / Ursache
Die zugrunde liegenden Datenpfade sind korrekt, aber der Anzeige-/Review-Pfad hat Debugtiefe ungefiltert in Spielerlesbarkeit verwandelt. Der Spieler braucht im Host/Client-F6-Moment kurze Tokens; der Entwickler braucht weiterhin die volle Quelle.

## Umfang
- `get_core_loop_host_client_feel_snapshot()` liefert eine kompakte Host/Client-F6-`ACT`-Zeile.
- Die volle `ACT`-Quelle bleibt als `mission_hud_interaction_line_full` erhalten.
- Der Selected-Fireteam-Kontext nutzt eine bevorzugte Statusquelle und dedupliziert leere/gleiche Zeilen.
- Neue Checks melden kompakte ACT-Zeile und deduplizierten Selected-Fireteam-Kontext.
- Der laufende HTML-Bericht wird als Zwischenbericht mit TASK_606-Stand und TASK_607-Follow-up aktualisiert.

## Nicht-Ziele
- Kein neues Networking.
- Kein echter Zwei-Instanz-Host/Client-Test.
- Kein Umbau der Objective-/Cargo-/Combat-Snapshots.
- Keine neue Runtime- oder Gameplay-Wahrheit im HUD.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_604_core_loop_host_client_feel_smoke.md`
- `docs/tasks/TASK_605_host_client_f6_visual_review_pass.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Kompakte Host/Client-F6-`ACT`-Zeile beginnt mit `ACT`, nennt `OBJ`, `CARGO` und `ROE` und bleibt im Zeichenbudget.
- Die volle Quellzeile bleibt im Snapshot fuer Diagnose erhalten.
- Selected-Fireteam-Status wird nicht als doppelter Karten-/Statusblock zusammengefuegt.
- Snapshot bleibt read-only und enqueued keine Commands.
- TASK_604 und TASK_605 bleiben als Regression gruen.
- HTML-Zwischenbericht nennt TASK_606 als erledigten Arbeitsstand und TASK_607 als naechsten sinnvollen Schritt.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_606_host_client_f6_visual_polish_findings.gd`
- `docs/tasks/TASK_606_host_client_f6_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_596_homebase_progression_player_review_notes.gd`
- `scripts/tests/task_598_homebase_progression_evidence_polish_findings.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_606_host_client_f6_visual_polish_findings.gd`
- Regression: `task_605_host_client_f6_visual_review_pass.gd`
- Regression: `task_604_core_loop_host_client_feel_smoke.gd`
- Regression: `task_596_homebase_progression_player_review_notes.gd`
- Regression: `task_598_homebase_progression_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_606 ist weiterhin ein kombinierter F6-/Review-Smoke, kein echter Zwei-Prozess-Multiplayer-Test.
- Die tatsaechliche Fensterlesbarkeit sollte spaeter in einem echten Host/Client-Runtime-Smoke oder manuellen Sichttest geprueft werden.
- Wenn echte Screenshots weitere Ueberlappung zeigen, muessen die naechsten Polish-Slices daraus abgeleitet werden.

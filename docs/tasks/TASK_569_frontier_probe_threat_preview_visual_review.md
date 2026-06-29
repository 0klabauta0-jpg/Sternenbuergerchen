# TASK_569 - Frontier Probe Threat Preview Visual Review

## Ziel / Problem
TASK_568 beweist Risky-/Suicidal-Kontaktlagen im Datenpfad, aber der sichtbare Preview-Pfad muss auch pruefbar zeigen, ob die Linien/Farben diese Gefahr lesbar tragen.

## Sinnhaftigkeit / Ursache
Ein Move kann korrekt als `SUICIDAL` bewertet werden und trotzdem visuell zu harmlos wirken, wenn klare Enemy-Lines nur als generische Linien erscheinen. Fuer Spielbarkeit braucht der Spieler vor `GO` eine konsistente Gefahrensprache: Gelb fuer riskant, Rot fuer suizidal, Grau fuer blockiert und Orange fuer Friendly-Fire.

## Umfang
- Bestehende Waypoint-Intent-Preview-Visuals weiterverwenden.
- Threat-Linien in 2D- und 3D-Preview nach Risk-State einfaerben, ohne Blocked/Friendly-Fire/Overwatch-Rollen zu verlieren.
- 3D-Render-Snapshot um Risk-/Line-Role-/Line-Color-Zaehler erweitern.
- Frontier-Probe-Fixture prueft `risky` und `suicidal` gegen diese Visual-Zaehler.
- HTML-Zwischenbericht, Status, Roadmap und Mission-Feedback-Contract auf TASK_569 weiterziehen.

## Nicht-Ziele
- Kein neuer ThreatAnalyzer.
- Kein neues Combat- oder Contact-System.
- Kein automatisches Bestehen eines menschlichen Sichttests.
- Kein GO/Command-Commit.
- Kein grosses HUD-Redesign.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_568_frontier_probe_risky_contact_preview_fixture.md`

## Akzeptanzkriterien
- Risky-Preview-Linien haben im Render-Snapshot mindestens einen gelben/risky Visual-Key.
- Suicidal-Preview-Linien haben im Render-Snapshot mindestens drei rote/suicidal Visual-Keys.
- Line-Role-Zaehler bleiben erhalten, damit klare, blockierte, Overwatch- und Friendly-Fire-Linien diagnostizierbar bleiben.
- Render-Snapshot-Zaehler spiegeln weiter die Preview-Line-Entries.
- Die Preview bleibt read-only und fuehrt keinen Befehl aus.
- Der HTML-Zwischenbericht nennt TASK_569 als erledigt und schlaegt einen naechsten spielbaren Slice vor.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/task_569_frontier_probe_threat_preview_visual_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_569_frontier_probe_threat_preview_visual_review.gd` (31 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_568_frontier_probe_risky_contact_preview_fixture.gd` (30 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_506_tactical_decision_clarity_contract.gd` (24 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_558_frontier_probe_multiplayer_manual_screenshot_notes_pass.gd` (34 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_561_frontier_probe_multiplayer_manual_visual_review_guide.gd` (49 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_562_frontier_probe_multiplayer_f6_visual_evidence_capture.gd` (38 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_563_frontier_probe_multiplayer_f6_evidence_report_preview.gd` (49 passed, 0 failed)
- `godot_console.exe --headless --path . --script scripts/tests/task_564_frontier_probe_multiplayer_apply_visual_polish_findings.gd` (46 passed, 0 failed)
- `git diff --check` (Exit 0)

## Risiken / offene Punkte
- Der Slice macht die Visualsprache messbar, ersetzt aber noch keinen menschlichen FullHD-Spielgefuehl-Test.
- Wenn spaeter echte Screenshot-Bewertungen andere Kontraste zeigen, sollten Farbstaerke und Labeldichte in einem eigenen Polish-Slice angepasst werden.

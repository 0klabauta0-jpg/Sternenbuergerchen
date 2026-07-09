# TASK_969 - Release First Decision Loop Two Real Window Capture

## Ziel / Problem
Der zweite Griff ist mit TASK_968 als `2ND`-Button erreichbar. Vor weiterem Polish muss der laufende Fensterzustand belegt werden: Ist der Button sichtbar, lesbar, vom `GO`-Schritt getrennt und bleibt der HUD-Pfad read-only?

## Sinnhaftigkeit / Ursache
Die bisherigen Tests beweisen Contracts und Controller-Anschluss, aber nicht den echten Fensterblick. Ohne Real-Window-Capture wuerden wir am zweiten Decision-Loop wieder zu schnell in Code-Polish gehen, ohne zu wissen, welche Reibung der Spieler tatsaechlich sieht.

## Umfang
- Read-only Analyzer fuer TASK_969-Capture-Manifeste.
- PowerShell-Tool, das ein Real-Window-Capture-Manifest fuer `--release-singleplayer-lz-drop-preview` schreibt.
- Pflichtchecks fuer `2ND`-Sichtbarkeit, Lesbarkeit, Confirm-Beobachtung, getrennten `GO` und sichtbares Feedback.
- Doku-Verankerung in Status, Roadmap und Decision-/Command-Contracts.

## Nicht-Ziele
- Keine neue Mission-, Command-, Movement-, Combat- oder Multiplayer-Logik.
- Keine automatische manuelle Abnahme.
- Keine Shortcut-Aenderung und kein Build-/Export-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_968_release_first_decision_loop_two_runtime_button.md`
- `scripts/mission/release_first_decision_loop_two_real_window_capture.gd`

## Akzeptanzkriterien
- `ReleaseFirstDecisionLoopTwoRealWindowCapture.build_snapshot()` bewertet TASK_968-Source und Capture-Manifest read-only.
- Fehlendes Manifest routet auf TASK_969 zurueck.
- Reviewbares Manifest routet zu `TASK_970 - Release First Decision Loop Two Visual Findings`.
- Vollstaendig manuell bestaetigte Pflichtchecks koennen den Capture akzeptieren.
- Tool-Manifest setzt `manual_review_done = $false` und `updates_shortcuts = $false`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_real_window.ps1`
- `scripts/tests/task_969_release_first_decision_loop_two_real_window_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_969_release_first_decision_loop_two_real_window_capture.gd`
- Regressionen: TASK_968, TASK_967, TASK_966
- `git diff --check`

## Risiken / offene Punkte
- Das Tool schreibt nur das Manifest und faket keine Sichtabnahme. Der echte visuelle Befund bleibt Folgearbeit.
- TASK_970 soll aus dem echten Capture gezielte visuelle Findings schneiden, statt pauschal UI umzubauen.

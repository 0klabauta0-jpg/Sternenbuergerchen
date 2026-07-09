# TASK_1018 - Release First Decision Loop Two Player Loop Scenario Real Window Capture

## Ziel / Problem
TASK_1017 beweist den Szenario-Griff als read-only Playability-Trace, aber noch nicht im echten Fenster. TASK_1018 legt den Real-Window-Capture-Rahmen fuer den kleinen FOB-Szenario-Griff an.

## Sinnhaftigkeit / Ursache
Der Weg zum kleinen runden Spiel braucht echte Sichtbelege. Ein Snapshot kann sagen, dass `FOB`, `NEXT`, `GO` und `FEEDBACK` lesbar sein sollen; der Release-Fensterblick muss danach zeigen, ob diese Informationen wirklich im HUD auffindbar sind.

## Umfang
- Neuer read-only Real-Window-Capture-Service fuer TASK_1018.
- Bewertung eines bestandenen TASK_1017-Scenario-Playability-Slices plus optionalem Capture-Manifest.
- PowerShell-Manifest-Tool fuer `--release-singleplayer-lz-drop-preview`.
- Pflichtchecks fuer Fensterstart, korrekten Inhalt, sichtbare FOB-/Objective-/Rollen-/NEXT-/GO-/Feedback-Flaechen, Screenshotpfade, HUD-read-only-Grenze und Multiplayer-Grenze.
- Export im `MissionTacticalSandboxController` und Command-Feedback.
- Doku in Status, Roadmap und relevanten Contracts.

## Nicht-Ziele
- Kein automatisches Akzeptieren eines manuellen Sichttests.
- Kein neues UI-Layout.
- Kein automatisches `GO`.
- Keine Movement-, Combat-, Damage- oder Multiplayer-Mutatoren.
- Keine Shortcut-Aenderungen.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1017_release_first_decision_loop_two_player_loop_scenario_playability_slice.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1018 blockiert ehrlich, wenn TASK_1017 nicht `scenario_playability_slice_passed` ist.
- Ohne Manifest meldet TASK_1018 `needs_scenario_real_window_capture`.
- Ein trusted Manifest ohne manuelle Checks meldet `review_ready`, aber nicht `accepted`.
- Ein trusted Manifest mit allen Pflichtchecks meldet `accepted`.
- Manifest und Snapshot bleiben read-only und erzeugen keine Commands, kein Movement und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1018 im Command-Feedback.
- Der naechste sinnvolle Schritt ist `TASK_1019 - Release First Decision Loop Two Player Loop Scenario Visual Findings`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_player_loop_scenario_real_window.ps1`
- `scripts/tests/task_1018_release_first_decision_loop_two_player_loop_scenario_real_window_capture.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1018_release_first_decision_loop_two_player_loop_scenario_real_window_capture.gd`
- Regression: TASK_1017, TASK_1016, TASK_1015
- `git diff --check`

## Risiken / offene Punkte
TASK_1018 legt den Capture-Rahmen und das Manifest-Format an, ersetzt aber keinen echten manuellen Sichtbefund. TASK_1019 sollte aus Manifest/Screenshot und Sichtnotizen konkrete Visual-Findings schneiden.

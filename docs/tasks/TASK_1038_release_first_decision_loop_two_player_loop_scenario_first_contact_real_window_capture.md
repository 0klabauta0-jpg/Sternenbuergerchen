# TASK_1038 - Release First Decision Loop Two Player Loop Scenario First Contact Real Window Capture

## Ziel / Problem
TASK_1037 beweist den First-Contact-Griff headless. TASK_1038 soll den naechsten Beweisrahmen fuer das echte Fenster schaffen: Der erste Kontakt muss im Release-/F6-Blick sichtbar genug sein, damit CONTACT, WHY, NEXT, FIRE/WAIT, FEEDBACK und `GO separat` nicht nur als Datenvertrag, sondern als Bildschirmmoment geprueft werden koennen.

## Sinnhaftigkeit / Ursache
Ein headless Slice kann sagen, welche Daten stimmen. Er beweist aber nicht, ob der Spieler im echten Fenster die wichtigen Flaechen sieht, ob das HUD ruhig bleibt und ob die Multiplayer-/Wahrheitsgrenze visuell nachvollziehbar ist. TASK_1038 legt dafuer Manifest, Analyzer und Capture-Tool an.

## Umfang
- Neuer read-only Analyzer `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactRealWindowCapture`.
- Manifest-Contract fuer echten Fenster-Capture nach bestandenem TASK_1037-Slice.
- Capture-Tool fuer ein lokales Manifest mit Pflichtchecks und Screenshot-Pfaden.
- Export im `MissionTacticalSandboxController` Command-Feedback.

## Nicht-Ziele
- Keine automatische Pixel-/Sichtabnahme.
- Kein neuer Combat-, Movement- oder UI-State.
- Kein Auto-Akzeptieren ohne manuelle Sichtpruefung.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1037_release_first_decision_loop_two_player_loop_scenario_first_contact_playability_slice.md`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1037-Quelle blockiert mit klaren Blocking-Issues.
- Bereite Quelle ohne Manifest meldet `needs_first_contact_real_window_capture`.
- Gutes Manifest ohne erledigte manuelle Checks wird `review_ready`, aber nicht akzeptiert.
- Manifest mit allen Pflichtchecks und manueller Review wird `accepted`.
- Snapshot und Tool bleiben read-only und setzen keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.gd`
- `scripts/tools/capture_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window.ps1`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1038_release_first_decision_loop_two_player_loop_scenario_first_contact_real_window_capture.gd`
- Regressionen: TASK_1037, TASK_1036, TASK_1035
- `git diff --check`

## Risiken / offene Punkte
TASK_1038 ist der Rahmen fuer den echten Fensterblick. Die eigentliche Sichtbewertung der Bilder folgt danach in `TASK_1039 - Release First Decision Loop Two Player Loop Scenario First Contact Visual Findings`.

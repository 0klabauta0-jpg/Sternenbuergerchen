# TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke

## Ziel / Problem
TASK_1026 kann melden, dass Build-Pfade, Testerhinweise und Risiken fuer den kleinen FOB/NEXT/GO/FEEDBACK-Spielmoment bereit sind. TASK_1027 schneidet daraus den sichtbaren Release-Smoke: frische EXE starten, Einzelspieler betreten, FOB sehen, NEXT/GO/FEEDBACK lesen und sicherstellen, dass keine Input-Sackgasse oder stale Verknuepfung im Weg ist.

## Sinnhaftigkeit / Ursache
Der vorherige Schritt ist nur Uebergabe-Readiness. Damit sich das Spiel wirklich Richtung angenehm spielbarer Zustand bewegt, brauchen wir einen belegten Sicht-Smoke ueber die Release-EXE, nicht nur weitere interne Snapshots.

## Umfang
- Neuer read-only Visible-Ship-Smoke-Service fuer TASK_1027.
- Bewertung einer bereiten TASK_1026-Ship-Readiness plus optionaler Sicht-Smoke-Notizen.
- Pflichtchecks fuer frischen Release-Ordner, EXE-Start, Einzelspieler, FOB, NEXT, GO, FEEDBACK, keine Input-Sackgasse, Responsiveness, keine stale Taskbar-/Build-Verwechslung und exportierte Smoke-Notizen.
- Issue-Flags fuer stale Export/Shortcut, blockierte Homebase, fehlendes FOB/NEXT/GO/FEEDBACK, Input-Dead-End, Performance, HUD-Wahrheit, Multiplayer-Grenze und Runtime-Startfehler.
- Export im `MissionTacticalSandboxController` und Command-Feedback als Snapshot, Line, Status und Gate.
- Routing zu `TASK_1027 - Release First Decision Loop Two Player Loop Scenario Visible Ship Smoke Polish` bei sichtbarer Reibung.
- Routing zu `TASK_1028 - Release First Decision Loop Two Player Loop Scenario Delivery Review` bei sauberem Smoke.

## Nicht-Ziele
- Kein automatischer Screenshot-Entscheid.
- Kein neuer Release-Export.
- Kein neuer Missionsflow.
- Keine Commands, kein Movement, keine Combat-/Damage-Wirkung.
- Keine Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1026_release_first_decision_loop_two_player_loop_scenario_ship_readiness_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1027 blockiert ehrlich, wenn TASK_1026 nicht `ship_readiness_ready` oder nicht `ready_for_visible_ship_smoke` ist.
- Ohne Sicht-Smoke-Notizen bleibt der Status `needs_visible_ship_smoke`.
- Fehlende Pflichtchecks melden `needs_visible_ship_smoke_completion`.
- Issue-Flags melden `visible_ship_smoke_regression_found` und routen zu TASK_1027-Polish.
- Ein sauberer Smoke setzt `visible_ship_smoke_passed` und `ready_for_delivery_review`.
- Die Visible-Smoke-Line nennt `VISIBLE SHIP`, EXE, FOB, NEXT, GO und FEEDBACK.
- Snapshot bleibt read-only und erzeugt keine Commands, kein Movement, keine Fire-/Damage-Events und keine Multiplayer-Wahrheit.
- Der Controller exportiert TASK_1027 im Command-Feedback als Snapshot, Line, Status und Gate.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.gd`
- `scripts/tests/task_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1027_release_first_decision_loop_two_player_loop_scenario_visible_ship_smoke.gd`
- Regression: TASK_1026, TASK_1025, TASK_1024
- `git diff --check`

## Risiken / offene Punkte
TASK_1027 bewertet Sicht-Smoke-Notizen und kann den Status sauber dokumentieren, aber er startet die EXE noch nicht selbst und entscheidet keine Pixel. Der naechste echte Schritt ist TASK_1028 als Delivery-Review oder bei Reibung ein gezielter TASK_1027-Polish.

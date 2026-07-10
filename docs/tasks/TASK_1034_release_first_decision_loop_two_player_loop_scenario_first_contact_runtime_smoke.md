# TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke

## Ziel / Problem
TASK_1033 macht den ersten Kontakt als Runtime-Hook lesbar, beweist aber noch nicht, dass CONTACT, WHY, NEXT, FEEDBACK und `GO separat` in einem konkreten Smoke-Trace zusammenhalten. TASK_1034 schneidet diesen Pruefpunkt als read-only Snapshot.

## Sinnhaftigkeit / Ursache
Der naechste spielbare Griff soll nicht durch mehr Kampf entstehen, sondern durch bessere Entscheidungslesbarkeit. Der Spieler muss sehen koennen, warum der erste Kontakt wichtig ist, welcher Grund im HUD steht, was als naechstes zu tun ist und dass GO weiterhin ein separater Commit bleibt.

## Umfang
- `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactRuntimeSmoke.build_snapshot()` bewertet einen bereiten TASK_1033-Hook und optionalen Smoke-Trace.
- Der Snapshot unterscheidet fehlende Quelle, fehlenden Trace, unvollstaendigen Trace, Regression und bestandenen Smoke.
- Pflichtchecks: Runtime-Hook bereit, CONTACT-Line sichtbar, Spielerfragen beantwortet, CONTACT/WHY/NEXT/GO-Hooks sichtbar, GO separat, kein Auto-GO, echter Snapshot-Kontext, First-Contact-/Engagement-/Combat-HUD-Gates, Feedback-zurueck-zu-NEXT, HUD-read-only-Grenze, Multiplayer-Grenze und Performance-Budget.
- `MissionTacticalSandboxController` exportiert den Snapshot im Command-Feedback mit Line, Status und Gate.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Keine neue UI-Wahrheit.
- Kein Command, kein Movement, keine Fire-/Damage-Events.
- Kein automatischer GO-Klick und kein Multiplayer-State.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/tasks/TASK_1033_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_hook.md`

## Akzeptanzkriterien
- Fehlender oder unbereiter TASK_1033-Hook blockt mit `blocked_until_first_contact_runtime_hook`.
- Bereiter Hook ohne Trace meldet `needs_first_contact_runtime_smoke_trace`.
- Unvollstaendiger Trace meldet `needs_first_contact_runtime_smoke_completion` und nennt fehlende Checks.
- Issue-Flags routen zu `TASK_1034 - Release First Decision Loop Two Player Loop Scenario First Contact Runtime Smoke Polish`.
- Ein sauberer Trace setzt `first_contact_runtime_smoke_passed`, `ready_for_first_contact_player_feel_findings` und routet zu `TASK_1035 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Findings`.
- Der Snapshot bleibt read-only und setzt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1034_release_first_decision_loop_two_player_loop_scenario_first_contact_runtime_smoke.gd`
- Regression: TASK_1033, TASK_1032, TASK_1031.
- `git diff --check`

## Risiken / offene Punkte
TASK_1034 beweist noch keinen menschlichen Player-Feel-Befund und startet keinen sichtbaren F6-/Release-Test. Der naechste sinnvolle Schritt ist TASK_1035, der aus bestandener Smoke-Evidence konkrete Lesbarkeits- und Gefuehlsbefunde fuer den ersten Kontakt sammelt.

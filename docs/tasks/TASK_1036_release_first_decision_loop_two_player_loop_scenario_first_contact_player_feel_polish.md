# TASK_1036 - Release First Decision Loop Two Player Loop Scenario First Contact Player Feel Polish

## Ziel / Problem
TASK_1035 kann nach einem bestandenen First-Contact-Runtime-Smoke noch Reibung melden: CONTACT ist nicht sofort klar, WHY fuehrt noch nicht stark genug zur naechsten Handlung, NEXT/FEEDBACK/GO wirken nicht rund genug oder HUD/MP-Grenze wird zu laut. TASK_1036 uebersetzt diese Befunde in konkrete, kleine Player-Feel-Surfaces fuer den ersten Kontakt.

## Sinnhaftigkeit / Ursache
Der erste Kontakt soll sich wie ein taktischer Griff anfuehlen, nicht wie ein technisches Log. Dafuer brauchen wir eine klare CONTACT-Zeile, eine handlungsfaehige WHY-Begruendung, einen sichtbaren NEXT-Griff, trockenheitsarmes Feedback, eine sichere GO-Grenze und ruhige HUD-/Multiplayer-Grenzen. Die Wahrheit bleibt weiterhin bei Runtime/Simulation; TASK_1036 beschreibt nur, was die UI lesen und anzeigen darf.

## Umfang
- Neuer read-only Service `ReleaseFirstDecisionLoopTwoPlayerLoopScenarioFirstContactPlayerFeelPolish`.
- Bewertung einer TASK_1035-Quelle mit Status `first_contact_player_feel_rework_needed` oder `accepted_for_first_contact_playability_slice`.
- Sechs Surface-Specs fuer CONTACT, WHY, NEXT, FEEDBACK, GO und HUD/MP.
- Compact Lines fuer Polish, NEXT, GO-Microcopy, HUD Guidance und Performance-Hinweis.
- Export im `MissionTacticalSandboxController` Command-Feedback.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Kein Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein sichtbarer F6-/Release-Playtest. Das folgt mit `TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1035_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_findings.md`

## Akzeptanzkriterien
- Fehlende oder unpassende TASK_1035-Quelle blockiert mit klaren Blocking-Issues.
- Rework- und Accepted-Quellen liefern `first_contact_player_feel_polish_ready`.
- Surface-Specs sind read-only und setzen keine Gameplay-Wahrheit.
- Command-Feedback exportiert Snapshot, Polish-Line, Surface-Specs und Status.
- Der Snapshot empfiehlt `TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1036_release_first_decision_loop_two_player_loop_scenario_first_contact_player_feel_polish.gd`
- Regressionen: TASK_1035, TASK_1034, TASK_1033
- `git diff --check`

## Risiken / offene Punkte
TASK_1036 verbessert die Leseflaechen und den Contract, aber noch nicht die echte sichtbare Spielbarkeit im ersten Kontakt. Der naechste sinnvolle Schritt ist `TASK_1037 - Release First Decision Loop Two Player Loop Scenario First Contact Playability Slice`.

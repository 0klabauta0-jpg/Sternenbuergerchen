# TASK_956 - First Decision Micro Scenario Polish

## Ziel / Problem
TASK_955 bewertet, ob der Decision-Overlay-Smoke bestanden ist. Im sichtbaren Spielfluss fehlt danach noch die kleine, angenehme Spielerfuehrung: Was ist der naechste Griff, warum ist er sinnvoll, was bleibt Preview und was passiert erst nach `GO`?

## Sinnhaftigkeit / Ursache
Die erste taktische Entscheidung soll sich nicht wie ein Debug-Overlay anfuehlen. Der Spieler braucht eine kurze `NEXT`-Zeile, eine `WHY`-Zeile und klare Choice-Zeilen, ohne interne Choice-IDs oder neue Gameplay-Wahrheit im HUD.

## Umfang
- Neuer Service `FirstDecisionMicroScenarioPolish`.
- Controller-Snapshot `get_first_decision_micro_scenario_polish_snapshot()`.
- Command-Feedback exportiert `first_decision_micro_scenario_polish`, `first_decision_micro_scenario_line` und `first_decision_micro_scenario_gate`.
- Empfohlene Choice steht an erster Stelle; Risky/Suicidal bleiben als Alternativen lesbar.

## Nicht-Ziele
- Kein neuer Command- oder Movement-Pfad.
- Kein automatisierter Real-Window-Playthrough-Capture.
- Kein neues HUD-Panel und kein UI-Tree-Rebuild.
- Kein Multiplayer-Feature in diesem Slice.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_955_decision_overlay_playability_smoke.md`
- `docs/tasks/TASK_950_wire_decision_scenario_into_f6_mission_hud.md`
- `docs/tasks/TASK_952_decision_overlay_f6_visual_polish.md`
- Folgepunkt: `TASK_957 - First Decision Real Playthrough Capture`

## Akzeptanzkriterien
- TASK_956 blockiert ohne bestandenen TASK_955-Smoke.
- Bestandener Smoke plus TASK_950/TASK_952-Quellen erzeugt eine kurze `NEXT ... -> GO`-Zeile.
- `WHY`, Vor-GO- und Nach-GO-Zeilen bleiben kurz, spielernahe und frei von rohen Choice-IDs.
- Drei Choice-Zeilen bleiben sichtbar; empfohlener `covered_push` steht zuerst.
- Snapshot bleibt read-only und erzeugt keine Gameplay-, Movement-, Combat- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/first_decision_micro_scenario_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_956_first_decision_micro_scenario_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_956_first_decision_micro_scenario_polish.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_955_decision_overlay_playability_smoke.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_952_decision_overlay_f6_visual_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_956 ist der spielnahe Micro-Scenario-Polish im Snapshot-/Feedback-Pfad. Der naechste Schritt sollte ein echter First-Decision-Playthrough-Capture sein, damit wir sehen, ob die neue Zeile im Fenster wirklich hilft.

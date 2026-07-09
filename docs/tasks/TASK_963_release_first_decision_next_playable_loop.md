# TASK_963 - Release First Decision Next Playable Loop

## Ziel / Problem
Nach TASK_962 ist klar, ob der erste Release-Decision-Griff akzeptiert oder nachzupolieren ist. Fuer Spielgefuehl reicht ein einzelner Move-Preview-Griff aber noch nicht: Der Spieler braucht nach `GO` eine zweite lesbare Entscheidung, damit der Ablauf wie ein kleiner Loop wirkt.

## Sinnhaftigkeit / Ursache
Der bisherige Pfad erklaert die erste Entscheidung sehr gut, endet aber zu schnell wieder in Feedback/Review. TASK_963 verlaengert den spielbaren Griff um eine zweite Entscheidung: Kontakt lesen, Winkel halten, gedeckt nachsetzen oder zuruecknehmen.

## Umfang
- Read-only Service `ReleaseFirstDecisionNextPlayableLoop`.
- Zweite Decision-Auswahl mit stabiler Reihenfolge:
  - `hold_angle`
  - `advance_cover`
  - `fallback_regroup`
- Controller-Snapshot `get_release_first_decision_next_playable_loop_snapshot()`.
- Export in `get_command_feedback_snapshot()` als `release_first_decision_next_playable_loop` und `release_first_decision_next_loop_line`.
- Live-Preview ist erlaubt, markiert aber klar `preview_available_needs_task_962_acceptance`.

## Nicht-Ziele
- Kein automatisches Druecken von `GO`.
- Keine neuen Commands, Movement-, Combat-, Damage-, Mission- oder Multiplayer-Mutationen.
- Keine echte TASK_962-Akzeptanz faken.
- Kein Export-/Capture-Umbau.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_962_release_first_decision_playtest_findings.md`
- `docs/tasks/TASK_956_first_decision_micro_scenario_polish.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- Nicht akzeptierte TASK_962-Findings blockieren den akzeptierten Next-Loop-Pfad.
- Akzeptierte TASK_962-Findings erzeugen einen aktiven zweiten Decision-Loop.
- Live-Preview ohne TASK_962-Abnahme ist sichtbar, aber ehrlich als nicht akzeptiert markiert.
- Choice-Zeilen fuer Hold/Advance/Fallback sind spielernahe Texte und enthalten keine rohen First-Decision-Choice-IDs.
- Command Feedback exportiert die Next-Loop-Zeile read-only.

## Betroffene Dateien
- `scripts/mission/release_first_decision_next_playable_loop.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_963_release_first_decision_next_playable_loop.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_963_release_first_decision_next_playable_loop.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_962_release_first_decision_playtest_findings.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_956_first_decision_micro_scenario_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_963 macht die zweite Entscheidung lesbar, fuehrt sie aber noch nicht als neuen Spielzug aus. `TASK_964 - Release First Decision Loop Two Playtest` sollte diesen Loop im echten Playtest oder einem kleinen F6-Smoke pruefen.
- Die Live-Preview ist bewusst kein Beweis, dass TASK_962 manuell akzeptiert wurde.

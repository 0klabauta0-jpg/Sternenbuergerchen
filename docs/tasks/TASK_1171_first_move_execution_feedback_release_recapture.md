# TASK_1171 - First Move Execution Feedback Release Recapture

## Ziel / Problem
TASK_1170 belegt die erste Move-Entscheidung vor `GO`. Der naechste spielbare Schritt ist der Moment direkt danach: `GO` wird ueber den bestehenden Pfad angenommen, das Fireteam beginnt die Bewegung, und der Spieler sieht, dass der Befehl laeuft.

## Sinnhaftigkeit / Ursache
Der alte TASK_541-Execution-Snapshot existiert bereits, ist aber noch nicht an den aktuellen Release-/Host-/Client-Recapture-Kontext nach TASK_1170 gebunden. Ohne diesen Anschluss ist der Spielgriff nur bis zur Vorschau belegt, nicht bis zur laufenden Ausfuehrung.

## Umfang
- Neuen read-only Snapshot `get_mission_first_move_execution_feedback_release_recapture_snapshot()` bereitstellen.
- Bestehende Quellen buendeln: TASK_1170-Handoff, TASK_541 Execution-Feedback, Release-Provenance und FirstContact-Capture-Artefakte.
- Verifier darf `GO` ueber `execute_selected_fireteam_orders()` ausfuehren, um den Runtime-Zustand herzustellen.
- Der Snapshot selbst darf danach nur lesen und keine weiteren Commands oder Effects erzeugen.

## Nicht-Ziele
- Kein neues Movement-System.
- Kein Contact-/Firefight-Polish.
- Kein UI-Layout-Umbau und kein neuer Capture-Flow.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1170_first_move_decision_preview_readability_recapture.md`
- `docs/tasks/TASK_541_mission_first_move_execution_feedback_pass.md`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.mission_first_move_execution_feedback_release_recapture.v1` und `task_id = TASK_1171`.
- TASK_1170 wird als Handoff-Quelle gelesen; nach `GO` muss die Vor-GO-Preview nicht mehr aktiv bleiben.
- TASK_541 bleibt `pass` nach echtem `GO`.
- Movement-State, Ziel-/Progressdaten und sichtbarer GO-/Running-Text sind vorhanden.
- Release-Provenance passt zu Git-HEAD und FirstContact-Capture-Kontext ist vorhanden.
- Der Snapshot ist read-only und mutiert nach dem bereits ausgefuehrten `GO` keine Command-/Effect-Queues.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1171_first_move_execution_feedback_release_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_1171_first_move_execution_feedback_release_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_1170_first_move_decision_preview_readability_recapture.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_541_mission_first_move_execution_feedback_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_1171 belegt den Start der Ausfuehrung, nicht den ersten Kontakt und nicht den kompletten Feuerwechsel.
- Der alte TASK_541-Meta-Layer-Verifier kann schwer sein; TASK_1171 nutzt deshalb die direkte Missions-Fixture fuer den aktuellen Release-Recapture.

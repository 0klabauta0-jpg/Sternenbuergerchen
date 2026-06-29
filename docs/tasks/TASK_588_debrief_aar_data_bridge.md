# TASK_588 - Debrief AAR Data Bridge

## Ziel / Problem
Die Mini-AAR-Kampfmetriken aus `MissionTacticalSandboxController` existieren bereits als read-only Snapshot, sind im sichtbaren Meta-Debrief aber noch nicht angekommen. Nach einer Mission sieht der Spieler dadurch zwar Ergebnis und Teamstatus, aber nicht die vorhandenen Fire-/Friendly-Fire-/SUP-/Wounded-Werte.

## Sinnhaftigkeit / Ursache
Der Debrief ist der natuerliche Ort fuer Lernen nach dem Einsatz. Die bestehenden Metriken sollen sichtbar werden, ohne daraus schon ein grosses XP-, Ammo- oder Suppression-System zu machen. Gameplay-Wahrheit bleibt in der Mission/Simulation; der Debrief liest nur den uebergebenen Snapshot.

## Umfang
- `MetaLayerFlow` uebernimmt den vorhandenen `get_mini_aar_debrief_screen_snapshot()` aus der aktiven Mission in das MissionResult.
- `DebriefTestScreen` rendert daraus eine kompakte AAR-Zeile, Chips, Rows und den vorhandenen Grenztext.
- Ein neuer read-only Snapshot prueft die Datenbruecke und die sichtbare Debrief-AAR-Sektion.
- Der laufende HTML-Zwischenbericht wird aktualisiert.

## Nicht-Ziele
- Keine XP-/Skill-Vergabe.
- Kein Ammo-Verbrauch.
- Keine echte Suppression-Wirkung.
- Kein neuer Mission-Result-Authority-Pfad im UI.
- Kein kompletter Debriefing-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/tasks/TASK_584_mini_aar_combat_metrics_shell.md`
- `docs/tasks/TASK_585_mini_aar_debrief_screen_stub.md`
- `docs/tasks/TASK_587_debrief_visual_polish_pass.md`

## Akzeptanzkriterien
- `MetaLayerFlow._build_mission_result()` fuegt einen vorhandenen Mini-AAR-Debrief-Snapshot als `mini_aar_debrief` ein.
- `DebriefTestScreen` zeigt AAR-Summary, mindestens fuenf AAR-Chips, mindestens vier AAR-Rows und den Grenztext.
- `get_debrief_aar_data_bridge_snapshot()` liefert `schema = sternenbuergerchen.debrief_aar_data_bridge.v1`.
- Snapshot und UI bleiben read-only und setzen keine Gameplay-Wahrheit.
- Der bestehende Debrief-Visual-Polish-Snapshot bleibt gruen.
- Der HTML-Zwischenbericht nennt erledigten TASK_588 und naechsten TASK_589.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/meta/debrief_screen.gd`
- `scripts/tests/task_588_debrief_aar_data_bridge.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_588_debrief_aar_data_bridge.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_587_debrief_visual_polish_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der sichtbare Debrief zeigt jetzt vorhandene AAR-Metriken, aber ein echter Spieler-Sichttest fuer Layout/Lesbarkeit bleibt Folgearbeit.
- Die Werte bleiben nur so gut wie die vorhandenen Mini-AAR-Quellen; echte XP-/Ammo-/Suppression-Folgen brauchen eigene Tasks.

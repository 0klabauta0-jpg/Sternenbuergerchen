# TASK_399 - Dropship Flow Contract Performance Pass

## Ziel
Den funktionierenden Homebase-Direct-Dropship-Ablauf als verbindlichen Contract dokumentieren und die spuerbare Traegheit im Mission-Dropship-HUD reduzieren, ohne die Per-Craft-Logik wieder zusammenzuziehen.

## Sinnhaftigkeit
Der Live-Test bestaetigt, dass Boarding, Send, Mission-Drop, Outbound und Return fachlich jetzt wie gewuenscht funktionieren. Gleichzeitig fuehlt sich die Godot-Vorschau clunky an. Der Codepfad zeigt, dass parallel laufende Dropships waehrend Inbound/Unloading/Outbound zu oft komplette UI-Rebuilds und Planning-State-Emits ausloesen.

## Umfang
- Homebase-Direct-Dropship-Zielverhalten als Dev-Contract ablegen.
- Mission-Dropship-Runtime-Feedback throttlen: Progress und Card-State bleiben aktuell, aber Voll-UI-Rebuilds und Planning-Emits laufen nicht mehr pro Drop-Frame.
- Parallele Drop-Sequenzen behalten ihre unabhaengige Bewegung und ihren Card-State, triggern aber nur noch getaktetes UI-/Planning-Feedback.
- Legacy-2D-Unit-Suppression im normalen HUD-Refresh cachen, explizite Suppression und Drop-Presence-Updates bleiben moeglich.
- Regressionstest fuer reduzierte Runtime-Feedback-Flushing-Frequenz und Legacy-Suppression-Gate.

## Akzeptanz
- Der Contract `docs/dev/homebase_direct_dropship_flow_contract.md` beschreibt die gewuenschte Spielerlogik fuer Homebase Direct, Mission Dropships und Per-Craft-Unabhaengigkeit.
- Eine laufende Deboarding-Sequenz ruft nicht pro simuliertem Frame den schweren Dropship-Runtime-Feedback-Flush auf.
- Parallele Dropship-Sequenzen aktualisieren weiter ihre Karten-/World-Overlay-Daten, ohne bei jedem Bewegungsschritt einen kompletten HUD-Rebuild zu erzwingen.
- Explizite Legacy-2D-Unit-Suppression blendet alte Sprite-Kinder weiter aus, der normale UI-Refresh wiederholt den rekursiven Scan aber nicht endlos.

## Betroffene Dateien
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/tasks/TASK_399_dropship_flow_contract_performance_pass.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`

## Pruefung
- [x] `godot --headless --path . --script res://scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_398_mission_dropship_outbound_command_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_397_mission_dropship_ux_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot --headless --path . --script res://scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Das ist kein finaler Godot-Profiler-Report. Falls die Vorschau danach weiter zaeh wirkt, muss ein eigener Profiling-Task mit Godot Script-Profiler/Visual-Profiler Messwerten folgen.
- Die Mission-Dropship-Karten werden weiterhin als dynamische Control-Trees gebaut; ein echter Card-Pool waere ein separater UI-Performance-Task.

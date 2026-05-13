# TASK_395 - Manual Dropship Parallel Flow Stabilization

## Ziel
Der manuelle Homebase-Direct-Dropship-Flow muss sich wie getrennte Schiffskarten verhalten: Fireteams koennen parallel boarden, Send startet sofort sichtbaren Transit-Fortschritt, und LZ/Drop/Anflug bleiben strikt pro Dropship.

## Sinnhaftigkeit
Der Live-Test zeigt weiterhin Abweichungen, obwohl der direkte Callback-Vertrag abgedeckt ist. Der reale GUI-Drag laeuft waehrend eines Boarding-Refreshs und kann dadurch unterbrochen werden. Zudem muss der Homebase-Send-Pfad den Transport-Timer ohne Umweg ueber die Mission Map starten.

## Umfang
- Homebase-Boarding-Refreshs duerfen aktive GUI-Drag-and-Drop-Vorgaenge nicht durch Rebuilds zerstoeren.
- Ein Fireteam kann in Dropship 2 gezogen werden, waehrend Dropship 1 noch boardet.
- Homebase-Direct-Send aktiviert den Transport-Timer sofort und aktualisiert Homebase-/Mission-Karten ohne Navigationszwang.
- Mission-LZs und Approach-Werte bleiben pro Dropship erhalten, wenn ein anderes Dropship ausgewaehlt und geplant wird.
- Der Anflugvektor wird als klare breite Pfeilform gerendert und zeigt die Anflugrichtung aus dem Approach-Ursprung zur LZ.

## Akzeptanz
- Waehrend eines simulierten aktiven GUI-Drags wird das Homebase-Flightdeck nicht neu gebaut; nach Drag-Ende wird der aufgeschobene Refresh nachgeholt.
- Zwei Dropships koennen nacheinander waehrend laufendem Boarding Fireteams aufnehmen und beide Boarding-Balken laufen weiter.
- Direkt nach `Send` ist der Homebase-Transport-Timer aktiv; der Fortschritt laeuft, ohne dass die Mission Map vorher geoeffnet werden muss.
- Alpha- und Beta-Dropship koennen eigene LZs/Approaches behalten; eine neue LZ fuer Alpha loescht Beta nicht.
- Der Primary3DView-Snapshot meldet den Approach als breite Pfeilform.

## Betroffene Dateien
- `docs/tasks/TASK_395_manual_dropship_parallel_flow.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_395_manual_dropship_parallel_flow.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_392_parallel_boarding_transit_feedback.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_390_homebase_direct_mission_transit_cards.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Drag-Refresh-Guard verschiebt nur UI-Rebuilds, nicht die Boarding-Simulation. Visuelle Fortschrittswerte koennen waehrend eines aktiven Drags bis zum Drop-Ende kurz verzögert angezeigt werden.
- Der Pfeil ist ein V1-Map-Visual auf Basis der vorhandenen 3D-Line-Meshes; finale Form/Breite bleibt ein manueller Sichtcheck.

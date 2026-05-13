# TASK_396 - Mission Dropship LZ Drop Hotfix

## Ziel
Mission-Dropships muessen ihre LZs, Buttons und Drop-Sequenzen klar pro Schiff behalten. Ein zweites Dropship darf die LZ des ersten nicht ueberschreiben, und `Drop` muss sichtbar mit Inbound-/Deboarding-Fortschritt starten.

## Sinnhaftigkeit
Der Live-Test zeigt, dass die Kartensteuerung fachlich richtig angelegt ist, aber fuer Spieler nicht eindeutig rueckmeldet, welches Dropship welche LZ nutzt. Zudem kann ein spaeter gesendetes Homebase-Direct-Dropship in der aktiven Mission ohne gueltige Friendly-Units landen und dadurch beim `Drop` scheinbar nichts tun.

## Umfang
- LZ-Labels werden kurz und unterscheidbar, z. B. `LZ1 Dropship Alpha` und `LZ2 Dropship Beta`.
- Mission-Dropshipkarten zeigen auch waehrend `inbound` und `landed` Fortschritt.
- Card-Command-Buttons bekommen stabilere Tooltips/Metadaten fuer aktive Approach-Auswahl und blockierte Drop-Zustaende.
- Homebase-Direct uebergibt der Mission alle aktuell startbereiten Dropship-Payloads als MissionSetup-Vertrag, ohne die craft-spezifische Drop-Card-Wahrheit zusammenzulegen.
- Eine bereits aktive Mission kann den erweiterten Friendly-Auswahlvertrag nachziehen, damit spaeter gesendete Dropships ihre Payload-Units droppen koennen.

## Akzeptanz
- Alpha- und Beta-Dropship behalten gleichzeitig eigene LZ-Marker und Labels.
- `Drop` fuer Beta startet auch dann, wenn Alpha bereits vorher in derselben aktiven Mission gestartet wurde.
- Beide Dropshipkarten koennen parallel `inbound` sein und zeigen Fortschrittsbalken.
- Der Primary3DView-Snapshot meldet mindestens zwei LZ-Marker und zwei lesbare LZ-Labels.

## Betroffene Dateien
- `docs/tasks/TASK_396_mission_dropship_lz_drop_hotfix.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_test_setup.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_396_mission_dropship_lz_drop_hotfix.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_395_manual_dropship_parallel_flow.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_394_per_craft_shipcard_commands.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_393_direct_dropship_independence_lz_vector.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_351_homebase_direct_payload_scope_contract.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die genaue optische Groesse der LZ-Labels bleibt ein manueller FullHD-Sichtcheck.
- Der Runtime-Selection-Refresh reidentifiziert Friendly-Slots fuer nachtraeglich gestartete Homebase-Direct-Payloads; die autoritative Deploy-Aktivierung bleibt weiter beim bestehenden Drop-/Presence-Pfad.

# TASK_1046 - Terrain Mission Status Payload Signature Guard

## Ziel / Problem

Der TASK-1045-Trace misst nach Missionsstart sichtbare Frames von 3,5 bis 7,1 Sekunden. Die Prozess-Isolation zeigt den Hotpath nur in der Kombination aus Mission Controller, SimulationRoot und TerrainMap3DView.

## Ursache

`TerrainMap3DView.set_mission_status_payload()` rekonstruiert bei jedem Aufruf den gesamten `StatusRoot3D`, auch wenn Objective-, Route-, Interaction- und Result-Payload unveraendert sind. Die Controller-HUD-Aktualisierung sendet diesen Status wiederkehrend, waehrend SimulationRoot und Terrain gleichzeitig laufen.

## Umfang

- Deterministischen, lokalen Visual-Payload-Fingerprint fuer Mission-Statusdaten.
- Gleicher Payload: kein StatusRoot-Rebuild, keine neuen 3D-Nodes.
- Geaenderter Objective-/Route-/Interaction-/Result-Payload: sofortiger Rebuild.
- Apply-/Rebuild-/Skip-Zaehler im Render-Snapshot.

## Nicht-Ziele

- Kein Cache fuer Objective- oder Gameplay-Wahrheit.
- Keine Veraenderung an SimulationRoot, Combat, Movement oder Multiplayer.
- Kein verstecktes Zeitintervall statt Datenvergleich.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1045_mission_first_contact_end_to_end_timing_trace.md`
- `docs/performance/large_map_scale_profile_report.md`

## Akzeptanzkriterien

- Identischer Status-Payload laesst StatusRoot3D-Kindinstanzen bestehen und erhoeht den Skip-Zaehler.
- Ein geaenderter sichtbarer Statuswert rekonstruiert die Visuals und erhoeht den Rebuild-Zaehler.
- Render-Snapshot meldet Apply-, Rebuild- und Skip-Zaehler.
- Visual-Guard bleibt read-only und erzeugt keine Gameplay-, Command-, Movement-, Fire-, Damage- oder Multiplayer-Wahrheit.
- TASK_1046 und passende Terrain-/Performance-Regressionen sind gruen.

## Betroffene Dateien

- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1046_terrain_mission_status_payload_signature_guard.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1046_terrain_mission_status_payload_signature_guard.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_170_performance_warning_gate_verifier.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1045_mission_first_contact_end_to_end_timing_trace.gd`
- `git diff --check`

## Risiken / offene Punkte

Ein zu schmaler Fingerprint koennte sich aendernde 3D-Statusdaten nicht zeigen. Der Verifier prueft deshalb identische Daten, nicht gerenderte Diagnostik und einen geaenderten Capture-/Route-Kontext gegen echte StatusRoot-Instanzen. Die Kombinationsprobe misst trotz korrektem Guard weiter rund 3.396 ms pro Frame; die eigentliche Cross-System-Ursache bleibt Folgearbeit in TASK_1047.

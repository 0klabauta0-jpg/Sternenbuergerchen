# TASK_1047 - Mission Visible Frame Cross-System Timing Breakdown

## Ziel / Problem

TASK_1045 misst nach Missionsstart sichtbare Frames von 3,4 bis 7,0 Sekunden. TASK_1046 verhindert unnoetige Terrain-Status-Rebuilds, aber die Kombination aus MissionController, SimulationRoot und TerrainMap3DView bleibt mit rund 3.396 ms pro Frame teuer.

## Ursache

Die vorhandene Messung isoliert Prozesse, kann aber den teuren Teil innerhalb eines gemeinsamen sichtbaren Frames nicht benennen. SimulationRoot besitzt bereits opt-in Tick-Scopes; Controller und Terrain liefern noch keinen gleichartigen read-only Frame-Snapshot.

## Umfang

- Opt-in Timing-Snapshots fuer MissionController und TerrainMap3DView.
- Controller misst seine Prozess-/UI-Teilpfade, Terrain misst Resize, Unit-Proxy-Sync und dynamische Order-Visuals.
- Ein Headless-Verifier aktiviert alle drei Profiler, sammelt die letzten Snapshots und nennt den teuersten Scope.
- Profiler ist im normalen Runtime-Betrieb deaktiviert.

## Nicht-Ziele

- Kein pauschaler Performance-Fix und kein Cache auf Verdacht.
- Keine Gameplay-, Command-, Combat-, Movement- oder Multiplayer-Mutation.
- Keine neue dauerhafte HUD-Anzeige fuer Profilerwerte.

## Relevante Contracts / Dokumente

- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_1045_mission_first_contact_end_to_end_timing_trace.md`
- `docs/tasks/TASK_1046_terrain_mission_status_payload_signature_guard.md`

## Akzeptanzkriterien

- Controller- und Terrain-Profiler sind standardmaessig deaktiviert und liefern nur bei explizitem Enable aktuelle Snapshots.
- Snapshots enthalten Gesamtzeit und benannte Teilzeiten in Mikrosekunden.
- Der Verifier erfasst Controller, SimulationRoot und TerrainMap3DView in einer echten Missionsfixture und meldet einen belegten teuersten Scope.
- Diagnostik bleibt read-only und erzeugt keine Gameplay- oder Multiplayer-Wahrheit.

## Betroffene Dateien

- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1047_mission_visible_frame_cross_system_timing_breakdown.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1047_mission_visible_frame_cross_system_timing_breakdown.gd`
- TASK_1045 Trace und TASK_170 Performance-/Warning-Gate
- `git diff --check`

## Risiken / offene Punkte

Profilerwerte sind lokal und nur eine Ursachenreihenfolge, kein universelles Framerate-Versprechen. Der naechste Fix wird ausschliesslich aus dem gemessenen teuersten Scope abgeleitet.

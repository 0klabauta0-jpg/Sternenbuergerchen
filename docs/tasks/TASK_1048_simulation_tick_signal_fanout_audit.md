# TASK_1048 - Simulation Tick Signal Fanout Audit and Guard

## Ziel / Problem

TASK_1047 misst `SimulationRoot.tick_processed.emit()` mit rund 400-478 ms in echten sichtbaren Missionsframes. Der direkte Empfaengerscan zeigt aktuell `MissionCombatLoopDriver` als einzigen Runtime-Empfaenger, aber der End-to-End-Trace enthaelt seine bereits vorhandenen Combat-Scopes noch nicht.

## Ursache

Ohne Combat-Scopes bleibt unklar, ob Kontakttracking, Taktik, Verhalten, Visual-Refresh oder ein daraus ausgeloester UI-Pfad die Emit-Zeit verursacht. Ein Fix waere ohne diese Aufschluesselung wieder Raten.

## Umfang

- TASK-1045-Trace aktiviert den vorhandenen Combat-Tick-Profiler mit den anderen opt-in Profilern.
- Jede sichtbare Startframe-Zeile nennt zusaetzlich den langsamsten Combat-Scope und die Combat-Gesamtzeit.
- Ein Verifier prueft den direkten Fanout, Combat-Profiler und read-only-Grenzen.

## Nicht-Ziele

- Kein Wechsel der autoritativen Simulationstaktung.
- Kein Disconnect/Delay fuer Combat ohne gemessene Ursache.
- Keine UI-, Command-, Combat-, Movement- oder Multiplayer-Wahrheit in der Diagnostik.

## Akzeptanzkriterien

- Der Fanout ist als direkter, reproduzierbarer Empfaengerscan belegt.
- Der reale Starttrace beinhaltet Combat-Timings zusammen mit Controller, Simulation und Terrain.
- Der naechste Fix-Kandidat ist aus einem benannten Combat-Scope ableitbar.

## Lokale Pruefung

- `godot_console.exe --headless --path . --script res://scripts/tests/task_1048_simulation_tick_signal_fanout_audit.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1045_mission_first_contact_end_to_end_timing_trace.gd`
- `git diff --check`

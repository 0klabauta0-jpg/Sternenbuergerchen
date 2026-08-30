# TASK_1191 - Gemeinsamer Combat-Visibility-Cache

## Ziel

Kontaktaufklaerung, Feuerentscheidung und Enemy Security lesen im selben
Simulationstick dieselbe Terrain-Sichtinformation. Dieser Task stellt ihnen
einen abgeleiteten, tickgebundenen Cache bereit, damit eine identische
Terrain-Occlusion nur einmal berechnet wird.

## Architekturgrenzen

- `SimulationRoot`, Combat-Resolver, Contact Tracker und Security-Entscheidungen
  bleiben autoritativ. Der Cache schreibt weder Commands, Effects noch
  Snapshot-Wahrheit.
- Im Cache liegt ausschliesslich das Ergebnis der reinen Terrain-Occlusion.
  Reichweite, Arc, Vitalstatus, Stealth, Weapon- und Command-Regeln bleiben
  bei ihren bisherigen Konsumenten.
- Ein Cache-Key enthaelt mindestens Tick, geordnete Source-/Target-ID,
  Source-/Target-Grid und Hoehenklasse sowie Terrain-, Cover- und
  Navigation-Revision. Die Reihenfolge von Source und Target ist absichtlich
  nicht austauschbar. Fuer Wall-Segment-LoS werden die Weltpositionen ebenfalls
  Teil des Keys, damit eine Bewegung innerhalb derselben Zelle kein altes
  Ergebnis wiederverwendet.
- Der Cache ist abgeleitet, pro Tick verworfen und wird nicht in
  Multiplayer-/Missions-Snapshots serialisiert.

## Akzeptanz

- Eine gleiche, geordnete Sichtabfrage im selben Tick fuehrt hoechstens eine
  Terrain-Occlusion aus; weitere Abfragen sind Cache-Hits.
- Unterschiedliche Richtung, Terrain-Revision, Position oder Tick teilt kein
  Ergebnis unzulaessig.
- Cache an/aus liefert ueber 600 deterministische Ticks dieselben
  Kontakt-/Detection-/Feuer-/Treffer-/Missions-Ergebnisse und denselben
  kanonischen Snapshot.
- Der Hotpath-Audit weist angefragte Paare, tatsaechliche Terrain-LoS, Hits und
  Team-Tactics-Rebuilds aus.

## Verifikation

```powershell
godot_console.exe --headless --path . --script scripts/tests/task_1191_shared_combat_visibility_cache.gd
godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd
godot_console.exe --headless --path . --script scripts/tests/task_202_enemy_security_direction_and_los_patch.gd
godot_console.exe --headless --path . --script scripts/tests/task_208_enemy_team_tactics_playability_smoke.gd
godot_console.exe --headless --path . --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd
godot_console.exe --headless --path . --script scripts/tests/task_542_mission_first_contact_readability_pass.gd
godot_console.exe --headless --path . --script scripts/tests/task_543_mission_first_engagement_feedback_pass.gd
pwsh -NoProfile -File scripts/tests/run_task_1187_tactical_map_frame_budget.ps1 -Mode Measure -ColdRuns 3 -WarmRuns 5
git diff --check
```

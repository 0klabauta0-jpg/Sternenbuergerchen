# Combat Loop Tick Budget System Split

## Ergebnis
TASK_336 ist umgesetzt. `MissionCombatLoopDriver._on_tick_processed()` nutzt jetzt eine explizite Combat-Tick-Phasenliste, statt die Tick-Schritte als lange Inline-Sequenz mit einzelnen Timing-Blöcken zu fuehren.

## Phaseninventar
Die Reihenfolge bleibt unveraendert:
1. `bleedout_queue`
2. `leadership`
3. `detection_timers`
4. `contact_tracking`
5. `enemy_security`
6. `enemy_team_tactics`
7. `flank_vulnerability`
8. `cooldowns`
9. `medic_support`
10. `enemy_advance`
11. `friendly_standard_behavior`
12. `overwatch_security`
13. `combat_fire_decision`
14. `combat_resolution`
15. `multiplayer_snapshot_context`
16. `status_update`

Harte Reihenfolge-Abhaengigkeiten sind im Phase-Catalog sichtbar, z. B. Contact Tracking nach Detection, Fire Decision nach Overwatch, Snapshot Context nach Combat Resolution.

## Phase-Dauer und Hauptzaehler
`get_combat_tick_budget_debug_snapshot()` enthaelt weiter `scopes_usec` fuer die bestehenden TASK_218-Gates und zusaetzlich:
- `phase_order`
- `phase_catalog`
- `phase_records`
- `budget_candidate_phase_ids`

Jeder Phase-Record meldet `duration_usec`, `scope_key`, Skip-Status und Hauptzaehler wie Contact-Count, Enemy-Tactics-Gruppen, Overwatch-Schuesse, Queue-Groessen oder Combat-Resolved-Status.

## Every-N-Kandidaten
Es wurde keine Every-N-Ausfuehrung aktiviert. Markiert sind nur Review-Kandidaten:
- `enemy_security`
- `enemy_team_tactics`
- `flank_vulnerability`
- `friendly_standard_behavior`
- `status_update`

Diese Marker sind Dokumentation fuer spaetere Budget-Tasks. Kampfregeln, AI-Cadence und Snapshot-Authority bleiben unveraendert.

## Authority
`SimulationRoot` bleibt Autoritaetswurzel. Der Combat Driver bleibt Tick-Subscriber und publiziert Snapshot-Kontext wie bisher ueber `SimulationRoot.set_multiplayer_snapshot_context`.

## Lokale Pruefung
- `scripts/tests/task_336_combat_loop_tick_budget_system_split.gd`
- `scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd`
- `scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- `git diff --check`

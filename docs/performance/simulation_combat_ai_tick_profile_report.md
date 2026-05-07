# TASK_218 Simulation Combat AI Tick Profile Report

Stand: 2026-05-06

## Ziel
Dieser Bericht bewertet SimulationRoot, CombatLoop, Enemy-Taktik, Security/Overwatch, Medic Support, lokale Avoidance und Unit-Minimalabstand auf Tick-Kosten. Der Task fuehrt Diagnose und breite Startbudgets ein; er aendert keine Combat- oder KI-Regeln.

## Instrumentierung
`SimulationRoot.get_runtime_tick_budget_debug_snapshot()` liefert bei aktivem Debug:

- `total_tick_usec`
- `scopes_usec.command_queue_usec`
- `scopes_usec.effect_queue_usec`
- `scopes_usec.local_avoidance_prepare_usec`
- `scopes_usec.unit_minimum_spacing_usec`
- `scopes_usec.objective_capture_usec`
- `scopes_usec.snapshot_broadcast_usec`
- `scopes_usec.tick_signal_emit_usec`
- Queue-, Unit-, Navigation- und Minimum-Spacing-Zaehler

`MissionCombatLoopDriver.get_combat_tick_budget_debug_snapshot()` liefert:

- `total_tick_usec`
- `contact_tracking_usec`
- `enemy_security_usec`
- `enemy_team_tactics_usec`
- `medic_support_usec`
- `enemy_advance_usec`
- `friendly_standard_behavior_usec`
- `overwatch_security_usec`
- `combat_fire_decision_usec`
- `combat_resolution_usec`
- `multiplayer_snapshot_context_usec`
- Unit-, Enemy-Group-, Fire-Event- und Queue-Zaehler

## Skalenszenarien
`scripts/tests/simulation_combat_ai_tick_budget_harness.gd` misst drei reproduzierbare Headless-Szenarien:

| Szenario | Umfang | Zweck |
|---|---|---|
| `small_mission` | 4 Friendly, 3 Enemy | kleine Runtime-Baseline |
| `two_fireteams_enemy_team` | 8 Friendly, 6 Enemy | 2 Fireteams gegen Enemy-Team-Taktik |
| `four_fireteams_multi_enemy_medic_overwatch` | 16 Friendly, 12 Enemy | groesserer AI-/Medic-/Downed-/Tactics-Mix |

Alle Szenarien liefern Median, P95 und P99 fuer Simulation- und Combat-Ticks sowie fuer die groessten Scopes.

## Hotpath-Audit
Der aktuelle Vertrag bleibt:

- Authority liegt bei `SimulationRoot`.
- CombatLoop ist ein autoritativer Tick-Subscriber.
- Unit-Zugriff laeuft ueber konfigurierte NodePaths und UnitRegistry-Filter, nicht ueber breite SceneTree-Suchen.
- Client-/Viewer-Pfade zeigen Snapshots, VFX und UI-Feedback, schreiben aber keine Combat- oder AI-Wahrheit.
- Enemy-Taktik, Medic, Security und Fire Decision bleiben pro Tick messbar; spaetere Staggering- oder Cache-Slices muessen diese Diagnose weiter bedienen.

## Budgets
Die automatischen Budgets sind bewusst breit, weil lokale Headless-Zeiten maschinenabhaengig sind. TASK_218 prueft primaer:

- Scope-Vollstaendigkeit.
- Median/P95/P99-Struktur.
- Keine unkontrolliert wachsenden Command-/Effect-Queues im Scale-Smoke.
- Authority-/Snapshot-Grenze bleibt sichtbar.

## Risiken
- Timing-Messung darf selbst nicht zum dominanten Kostenblock werden.
- Eine spaetere Optimierung darf Combat-Autoritaet nicht in UI, Viewer oder Client-Pfade verschieben.
- Wenn Enemy- oder Medic-Logik spaeter echte Staggering-Intervalle bekommt, muessen die Scope-Namen stabil bleiben oder bewusst migriert werden.

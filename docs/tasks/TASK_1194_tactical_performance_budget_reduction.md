# TASK_1194 - Tactical Performance Budget Reduction

## Status: IN ARBEIT

## Ziel / Problem

Der TASK_1193-Release-Gate blockiert auf `integration/core-foundation`, obwohl
alle Funktions- und Architektur-Enforcer gruen sind. Die reproduzierbar roten
Werte sind Combat-Tick-p99, Simulation-Tick-p99 und die einmalige
LZ-Arming-Eingabe. Budgets und manuelle Evidenz werden in diesem Task nicht
gelockert oder erzeugt.

## Architektur und Grenzen

- Gameplay-Wahrheit bleibt bei `SimulationRoot`; UI bleibt Ausloeser und
  Anzeige.
- Bestehende `CombatVisibilityCache`-, Registry- und Dirty-Update-Pfade werden
  wiederverwendet. Es wird kein zweiter Combat- oder UI-State eingefuehrt.
- Erst wird die vorhandene Messung feingranular erweitert. Danach wird pro
  nachgewiesenem Hotspot nur eine minimale Ursache behoben und gegen denselben
  Harness verglichen.
- Eine echte 128x128-Manuell-Evidenz bleibt menschlich und ist kein Bestandteil
  dieses Automation-Tasks.

## Akzeptanzkriterien

- Der Tactical-Map-Bericht zeigt die bereits instrumentierten Combat- und
  Simulation-Subscopes mit Invocation Count und Quantilen, ohne den bisherigen
  Vertrag zu brechen.
- Die LZ-Arming-Aktion aktualisiert UI und Button-State nur einmal nach der
  finalen Zustandsmutation; der sichtbare Zustand und die Planning-Signale
  bleiben gleich.
- Jede produktive Optimierung hat einen vorher roten Verifier sowie eine
  Ergebnis-/Gameplay-Regression auf dem echten Harness.
- Die harten TASK_1193-Budgets bleiben unveraendert. Ein Release wird nur bei
  echten gruenen Messwerten und separat vorliegender manueller Evidenz erlaubt.

## Relevante Dateien

- `scripts/tests/tactical_map_frame_budget_harness.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1194_tactical_performance_budget_reduction.gd`
- `scripts/tests/task_1187_tactical_map_frame_budget.gd`
- `docs/performance/simulation_combat_ai_tick_profile_report.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung

1. Task-1194-Verifier mit einem kurzen echten Tactical-Harness-Lauf.
2. Betroffene Gameplay-/Authority-Regressionen und TASK_1187-Messlauf.
3. TASK_1193-Acceptance-Gate erst nach der Optimierung erneut ausfuehren.
4. `git diff --check` vor jedem Commit.

## Nicht-Ziele

- Keine Budgetanhebung.
- Kein Fake-Manuelltest und keine 256x256-Release-Freigabe.
- Kein Big-Bang-Refactor des Combat- oder Tactical-Controllers.

# TASK_218 - Simulation Combat AI Tick Budget Pass

## Ziel
SimulationRoot, CombatLoop, Enemy-Taktik, Overwatch, Medic, Morale/Suppression, Security und NPC-Minimalabstand sollen ein klares Tick-Budget bekommen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_089 - Enemy Cover-Seeking on Damage
- TASK_092 - Stealth and Contact Range Contract
- TASK_111 - Fireteam Security Direction and Overwatch
- TASK_113 - Flank Vulnerability Contract
- TASK_162 - Combat Authority Contract
- TASK_187 - NPC Minimum Spacing and Multiplayer Authority
- TASK_189 - Medic Adjacent Tile Healing Rule
- TASK_200 bis TASK_204 - Enemy Team Tactics Grundlagen
- TASK_215 - Performance Deep Pass Baseline and Research

## Kontext
Die Mission-Logik wird taktisch reicher: mehr NPCs, Enemy-Team-Profile, Waffenreichweiten, Muzzle-Events, Rank-Badges und Bubble-Feedback. Das darf nicht zu "jede Unit scannt alles jeden Tick" fuehren.

## Umfang
1. Tick-Messung:
   - SimulationRoot command queue.
   - Effect queue.
   - Combat-fire decision.
   - Overwatch/security.
   - Enemy advance/cover/reposition.
   - Medic support.
   - Local avoidance/separation.
2. Skalenszenarien:
   - Kleine Mission.
   - 2 Fireteams vs. 1 Enemy-Team.
   - 4 Fireteams vs. mehrere Enemy-Gruppen.
   - Downed/Medic/Overwatch/Objective gleichzeitig.
3. Hotpath-Audit:
   - Keine SceneTree-Suchen in Combat-/AI-Hotpaths.
   - Keine Node-Lookups in grossen Unit-Schleifen, wenn Referenz/Registry vorhanden ist.
   - Keine Dictionary-/Array-Neuaufbauten pro Unit, wenn pro Tick ein Snapshot reicht.
4. Event-driven statt per-frame:
   - Reactions auf Commands, Damage, Contact, Objective, State change.
   - Periodische Checks gestaffelt oder budgetiert.
5. Multiplayer-Grenze:
   - Authority entscheidet Combat/AI.
   - Client-/Viewer-Pfade zeigen nur Snapshots/VFX/Bubbles.
6. Verifier:
   - Timing-Scopes und Zaehler fuer alle grossen Runtime-Pfade.
   - Broad Budgets, spaeter schaerfbar.

## Nicht-Ziele
- Kein Gameplay-Rebalance.
- Kein KI-Neuschreiben.
- Kein Threading-Patch ohne Not.
- Keine clientseitige Prediction.

## Akzeptanzkriterien
- [x] Combat-/AI-Hotpaths haben Timing-Zaehler.
- [x] Unit-Skalenszenarien zeigen Median/P95/P99 fuer Runtime-Ticks.
- [x] SceneTree-/Node-Lookup-Hotpaths sind geprueft und dokumentiert.
- [x] Enemy-Taktik erzeugt keine unbudgetierten Full-Team-Scans pro Frame.
- [x] Medic/Overwatch/Security bleiben authority-seitig und snapshotfaehig.
- [x] Ein TASK_218-Verifier prueft Tick-Budgets und Hotpath-Diagnosen.

## Erwartete Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/simulation_combat_ai_tick_budget_harness.gd`
- `docs/performance/simulation_combat_ai_tick_profile_report.md`
- `scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd`
- `docs/tasks/TASK_218_simulation_combat_ai_tick_budget_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_218_simulation_combat_ai_tick_budget_pass.gd` (81/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd` (20/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_162_combat_authority_contract_verifier.gd` (23/0)
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_187_npc_minimum_spacing_and_multiplayer_authority.gd` (16/0)
- [x] `git diff --check`

## Umsetzung
- `SimulationRoot` liefert bei aktivem Runtime-Debug Scopezeiten fuer Command Queue, Effect Queue, lokale Avoidance, Minimum Spacing, Objective, Snapshot-Broadcast und Tick-Signal.
- `MissionCombatLoopDriver` liefert Combat-Scopezeiten fuer Contact Tracking, Enemy Security, Enemy Team Tactics, Medic Support, Enemy Advance, Friendly Standard Behavior, Overwatch/Security, Fire Decision, Resolution und Snapshot-Kontext.
- `simulation_combat_ai_tick_budget_harness.gd` misst drei Scale-Szenarien: kleine Mission, zwei Fireteams gegen Enemy-Team und vier Fireteams mit Medic/Downed/Tactics-Druck.
- `simulation_combat_ai_tick_profile_report.md` dokumentiert Scopes, Hotpath-Audit, Authority-Grenze und breite Startbudgets.

## Risiken
- Timing-Messung darf selbst nicht zum groessten Kostenblock werden.
- Optimierung darf Combat-Autoritaet nicht aus SimulationRoot herausziehen.

## Naechster Schritt
Nach TASK_218 prueft TASK_219 UI, HUD, Meta-Screens und Comic-Bubbles.

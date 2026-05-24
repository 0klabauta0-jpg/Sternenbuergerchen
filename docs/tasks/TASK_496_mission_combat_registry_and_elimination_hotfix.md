# TASK_496 - Mission Combat Registry and Elimination Hotfix

## Ziel / Problem
Der `MissionCombatLoopDriver` ruft aktuell einen privaten `SimulationRoot`-Helper `_get_unit_registry()` von aussen auf. Ausserdem liefert `_is_enemy_team_eliminated()` bei leerer aktiver Enemy-Liste immer `false`, auch wenn keine Enemy-Waves und keine Enemy-Respawns mehr ausstehen.

Ziel ist ein kleiner, verhaltensnaher Hotfix: Registry-Zugriff oeffentlich oder sauber injiziert machen und Elimination-Sieg korrekt pruefen.

## Sinnhaftigkeit / Ursache
Der private Registry-Zugriff koppelt Driver und SimulationRoot an eine nicht oeffentliche Methode. Der Elimination-Ast kann Missionen blockieren, wenn alle Gegner weg sind, aber der Sieg nicht ausgeloest wird.

## Umfang
- Einen stabilen oeffentlichen Zugriffspfad fuer die UnitRegistry schaffen oder den Driver auf eine vorhandene exportierte Referenz/NodePath umstellen.
- Den Aufruf auf `SimulationRoot._get_unit_registry()` entfernen.
- `_is_enemy_team_eliminated()` so korrigieren, dass keine aktiven Gegner plus keine pending Waves/Respawns als Elimination gelten.
- Einen kleinen Verifier fuer den leeren-Enemy-/keine-Waves-/keine-Respawns-Fall ergaenzen.
- Bestehende Faelle mit pending Waves oder pending Respawns muessen weiterhin nicht gewinnen.

## Nicht-Ziele
- kein neues Wincondition-System
- keine Objective-Capture-Aenderung
- kein Combat-Balancing
- keine Umstrukturierung des gesamten Drivers

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/tasks/TASK_041_siegbedingung.md`
- `docs/tasks/TASK_162_combat_loop_authority_split.md`
- `docs/tasks/TASK_479_fireteam_runtime_hotpath_guards.md`

## Akzeptanzkriterien
- Kein externer Code ruft `SimulationRoot._get_unit_registry()` mehr auf.
- Der Registry-Zugriff ist als oeffentlicher Contract oder explizite NodePath-Abhaengigkeit erkennbar.
- Elimination-Sieg feuert, wenn alle Enemy-Units inaktiv/nicht fit sind und keine Waves/Respawns ausstehen.
- Pending Waves und pending Respawns blockieren Elimination weiterhin.
- Bestehende Objective- und Multiplayer-Smokes bleiben gruen.

## Betroffene Dateien
- `scripts/core/simulation_root.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- neuer oder bestehender Verifier unter `scripts/tests/`

## Lokale Pruefung
- Neuer TASK_496-Verifier fuer Registry-Zugriff und Elimination-Edge-Cases.
- Relevante Regressionen:
  - `scripts/tests/task_479_fireteam_runtime_hotpath_guards.gd`
  - `scripts/tests/task_473_fireteam_combat_feedback_runtime_overhaul.gd`
  - `scripts/tests/task_160_tactical_playability_verifier.gd`
- `git diff --check`

## Risiken / offene Punkte
- Manche Tests koennen private Helper indirekt erwarten. Der neue Zugriffspfad muss kompatibel bleiben, ohne die private Methode als externen Contract zu zementieren.
- Elimination darf Objective-Defense-/Objective-Capture-Szenarien nicht vorzeitig beenden.

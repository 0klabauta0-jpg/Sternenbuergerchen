# TASK_1084 - Release Deep-Link Runtime Authority Repair

## Status: IMPLEMENTIERT

## Ziel / Problem

Der Release-Direkteinstieg fuer den ersten Feuerwechsel darf Fireteam- und Gegnerstatus nicht direkt aus `MetaLayerFlow` setzen. Auch der reproduzierbare Testaufbau muss ueber die autoritative Missions- und `SimulationRoot`-Command-Kette laufen.

## Ursache / Sinnhaftigkeit

Die TASK-832-/TASK-868-Helfer waren als deterministischer Release-Testaufbau entstanden und riefen `set_runtime_status()` beziehungsweise `assign_unit_command()` direkt auf Units auf. Damit bestand zwar ein sichtbarer Feuerwechsel, aber der Meta-Layer besass ungewollt Gameplay-Autoritaet und TASK_284 meldete einen Architekturverstoss.

## Umfang

- Runtime-Gateway im Missionscontroller fuer den eng begrenzten First-Exchange-Hold-Command.
- Enqueue des gueltigen `UnitCommand` ueber `SimulationRoot`.
- Verarbeitung der Queue vor dem erzwungenen ersten Feuerentscheid.
- Fokussierter Verifier sowie Regressionen fuer Architektur und Release-Direkteinstieg.

## Nicht-Ziele

- Kein Combat- oder Deep-Link-Redesign.
- Keine neuen Spielerbefehle.
- Keine Aenderung an ROE, Schaden, Zielwahl oder Multiplayer-Ownership.
- Keine Verlagerung von Gameplay-Wahrheit in UI oder Meta-Layer.

## Akzeptanzkriterien

- `MetaLayerFlow` ruft weder `set_runtime_status()` noch `assign_unit_command()` direkt auf.
- Der Missionscontroller baut und enqueued den Setup-Command ueber `SimulationRoot`.
- Die autoritative Queue wurde vor `_force_release_first_engagement_decision()` verarbeitet.
- TASK_284, TASK_832 und TASK_868 laufen gruen.

## Betroffene Dateien

- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1084_release_deeplink_runtime_authority_repair.gd`
- Status-, Roadmap-, Contract- und HTML-Berichtsdokumentation

## Lokale Pruefung

- `task_1084_release_deeplink_runtime_authority_repair.gd`
- `task_284_gameplay_truth_architecture_boundary_audit.gd`
- `task_832_release_first_go_firefight_deeplink_evidence.gd`
- `task_868_release_first_exchange_los_setup_polish.gd`
- `git diff --check`

## Risiken / offene Punkte

- Der Direkteinstieg bleibt ein deterministischer Release-/Testaufbau und darf nicht zum alternativen normalen Missionspfad wachsen.
- Die Queue-Synchronisation darf nur auf einen Physik-Tick warten und keinen privaten SimulationRoot-Drain aus dem Meta-Layer ausloesen.

## Ergebnis

- `MetaLayerFlow` delegiert den deterministischen Hold-/Engage-Aufbau nur noch per Unit-ID, Zielposition und Testquellenkennung an den Missionscontroller.
- Der Missionscontroller validiert die Runtime-Unit, baut einen gueltigen `UnitCommand` und enqueued ihn mit stabilem Command-Token ueber `SimulationRoot`.
- Der Direkteinstieg wartet bis nach dem autoritativen Physik-Tick, bevor der Combat-Driver den ersten Feuerentscheid anfordert.
- TASK_1084 ist 12/12, TASK_284 64/64, TASK_832 37/37 und TASK_868 41/41 gruen.

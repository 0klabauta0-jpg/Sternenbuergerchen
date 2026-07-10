# TASK_1049 - Enemy Team Tactics Hotpath Breakdown and Decision Revision Guard

## Ziel / Problem

TASK_1048 misst `enemy_team_tactics_usec` mit rund 405-420 ms als dominanten Teil jedes Combat-Ticks im Missionsstart. Die Taktik sucht und sortiert Cover-Slots samt LOS bei gleicher Lage wiederholt.

## Ursache

`_update_enemy_team_tactics_state()` rekonstruiert Gruppenstates bei jedem Tick. Die teure Cover-/LOS-Arbeit ist bei identischen Enemy-, Friendly-, Objective- und Taktikdaten dieselbe.

## Umfang

- Deterministische Entscheidungs-Signatur aus Enemy-/Friendly-Positionen, Vital-States, Gruppenkonfiguration und Objective.
- Gleiche Eingaben behalten den letzten Taktikstate; jede relevante Aenderung baut sofort neu auf.
- Read-only Rebuild-/Skip-Diagnostik und Regressionsverifier.

## Nicht-Ziele

- Kein Aussetzen der gegnerischen KI auf Zeitbasis.
- Keine Aenderung an autoritativer Tickfolge, Commands, Combat oder Multiplayer.

## Akzeptanzkriterien

- Identische Eingaben skippen die wiederholte Cover-/LOS-Entscheidung.
- Bewegte Friendly-/Enemy-Positionen, Vital- und Ziel-/Taktikwechsel bauen sofort neu auf.
- TASK-1045 passiert die sichtbaren Missionsframes ohne den vorherigen 20-Sekunden-Budgetabbruch.

## Lokale Pruefung

- TASK_1049 6/6.
- TASK_1045 Trace: acht sichtbare Missionsframes innerhalb von rund 4,8 Sekunden; danach neuer Blocker `lz_drop_and_deboard`.
- TASK_170 und `git diff --check`.

## Risiken / offene Punkte

Der erste Aufbau bleibt teuer und ist bewusst nicht weggegated. Der neue LZ/Drop-Blocker und der einzelne Controller-UI-Refresh werden getrennt behandelt.

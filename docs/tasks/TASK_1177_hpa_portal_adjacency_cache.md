# TASK_1177 - HPA Portal Adjacency Cache

## Ziel / Problem

Jede HPA-Query baute die Portal-Adjazenz erneut. Bei Formationsbewegung wird
dieselbe Graphstruktur mehrfach pro Bewegungsstufe gelesen.

## Aenderung

`HPAPathfinder` cached die Adjazenz pro Graphinstanz und Graphrevision.
`HPANavigationGraph` erhoeht die Revision nach Full- und Dirty-Rebuild. Damit
bleiben Terrain-Aenderungen sicher invalidierend.

## Akzeptanz

- Wiederholte Query: ein Adjazenz-Build, mindestens ein Cache-Hit.
- Full-Rebuild: erneuter Build.
- Bestehende HPA- und SimulationRoot-Pfade bleiben gruen.

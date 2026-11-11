# Regional navigation without blocking the first GO

## Problem and scope

The native B profile measured an 8.574 s first-GO frame. The first ground
route builds the whole HPA graph synchronously, and later HPA queries can
also take hundreds of milliseconds. Keep all three 512 × 256 maps and
retain the established HPA path for smaller or non-hex terrain.

## Behavior and acceptance

SimulationRoot advances regional ground A* in bounded slices through the
existing command queue. Search state belongs to the queued move and is
invalidated by a terrain revision or changed start/target. Follow legal
steps and the existing cost model, including ramps, cover and doors.
If a destination is unreachable, stop at a reachable cell instead of
crossing a blocker. Superseded moves must stay superseded.

## Source and local verification

See TASK_412 and the native Glut QA profile. Change TerrainPathfinder,
SimulationRoot and the native B verifier only as required. Check bounded
expansion, route and fallback behavior, then replay the same real B guard
encounter from the existing post-A checkpoint at native 1×. Compare first
GO, approach, combat and route latency. Long or unreachable routes can
take more simulation ticks to resolve.
## Ergänzung vom 11.11.2026

Der normale Auslösevorgang braucht neben der eigentlichen Wegsuche eine
schnelle Auflösung blockierter Formationsziele. Der bestehende räumliche
Registry-Index wird deshalb nach dem Einlesen vorbereitet und für lokale
Nächstfeld-Abfragen wiederverwendet. Außerhalb des bewiesenen lokalen
Suchbereichs bleibt die vollständige Abfrage verfügbar. Die ursprüngliche
Reihenfolge, Distanzmetrik, Toleranz und aktuelle Tür-Walkability bleiben
maßgeblich. Reine Overrides verändern die Positionen des Index nicht.
## Budget und Diagnose

Die regionale A*-Suche erhält 24 Expansionen je Slice und insgesamt
96 Expansionen je Simulationstick. Bis zu vier wartende Aufträge werden
nach Priorität, danach nach dem letzten Bedienungstick und der
Eingangsreihenfolge zugelassen. Der Prüffall mit sechs Einheiten lässt
fünf lange unerreichbare Aufträge weiterrechnen und den letzten kurzen
Auftrag anlaufen. Ein neuer Befehls-Token und Hold lösen alte Aufträge ab.
Revisions- und Kostenwechsel verwerfen die zugehörige Suche.

Die Diagnose führt CPU-Arbeit, maximales Slice und Wall-Latenz getrennt.
Ein Wartetick ohne Rechenarbeit meldet 0 µs. Die Pfadrekonstruktion hängt
die Zellen an und kehrt das Ergebnis einmal um. Dies vermeidet wiederholtes
Verschieben bereits rekonstruierter Zellen.

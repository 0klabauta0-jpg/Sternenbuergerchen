# TASK_1184 - Grid Sweep Objective/Debrief Acceptance

## Ziel

Der `grid_sweep`-Spielerpfad muss Objective-Sieg und den vorhandenen Debrief-
Handoff deterministisch belegen.

## Befund

Der bisherige Verifier griff nach dem siegausloesenden Physics-Tick auf bereits
freigegebene Missionsnodes zu. Dadurch waren 18/18 mit `previously freed
instance` und Exit 0 moeglich.

Der Lauf startet eine reguläre `Take`-Order mit elf Bounding-Stages und wartet
danach auf die native Objective-Capture-Progression. Das frühere Budget von 256
Ticks war unter derselben Eingabe in einzelnen Läufen zu knapp. Das Budget ist
daher auf 384 Ticks erhöht; es ändert weder Szenariodaten noch Gameplay-Logik,
sondern nur das Verifier-Timeout. Nach dem Sieg wartet der Verifier außerdem
explizit auf den vorhandenen Debrief-Handoff, bevor er dessen Snapshot prüft.

## Akzeptanz

- Drei serielle Laeufe liefern jeweils `22 passed, 0 failed` und Exit 0.
- Der Debrief enthaelt denselben letzten Missionsresult-Snapshot.
- Das Result ist `victory` mit `objective_captured`.
- Freigegebene Missionsnodes und Script-Fehler lassen den seriellen Runner
  fehlschlagen.

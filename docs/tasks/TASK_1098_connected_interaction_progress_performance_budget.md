# TASK_1098 - Connected Interaction Progress Performance Budget

## Ziel / Problem
Die Progress-Oberflaeche ist dedupliziert, muss aber bei mehreren parallelen Fireteams die bevorzugte aktive Interaction stabil halten und hohe Snapshot-Frequenz verkraften.

## Umfang
- Bevorzugte aktive Interaction vor anderen aktiven States anzeigen.
- Abgeschlossene bevorzugte Interaction darf laufende andere States nicht verdecken.
- Stress mit acht parallelen States und tausenden Snapshots.
- Updatezahl und Gesamtlaufzeit messen.

## Akzeptanzkriterien
- Bevorzugte aktive Interaction bleibt sichtbar.
- 2000 Snapshots bleiben unter einem breiten 250-ms-Guard.
- Dedupe reduziert Label-Updates auf hoechstens 250.
- Kein kompletter HUD-Rebuild wird eingefuehrt.

## Risiken / offene Punkte
Der Guard ist ein lokaler Regressionsschutz, kein Ersatz fuer Plattformprofiling mit echtem Netzwerkjitter.

## Ergebnis
- 5/5: bevorzugte aktive Fireteam-Interaction bleibt bei acht parallelen States sichtbar.
- 2000 Snapshots benoetigen lokal rund 75 ms und erzeugen nur 201 Label-Updates.
- Der 250-ms-/250-Update-Guard ist deutlich gruen.
- TASK_1096 bleibt 10/10 gruen.
- Naechster Schritt: TASK_1099 - Connected Interaction Snapshot Payload Budget und Delta-Kandidat fuer wachsende Parallelitaet.

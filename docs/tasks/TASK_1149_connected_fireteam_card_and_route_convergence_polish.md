# TASK_1149 - Connected Fireteam Card and Route Convergence Polish

## Ziel / Problem
Der echte TASK_1148-Release-Capture zeigt nach erfolgreichem Drop und Host-bestaetigtem GO widerspruechliche Lesedaten: Member-Cards melden Bewegung, waehrend die linken Fireteam-Mini-Cards auf dem Client `WARTET` und auf dem Host `STABIL` zeigen. Die Client-Routenlinie verlaesst zugleich den eigentlichen Kartenfokus.

## Umfang
- Mini-Card-Status gegen denselben autoritativen Fireteam-Movement-Snapshot wie Member-Cards abgleichen.
- Host/Client-Snapshot-Reihenfolge und Dirty-Refresh nach Command-Accept pruefen.
- Routen-/Waypoint-Endpunkt auf walkable Kartenposition und sichtbare Kartenbounds pruefen.
- 1600x900 Host-/Client-Recapture nach erstem verbundenem GO.

## Nicht-Ziele
- Kein Movement-, Pathfinding- oder Snapshot-Rewrite.
- Keine zweite UI-Wahrheit fuer Fireteams.
- Keine Aenderung an LZ-, Drop- oder Authority-Regeln ohne reproduzierbaren Runtime-Befund.

## Akzeptanzkriterien
- Host und Client zeigen fuer dasselbe Fireteam denselben autoritativen Bewegungszustand.
- Mini-Card und Member-Cards widersprechen sich nicht.
- Die sichtbare Route endet innerhalb der taktischen Kartenflaeche am autoritativen Ziel.
- Blue- und Gold-Perspektive bleiben getrennt; fremde Commands bleiben blockiert.

## Risiken / offene Punkte
Der Unterschied kann entweder aus stale UI-Dirty-State oder aus einem spaet eintreffenden Movement-Snapshot stammen. Erst Trace/Source-Abgleich, dann minimaler Fix.

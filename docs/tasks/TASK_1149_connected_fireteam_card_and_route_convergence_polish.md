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
Der alte `bugfix_mission_dropship_plans_and_facing.gd` erwartet zwei Approach-Linien in einer Szene, in der der spaetere TASK_842-Release-Declutter sie bereits unterdrueckt. Die aktuellen dedizierten Dropship-, Perspektiv- und Declutter-Vertraege sind gruen; der historische Assert bleibt separate Testhygiene.

## Ergebnis
- Die Mini-Card priorisiert bei aktivem Fireteam-Movement dessen read-only Movement-Text.
- Im kurzen Snapshot-Uebergang bleibt `MARSCHIERT` aus dem bereits vorhandenen Member-Runtime-Snapshot sichtbar.
- Leere Personal-Dropships in `outbound`, `to_homebase` oder `complete` zeichnen keinen Einsatzvektor mehr ueber die Karte. Beladene Planungs- und Cargo-Vektoren bleiben bestehen.
- Der echte 1600x900-Host-/Client-Release-Recapture zeigt Blue und Gold auf beiden Seiten als `MARSCHIERT`; die lange gruene Client-Linie ist verschwunden.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1149_connected_fireteam_card_route_convergence_polish.gd`

## Lokale Pruefung
- TASK_1149: 6/6
- TASK_369: 14/14
- TASK_842: 33/33
- TASK_1109: 18/18
- TASK_1110: 20/20
- TASK_1148 Deeplink/Harness: 7/7 und 10/10
- TASK_222 Performance Gate: 82/82
- Echter Zwei-EXE-Release-Lauf: `pass`, `deployment_converged = true`

# TASK_1115 - Connected Parallel Dropship Drop Deboard Return Playthrough

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Zwei verbundene Spieler muessen ihre getrennten Dropships nicht nur planen, sondern den kompletten Transportlauf parallel abschliessen koennen: LZ setzen, anfliegen, landen, eigenes Fireteam aussteigen lassen und zum FOB zurueckkehren.

## Sinnhaftigkeit / Ursache
TASK_1110 bis TASK_1114 sichern Snapshot, Authority, Dedupe, Pending und Kartenfeedback ab. Der vollstaendige parallele Runtime-Lauf wurde bisher nur lokal mit zwei Schiffen getestet, nicht ueber echte Host-/Client-Snapshots.

## Umfang
- Drei echte ENet-Peers: Host, BLUE und GOLD.
- Zwei Crafts mit getrennten Fireteam-Payloads und LZs.
- Beide Clients senden ihren Drop-Command zum Host.
- Host simuliert beide Drop-Sequenzen parallel bis Deboarding und RTB.
- Alle Peers konvergieren auf leere Embarked- und vollstaendige Deployed-IDs.
- Craft- und Fireteam-Auswahl bleibt lokal pro Client.
- BLUE- und GOLD-Payload werden nie vermischt.

## Nicht-Ziele
- Keine neue Flugphysik oder Abschusslogik.
- Kein Host-Migration-Support waehrend des Drops.
- Kein neues Snapshotformat.
- Kein Redesign der Dropship-Karten.

## Akzeptanzkriterien
- Beide Drops starten hostautoritativ und gleichzeitig.
- Jedes Craft entlaedt ausschliesslich seine eigene Payload.
- Beide Clients sehen alle deployten Units und keine eingebetteten Rest-IDs.
- Beide Karten erreichen einen RTB-Zustand ohne die andere Sequenz zu ueberschreiben.
- Lokaler BLUE-/GOLD-Auswahlfokus bleibt erhalten.
- Client-Anwendung erzeugt keine eigenen Commands oder Effects.

## Betroffene Dateien
- `scripts/tests/task_1115_connected_parallel_dropship_drop_deboard_return_playthrough.gd`
- bei Befund: `scripts/tests/mission_tactical_sandbox_controller.gd`
- Status, Roadmap und HTML-Arbeitsbericht

## Lokale Pruefung
- TASK_1115 Drei-Peer-Playthrough
- TASK_1114 Kartenfeedback
- TASK_1113 Pending-/Double-Submit
- TASK_1112 Parallel Lifecycle
- TASK_396 lokaler Zwei-Dropship-Deboarding-Lauf
- TASK_399 Dropship-Hotpath
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Der Verifier darf den Host-Runtime-Timer beschleunigen, aber keine Client-Sequenz direkt mutieren. Der Beweis muss ueber Host-Snapshot-Konvergenz laufen.

## Ergebnis
- Host, BLUE und GOLD laufen mit echten ENet-Peers durch getrennte LZ-, Drop-, Deboard- und RTB-Sequenzen.
- Alle drei Peers konvergieren auf leere Embarked-Payloads und dieselben vollstaendigen Deployed-IDs.
- BLUE und GOLD behalten ihren lokalen Craft-/Fireteam-Fokus und vermischen keine Payloads.
- Der rote Lauf fand eine echte Client-Queue-Drift: Snapshot-Presence legte lokale Deploy-Effects auf Clients ab, die dort absichtlich nicht getickt werden.
- Verbundene Snapshot-Clients spiegeln Presence jetzt rein visuell; Gameplay-Effects bleiben Host-Sache.
- TASK_1115 besteht 25/25. TASK_1114 13/13, TASK_1113 16/16, TASK_1112 13/13, TASK_396 17/17, TASK_399 9/9 und TASK_1104 31/31 bleiben gruen.

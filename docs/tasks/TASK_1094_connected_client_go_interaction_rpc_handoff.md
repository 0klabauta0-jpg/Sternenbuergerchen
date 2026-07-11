# TASK_1094 - Connected Client GO Interaction RPC Handoff

## Ziel / Problem
Der volle Network-Interaction-Contract ist vorhanden, aber der sichtbare Client-GO-Griff startet noch lokale Waypoint-Ausfuehrung.

## Umfang
- Verbundener Client erkennt einen bestaetigten Interaction-Intent beim GO.
- GO projiziert und sendet genau einen Host-Command.
- Lokale Pending-Waypoints werden entfernt und nicht ausgefuehrt.
- Pending/Accepted/Blocked werden aus Host-Feedback angezeigt.
- Einzelspieler-GO bleibt unveraendert.

## Akzeptanzkriterien
- Echter Client-Controller-GO erreicht Host-Validation ueber ENet.
- Client bewegt keine Unit und enqueued keinen lokalen Command.
- Doppel-GO waehrend Pending sendet nicht erneut.
- Host-Ergebnis beendet Pending und ist read-only sichtbar.
- TASK_1093 und lokale Route bleiben gruen.

## Risiken / offene Punkte
Ein spaeterer sichtbarer Zwei-Fensterlauf soll Microcopy und Timing von `HOST PENDING`/`HOST OK` beurteilen.

## Ergebnis
- 6/6: echter Client-Controller-GO sendet genau einen ENet-Request.
- Ein zweiter GO-Klick bleibt waehrend Host-Pending blockiert.
- Der Client enqueued keine lokale Bewegung; Host-Feedback beendet Pending read-only.
- Der lokale Einzelspieler-Interaction-GO bleibt 23/23 gruen.
- Naechster Schritt: TASK_1095 - Connected Interaction Feedback Visual Polish and Two-Window Readability.

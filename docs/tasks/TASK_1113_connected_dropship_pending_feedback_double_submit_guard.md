# TASK_1113 - Connected Dropship Pending Feedback and Double-Submit Guard

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Ziel / Problem
Ein laufender Dropship-Request muss direkt auf der betroffenen Craft-Karte sichtbar sein. Schnelle Mehrfachklicks duerfen fuer dasselbe Craft keine neuen Command-IDs erzeugen; andere Crafts muessen parallel bedienbar bleiben.

## Sinnhaftigkeit / Ursache
TASK_1112 dedupliziert Retransmits derselben Command-ID. Jeder UI-Klick erzeugt aber eine neue ID. Der Mission-Controller speichert bisher keinen per-Craft Pending-Zustand und deaktiviert die Aktionsbuttons waehrend der Hostantwort nicht.

## Umfang
- Read-only Pending-State pro Craft mit Command-ID, Aktion, Phase und Timeout.
- Zweiten Request fuer dasselbe Craft vor dem RPC blockieren.
- Andere Crafts parallel erlauben.
- Card-Status zeigt `ACTION -> HOST` beziehungsweise `HOST OK` bis Snapshot.
- Card-Aktionsbuttons waehrend Pending deaktivieren.
- Reject entfernt Pending sofort und zeigt lesbares Feedback.
- Akzeptierter Request bleibt bis passendem Snapshot gesperrt.
- Timeout gibt Craft wieder frei und zeigt `HOST TIMEOUT`.

## Nicht-Ziele
- Keine neue Gameplay- oder Transportwahrheit im UI.
- Kein allgemeines Request-Queue-System.
- Kein UI-Redesign der Dropship-Karte.
- Keine Aenderung am Snapshottransport.

## Akzeptanzkriterien
- Erster BLUE-Request setzt genau einen Pending-Eintrag.
- Zweiter BLUE-Klick wird lokal geblockt und erzeugt keine neue ID.
- GOLD kann waehrend BLUE-Pending separat senden.
- Nur Buttons des betroffenen Crafts sind deaktiviert.
- Host-Reject und Timeout geben das Craft wieder frei.
- Host-OK bleibt bis zur Snapshot-Konvergenz sichtbar gesperrt.
- Keine Commands oder Effects werden durch reine Pending-Anzeige erzeugt.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1113_connected_dropship_pending_feedback_double_submit_guard.gd`
- Status-, Roadmap- und HTML-Arbeitsreport-Dokumentation

## Lokale Pruefung
- TASK_1113 Verifier
- TASK_1112 Parallel Lifecycle
- TASK_1111 Authority/Ownership
- TASK_1110 Snapshot-Perspektive
- TASK_399 Dropship-Hotpath
- TASK_1104 Drei-Peer-Produktlauf
- `git diff --check`

## Risiken / offene Punkte
Der Pending-State darf niemals als Beweis fuer einen erfolgreichen Drop gelten. Akzeptierte Requests werden erst durch einen passenden autoritativen Snapshot abgeschlossen.

## Ergebnis
- Ein Request erzeugt pro Craft genau einen lokalen, read-only Pending-Eintrag.
- Weitere Klicks desselben Crafts bleiben vor Command-ID und RPC stehen; andere Crafts bleiben parallel bedienbar.
- Host-OK wartet auf den passenden autoritativen Snapshot, Reject und Timeout geben die Karte wieder frei.
- Kartenfeedback und Aktionsbuttons lesen denselben Pending-Eintrag, ohne Transportstate zu mutieren.
- Verifiziert mit TASK_1113 16/16 sowie TASK_1112 13/13, TASK_1111 30/30, TASK_1110 20/20, TASK_399 9/9 und TASK_1104 31/31.

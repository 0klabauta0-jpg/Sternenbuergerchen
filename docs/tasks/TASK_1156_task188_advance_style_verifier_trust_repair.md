# TASK_1156 - TASK 188 Advance Style Verifier Trust Repair

## Ziel / Problem
TASK 188 meldet 13 fehlgeschlagene Assertions, beendet Godot aber mit Exit 0. Damit kann ein roter Movement-/Map-Verifier in automatischen Gates unbemerkt als erfolgreich gelten.

## Ursache / Sinnhaftigkeit
Der Verifier ruft `quit()` ohne Fehlercode auf. Seine Fixture startet alle Advance Styles mit dem Baseline-Befehl `move`; die aktuelle Doctrine normalisiert `move` absichtlich auf `rush`. Bounding und Caterpillar werden deshalb nie erzeugt, obwohl deren Runtime-Logik weiterhin vorhanden ist.

## Umfang
- TASK-188-Prozess bei Assertion-Fehlern nonzero beenden.
- Stiltreue Fixture fuer Rush, Bounding und Caterpillar verwenden.
- Aktuelle Baseline-Doctrine (`move` bleibt Rush) separat respektieren.
- Map-Snapshot und Selected-Fireteam-Lesbarkeit erneut pruefen.

## Nicht-Ziele
- Keine Aenderung an Movement-Doctrine, Pathfinding oder Formation.
- Kein Rueckbau der bewussten Move-zu-Rush-Regel.
- Kein Karten- oder HUD-Redesign.

## Akzeptanzkriterien
- Ein Assertion-Fehler fuehrt zu Exit 1.
- TASK 188 ist mit allen drei tatsaechlich erzeugten Stilen gruen.
- TASK 110/111, Pathfinding- und Performance-Gates bleiben gruen.

## Betroffene Dateien
- `scripts/tests/task_188_fireteam_advance_styles_map_readability.gd`
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- TASK 188 vor Fix: 24 bestanden, 13 fehlgeschlagen, fehlerhaft Exit 0.
- TASK 188 nach Fix komplett gruen und Exit 0.
- Movement-/Pathfinding-/Performance-Regressionen.
- `git diff --check`.

## Risiken / offene Punkte
Die Fixture darf nicht die Produktdoctrine umgehen, um einen alten Test kuenstlich gruen zu machen. Sie verwendet `flank` nur als bestehenden stiltreuen Command zur isolierten Visualpruefung und prueft `move -> rush` weiterhin ueber bestehende Doctrine-Gates.

## Ergebnis
- Status: implementiert.
- TASK 188 verwendet fuer die isolierte Style-Visualpruefung den bestehenden stiltreuen `flank`-Command; die Produktdoctrine `move -> rush` bleibt unveraendert.
- Rush, Bounding und Caterpillar sind wieder als echte Runtime-Snapshots und Map-Entries belegt.
- `quit(1 if _failed > 0 else 0)` macht Assertion-Fehler fuer Shell, CI und Agenten sichtbar.
- Ein expliziter `--task188-force-failure`-Lauf liefert Exit 1; der normale Lauf liefert Exit 0.

## Abschlusspruefung
- TASK 188 normal: 37/37, Exit 0.
- TASK 188 Forced Failure: 37 bestanden, 1 absichtlich fehlgeschlagen, Exit 1.
- TASK 501 Movement Command Lifecycle: 10/10.
- TASK 222 Performance: 82/82.
- Offener Harness-Befund: Der historische TASK-110-Verifier lief isoliert in ein 120-Sekunden-Timeout. Das ist nicht durch diese reine Verifier-Aenderung verursacht, sollte aber bei Wiederholung separat untersucht werden.

## Naechster Schritt
Zur sichtbaren Produktarbeit zurueckkehren: Die Befehlsmatrix links unten im 1280x720-Release ist klein, kuerzelreich und der naechste klare Lesbarkeitskandidat.

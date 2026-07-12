# TASK_1155 - Contact Focus Empty Dropship Surface Retirement

## Ziel / Problem
Im aktuellen Host-/Client-First-Contact-Capture bleiben rechts zwei grosse Dropship-Karten sichtbar. Beide Schiffe sind leer, der Trupp ist deployed und der Status lautet `Leaving mission map`; die Karten besitzen zu diesem Zeitpunkt keine sinnvolle Aktion mehr und verdecken taktische Kartenflaeche.

## Ursache / Sinnhaftigkeit
Der vorhandene TASK-1120-Filter blendet nur leere Karten im Zustand `to_fob` mit ETA 0 aus. Der echte Release-Drop bleibt waehrend des ersten Feuerkontakts noch im Zustand `outbound` und gilt wegen der laufenden Sequenz nicht als abgeschlossen, obwohl die UI-Surface bereits rein historisch ist.

## Umfang
- Leere `outbound`-Dropship-Karten bei aktivem Contact-Fokus aus der grossen Bedienflaeche entfernen.
- Leere abgeschlossene `to_fob`-Karten weiterhin entfernen.
- Beladene, wartende, gelandete oder wirklich pending Karten sichtbar lassen.
- Abgelaufener, nur noch in der replizierten Karte konservierter Result-Text darf eine leere Surface im Contact-Fokus nicht festhalten.
- Karten-/Transportdaten und autoritative Sequenz unveraendert lassen.

## Nicht-Ziele
- Kein Abbruch oder Beschleunigen der Dropship-Sequenz.
- Keine Aenderung an Transportstate, Snapshots, Commands oder Multiplayer-Authority.
- Kein generelles Verstecken von Dropships ausserhalb des Contact-Fokus.

## Akzeptanzkriterien
- Zwei leere `outbound`-Karten ergeben bei `CONTACT FIRE` keine grossen Bedienkarten mehr.
- Dieselben Karten bleiben ohne Contact-Fokus sichtbar.
- Payload, echte Pending-Commands und noch bedienbare Craft-Zustaende bleiben sichtbar.
- Host und Client behalten Deployment, Contact und First Fire.
- TASK_1120, TASK_1109, TASK_1110, TASK_1150 und TASK_222 bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_1155_contact_focus_empty_dropship_surface_retirement.gd`
- Status, Roadmap und HTML-Handbuch

## Lokale Pruefung
- TASK_1155 RED/GREEN.
- TASK_1120, TASK_1109, TASK_1110, TASK_1150 und TASK_222.
- Exportierter Host-/Client-First-Contact-Capture.
- `git diff --check`.

## Risiken / offene Punkte
Eine leere Karte kann noch historischen Host-Text tragen. Nur ein echter Pending-Command verhindert das Ausblenden; Result-Feedback bleibt weiterhin in Command-/Event-Feedback nachvollziehbar, darf aber im Feuerkontakt keine nicht mehr bedienbare Grosskarte festhalten.

## Ergebnis
- Status: implementiert und im exportierten Host-/Client-First-Contact sichtbar verifiziert.
- Leere `outbound`-Karten verschwinden im Contact-Fokus; leere `to_fob 0s`-Karten verschwinden generell, weil sie keine Aktion mehr besitzen.
- Historischer `HOST TIMEOUT`-Text pinnt keine leere Grosskarte mehr. Echte Pending-Commands halten ihre Surface weiterhin sichtbar.
- Connected Perspective, persistierte First-Fire-Evidence und die tatsaechlich sichtbare Combat-HUD-Density speisen dieselbe Contact-Fokus-Entscheidung.
- Multiplayer-Snapshots loesen nur bei Contact-Fokus-Wechsel oder geaendertem Dropship-State im aktiven Fokus einen Panel-Refresh aus.

## Abschlusspruefung
- TASK_1155: 17/17.
- TASK_1120: 11/11; TASK_1114: 13/13.
- TASK_1109: 18/18; TASK_1110: 20/20.
- TASK_1117: 15/15; TASK_1150: 18/18.
- TASK_222: 82/82.
- Exportierter Zwei-EXE-Lauf `pass`; finale Host-/Client-PNGs zeigen rechts keine leeren Dropship-Karten mehr.

## Naechster Befund
TASK 188 meldet 13 fehlgeschlagene Assertions, beendet sich aber mit Exit 0. Diese Testvertrauensluecke sollte zuerst geschlossen werden. Danach ist im 1280x720-Release die kleine Befehlsmatrix links unten der naechste sichtbare Lesbarkeitskandidat.

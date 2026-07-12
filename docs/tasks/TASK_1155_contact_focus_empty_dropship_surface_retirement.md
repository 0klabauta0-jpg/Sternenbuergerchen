# TASK_1155 - Contact Focus Empty Dropship Surface Retirement

## Ziel / Problem
Im aktuellen Host-/Client-First-Contact-Capture bleiben rechts zwei grosse Dropship-Karten sichtbar. Beide Schiffe sind leer, der Trupp ist deployed und der Status lautet `Leaving mission map`; die Karten besitzen zu diesem Zeitpunkt keine sinnvolle Aktion mehr und verdecken taktische Kartenflaeche.

## Ursache / Sinnhaftigkeit
Der vorhandene TASK-1120-Filter blendet nur leere Karten im Zustand `to_fob` mit ETA 0 aus. Der echte Release-Drop bleibt waehrend des ersten Feuerkontakts noch im Zustand `outbound` und gilt wegen der laufenden Sequenz nicht als abgeschlossen, obwohl die UI-Surface bereits rein historisch ist.

## Umfang
- Leere `outbound`-Dropship-Karten bei aktivem Contact-Fokus aus der grossen Bedienflaeche entfernen.
- Leere abgeschlossene `to_fob`-Karten weiterhin entfernen.
- Beladene, wartende, gelandete, pending oder mit Feedback versehene Karten sichtbar lassen.
- Karten-/Transportdaten und autoritative Sequenz unveraendert lassen.

## Nicht-Ziele
- Kein Abbruch oder Beschleunigen der Dropship-Sequenz.
- Keine Aenderung an Transportstate, Snapshots, Commands oder Multiplayer-Authority.
- Kein generelles Verstecken von Dropships ausserhalb des Contact-Fokus.

## Akzeptanzkriterien
- Zwei leere `outbound`-Karten ergeben bei `CONTACT FIRE` keine grossen Bedienkarten mehr.
- Dieselben Karten bleiben ohne Contact-Fokus sichtbar.
- Payload, Pending/Feedback und noch bedienbare Craft-Zustaende bleiben sichtbar.
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
Eine leere Karte kann noch kurzfristiges Host-Feedback tragen. Pending- oder Feedbackzustand verhindert deshalb das Ausblenden, bis der vorhandene Feedback-Lifecycle abgeschlossen ist.

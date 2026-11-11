# Orbit- und Quantum-Reisevertrag

Freigegebener Scope: `docs/tasks/ORBIT_QUANTUM_TRAVEL_2026_11_09.md`.

## Reise und Ladegrenze

`homebase` liegt auf dem Mond. `satellite_crash` und `trade_outpost` liegen auf
einem Planeten. Abheben fuehrt ohne konkrete Missionswahl zum `moon_orbit`.
Ein Klick auf `planet_orbit` oder `moon_orbit` startet einen 3-s-Quantum-Sprung.
Abbruch behaelt die interpolierte Position (`stopped`); gleicher oder anderer
Zielklick beginnt dort einen neuen Sprung. Keine automatische Wiederaufnahme.
Nur angekommener Orbit erlaubt zugehoerigen Ortsanflug. Auswahl ist kein Anflug.

Der ausdrueckliche Anflug zeigt vor dem Laden „Sternkarte wird verlassen“ und
den konkreten Zielort. Erst nach sichtbarer Uebergangsphase duerfen Mission
und Timer starten. Die Missionskarte behaelt ihren eigenen Landungs-/LZ-Pfad.
Rueckflug vom Ort fuehrt in den Planetenorbit, Heimreise in den Mondorbit;
erst Landung ist Heimkehr. Ergebnis darf vorher angezeigt, aber nicht als
Heimkehr oder neuer Basischeckpoint gewertet werden.

Basis- und Schiffsreparaturdaten sind keine Heimkehrbelege. Solange der
Reiseowner das Schiff ausserhalb `grounded` fuehrt, verschieben Laden oder
Fortschalten seiner Reparaturmetadaten es nicht zur Heimatbasis; Basisreparatur
schreitet erst dort fort. Eine fehlgeschlagene Extraktion mit Besatzungsverlust
bleibt am Ort und bietet den ausdruecklichen letzten sicheren Checkpoint an.
Auch bei beschaedigtem Schiff bleibt der sichere Checkpoint unveraendert.

## Autoritaet und Grenzen

`singleplayer_space_travel_state.gd` besitzt Reisephase, Position und Quantum-
Fortschritt. Mutationen laufen ueber `SimulationRoot` und den Runtimeadapter.
Lifecycle-/Tick-Evidenz kommt vom Runtimepfad; UI-Payload ist kein solcher Beleg.
Payload, Pilot, Boarding, LZ und bestehende Transportphasen behalten ihren Owner.
Sternkarte und Regionalkartenwrapper lesen denselben Snapshot.
Basis-/Trupp-/Ausrustungsvorschauen lesen denselben Standort: reales Pad am
Boden, Weltraum nach dem Abheben. Operationsansichten duerfen waehrend der
Reise geoeffnet werden; das aendert weder Standort noch Heimkehrbelege.

Ort/Karte/Szenario, Auftrag und Orbit sind getrennte IDs. Auftragsannahme und
Quantum-Reise aktivieren/erfuellen keinen Auftrag. Kampagnenfreischaltungen
bleiben gueltig. Bereitschaft fuer Abheben braucht Pilot, fertig geboardete
Payload und reales Pad; Ortsanflug prueft zudem Ort, Auftrag und Rueckreserve.
Bestehende Fuel-Kosten werden genau einmal beim verbindlichen Ortsanflug und
Rueckflug gebucht. Quantum-Abbruch/Neustart fuehren keine zusaetzliche Oekonomie
ein. UI besitzt keine Craft-, Fuel-, Missions- oder Reiseparallelwahrheit.

V1: ein aktiver Reiseausflug, ein Mond, ein Planet, zwei Zielorte. Bestehende
andere Skirmish-/Multiplayer-Missionen bleiben getrennt. Basischeckpoint bleibt
einziger Savepunkt; Abbruch der Anwendung im Orbit setzt beim Fortsetzen auf
den letzten Basischeckpoint zurueck.

## Sternkartenkamera und Zukunftspositionen

Die Kamera ist UI-Zustand: Verschieben per Ziehen, Mausradzoom am Cursor,
Gesamtansicht. Vor und nach dem Zoom muss derselbe Kartenpunkt unter dem
Cursor liegen (ausser eine erreichte Zoomgrenze veraendert den Faktor nicht).
Zeichnung, klickbare Himmelskoerper und Schiffsposition nutzen einen gemeinsamen
Transform. Kamerabewegung sendet keine Reise- oder Gameplaycommands.

Die drei Datenplaetze unter `planet_orbit.encounter_slots` sind für spätere
Begegnungen reserviert. Sie bleiben in der Definition und werden auf der
Sternkarte ausgeblendet. Die aktiven Quantum-Ziele folgen dem Abschnitt
Orbitmarker.

## Pruefung

Domain: Abbruchposition, Neustart, Ankunft, Orbitgrenzen, ungueltige/duplizierte
Commands. UI: Aktionen, Sperrgruende, expliziter Anflug. Flow: keine vorzeitige
Mission/Timer, echte Ortskarte erst nach Anflug, Fuel einmal, Rueckorbit und
Landung vor Heimkehr. Native Verstaendlichkeit bleibt getrennte Sichtpruefung.

## Revision 10.11.2026
Die historische Ein-Reise-Grenze ist fuer diesen Slice abgeloest: singleplayer_fleet_travel_state.gd indiziert unveraenderte individuelle Reiseowner. Orte und Ansicht folgen persistent_location_runtime_contract.md. Die erste Kampagne bleibt bei zwei Personen/einem Schiff; Mehrtruppbetrieb ist mit isoliertem groesserem Team geprueft. Mehrschiff-Weltcheckpoint bleibt sichtbar gesperrt, statt ein unvollstaendiges Ein-Schiff-Save zu erzeugen.

## Orbitmarker

Jeder anfliegbare Himmelskörper besitzt drei einzelne Orbitmarker an
abwechselnden Ecken seines Hexgürtels. Karte und Liste wählen denselben
Marker. Die Sonne besitzt keine Orbitmarker. Der Quantum-Command nimmt
optional `target_orbit_marker_id` entgegen. Ohne Marker startet die Reise
zum bisherigen Standardpunkt. `orbit_id` bleibt die kanonische Ortsbindung.
Der Snapshot hält den Zielmarker während des Sprungs und den erreichten
Marker für Orbit, Anflug, Ortsbesuch und Rückflug. Jeder Marker am richtigen
Körper erlaubt den regulären Anflug beziehungsweise die Heimlandung.

Die Orbitbereichsdaten bleiben für ihre bisherige Bedeutung erhalten. Die
Anzeige erfindet keine Feindpräsenz oder Freigabe. Der Basischeckpoint
speichert weiterhin nur den geerdeten Stand.

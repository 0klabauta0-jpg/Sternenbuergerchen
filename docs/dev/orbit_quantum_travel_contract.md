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
Payload und reales Pad; Ortsanflug prueft zudem Ort, Auftrag und den Treibstoff fuer seine eigene Etappe (keine Rueckreserve mehr, Regel 8, 21.11.).
Fuel wird je Etappe genau einmal gebucht, wenn die Etappe beginnt: Abheben,
Quantensprung, verbindlicher Ortsanflug, Ortsabflug (Landung auf der Mondbasis
kostet 0). Ein Quantum-Abbruch erstattet nichts; der Neustart aus stopped
kostet die Sprungetappe nicht noch einmal. UI besitzt keine Craft-, Fuel-, Missions- oder Reiseparallelwahrheit.

Historischer V1-Umfang: ein aktiver Reiseausflug, ein Mond, ein Planet, zwei
Zielorte. Bestehende andere Skirmish-/Multiplayer-Missionen bleiben getrennt.
Seit dem aktiven Kampagnencheckpoint sind unterstuetzte stabile Ein-Schiff-
Bodeneinsaetze separat speicherbar. Normales `continue` laedt einen gueltigen,
zum Basisstand passenden Einsatzstand, sonst den Basisstand. Orbitflug selbst
ist weiterhin kein Dateisavepunkt. Ein ungueltiger Einsatzstand wird nicht
stillschweigend durch den Basisstand ersetzt; die ausdrueckliche Rueckkehr zum
Basisstand verwendet `continue_home` gemaess `campaign_introduction_contract.md`.

## Sternkartenkamera und Zukunftspositionen

Die Kamera ist UI-Zustand: Verschieben per Ziehen, Mausradzoom am Cursor,
Gesamtansicht. Vor und nach dem Zoom muss derselbe Kartenpunkt unter dem
Cursor liegen (ausser eine erreichte Zoomgrenze veraendert den Faktor nicht).
Zeichnung, klickbare Himmelskoerper und Schiffsposition nutzen einen gemeinsamen
Transform. Kamerabewegung sendet keine Reise- oder Gameplaycommands.

`Glut` und `Glut I` sind vorlaeufige deutsche Namen. Die drei Datenplaetze
unter `planet_orbit.encounter_slots` sind sichtbare Zukunftsmarkierungen,
keine anfliegbaren Orte und keine neuen Quantum-Ziele. Raumkaempfe und
generierte Weltraumkarten benoetigen spaetere eigene Runtime-/Kartenvertraege.

## Pruefung

Domain: Abbruchposition, Neustart, Ankunft, Orbitgrenzen, ungueltige/duplizierte
Commands. UI: Aktionen, Sperrgruende, expliziter Anflug. Flow: keine vorzeitige
Mission/Timer, echte Ortskarte erst nach Anflug, Fuel einmal, Rueckorbit und
Landung vor Heimkehr. Native Verstaendlichkeit bleibt getrennte Sichtpruefung.

## Revision 10.11.2026
Die historische Ein-Reise-Grenze ist fuer diesen Slice abgeloest: singleplayer_fleet_travel_state.gd indiziert unveraenderte individuelle Reiseowner. Orte und Ansicht folgen persistent_location_runtime_contract.md. Die erste Kampagne bleibt bei zwei Personen/einem Schiff; Mehrtruppbetrieb ist mit isoliertem groesserem Team geprueft. Mehrschiff-Weltcheckpoint bleibt sichtbar gesperrt, statt ein unvollstaendiges Ein-Schiff-Save zu erzeugen.

## Encounterabschluss, Revision 13.11.2026

Der gebundene Notrufeinsatz endet nach bestaetigtem Sieg, Rueckzug oder
Niederlage ueber `SimulationRoot.commit_campaign_space_return`. Root prueft
den terminalen, noch nicht verbrauchten Encounterbeleg, die tatsaechlichen
Combat-/Flightowner und den vorherigen Abflugbeleg. Fleet und Einzelreiseowner
bereiten `end_campaign_encounter` nur fuer `approach` an `distress_orbit` im
passenden lokalen Orbitbereich vor. Erst nach gemeinsamer Reise-/Fuelvalidierung
werden Rueckflugkosten, Kontaktentfernung und `orbit` synchron publiziert.
Der Spielerflight und seine lokale Position bleiben erhalten; dies ist keine
Heimkehr oder Basislandung. Gleiche abgeschlossene Requests sind wiederholbar,
ohne erneut Fuel oder Ergebnisse zu erzeugen. Ein voruebergehend abgelehnter
Abschluss bleibt sichtbar ausstehend und wird vom Runtimepfad erneut versucht.

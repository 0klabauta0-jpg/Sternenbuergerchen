# Heimatbasis Operations UX, 05.11.2026

Die aktuelle Nutzeranweisung ersetzt die historische UI-first-Grenze aus
PROJECT_BRIEF fuer diese Heimatbasis: eine echte begehbare Basis ist Teil des
normalen Angebots. Roster, Teams, Loadout, Transport und Mission bleiben bei
den bestehenden Meta-/Aircraft-/Runtime-Owners. Die Basis besitzt nur ihren
lokalen Commander und ihre Erkundungsdarstellung.

## Primaerer Ablauf
Zielrevision 09.11.2026: Der regulaere Einzelspielerweg verwendet ausschliesslich
die Operationsseiten. Erweiterte Werkzeuge gehoert nicht mehr zur normalen
Navigation; benoetigte Funktionen werden im neuen Weg bedienbar gemacht.
FOB bleibt sichtbar gesperrt und auch ueber regulaere programmatische
Navigation nicht aktivierbar. Zielnavigation: Basis erkunden, Personal,
Trupp & Ausruestung, Smart Mobile, Karte, Einsatz & Abflug. Neue Ziele bleiben
bis zur echten Anbindung deaktiviert. Diese Zielrevision ersetzt die folgenden
historischen Aussagen ueber grosse Portraets und Erweiterte Werkzeuge.
Kompakte Personalzeilen behalten Identitaeten; Rang bedeutet vorhandene
Rollen-/Faehigkeitsbadges, keinen erfundenen Dienstgrad. Der unklare Begriff
Cutlist rechtfertigt kein blindes Loeschen eines benannten Controls.

Die Heimatbasis startet bei Trupp & Ausruestung. Links kompakte Personenzeilen
mit erhaltenen Gesichtern, Rollen-/Faehigkeitsabzeichen und Ausruestungskurztext;
mittig ein waehlbarer Trupp mit vier gut erkennbaren Plaetzen,
daneben genau ein fokussiertes Mitglied mit Ruestung, Primaer- und
Sekundaerwaffe. Rechts stehen reales Schiff, Pilot, Boardingfortschritt und
die naechste gueltige Aktion. Der vorhandene Charakterbogen bleibt ueber Details
und Doppelklick erreichbar. Die alte Werkzeugansicht ist kein regulaerer Weg.

Navigation: Basis erkunden, Personal, Trupp & Ausruestung, Smart Mobile, Karte,
Einsatz & Abflug; neue noch ungebundene Ziele bleiben ehrlich gesperrt.
Die normale Mission startet direkt aus der Heimatbasis; kein primaerer FOB-Link.
Die Bildsprache folgt den bestaetigten Originalen menu_heimatbasis und
menu_fob_loadout; deren Beispielnamen/-werte werden nicht als Spielwerte kopiert.

## Zustands- und Eingabegrenze
`get_operations_snapshot()` liest die bestehenden IDs/Profile/Definitionen/
Loadouts/Aircraftdaten und liefert einen abgeleiteten Snapshot. Der Presenter
besitzt nur Controls, Caches und Anzeigefokus. `request_operation()` erlaubt
benannte Aktionen und delegiert an bestehende Homebasecallbacks; unbekannte
Operationen oder Werte sowie Busy-/Transit-Requests werden abgelehnt.
Ein bereits zu einem beschaeftigten Schiff gehoerender Trupp bleibt sichtbar,
aber seine Aufstellung und Ausruestung sind entsprechend dem Ownergate gesperrt.
Andere freie Trupps duerfen weiter bearbeitet werden.

Die Controls werden einmal gebaut, Personenreihen nach Unit-ID wiederverwendet.
Aktive Ansichten aktualisieren hoechstens alle 0.25 Sekunden oder nach Aktion;
versteckte Presenter pollen nicht. Keine SceneTree-Vollscans im Updatepfad.
Alte NodePaths/Callbacks bleiben fuer Details und Regressionen bestehen.

Sortierung verwendet vorhandene Name-/XP-/Leader-/Tutor-/Pilotmetriken und
vorhandene Rollen-/Faehigkeitsabzeichen, mit stabilen Name-/Unit-ID-Ties.
Personen, Teamkopf, Schiffsauswahl und Ausruestungsslots bieten echte native
Drag-/Dropadapter. Sie speichern nur angezeigte IDs, reichen Payloads an
request_operation weiter und zeigen dessen konkrete Ablehnung. Das Zurueckfeld
im Personal loest Mitglieder aus dem Trupp. Ein voller oder transportgebundener
Trupp bleibt gesperrt, ein zweiter freier Trupp bleibt bedienbar.

## Begehbare Basis
Die existierende ExplorableHomebase wird als echte Szene eingebettet.
`set_active(true)` gilt nur bei sichtbarem Modus Basis; alle anderen Modi sowie
versteckte Heimatbasis setzen nur diesen Branch inaktiv. WASD/Rechtsklick/E
werden nur dort verarbeitet. Terminals personnel/team/flightdeck/mission
oeffnen die passenden echten Operationsseiten. Zurueck fuehrt zur Truppansicht.

## Nachweisgrenze
Headless-/Strukturtests sichern Callbackrouting, echte IDs, Busy-/Leer-Gates,
Rostererhalt, Ressourcen und Controlwiederverwendung. Native Fullscreenbilder
bei 3440x1440, 1920x1080 und 1280x720 pruefen Layout, Eingabe und Crop.
Gestalterisches Nutzerurteil und menschliche Verstaendlichkeit bleiben eigene Gates.

## Playtestrevision 10.11.2026

Personalspalte begrenzt auf ca. ein Viertel der Arbeitsflaeche (280..380 Designpixel),
Truppansicht mit wiederverwendetem Referenzinventar und eigener revisionstreuer
Schiffsvorschau/Schiffsauswahl. Namen/Details, Badges, Sortierung und DnD bleiben.
FOB entfaellt als Menueknopf, Smart Mobile steht unter den uebrigen Aktionen.
Kampagnenhilfe laesst sich am Titel ziehen; Detailhilfe respektiert Navigation
und Abflugaktionen. Ausgeblendete Hilfe bleibt kompakt im Kopfbereich.

Sternkarte: groesserer Glut mit direkt anklickbaren Ortsmarkern. Marker benutzen
denselben Kameratransform und dieselben Freigaben/Selection-Commands wie die rechte
Liste. Auswahl allein startet keinen Anflug. Der Schiffsmarker benutzt die
vorhandene hashgebundene isometrische Cutlass-Projektion aus dem Visualkatalog.
Keine neuen Referenzorte werden als erfundener Spielinhalt eingefuehrt.

## Flugdeck und Pilotenfunktion — 10.11.2026
Die Navigationsfolge lautet Basis erkunden, Personal, Trupp & Ausrüstung,
Flugdeck, Sternkarte; Smart Mobile bleibt unten. Schritt03 und Startbereich
heißen Flugdeck. Rechts steht die reale Pad-/Schiffsvorschau; darunter
Padwahl und Schiffsselektion rechts, kompakte Pilot-/Statusfelder und eine
horizontale Boarding-/Abflugzeile. Keine zweite Schiffskarte links im Flugdeck.
Padwahl liest nur gebaute Runtimepads und fokussiert deren zugeordnetes Schiff.
Freies gebautes Pad bleibt ohne erfundenes Schiff inspizierbar. Die äußere
2D-Vorschau bleibt sichtbar aktualisiert, während die innere 3D-Projektion ihre
Dirty-Updates abschließt. Reiseansichten zeigen weiterhin den echten Standort.
Pilotenfunktion und FT-Mitgliedschaft dürfen im physischen Einzelspielerpfad
zusammenfallen. Ein ausgestiegener zugewiesener Pilot darf per bestehendem
Assign-/Dragcommand FT1 beitreten, auch wenn FT1 auf genau seinem geerdeten
Schiff bereits geboardet ist. Keine Erlaubnis für fremde Schiffe/Transit/volle
Teams. Individualausstieg des Piloten entfernt weder FT-Mitgliedschaft noch
Anjas Boarding. Physische Anwesenheit wird separat als An Bord/Nicht an Bord
angezeigt; tatsächlicher Wiedereinstieg bleibt Voraussetzung des Abhebens.
Legacyansichten ohne physischen Basisowner behalten ihre bisherige Exklusivität.

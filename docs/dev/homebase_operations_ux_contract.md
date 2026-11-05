# Heimatbasis Operations UX, 05.11.2026

Die aktuelle Nutzeranweisung ersetzt die historische UI-first-Grenze aus
PROJECT_BRIEF fuer diese Heimatbasis: eine echte begehbare Basis ist Teil des
normalen Angebots. Roster, Teams, Loadout, Transport und Mission bleiben bei
den bestehenden Meta-/Aircraft-/Runtime-Owners. Die Basis besitzt nur ihren
lokalen Commander und ihre Erkundungsdarstellung.

## Primaerer Ablauf
Die Heimatbasis startet bei Trupp & Ausruestung. Links Personal mit grossen
Portraets, mittig ein waehlbarer Trupp mit vier gut erkennbaren Plaetzen,
daneben genau ein fokussiertes Mitglied mit Ruestung, Primaer- und
Sekundaerwaffe. Rechts stehen reales Schiff, Pilot, Boardingfortschritt und
die naechste gueltige Aktion. Die volle Personnel-/Creator-/Cargo-/Fachansicht
bleibt ueber Details oder Erweiterte Werkzeuge erreichbar.

Navigation: Basis erkunden, Personal, Trupp & Ausruestung, Einsatz & Abflug.
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

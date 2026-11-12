# Stations-, Schiffskollision und Bettplaetze

## Ziel und Ursache
Die Anwerbung und der Shuttle-Rundlauf wurden bisher mit vereinfachter Stations- und Schiffsgeometrie geprueft. Der Bettenausbau pruefte Erreichbarkeit, aber nicht vollstaendig die tatsaechlichen Hindernisse. Diese Luecken sollen intern ohne sichtbares Fenster untersucht und belegte Fehler behoben werden.

## Umfang und Nicht-Ziele
Reale Laufzeitdaten und deren Kollisions- und Navigationspfade fuer Stationspad, Shuttle und Heimatbettplaetze pruefen; Fehler in deren Benutzbarkeit korrigieren. Keine visuellen Umgestaltungen oder Aenderungen der allgemeinen Spielbalance.

## Contracts und Dokumente
`docs/dev/base_automatic_rest_contract.md`, `docs/dev/parallel_location_operations_contract.md`, `docs/tasks/CAMPAIGN_HELP_RECRUITMENT_2026_11_12.md`, `docs/tasks/CAMPAIGN_BED_EXPANSION_2026_11_12.md`.

## Akzeptanz und lokale Pruefung
Gezielte headless Tests verwenden moeglichst die produktiven Geometrie- und Navigationsdaten, pruefen Ein- und Ausstieg sowie Bettplatzierung und decken konkrete Kollisionen ab. Vorhandene Anwerbungs-, Shuttle- und Bettenpruefungen bleiben erfolgreich. Fixture-Anteile und nicht pruefbare Sichtbarkeit werden dokumentiert; kein Zugriff auf den Desktop oder reale Spielstaende.

## Betroffene Dateien und Risiken
Je nach Befund Stations-/Shuttle-Kollisions- und Bewegungsowner, Basis-Bettplatzierung, zugehoerige Verifier und diese Task-Datei. Physische Kollision, taktische Hex-Hindernisse und visuelle Modelle koennen unterschiedliche Quellen verwenden; Nachweise muessen diese Grenzen benennen.

## Ergebnis
Die Stationskarte aktivierte den fuer die Anwerbung erforderlichen Hex-Owner nicht; Karte und Generator tragen jetzt die passende Regel. Ein Parsefehler der Bettanzeige im Service-Presenter wurde behoben. Die Headless-Pruefungen verwenden die echte Stationskarte, sieben Padpositionen und die Cutlass-Modellgrenzen fuer die produktive Hexmaske. Aus- und Einstieg sowie ein blockierter Landeplatz wurden mit Testpersonen geprueft. Der echte Kampagnen-Rundflug prueft auch die Zulassung eines Stationspiloten am Globus. Polygonale 3D-Kollision und sichtbare Darstellung sind nicht Gegenstand dieser Tests.

Historischer Befund vor der Nutzerkorrektur: Die berechneten Wege zu den zusaetzlichen Feldbetten schnitten die Bettkoerper. Der damalige Feldbettpfad wurde korrigiert und mit Geometrie und Kapselproxy geprueft; er ist fuer den aktuellen Kampagnenausbau durch Unterkuenfte mit Originalbetten ersetzt. Fuer den aktuellen Stand und dessen Pruefgrenzen siehe `CAMPAIGN_BED_EXPANSION_2026_11_12.md`. Fuer zukuenftige Basiskarten mit taktischer Hexnavigation bleibt der Unterkunftsbau gesperrt, bis dort entsprechende Hindernisse unterstuetzt werden; die regulaere Kampagnenbasis verwendet den geprueften anderen Navigationspfad.

Ein Godot-Editor-Import wurde zwar beendet, meldete aber beim Beenden eine ObjectDB-Leakwarnung; der separate Import-Gate ist daher nicht bestanden. Die anschliessenden Laufzeitpruefungen sind getrennt zu bewerten.

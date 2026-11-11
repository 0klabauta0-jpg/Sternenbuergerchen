# Hex Runtime Foundation — 11.11.2026

Basis97e00aba14ced147b268113085854ac67dc764c5, eigener isolierter Branch
 task/hex-ground-foundation-20261111. Vertrag: docs/dev/hex_tactical_runtime_contract.md.
AP0 wurde nach dem direkten Nutzerauftrag zur Abstimmung vom Kartenchat übernommen.
Breite Rampenbänder, seitlicheH+0.5-Anschlüsse und Floatstandhöhen bleiben erhalten.

## Ergebnis

Ground 25/0, Sicht/Cache 38/0, Erkennung 21/0: 84 kleine Checks, Engine-Exit 0,
keine Script-/Leakfehler, geprüfte private Nutzerverzeichnisse und unveränderte
Originalprofile/Quellbytes in allen drei finalen Läufen. Original-Logs und
ReportJSONs aller Versuche in contract_runs.zip; manifest.json bindet Quellen.

Die Tests laufen in einem frischen minimalen Godot-Projekt mit bytegleichen
Kopien der tatsächlich geprüften Runtime-/Terrainquellen. Ein kleiner Import
registriert ausschließlich diese Klassen. Das komplette Spiel, seine Menüs,
Gefechtsszenen, UI-/Assetbäume und Kampagnenprofile werden nicht gestartet.
Keine große Matrix, native Kamera-/Gefechtsprobe oder Performanceaussage.

## RED/GREEN und erhaltene Fehlversuche

Ground44b337cb...: sauberer RED mit 0 bestandenen und 1 fehlgeschlagenen Check
wegen fehlendem Helper, danach 20/0 GREEN und nach Reviewergänzung 25/0.
Der davorliegende ea507a89... war ein Setupfehler durch fehlenden generierten
Godot-Klassenindex; er ist kein gültigerRED. Kleiner Privatimport behebt ihn.

Sicht08c6a3cb...: sauberer RED wegen fehlendem Helper, später 30/0 fachlich grün.
Der erste 30/0-Lauf e486ee91... wurde dennoch verworfen: Das Originalprofil
unterschied sich im Vorher/Nachhervergleich. Ursache und einzelne Dateidiffs
sind für diesen frühen Versuch nicht attribuiert; kein Wiederherstellen oder
Überschreiben. Ein unveränderter Folgelauf d9bc5156... besteht inklusive
Originalschutz; der Runner erfasst seitdem bei Änderungen auch Dateinamen.
Nach Reviewergänzung finale 38/0 inklusive Legacycache und Kapazität 1.

Erkennung54586130...: sauberer RED wegen fehlendem Helper, danach 17/0 und
nach ergänzten Zeitgrenzen 21/0. Alle erfolglosen Versuche bleiben im Archiv.

## Frischer Review

Read-only Reviewer hex_foundation_review: kein Blocker bei atomarer Aufnahme,
Halbhöhen, Cacheinvalidierung und verketteterLRU. Keine Engine gestartet oder
Datei geändert. Vier kleine Testlücken wurden ergänzt: LRU1/Clear, ungültige
Sichtparameter/Registry, Erkennungs-Zeitgrenzen und Terrainrefresh nachAdmission.

## Praktische Grenzen / nächster Anschluss

Ground-State ist noch nicht vom aktiven SimulationRoot konfiguriert. Neue
Hexcache-API wird von aktuellen Mission-/FoW-/Combatpfaden noch nicht benutzt;
Legacycache behält seine ursprüngliche Tick-Lebensdauer. Erkennungsepisoden
sind noch nicht an den bestehenden ContactTracker-/Combatablauf angeschlossen.
Keine tatsächlich ausgeführte Feld-/Kantenreservierung und kein Nachweis
flüssiger Engstellenbewegung oder höherer Bildrate. AP1-Anbindung, AP3-Consumer,
AP4/5-Reservierung/Bewegung und Lifecycle/Save bleiben weitere Arbeit.

Kartenchat-Folgestand5204312c0 verlangt, bei späterer MapData-Anbindung die
Unterstützung regional_terrain_version2und3 zu erhalten. Keine rückwärtigen
Sourcekopien aus dem alten Kampagnencheckout übernehmen. Polisa/BasePersonnel
bleiben derzeit fremde Arbeit und benötigen erneute Schnittstellenabstimmung.

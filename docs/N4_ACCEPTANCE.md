# N4-Abnahme · Besatzung, Reise, Ausrüstung und gemeinsame Crew

13.09.2026, Godot 4.6.2. Basis: N3 `ef502214d862024980e581386af57fd098aed87d`; eigener Branch `codex/rostgrenze-crew-reise-ausruestung`. Das alte Sternenbürgerchen bleibt unverändert. Die versehentlich hier genannten InselKrieg-Wünsche wurden vom Nutzer als falscher Chat bestätigt und nicht übernommen.

## Ergebnis im Spiel

Figuren laufen durch Türöffnungen und um gemeinsam definierte Wände, Möbel, Felsen und das gelandete Schiff. Rechtsklick auf die Entersäbel startet den Weg zum Heckzugang. Der Kern reserviert ohne Vorgabe zuerst den Pilotenplatz nach Pilotieren, dann den Turm nach dem Geschützwert der übrigen Crew. Eine manuelle Sitzwahl hat Vorrang.

Einsteigen, Abheben, Orbit, benanntes Reiseziel, lokaler Flug, Landen und Aussteigen sind getrennte Schritte. Die neue Reisekarte erklärt Ziel, Gebiet und vorläufiges Begegnungsrisiko. Ein Zielgebiet wird schwebend am Rand erreicht. Fracht wird am Heimatdock ausdrücklich umgeladen. Das Schiff sammelt beim Start keine Personen automatisch ein.

Doppelklick auf ein Crewporträt öffnet das Dossier mit sichtbarer Figur und fünf Drag-and-drop-Slots. Rucksack, Multi-Tool, wechselbare Aufsätze, Medgun und Ladungen sind herstellbar/kaufbar und besitzen echte Bestände. Rucksackkapazität, Nähe, Slot-Eignung und Heilverbrauch werden autoritativ geprüft. Die Medgun kann eine ausgefallene Person aufrichten; der bestehende Respawn-Timer bleibt als Rückfall erhalten.

Beide Koop-Commander dürfen alle Personen und gemeinsamen Gameplay-Aufgaben befehligen. Hostautorität und lokale Dateiverwaltung bleiben erhalten. Die Außenkarten haben mehr Platz; sechs Betten stehen an der Unterkunftswand. Frontwände benutzen dieselbe Form mit reduzierter Deckkraft. Die lokale Entersäbel wurde in Blender auf 15.705 Dreiecke mit drei Fahrwerksfüßen, entfernten Frontwaffen und echtem Turmpivot überarbeitet.

## Nachweise

| Prüfung | Ergebnis | Beleg |
|---|---:|---|
| Crew, Sitze, Reise, Ausrüstung, Medgun | 57/57 | `tests/crew_travel_core_test.gd` |
| Migration v1/v2/v3 und aktuelle Spielstände | 67/67 | `tests/crew_migration_test.gd` |
| Navigation, Türen, Schiffsumriss, erreichbare Betten und POIs | 153/153 | `tests/crew_navigation_test.gd` |
| Angepasste Wirtschafts-, Orbit- und Bodenregressionen | 104/104 + 73/73 + 147/147 | `tests/core_flow_test.gd`, `next_stage_core_test.gd`, `ground_stage_core_test.gd` |
| Vollständiger aktueller Produktweg | 76/76 | `tests/crew_product_test.gd`, `output/n4-product-result.json` |
| Native manuelle Sitzwahl im versetzten Hauptfenster | 7/7 | `tests/crew_ui_window_test.gd`, `output/n4-ui-result.json` |
| Rahmenauswahl, Rechtsklick, Pause, Kamera-only-WASD | 13/13 | `tests/control_window_test.gd`, `output/control-result.json` |
| Dossier mit echter Maus und Drag-and-drop | 22/22 | `tests/crew_dossier_report.md` |
| Vier echte Produktstarts / Speicherfehler und Wiederaufnahme | 12/12 | `tests/save_lifecycle_report.md` |
| ENet-Koop im echten Produktfenster | 62/62 | `tests/network_report.md` |
| Öffentliche verschlüsselte WSS-Verbindung | 70/70 | `tests/internet_report.md` |
| Gateway-Validierung und Aufräumen | 15/15 | `tests/internet_gateway_test.gd` |
| Weltfenster / gemeinsame Objektumrisse | 142/142 + 21/21 | `docs/N4_WORLD_ASSET_METRICS.md` |
| Lokale Modellwahl / isolierter Quellstand / Schiffprofile | 9/9 + 12/12 + 8/8 | `docs/N4_WORLD_ASSET_METRICS.md` |
| Windows-Release: PCK-Prüfung, Dossier aus Export, Assetwahl | 22/22 + 22/22 + 9/9 | `docs/WINDOWS_DELIVERY.md`, reguläre Menü-/Spielstarts und frisches ZIP ebenfalls fehlerfrei |

Die Kernprüfungen ergeben zusammen **601**. Der Produktweg stellt einen Rucksack aus echten Startmaterialien her, pausiert Arbeit, öffnet das Dossier, übernimmt den Auftrag, besetzt das Schiff, reist über den Orbit, findet den Satelliten, birgt die Blackbox, landet am Heimatdock, entlädt, erhält die Auszahlung und kauft am Stationsmarkt die neuen Werkzeuge. Speichern/Laden erhält Fracht und Sitze. Gameplay-Zustand oder Belohnungen werden dabei nicht injiziert; normale Zeit wird nur beschleunigt. Die separate Welt-Fotoprobe verwendet ausdrücklich bezeichnete Ausrüstungsfixtures.

Die aktuelle Produktprobe nutzt Maus-/Ray-Eingaben im Hauptfenster und fokussierte Tastatureingaben im nativen Reisefenster. Das ist von einer menschlichen Verständlichkeitsprüfung zu unterscheiden. Native Maus-/Fensterereignisse erforderten im Test eine geordnete Aktualisierung der Mausposition; die Karten- und Menübefehle bleiben unverändert. Einladungen wurden nicht in öffentliche Nachweise geschrieben. Die normale Nutzerkarriere wurde nicht mit Testfortschritt überschrieben.

## Reviewkorrekturen

Die unabhängigen Reviews führten zu konkreten Korrekturen: native Popup-Koordinaten verwenden die Fenster-/Viewporttransformation, Rückzug zeigt den tatsächlichen Timer, Markttext erklärt manuelles Entladen. Pflichtwerkzeuge werden bereits vor dem Gewinnungsbefehl erläutert, weitere Satellitenverwertung ist passend gesperrt, und die Medgun ist bei nicht einsatzfähiger oder gebundener Anwenderfigur deaktiviert. Im Flug heißen Rechtsklickziele ausdrücklich Flugziele.

## Grenzen und nächste Stufe

- Es gibt eine gemeinsame aktive Region und zwei feste Crewpersonen. Alle aktuellen Personen müssen vor dem Start an Bord sein. Unabhängige Teams auf mehreren gleichzeitigen Karten brauchen einen eigenen Simulationsausbau.
- Der Nutzer hat Schiffsinnenräume ausdrücklich für den nächsten Ausbau gewählt: Schnittansicht von oben, Wege zwischen Cockpit, Turm, Lade- und später Betankungsstationen. Caterpillar und Tanker sind spätere Beispiele, noch keine gelieferten zusätzlichen Schiffe.
- Fähigkeiten wirken, wachsen aber noch nicht. Bewerber, Forschung, tatsächlich baubare Raumslots, Erfahrung, Traits und PvP sind offen. Sechs Betten sind räumliche Vorbereitung und keine fertige Rekrutierung.
- Navigation verwendet vereinfachte 2D-Grundrisse mit Crewabstand, keine exakte 3D-Physik und keine gegenseitige Figurenverdrängung. Laufpfade sind gecacht; eine lange erstmalige A*-Suche dauerte lokal bis 716 ms. Das bleibt ein Optimierungspunkt für große Gruppen und lange Routen.
- Internet wurde öffentlich mit zwei Prozessen auf diesem PC geprüft. Der längere Test über zwei Heimanschlüsse, insbesondere Österreich, bleibt ausstehend. Quick Tunnel ist noch kein dauerhaft betriebener Vermittlungsdienst.
- Werkzeuge, Wirtschaft, Kämpfe und medizinische Wirkung sind erste Regeln. Raum-Mining, Raum-Salvage, Lieferverträge, Evakuierung, ausgearbeitete Gegner und mehr Inhalte auf den großen Karten folgen.
- Aktuelle Windows-Auslieferung und echte EXE-Starts werden gesondert in `docs/WINDOWS_DELIVERY.md` dokumentiert. Lokale Schiffdateien bleiben aus Git und dem Handy-Bericht ausgeschlossen; der Bericht enthält Spielbilder.

## Bericht

`tools/build_report.py` erzeugt aus dem versionierten Template den eigenständigen HTML-Spielplan und Spielstandbericht mit 16 tatsächlichen Aufnahmen. Dieselbe aktuelle Fassung wird unter der bestehenden privaten Handy-Adresse veröffentlicht: https://sternenbuergerchen-neustart.klabauta.chatgpt.site . Die Seite unterscheidet vorhandene Funktionen, bestätigte nächste Ausbauten und offene Fragen. Alte N1/N2/N3-Abnahmen bleiben historische Nachweise; ihre früheren Bedienfolgen ersetzen nicht den aktuellen N4-Produktweg.

Veröffentlichung bestätigt: private Site-Fassung **3**, Source `74fc288b621ce1279842ea1750cbb9e75b56288a`, gespeicherte Version `appgprj_6aa62f5331b081918ef8f9dfa0a19ab6~appgver_2c446f89cb948191a31df030b9365b7e`, Deployment `appgdep_6aa6ac53e7b48191b5ea0074c26bc7c0`, Status **succeeded** am 13.09.2026. Das Archiv enthält HTML und Bilddateien, keine EXE, PCK oder Modelle. Der Codex-Browseraufruf wurde für die Aufgabe vorgemerkt; eine zusätzliche mobile Browser-Bedienprobe wird nicht behauptet.

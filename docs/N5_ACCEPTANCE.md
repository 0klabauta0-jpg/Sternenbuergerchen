# N5 · größere Karten, Handelsring und Feldreparatur

13.09.2026. Arbeitsbranch `codex/rostgrenze-routen-bunker-gelaende`. Die [N5-Aufgabe](tasks/N5_ROUTES_WORLD.md) ist umgesetzt. Frühere N4-Abnahmen bleiben historisch.

## Spielbares Ergebnis

- Neun Reiseziele, vierzehn einzeln geladene Regionen. Orbit und Raumkontakt jeweils1200×1200m. Drei Bunkeroberflächen ebenfalls1200×1200m; Untergrundgrenzen256/320/384m mit tatsächlich vergrößerten Hallen und Gängen sowie Unterteilungen. Der nutzbare Gebäudekomplex ist jeweils kleiner als die Kartengrenze: ungefähr160×192,200×240,240×288m.
- Karst leicht: Flak+Wache oben, eine Wache unten. Kluft mittel: drei Gegner oben, zwei unten. Bastion schwer: fünf oben, vier unten. Mehr Gesundheit und doppelte/dreifache endliche Fundbestände. Oberflächen und Untergründe führen getrennte Gegner/Ressourcen; jeder Aufzug kehrt zu seiner eigenen Oberfläche zurück.
- Freihafen ist ein freundliches Verteilzentrum. Knotenwerk bleibt feindlich und sperrt Handel bis zum Sieg über beide Depotwachen. Beide Karten1280×1280m.
- Drei feste Handelsstrecken: Meridian→Freihafen Bauteile24→36; Freihafen→Staubmarkt Metall8→14; Staubmarkt→Meridian Legierung110→145 Credits. Je ein Stück ergibt53 Credits Bruttomarge vor Schäden/Reparaturen. Fracht und Guthaben werden real verbucht, keine garantierte Nettorendite.
- Kenney Factory3.0 und Space-Kit: Antennen, Satellitenschüsseln, Maschinen, Werkstattarme, Wandfelder und Vorräte. Breite horizontale Felsstufen und gewundene Schluchten, gemeinsame Hindernisse für Navigation und Projektion. Terrassen sind keine begehbaren Höhenebenen.
- Entersäbel:9714 Dreiecke,14 Meshes, vier Materialien,7,5×11m horizontales Profil. Achteckiger Turm mit Panzerkappe, abgeschrägte Füße, eigene drehbare Turmachse. Blender5.1.1 öffnete die gespeicherte Blend-Datei und prüfte das erneut importierte GLB; Original-SHA unverändert. [Quellen](N5_ASSET_SOURCES.json), reproduzierbar mit `tools/prepare_shuttle_n5.py`.
- Reparaturaufsatz:45/22 Credits Kauf/Verkauf; WerkbankI, Technik1, ein Metall+ein Bauteil,5s. Freie gesunde Person mit Multi-Tool, Aufsatz und einem Bauteil im eigenen Rucksack, höchstens6m am erreichbaren Zugang eines gelandeten Schiffs. Pro Aktion10+Technik Zustand, maximal70%. Duplikate verbuchen nichts erneut. Für größere Reparaturen bleibt die Basiswerkstatt erforderlich.

## Architektur und gespeicherte Karrieren

Schema5. `regions.gd` besitzt stabile IDs, Archetypen, Aufzugspaare, Maßstäbe und Risiken; `trade_routes.gd` besitzt die regionalen Preise. UI und Renderer lesen diese Daten. `SimulationRoot` bestätigt sämtliche Mutationen, auch im gemeinsamen Koop.

`legacy_n4/` friert den vorherigen Validator, Katalog, Navigation und die v3→v4-Umstellung samt Abhängigkeiten ein. Die bestehende Kette validiert alte Daten zuerst, ergänzt neue Regionen/Items danach. `world_expansion_state.gd` erhält Geld, Vorräte, Sitzplätze, Anfragebelege und aktive Arbeit. Alte Untergrundpositionen skalieren mit der Anlage, unzulässige Positionen werden auf freie Punkte angepasst und geloggt. Beschädigte Altdaten werden abgelehnt.

## Aktuelle Nachweise

| Prüfung | Bestanden | Beleg |
|---|---:|---|
| Neue Orte, komplette Handelsrunde, Kampf, alle drei Aufzüge, Feldreparatur und N4-Migration |162| `tests/world_expansion_test.gd`, `output/n5-expansion-result.json` |
| Bestehende Kernregressionen am Schema5 |599|57 Crew/Reise,67 Migration,151 Navigation,104 Grundlauf,73 Orbit,147 Boden; `output/n5-*-test.log` bzw. entsprechende Testnamen |
| Vollständiger Einstieg im tatsächlichen Produktfenster |76| `tests/crew_product_test.gd`, `output/n5-product.log` |
| Native Reisekarte, neun anklickbare Ziele, Reisen, Marktpreise und Weltansichten |72| `tests/world_expansion_window_test.gd`, `output/n5-window-result.json` |
| Native Herstellung und kleine Schiffsreparatur |11| `tests/field_repair_window_test.gd`, `output/n5-repair-window-result.json` |
| Speicherlebenszyklus über vier Produktstarts |12| `output/n5-lifecycle.log` |
| ENet, zwei tatsächliche Produktfenster |62| `output/n5-network.log` |
| Öffentlicher WSS-Weg, zwei Prozesse, erzwungener produktiver DNS-Ersatzweg |70| `output/n5-internet-fallback.log` |
| Richtige lokale Modelle und Abmessungen |9| `tests/asset_delivery_test.gd`, Quellprojekt und exportierter PCK |
| Exportierter PCK, tatsächlicher Menü-/Gameweg, neue Inhalte und Modelle |25| `output/windows-n5-delivery/portable-result.json` |

Alle genannten finalen Testläufe sind ohne gemeldete Fehlschläge und Enginefehler abgeschlossen. Der erste öffentliche Tunnelaufbau hatte einen75s-Timeout; der anschließende Lauf über den vorgesehenen DNS-Ersatzweg bestand. Das belegt weder dauernde Tunnelverfügbarkeit noch zwei getrennte Heimanschlüsse. Gemeinsame Snapshots stimmen bei Pause, Restore und Abschluss überein; der Gast fliegt zum neuen Freihafen und kauft den neuen Aufsatz.

Die Untergrundfotos sind ausdrücklich Darstellungsfixtures. Der Kerntest weist die tatsächlichen drei Aufzugspaare und den Oberflächenkampf nach. Der separate Reparaturfenstertest erhält genau zwei Hilfsgegenstände und einen beschädigten Rumpf als Fixture; Aufsatzherstellung, Ausrüstung, Materialtransfer und Reparatur erfolgen über normale Befehle bzw. echte Buttons. Der vollständige76-Prüfungen-Einstieg injiziert keine Erfolgszustände.

Ein lokaler Nav-Regressionslauf benötigte für seine langsamste erste Wegsuche1,514s; laufende Wege werden gecacht. Das ist keine allgemeine Performancefreigabe. Menschliche Spielspaß-/Verständlichkeitstests, Balance und weitere Hardware bleiben offen.

## Lieferung und weitere Reise

Das private Windows-N5-Paket liegt lokal unter `output/Sternenbuergerchen-Windows-N5.zip`; [Liefernachweis](WINDOWS_DELIVERY.md). Der Handybericht enthält16 echte Aufnahmen und bleibt unter der bestehenden privaten Site erreichbar. Kein Spielpaket und keine Modelldateien wurden dorthin hochgeladen.

Nächster bestätigter Ausbau: begehbare Schiffsinnenräume. Weiter geplant: Rekrutierung, bezahlte Erweiterungsslots, Forschung, Lern-/Trait-Systeme, unabhängige gleichzeitige Regionen, ausführlichere Berufe, medizinische Logistik und PvP. Die versehentliche InselKrieg-Nachricht ist nicht Teil dieser Umsetzung.

Handybericht veröffentlicht: private Site, Fassung4, Quelle `8c4e9a8cc16c67cdad721c912dfd9ca82dbecdd4`. Veröffentlichung erfolgreich am13.09.2026. Der Bericht blieb beim bestehenden Empfängerkreis.

# N8 – Begehbare Höhenwelten, bewohnte Orte und Energie

Status: vom Nutzer bestätigt; Umsetzung läuft, noch keine finale N8-Abnahme. Basis: N7, Commit 1895361. Datum: 21.09.2026.

## Ziel und Ausgangslage
Die Karten sollen die räumliche Staffelung und wohnliche Wirkung der vom Nutzer gelieferten Vorlagen erreichen. Aktuell erzeugt WorldTerrain den begehbaren Boden auf y=0; die Mesas sind aufgesetzte Hindernisse. Gebäude, Straßen und Interaktionspunkte nehmen dieselbe Ebene an. Solarzellen und Sendestation sind bisher reine Requisiten. Regionen verwenden feste Archetypen; TeamCampaign speichert Bestände pro Planet, noch nicht pro eigenständigem Einsatzort.

Bestätigte Wünsche: erkennbare Geländeebenen, reichere Bunker und Freihafen, Kenney/eigene Assets kombiniert, wohnliche Basis, Ausbau mit Energieverbrauch, Forschung/gefundenen Bauplänen/Ressourcen, vier bis fünf verschiedene Orte je Missionsart. Unterschiedliche Teams müssen denselben Ort besuchen können. Bestehende zwei Teams mit acht Menschen bleiben erhalten.

Annahmen dieses Entwurfs: vier Varianten je Missionsart als erster Umfang, über die bestehenden vier Welten verteilt; nicht vier Kopien jeder Mission auf jedem Planeten. Rostwelt plus drei weitere Welten bleiben erhalten. Keine zufällige private Missionsinstanz. Zahlen für Energie sind erste Balancingwerte.

## 1. Gelände als spielbarer Raum
Empfohlen wird ein fest gestaltetes, stufenförmiges Höhenfeld je Ort. Rein dekorative Podeste lösen das Problem nicht. Völlig zufälliges Gelände erschwert Referenztreue, Wegprüfung und gemeinsam gespeicherte Orte.

- Drei gut lesbare Haupthöhen: Talboden 0 m, Siedlungsterrasse +4 m, obere Felsbank +9 m. Größere Randmassive dienen als Kulisse, nicht jede Spitze ist begehbar.
- Breite Rampen verbinden die begehbaren Terrassen. Kurze Treppen können Fußwege ergänzen, dürfen nicht heimlich als Fahrzeugrampe gelten.
- Kanten sind echte Hindernisse; Figuren können sie nicht entlang einer flachen Luftlinie überqueren. Die Wegsuche prüft Übergänge, Rampenbreite und Steigung.
- TerrainLayout liefert Höhe, Oberflächennormale, Rampen und sperrende Kanten aus derselben Datenquelle an Renderer, Navigation, Schussprüfung und Flug-/Landelogik.
- Bodenfiguren, Gegenstände, Möbel, Gebäude, Landepads und Interaktionsmarker liegen auf der richtigen Höhenfläche. Kein nachträgliches optisches Hochziehen nur der Gebäude.
- Schiffe halten Abstand über der örtlichen Oberfläche. Landung braucht eine ausreichend große ebene Fläche. Klippen zählen beim Ausweichen und bei der Sichtlinie.
- Bunkeruntergrund bleibt eine andere Einsatzebene. Eine Geländeterrasse wird nicht mit dem Untergeschoss gleichgesetzt.
- Alte Spielstände erhalten sichere Positionen auf dem entsprechenden Boden; blockierte frühere Positionen werden nachvollziehbar versetzt. Keine neuen unsichtbaren Hindernisse in bestehenden Figuren.

Erstes sichtbares Muster: Heimatbasis auf einer zusammenhängenden Terrasse, Landeplatz auf einem niedrigeren Absatz, geschwungene Verbindungsrampe, Solaranlage und Antenne auf einer höheren Wartungsterrasse. Links/rechts geschichtete Felsbänder mit Schluchten; offene Flächen für Erweiterungen bleiben frei.

## 2. Bewohnte Orte statt verteilter Requisiten
Kenney Factory, Space Kit und Space Station liefern Bauteile, eigene Habitat-Assets ergänzen sie. Quellen bleiben unverändert. Ein einheitlicher Maßstab, gebrochene helle Paneele, gedämpftes Orange und wenige türkisfarbene Anzeigen verbinden die Kits.

Heimat: warme Eingangs- und Arbeitsplatzlichter, geschützte Nischen, Bett an der Wand mit Fach und kleiner Lampe, Kleidung/Stauraum, Küchenecke mit Sitzgruppe, wenige Pflanzen unter Glas, Kabelkanäle, Lüfter, Geländer und kleine Wartungsflächen. Keine beliebige Streudeko im Gehweg. Wohnlichkeit entsteht durch menschlichen Maßstab und sichtbare Nutzung.

Bunker: gestaffelter Vorplatz, Wachunterstand, Schleuse, Wartungshof, eingelassene Flakstellung, Antenne, Versorgungskabel, abgestufte Seitenwege. Innen klare Schleuse → Technik-/Versorgungsräume → Zielraum; einzelne Aufenthaltsnischen statt leerer Kistenhallen. Schwierigkeitsgrad verändert Bewachung und Zugänge, nicht nur Gebäudegröße.

Freihafen: wirkliche zusammenhängende Hallen mit Torrahmen und sichtbaren Innenzonen, Verladerampen, Ladehöfe, Containergruppen mit Fahrgassen, Büro und kleine Kantine, Werkstatt, Tanks und Wartungsgänge. Dach-/Wandausblendung erhält den Baukörper, ohne Crew zu verdecken. Freundliche und feindliche Depots erhalten unterschiedliche Betriebszustände.

Drei Detailmaßstäbe: zuerst Silhouette und Terrassen, dann Gebäude/Höfe, zuletzt kleine Gegenstände. Sichtbare Details in nutzbaren Gruppen konzentrieren; große Geländeweiten dürfen ruhig bleiben. Wiederkehrende Requisiten als MultiMesh bzw. geteilte Ressourcen. Keine tausenden einzelnen aktiven Lichtquellen.

## 3. Feste Missionsorte und Begegnungen
Neue Identität: Planet + site_id + Einsatzebene. Archetyp ist nur die Bau-/Regelvorlage. Der Host erstellt und speichert Ressourcen, Gegner, geborgene Ziele und Veränderungen pro Ort. Gleiche Orts-ID bedeutet für beide Teams denselben Zustand; verschiedene IDs teilen keine Beute und keine Gegner.

Erster Umfang: 28 benannte Bodenorte, die bisherigen Standorte werden als erste Varianten erhalten.

| Familie | Vier Varianten |
|---|---|
| Blackbox-Bergung | abgestürzter Satellit im Becken; Frachterbruch an einer Schlucht; Kurierwrack auf einer Terrasse; verstreute Trümmer bei einer alten Relaisstation |
| Bunker leicht | Wachposten; Versorgungsbunker; Pumpenposten; Relaisbunker |
| Bunker mittel | Forschungsposten; gestaffeltes Depot; Schluchtenwache; Industrieaußenstelle |
| Bunker schwer | Felsbastion; befestigter Komplex; tiefer Versorgungsknoten; gesicherte Forschungsanlage |
| Freundliches Verteilzentrum | Freihafen und drei Höfe mit anderen Zufahrten, Hallenanordnungen und Nebenorten |
| Feindliches Verteilzentrum | Knotenwerk und drei besetzte Anlagen mit unterschiedlichen Annäherungswegen |
| Kleiner Handelsposten | Staubmarkt und drei Niederlassungen mit unterschiedlichen Geländeeinbettungen und Warenprofilen |

Mining und Salvage werden zunächst als vier räumlich unterschiedliche Fundstellenkonzepte innerhalb dieser Karten eingebaut: Erzbank, alte Abbaugrube, freigelegte Felsschicht, Geröllader; kleines Wrack, Frachttrümmer, Schrottlager, bergbares Auftragswrack. Keine zusätzlichen 32 leeren Karten nur für dieselben Aktivitäten.

Varianten unterscheiden Grundriss, Höhenprofil, Anflug-/Landeflächen, Suchsektor und Nebenfundstellen. Nur Gegenstände umzubenennen oder die Karte zu drehen zählt nicht als eigene Variante. Missionsziele werden innerhalb definierter, erreichbarer Suchbereiche platziert und bleiben nach Erzeugung gespeichert.

Systemkarte: erst Planet, dann benannte Orte mit Auftrag, Gefahrenstufe, bekanntem Handel und gegebenenfalls anderer Teampräsenz nach Sensorregeln. Kein verräterischer globaler Gegner-Tracker. Alte direkte Ziele bleiben migrierbar. Auftrag und Abgabe gehören zu Auftrag-ID und Fundobjekt-ID; dieselbe Blackbox darf nicht bei beiden Teams als einmalige Weltbeute entstehen. Wiederholungsaufträge verwenden ausdrücklich neue Zielinstanzen oder einen neuen Auftrag, ohne den ganzen Ort zurückzusetzen.

## 4. Solaranlage, Sendestation und Ausbau
Autoritativer BaseInfrastructure-Zustand: gebaute Module, Stufe, priorisierte Verbraucher, verfügbare Leistung und laufende Arbeiten. Kein lokaler UI-Zähler. Zunächst konstante verfügbare Solarleistung; Tag/Nacht und Wetter sind ein späterer Ausbau.

Vorgeschlagener kleiner Anfang: 24 Leistungseinheiten Solarversorgung. Grundversorgung 6, Sendestation I 4, Werkbank I während Arbeit 6: ausreichende Reserve, keine Start-Sackgasse. Werkbank II benötigt 12, Forschung zusätzlich 6. Verbesserte Sendestation 8 und zusätzliche Unterkunft 2 erzeugen zusammen nachvollziehbaren Ausbaubedarf.

- Nachtrag des Nutzers: Anlagen sind auch mit Lieferung kaufbar. Solar I → II → III, danach kleiner und großer Fusionsreaktor. Baupläne können gefunden, erforscht oder gekauft werden. Herstellung benötigt Materialien; ein Anlagenkauf bezahlt Lieferung und Montage.
- Solar I ist am Start vorhanden. Weitere Module brauchen Metall, Bauteile und Bauzeit mit Techniker. Solar II setzt gefundenen Bauplan und Energieforschung voraus, erhöht Leistung pro Slot.
- Sendestation I bietet die lokalen Einstiegsaufträge. Ausbau erschließt neue Auftragsklassen/weitere Angebote; die Systemkarte und der Heimflug werden bei Strommangel nicht gesperrt.
- Forschungsast: Grundlagen Energie → effiziente Solarzellen → Netzsteuerung; Kommunikationsast: Relaistechnik → Sendestation II. Voraussetzungen und Fundhinweise sind im bestehenden Baum sichtbar.
- Bestimmte Bergungs-/Bunkeraufträge liefern einmalige garantierte Grundbaupläne. Zufällige Zusatzfunde sind Bonus, kein möglicher dauerhafter Fortschrittsblocker.
- Geld und Ressourcen werden beim Start einer Bau-/Forschungsarbeit genau einmal reserviert. Abbruchregeln folgen dem bestehenden Arbeitsmodell. Fertigstellung, Wirkung und Freischaltung sind atomar.
- Bei Unterversorgung pausieren niedrig priorisierte Verbraucher. Oberfläche nennt Ursache, Fehlleistung und betroffene Arbeit; reservierte Materialien bleiben erhalten. Kein Fortschritt während Pause, kein mehrfacher Verbrauch beim Laden.
- Grundversorgung und Not-Auftragszugriff bleiben gesichert. Spieler können Verbraucher abschalten oder priorisieren, um den Ausbau aus eigener Kraft zu ermöglichen.
- Die sichtbaren Solarflächen und Antennen entsprechen tatsächlich gebauten Modulen. Neue Module erscheinen erst bei Fertigstellung; reine Dekoration wird nicht als nutzbare Leistung gezählt.

## Umsetzung und Abnahme
1. Höhenmodell samt Navigation, Landung, Sichtlinien und Migration an einer Heimatkarte. Vergleichsaufnahme aus demselben Blickwinkel wie die Zielvorlage, Nahaufnahme der Rampe und echter Fuß-/Flugweg.
2. Heimat, ein Bunker und Freihafen mit zusammenhängenden Gebäuden und wohnlichen Details ausarbeiten. Erst diesen Stil prüfen, dann auf Varianten übertragen.
3. Ortsidentität, Weltzustand und Auftragsbelege erweitern; zwei Teams am selben und an unterschiedlichen Orten prüfen. Erst dann alle 28 Orte ausrollen.
4. Energieversorgung und Forschungs-/Bauplanfortschritt integrieren; Anfangsmission bis Ausbau ohne Sackgasse testen.
5. Varianten vollständig prüfen: erreichbare Ziele, Rampen, sichere Landung, keine doppelten Belege, Speichern/Laden, getrennte Kameras und 16 Teilnehmer. Native Bilder, Bericht und neues separates Windows-Paket. N7 bleibt verfügbar.

Technische Zielstellen: scripts/core/world_layout.gd und neuer TerrainLayout; Navigation/FlightNavigation; world_terrain/world_rooms/world_ground_sites/world_projection; regions/catalog plus neuer SiteCatalog; TeamCampaign-Weltbindung und SaveValidator; Aufträge/WorkOperations und research_catalog; Systemkarte, Basisverwaltung und Forschungsbaum.

Nicht enthalten: frei verformbares Gelände, Physikfahrzeuge, Wetter-/Tageslichtsimulation, zusätzliche Teams, Schiffsinnenräume oder automatisch vorausgesetztes Schiff-PvP. Keine Änderungen an InselKrieg.

## Abnahmekriterien
- Mindestens drei echte begehbare Höhenbereiche im Muster; alle Übergänge ohne Kanten-Durchlaufen erreichbar.
- Gebäude/Möbel/Marker und landende Schiffe sitzen sichtbar korrekt auf ihrer Fläche.
- Bunker und Freihafen haben aus der Spielkamera eine erkennbare Architektur, Funktionszonen und räumliche Staffelung; Vergleich zur Nutzerreferenz statt allein zum vorherigen Stand.
- Vier unterschiedliche Orte je genannter Familie; persistente gemeinsame Ortszustände ermöglichen Teambegegnungen.
- Solar-/Senderausbau benötigt nachvollziehbare Ressourcen und Freischaltungen und verändert den tatsächlichen Betrieb.
- Bestehende Karrieren bleiben ladbar; alte Fund- und Belohnungsstände gehen nicht verloren.

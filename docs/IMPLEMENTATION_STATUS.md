# Umsetzungsstand · 13.09.2026

## Aktuelle Erweiterung N5 · 13.09.2026

N5 liefert neun Reiseziele und vierzehn getrennte Karten: größere Orbit-/Kontaktkarten, drei Bunker mit eigenem Untergrund, freundliches Freihafen und besetztes Knotenwerk. Ein echter Handelsring verbindet Meridian, Freihafen und Staubmarkt. Kenney-Details, terrassierte Felsen/Schluchten, die Entersäbel mit9714 Dreiecken und der kleine Reparaturaufsatz ergänzen den bisherigen Spielkreis.

Schema5 erhält streng geprüfte alte Karrieren über eingefrorene N4-Abhängigkeiten. `regions.gd` vereinheitlicht Welt-/Reise-/Aufzugs-IDs; regionale Preise stammen aus `trade_routes.gd`. Der Host bleibt einzige Autorität; beide Commander führen alle Personen.

Verbindliche Umsetzung, Zahlen, Nachweise und Grenzen: [N5_ACCEPTANCE.md](N5_ACCEPTANCE.md). Aufgabe: [N5_ROUTES_WORLD.md](tasks/N5_ROUTES_WORLD.md). Die nächsten begehbaren Schiffsinnenräume bleiben im anschließenden Ausbau. Alle folgenden N4-/N3-Abschnitte sind historische Stände.


## Aktueller Stand N4 · Crew, Wege, Reise und Ausrüstung

N4 ist implementiert; der vollständige aktuelle Produktfensterdurchlauf besteht mit76/76 Prüfungen. Abschließende Steuerungs-/Fenster- und Paketprüfung werden getrennt geführt; die private Windows-N4-Auslieferung ist [separat geprüft](WINDOWS_DELIVERY.md). Verbindlich sind [N4_CREW_TRAVEL.md](contracts/N4_CREW_TRAVEL.md) und die [N4-Aufgabe](tasks/N4_CREW_TRAVEL_EQUIPMENT.md). N3 und frühere Ergebnisse stehen weiter unten ausdrücklich als Historie.

Die Crew läuft um dieselben Möbel, Wände, Felsen und gelandeten Schiffsumrisse, die sichtbar dargestellt werden. Einsteigen erfolgt am erreichbaren Zugang mit reserviertem Platz. Automatik verteilt freie Rollen nach Fähigkeiten und bewahrt vorhandene Reservierungen; manuelle Rollen bleiben möglich. Abheben sammelt niemanden automatisch ein. Lokaler Flug → Orbit → benannter Zielort → schwebende Ankunft → Landung → Aussteigen sind getrennte Schritte. Rückkehr entlädt die Fracht nicht automatisch; direkte Lager-/Frachtbewegung erfordert das Heimatdock und eine Figur am Zugang oder an Bord.

Beide Koopspieler dürfen alle vorhandenen Figuren und gemeinsamen Gameplayaktionen steuern. Die Hostautorität und Mitglieds-/Transaktionsprüfung bleiben bestehen. Dossier und echte Drag-and-drop-Ausrüstung, kauf-/herstellbarer8er-Rucksack, Multi-Tool mit Aufsätzen sowie Medgun mit verbrauchbaren Ladungen ergänzen die bisherigen Rezepte und Kämpfe. Werkzeugregeln gelten für neue Gewinnungsaufträge; die erste Blackbox bleibt ohne Zusatztool erreichbar. Für weitere Satellitenverwertung und Wracks genügt auch der höherwertige Schneider. Flak, endliche Ressourcen, Rüstung und ausdrücklich zurückzugebende Geier-Miete bleiben aktiv.

Alle Orte sind einzeln geladene Karten: Basis/Rostgebiet/Bunkeroberfläche/Handelsposten jeweils960×960m, Verteilzentrum1280×1280m, Station160×160m, Untergrund128×128m, Orbit und Raumkontakt jeweils480×480m. Die Fläche sagt nichts über vollständig begehbaren Innenraum aus. Figuren wechseln die Region gemeinsam; vier abstrahierte Sitze sind noch kein begehbares Schiffsinnere.

### Bestätigte N4-Prüfungen

| Prüfung | Bestanden | Nachweis |
|---|---:|---|
| Autoritativer Kern einschließlich Migration und Navigation | 601 | 57 Crew/Reise +67 Migration +153 Navigation +104 Grundlauf +73 Orbit +147 Boden; [Kernvertrag](contracts/N4_CREW_TRAVEL.md) |
| Welt | 142 | bestätigte Welt-Teilabnahme N4 |
| Schiffsumrisse | 21 | bestätigte Umriss-Teilabnahme N4 |
| Ersatzmodelle ohne lokale Schiffsdaten | 8 | bestätigte Fallback-Teilabnahme N4 |
| Vollständiger aktueller Produktfensterweg | 76 | `output/n4-product-result.json` |
| Dossier, tatsächliche native Maus-/Fensterbedienung | 22 | [Dossierbericht](../tests/crew_dossier_report.md) |
| Zwei echte ENet-Produktfenster | 62 | [Netzwerkbericht](../tests/network_report.md) |
| Öffentliche WSS, zwei echte Prozesse | 70 | [Internetbericht](../tests/internet_report.md) |
| Gateway, Einladungsprüfung und Freigabe | 15 | `tests/internet_gateway_test.gd` |
| Save-Lebenszyklus, vier tatsächliche Produktstarts | 12 | [Speicherbericht](../tests/save_lifecycle_report.md) |

Die sechs Kernläufe sind grün. Die aktuellen ENet-/WSS-Läufe vergleichen vollständige Host-/Gast-Snapshots bei Pause, Restore und Abschluss; die abschließenden Enginefehlerlogs sind leer. Öffentliche WSS bedeutet hier tatsächlichen öffentlichen Tunnelverkehr zwischen zwei Prozessen auf diesem Rechner, keinen Nachweis zweier unabhängiger Haushalte. Der produktive DNS-/TLS-Ersatzweg wurde in N3 separat geprüft; N4 behauptet dafür keinen zusätzlichen eigenen Lauf.

Validierte v1/v2/v3-Saves werden auf4 migriert. Laufende Arbeit, Inventare und Anfragebelege bleiben erhalten. Neue Geometrie kann alte blockierte Positionen auf sichere Punkte korrigieren; diese räumliche Anpassung wird gemeldet. Navigation nutzt gecachte Wege und gemeinsame Hindernisse, verspricht aber weder global kürzeste Pfade noch durchgehend kurze Suchzeiten; Einzelheiten und die lokal gemessene Planungsspitze stehen im Kernvertrag.

**Nächster bestätigter Ausbau:** begehbare Schiffsinnenräume mit Schnittansicht, Cockpit-/Turmwegen und Lade-/Betankungsplätzen. Weiter offen: simultane unabhängige Regionssimulation, zusätzliche Crew/Rekrutierung, baubare Erweiterungsplätze/Module, Forschung, XP, Traits, Beziehungen/Moral, umfassende medizinische Evakuierung, weitergehende taktische KI, Raumberufe und PvP. Technische Tests ersetzen keine menschliche Verständlichkeits-/Spielspaßabnahme. Das private Windows-N4-Paket ist lokal fertig und separat geprüft; das N3-Paket bleibt historisch.
## Historischer Stand N3 · Außenposten, Ausrüstung und Internet-Koop

N3 ist als kleine spielbare Erweiterung implementiert. Der bisherige Aufbau erhält Rüstung aus Herstellung oder Handel mit tatsächlicher Schadensreduktion, endliche Erz-/Wrackgewinnung, die nur mietbare Geier, einfachen Bodenkampf und einen pausierbaren 20-Sekunden-Respawn ohne dauerhaften Verlust. Flak schädigt nahe fliegende Schiffe; sichere entfernte Landung und Bodenangriff sind möglich. Die Crewakte erklärt die wirkenden Werte und Ausrüstung; das erhaltene historische Hauptmenümotiv ist wieder eingebunden.

Alle Orte sind einzeln geladene Karten: Basis 320×320 m, Rostgebiet 960×960 m, Station 160×160 m, Raumkontakt 480×480 m, Bunkeroberfläche 640×640 m, Untergrund innerhalb 128×128 m mit begrenzten begehbaren Räumen/Gang, Verteilzentrum 800×800 m und Handelsposten 400×400 m. Der Aufzug verbindet Oberfläche und Untergrund. Neue gemeinsame Hindernisrechtecke werden vom Kern für Laufwege und gerade Schusslinien verwendet und von der Welt passend dargestellt. Zusätzliche Landschaftsdekoration und gegenseitige Figuren-/Schiffskollision bleiben außerhalb dieses Navigationsmodells.

Aktuelle Abnahme: [N3_ACCEPTANCE.md](N3_ACCEPTANCE.md). Verifiziert sind **151 neue Kernprüfungen und 167 bestehende Kernregressionen**, der **69-Prüfungen-N3-Produktpfad**, außerdem **63 bestehende Produktfensterprüfungen, 13 Steuerungsprüfungen und 10 Speicherprüfungen über vier echte Starts**. Save v1/v2 wird nach strenger Altvalidierung zu v3 migriert; Karriere, Arbeit und Anfragebelege bleiben erhalten. Belege und genaue Regeln: [N3_GROUND.md](contracts/N3_GROUND.md), [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md), `output/n3-product-result.json` und `output/ground-stage-core.json`. Die Gesamt-Abnahme führt weitere Welt-/Asset-Nachweise auf.

Internet-Koop wurde mit zwei echten Godot-Prozessen über einen öffentlichen WSS-Tunnel geprüft: **55/55 direkt und 55/55 über den produktiven DNS-/TLS-Ersatzweg**. ENet-LAN-Regression **69/69**, Gateway und direkte Session-Freigabe **15/15**. Anmeldung prüft Schlüssel, Protokoll und Schema vor Snapshots/Besitzvergabe; TLS bleibt geprüft. Details: [INTERNET_COOP.md](INTERNET_COOP.md), [internet_report.md](../tests/internet_report.md). Ein unabhängiges zweites Heimnetz, Langzeitbetrieb, Matchmaking und garantierte Verfügbarkeit sind nicht abgenommen. Internet und LAN verwenden denselben einen Gastplatz und dieselbe Spielautorität.

**Noch offen:** vollständiges Lernen/XP, Traits, Beziehungen, Moral/Frust und Missionsbiografien, Rekrutierung, baubare Raummodule, Forschung, medizinische Evakuierungs-/Genesungslogistik, weitergehende taktische KI/Deckung, Raumberufe, weitere Planeten und PvP. Drei Fähigkeiten wirken bereits: Technik auf Eignung und Gewinnungszeit, Pilotieren auf Fluggeschwindigkeit, Geschützkenntnis auf Boden-/Turmschaden. Das ist keine passive Charakterentwicklung. Guards sind einfache stationäre Gegner, Ressourcen bleiben endlich, Mietzeit ist pausierbare Simulationszeit. Menschliche Verständlichkeits- und Spielspaßtests stehen aus.

## Historischer Stand N2 · Räume und Orbit

Die folgenden Ergebnisse und Grenzen dokumentieren die vorige Stufe. Aktuelle Funktionen und Abnahme stehen ausschließlich im N4-Abschnitt oben.

Die Stufe **Räume, Suche und erster Raumkontakt** ist implementiert und technisch geprüft. Vier getrennte Basisräume, sichtbare Ausbauflächen, größere einzeln geladene Karten, ein Stationsdock, Radarentdeckung, planarer Schiffskampf gegen einen zufälligen Freibeuter, Jaros Geschützturm, Werkbankstufen und die erste Crewakte erweitern den bisherigen Spielkreis.

Damals dokumentierte Abnahme: **67 neue Kernprüfungen, 100 Kernregressionen, 63 Produktfensterprüfungen, 13 Steuerungsprüfungen, 43 Weltprüfungen, 75 Prüfungen mit zwei echten ENet-Prozessen und 10 Speicher-Lebenszyklusprüfungen bestanden.** Alte v1-Spielstände wurden validiert in v2 übernommen. Details, Grenzen und Belege: [ROOMS_ORBIT_ACCEPTANCE.md](ROOMS_ORBIT_ACCEPTANCE.md), [N2_ORBIT.md](contracts/N2_ORBIT.md) und [network_report.md](../tests/network_report.md).

In N2 wurde nur die aktive Karte aufgebaut: Basis 320×320 m, Satellitengebiet 640×640 m, Station 160×160 m, Raumkontakt 480×480 m. Die Stationsreise erhielt 35 % Begegnungschance; der einmalige gespeicherte Wurf, planare Flugziele und die Rückkehr zur Basis bei Niederlage bleiben auch in N3 erhalten.

**Damals noch offen:** Hindernisnavigation und Deckung, tatsächlich baubare Raummodule, Bunkerkampf, das vollständige Verwundungs-/Evakuierungs-/Respawnsystem, Rekrutierung, Persönlichkeit und fortlaufende Charakterentwicklung, Forschung, Raumberufe, weitere Planeten/Schiffe und PvP. Wände und Felsen waren visuell. Die Crewakte zeigte bereits echte Fähigkeiten, Aufgabe und Ausrüstung; die Ausbauflächen waren vorbereitete Standorte. Loopback-Koop mit zwei Prozessen war geprüft, Internetvermittlung und Matchmaking noch nicht. Menschliche Verständlichkeits- und Spielspaßtests standen aus.

Der Gesamtplan mit echten Spielbildern ist privat veröffentlicht: [Sternenbürgerchen-Spielplan](https://sternenbuergerchen-neustart.klabauta.chatgpt.site). Lokal erzeugt `tools/build_report.py` die eigenständigen HTML-Dateien unter `output/`.

## Historischer Stand N0/N1 · 12.09.2026

Die folgenden Ergebnisse beschreiben die ursprüngliche Stufe. Für aktuelle Funktionen und Grenzen gelten der N4-Abschnitt oben und die aktuelle N4-Abnahme.

12.09.2026 — Erste spielbare Neustartstufe N0/N1 umgesetzt; N1a als lokaler Zwei-Prozess-Nachweis bestanden. Eigenes Godot-4.6.2-Projekt, Start über `Spielen.cmd`.

Spielbar: zwei Crewmitglieder mit Betten in einer sichtbaren Basis, Point-and-Click und Rahmenauswahl, Kamerafolge, Werkbank mit tatsächlichem Arbeiter/Material, Herstellung und Reparatur, sichtbare Reise, Satellitenbergung auf eigener Rostwelt-Karte, einmalige Auszahlung plus nutzbarer Blueprint, Handel an einer abstrakten Orbitalstation, Verladen, Pause und fortgesetzte Karriere über Save/Laden.

Grafik: weißer Kenney-Astronaut mit Helm und Idle-/Walk-/Work-Animationen; lokales Blender-Shuttle Entersäbel mit 17.879 Dreiecken; geschlossene Wandkontur mit transparenter Front; schmales Icon-HUD mit Porträts, kurzen Aktionsnamen, Tooltips und Besitzkennzeichnung.

### Historische N1-Abnahme

| Prüfung | Resultat | Weg |
|---|---|---|
| Autoritativer Kern | 100 / 100 | `tests/core_flow_test.gd` |
| Echte Produktfenster, Maus, Crafting, Handel, Mission, Save | 48 / 48 | `tests/product_flow_test.gd` |
| Point-and-Click, Rahmen, Einzelansicht, WASD nur Kamera, Pause | 13 / 13 | `tests/control_window_test.gd` |
| Vier echte Produktstarts: Beenden, Fortsetzen und Speicherfehlerschutz | 10 / 10 | `tests/save_lifecycle_probe.gd` mit initial/restore/guards/recovered |
| Zwei echte ENet-Produktprozesse | 48 / 48 | `tests/network_run.ps1 -Visual`; Detail `tests/network_report.md` |

Die damaligen Fensterbelege und JSON-Ergebnisse lagen lokal unter `output/`, Netzwerkbelege im im Netzwerkbericht genannten temporären Ordner. Die Tests veränderten keine normale Nutzerkarriere. Verwendete Engine `4.6.2.stable.official.71f334935`; ältere Godot-Installation nicht verändert. Aktuelle Läufe können gleichnamige lokale Belegdateien erneuern; die obigen historischen Zahlen bleiben dem damaligen Stand zugeordnet.

Zusätzliche sechssekündige Stichproben je Karte im angeforderten 2560×1440-Fenster mit RTX 4070 Ti SUPER und Ryzen 7 7800X3D: Basis Framezeit p95 4,281 ms, Physik p95 1,165 ms, Szenenaufbau 271,475 ms; Rostkarte 4,242 ms / 0,321 ms / 18,511 ms. Monotone reale Frameabstände, je zwei Sekunden Warmup. Logische UI 1440×900; gemeldete Rendertextur 3687×2304 unter aktueller Display-Skalierung. Speicherangaben im JSON sind Godots statischer Speicher, kein gesamter Prozess-/GPU-Speicher. Keine exklusive Hardwarebelegung oder allgemeine Performancefreigabe; `output/window-performance.json` bewahrt die Messbedingungen.

### Historische Grenzen von N1

In N1 noch nicht umgesetzt: Bunkerkampf, Verwundung/Evakuierung/Respawn, baubare Erweiterungsslots, Forschungskammer/Rekrutierung, freier Raumflug/Raumkampf, Mining/Salvage im Orbit, weitere Planeten und PvP. Dafür waren spätere Etappen N2–N8 vorgesehen. Der Satellitenauftrag bildete einen einzelnen vollständigen Einstieg, keinen endlosen Missionskatalog.

Die N1-Karten verwendeten offene Bewegungsflächen und feste Anflugpunkte. Wände/Felsen waren visuelle Darstellung; Hindernisnavigation, Deckung und wählbare Landestellen fehlten noch. Die transparente Front war bereits eine Kameradarstellung der Basis.

Koop war mit zwei lokalen Prozessen und Loopback geprüft. Internetvermittlung, Matchmaking, vollständige Netzglättung, weitere Gäste und kompetitive Pausenregeln waren nicht abgenommen. Bereits damals führte der Host Ida und gemeinsame Transaktionen/Pause/Reise, der Gast Jaro; Abbruch pausierte und gab den Gastplatz zurück. Die Clientansicht blieb bei Verbindungsverlust auf dem letzten bestätigten Stand.

Die N1-UX war implementiert und technisch geprüft; menschliche Verständlichkeits- und Spielspaßtests standen aus. Als weiterer Bauabschnitt waren Bunker, Kampf und Genesung vorgesehen. Ihr heute gelieferter kleiner Umfang und die weiterhin offenen Ausbau-/Crewziele stehen im N4-Abschnitt oben.

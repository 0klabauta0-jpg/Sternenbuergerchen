# Umsetzungsstand · 13.09.2026

## Aktueller Stand N3 · Außenposten, Ausrüstung und Internet-Koop

N3 ist als kleine spielbare Erweiterung implementiert. Der bisherige Aufbau erhält Rüstung aus Herstellung oder Handel mit tatsächlicher Schadensreduktion, endliche Erz-/Wrackgewinnung, die nur mietbare Geier, einfachen Bodenkampf und einen pausierbaren 20-Sekunden-Respawn ohne dauerhaften Verlust. Flak schädigt nahe fliegende Schiffe; sichere entfernte Landung und Bodenangriff sind möglich. Die Crewakte erklärt die wirkenden Werte und Ausrüstung; das erhaltene historische Hauptmenümotiv ist wieder eingebunden.

Alle Orte sind einzeln geladene Karten: Basis 320×320 m, Rostgebiet 960×960 m, Station 160×160 m, Raumkontakt 480×480 m, Bunkeroberfläche 640×640 m, Untergrund innerhalb 128×128 m mit begrenzten begehbaren Räumen/Gang, Verteilzentrum 800×800 m und Handelsposten 400×400 m. Der Aufzug verbindet Oberfläche und Untergrund. Neue gemeinsame Hindernisrechtecke werden vom Kern für Laufwege und gerade Schusslinien verwendet und von der Welt passend dargestellt. Zusätzliche Landschaftsdekoration und gegenseitige Figuren-/Schiffskollision bleiben außerhalb dieses Navigationsmodells.

Aktuelle Abnahme: [N3_ACCEPTANCE.md](N3_ACCEPTANCE.md). Verifiziert sind **151 neue Kernprüfungen und 167 bestehende Kernregressionen**, der **69-Prüfungen-N3-Produktpfad**, außerdem **63 bestehende Produktfensterprüfungen, 13 Steuerungsprüfungen und 10 Speicherprüfungen über vier echte Starts**. Save v1/v2 wird nach strenger Altvalidierung zu v3 migriert; Karriere, Arbeit und Anfragebelege bleiben erhalten. Belege und genaue Regeln: [N3_GROUND.md](contracts/N3_GROUND.md), [N3_SKILLS_MENU.md](N3_SKILLS_MENU.md), `output/n3-product-result.json` und `output/ground-stage-core.json`. Die Gesamt-Abnahme führt weitere Welt-/Asset-Nachweise auf.

Internet-Koop wurde mit zwei echten Godot-Prozessen über einen öffentlichen WSS-Tunnel geprüft: **55/55 direkt und 55/55 über den produktiven DNS-/TLS-Ersatzweg**. ENet-LAN-Regression **69/69**, Gateway und direkte Session-Freigabe **15/15**. Anmeldung prüft Schlüssel, Protokoll und Schema vor Snapshots/Besitzvergabe; TLS bleibt geprüft. Details: [INTERNET_COOP.md](INTERNET_COOP.md), [internet_report.md](../tests/internet_report.md). Ein unabhängiges zweites Heimnetz, Langzeitbetrieb, Matchmaking und garantierte Verfügbarkeit sind nicht abgenommen. Internet und LAN verwenden denselben einen Gastplatz und dieselbe Spielautorität.

**Noch offen:** vollständiges Lernen/XP, Traits, Beziehungen, Moral/Frust und Missionsbiografien, Rekrutierung, baubare Raummodule, Forschung, medizinische Evakuierungs-/Genesungslogistik, weitergehende taktische KI/Deckung, Raumberufe, weitere Planeten und PvP. Drei Fähigkeiten wirken bereits: Technik auf Eignung und Gewinnungszeit, Pilotieren auf Fluggeschwindigkeit, Geschützkenntnis auf Boden-/Turmschaden. Das ist keine passive Charakterentwicklung. Guards sind einfache stationäre Gegner, Ressourcen bleiben endlich, Mietzeit ist pausierbare Simulationszeit. Menschliche Verständlichkeits- und Spielspaßtests stehen aus.

## Historischer Stand N2 · Räume und Orbit

Die folgenden Ergebnisse und Grenzen dokumentieren die vorige Stufe. Aktuelle Funktionen und Abnahme stehen ausschließlich im N3-Abschnitt oben.

Die Stufe **Räume, Suche und erster Raumkontakt** ist implementiert und technisch geprüft. Vier getrennte Basisräume, sichtbare Ausbauflächen, größere einzeln geladene Karten, ein Stationsdock, Radarentdeckung, planarer Schiffskampf gegen einen zufälligen Freibeuter, Jaros Geschützturm, Werkbankstufen und die erste Crewakte erweitern den bisherigen Spielkreis.

Damals dokumentierte Abnahme: **67 neue Kernprüfungen, 100 Kernregressionen, 63 Produktfensterprüfungen, 13 Steuerungsprüfungen, 43 Weltprüfungen, 75 Prüfungen mit zwei echten ENet-Prozessen und 10 Speicher-Lebenszyklusprüfungen bestanden.** Alte v1-Spielstände wurden validiert in v2 übernommen. Details, Grenzen und Belege: [ROOMS_ORBIT_ACCEPTANCE.md](ROOMS_ORBIT_ACCEPTANCE.md), [N2_ORBIT.md](contracts/N2_ORBIT.md) und [network_report.md](../tests/network_report.md).

In N2 wurde nur die aktive Karte aufgebaut: Basis 320×320 m, Satellitengebiet 640×640 m, Station 160×160 m, Raumkontakt 480×480 m. Die Stationsreise erhielt 35 % Begegnungschance; der einmalige gespeicherte Wurf, planare Flugziele und die Rückkehr zur Basis bei Niederlage bleiben auch in N3 erhalten.

**Damals noch offen:** Hindernisnavigation und Deckung, tatsächlich baubare Raummodule, Bunkerkampf, das vollständige Verwundungs-/Evakuierungs-/Respawnsystem, Rekrutierung, Persönlichkeit und fortlaufende Charakterentwicklung, Forschung, Raumberufe, weitere Planeten/Schiffe und PvP. Wände und Felsen waren visuell. Die Crewakte zeigte bereits echte Fähigkeiten, Aufgabe und Ausrüstung; die Ausbauflächen waren vorbereitete Standorte. Loopback-Koop mit zwei Prozessen war geprüft, Internetvermittlung und Matchmaking noch nicht. Menschliche Verständlichkeits- und Spielspaßtests standen aus.

Der Gesamtplan mit echten Spielbildern ist privat veröffentlicht: [Sternenbürgerchen-Spielplan](https://sternenbuergerchen-neustart.klabauta.chatgpt.site). Lokal erzeugt `tools/build_report.py` die eigenständigen HTML-Dateien unter `output/`.

## Historischer Stand N0/N1 · 12.09.2026

Die folgenden Ergebnisse beschreiben die ursprüngliche Stufe. Für aktuelle Funktionen und Grenzen gelten der N3-Abschnitt oben und die N3-Abnahme.

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

Die N1-UX war implementiert und technisch geprüft; menschliche Verständlichkeits- und Spielspaßtests standen aus. Als weiterer Bauabschnitt waren Bunker, Kampf und Genesung vorgesehen. Ihr heute gelieferter kleiner Umfang und die weiterhin offenen Ausbau-/Crewziele stehen im N3-Abschnitt oben.

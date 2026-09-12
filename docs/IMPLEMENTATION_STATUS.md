# Umsetzungsstand

12.09.2026 — Erste spielbare Neustartstufe N0/N1 umgesetzt; N1a als lokaler Zwei-Prozess-Nachweis bestanden. Eigenes Godot-4.6.2-Projekt, Start über `Spielen.cmd`.

Spielbar: zwei Crewmitglieder mit Betten in einer sichtbaren Basis, Point-and-Click und Rahmenauswahl, Kamerafolge, Werkbank mit tatsächlichem Arbeiter/Material, Herstellung und Reparatur, sichtbare Reise, Satellitenbergung auf eigener Rostwelt-Karte, einmalige Auszahlung plus nutzbarer Blueprint, Handel an einer abstrakten Orbitalstation, Verladen, Pause und fortgesetzte Karriere über Save/Laden.

Grafik: weißer Kenney-Astronaut mit Helm und Idle-/Walk-/Work-Animationen; lokales Blender-Shuttle Entersäbel mit 17.879 Dreiecken; geschlossene Wandkontur mit transparenter Front; schmales Icon-HUD mit Porträts, kurzen Aktionsnamen, Tooltips und Besitzkennzeichnung.

## Aktuelle Abnahme

| Prüfung | Resultat | Weg |
|---|---|---|
| Autoritativer Kern | 100 / 100 | `tests/core_flow_test.gd` |
| Echte Produktfenster, Maus, Crafting, Handel, Mission, Save | 48 / 48 | `tests/product_flow_test.gd` |
| Point-and-Click, Rahmen, Einzelansicht, WASD nur Kamera, Pause | 13 / 13 | `tests/control_window_test.gd` |
| Vier echte Produktstarts: Beenden, Fortsetzen und Speicherfehlerschutz | 10 / 10 | `tests/save_lifecycle_probe.gd` mit initial/restore/guards/recovered |
| Zwei echte ENet-Produktprozesse | 48 / 48 | `tests/network_run.ps1 -Visual`; Detail `tests/network_report.md` |

Fensterbelege und JSON-Ergebnisse liegen lokal unter `output/`, Netzwerkbelege im im Netzwerkbericht genannten temporären Ordner. Die Tests verändern keine normale Nutzerkarriere. Aktuelle Engine `4.6.2.stable.official.71f334935`; ältere Godot-Installation nicht verändert.

Zusätzliche sechssekündige Stichproben je Karte im angeforderten 2560×1440-Fenster mit RTX 4070 Ti SUPER und Ryzen 7 7800X3D: Basis Framezeit p95 4,281 ms, Physik p95 1,165 ms, Szenenaufbau 271,475 ms; Rostkarte 4,242 ms / 0,321 ms / 18,511 ms. Monotone reale Frameabstände, je zwei Sekunden Warmup. Logische UI 1440×900; gemeldete Rendertextur 3687×2304 unter aktueller Display-Skalierung. Speicherangaben im JSON sind Godots statischer Speicher, kein gesamter Prozess-/GPU-Speicher. Keine exklusive Hardwarebelegung oder allgemeine Performancefreigabe; `output/window-performance.json` bewahrt die Messbedingungen.

## Grenzen dieser Stufe

Noch nicht umgesetzt: Bunkerkampf, Verwundung/Evakuierung/Respawn, baubare Erweiterungsslots, Forschungskammer/Rekrutierung, freier Raumflug/Raumkampf, Mining/Salvage im Orbit, weitere Planeten und PvP. Diese bleiben im bestätigten Gesamtplan N2–N8. Der derzeitige Satellitenauftrag ist ein einzelner vollständiger Einstieg, kein endloser Missionskatalog.

Die N1-Karten verwenden offene Bewegungsflächen und feste Anflugpunkte. Wände/Felsen sind aktuell visuelle Darstellung; Hindernisnavigation, Deckung und wählbare Landestellen sind noch keine spielerischen Systeme. Die transparente Front ist eine Kameradarstellung der Basis.

Koop ist mit zwei lokalen Prozessen und Loopback geprüft. Internetvermittlung, Matchmaking, vollständige Netzglättung, weitere Gäste und kompetitive Pausenregeln sind nicht abgenommen. Host führt Ida und gemeinsame Transaktionen/Pause/Reise, Gast Jaro; Abbruch pausiert und gibt den Gastplatz zurück. Clientansicht bleibt bei Verbindungsverlust auf dem letzten bestätigten Stand.

Die UX ist implementiert und technisch geprüft; menschliche Verständlichkeits- und Spielspaßtests stehen aus. Nächster fachlicher Bauabschnitt: kleiner Bunker mit Kampf und Genesungs-/Evakuierungsregeln, anschließend Ausbau und neue Crew.

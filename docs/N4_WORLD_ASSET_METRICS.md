# N4 – Welt, Schiff und sichtbare Ausrüstung

Stand 13.09.2026. Godot 4.6.2 / OpenGL Compatibility, Blender 5.1.1. Dies dokumentiert die Welt-/Assetprüfung; vollständige Spielfluss-, Save- und Netzwerkabnahme werden separat geführt.

## Gemeinsamer Maßstab und Layout

`scripts/core/world_layout.gd` liefert deterministische Daten für Renderer und Core: Kartenmaße, Räume, Landmarken, Möbel, Felsen und Schiffprofile. Heimatbasis, Rostwelt, Bunkeroberfläche und Handelsposten messen jeweils **960 × 960 m**, Distribution **1280 × 1280 m**; Station 160 × 160, Untergeschoss 128 × 128, Orbit/Kontakt jeweils 480 × 480 m. Nur die aktive Karte wird aufgebaut. Die Raumwände verwenden dieselben Segmente und freien Türöffnungen wie die Navigation. Frontwände behalten ihre Geometrie und werden von der festen Kameraseite transparent dargestellt.

Die Unterkunft besitzt zwei benannte und vier zusätzliche Betten an der Nordwand. Das ist räumliche Reserve und keine implementierte Rekrutierung. Der rechte Schrank wurde nach einer echten Erreichbarkeitsprobe aus dem Türbereich nach `[-5.6,-7.3]` verlegt. Kleine Felsen liegen in einem MultiMesh; auch ihre Umrisse stammen aus der gemeinsamen Quelle. Die bestehende Mars-Farbgebung und Mesa-Gestaltung bleibt erhalten. Keine neue Bergsimulation oder InselKrieg-Landschaft wurde begonnen.

Der Bunker hat eine geschlossene Umfassung mit einer acht Meter breiten Eingangsöffnung. Das Handels-Hab hat eine fünf Meter breite Schleuse. Für das Verteilzentrum bleiben kleine getrennte Hallen, offene Funktionsgassen, Handel, Sicherheitsbereich und Bergedock lesbar. Dekorative Bodenmarkierungen sind keine zusätzlichen Hindernisse. Navigation verwendet vereinfachte Grundrissrechtecke mit Crewabstand, keine physikalische 3D-Begehung jedes Details.

## Entersäbel: unveränderte Quelle, lokale Ableitung

- Original: `C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE/DRAKE-CUTLASS.obj`
- Original-SHA-256: `8c9998b2d29b359a63ab9b72b6f7065fbf9ed63068b5856d7f09376035eb8a60`
- Reproduzierbarer Converter: `tools/prepare_shuttle_n4.py`; Blender `--background --python tools/prepare_shuttle_n4.py`.
- GLB: `assets/local/entersaebel_n4/entersaebel.glb`
- Blender-Szene: `assets/local/entersaebel_n4/source/entersaebel.blend`
- Studio-Vorschau und Rohmetriken: `assets/local/entersaebel_n4/preview.png`, `metrics.json`.

| Messung | Wert |
|---|---:|
| Originaldreiecke | 265.435 |
| GLB-Dreiecke, nach erneutem Import | 15.705 |
| Export-Vertices einschließlich harter Normalen/Materialgrenzen | 44.711 |
| Meshteile / Materialien | 12 / 4 |
| Gesamter Bodenbereich, X × Z | 7,5 × 11,0 m |
| Gesamthöhe inklusive Turm und Fahrwerk | 3,595 m |
| Unterste Stelle | Y = 0 |
| Heck-Zugang relativ zum Schiff | X = 0, Z = +6,8 m |

Vordere Flügel-/Waffenanbauten sowie die feste alte Turmgeometrie wurden aus der Ableitung entfernt. Drei klare Fahrwerksfüße und ein Hecktritt sind ergänzt. `TurretPivot` ist ein eigener, tatsächlich drehbarer Node. Die Darstellung übernimmt `ship.yaw`, `ship.turret_yaw` und bestätigte Sitzbelegung; ein belegter Schützensitz zeigt einen Helm im Turm. Keine eigene Treffer- oder Rollensimulation im Renderer. Schiffinnenräume sind auf Nutzerwunsch der nächste Ausbau.

Der Converter importierte das fertige GLB erneut, öffnete die gespeicherte `.blend` nochmals und bestätigte den unveränderten Originalhash. Studio- und echte Godot-Fensterbilder wurden angesehen. Die Dateien bleiben private, Git-ignorierte Ableitungen; eine Weiterverbreitungslizenz wird nicht behauptet. Die mitgeführten Kenney-Modelle bleiben Fallbacks, wenn lokale Dateien fehlen. `ResourceLoader.exists` unterstützt importierte PCK-Ressourcen. Der Renderer passt auch Fallbacks innerhalb des gemeinsamen Grundrisses ein. Der Geier verwendet weiterhin den N3-Converter und ein Profil von 4,04 × 8,4 m mit Heckzugang Z = +5,3 m.

## Sichtbare Ausrüstung

`world_equipment.gd`, aufgerufen durch `world_ground_projection.gd`, bindet Rucksack und Handwerkzeug an `Chest` beziehungsweise `RightHand` des bestehenden Kenney-Rigs. Mining-, Salvage- und Medgun-Kennung folgen den ausgerüsteten Item-IDs. Brust- und Schulterpanzer aus N3 bleiben riggebunden. Die Ausrüstung erzeugt keine Boni oder Inventarwerte; sie projiziert den bestätigten Snapshot.

## Tatsächliche Prüfungen und Bilder

`scripts/world/world_n4_probe.gd`: **142 Prüfungen, keine Fehler** im echten 1440 × 900-Produktfenster. Reguläre Befehle bestätigten Ausrüsten, Wege zum Schiffszugang, Pilot/Schütze, Start, getrennten Orbit und Reisen auf alle Außenkarten sowie Station. Weitere Prüfungen: sechs Betten, Rig-Anhänge, tatsächliches Rumpfmaß innerhalb des Navprofils, Weg um den Schiffsrumpf und Übereinstimmung aller geprüften Raum-/Möbelknoten mit ihren Layoutdaten. Die Foto-Ausrüstung stammt aus einem einmaligen, ausdrücklich begrenzten Inventarfixture; sie wurde für diese Probe nicht erspielt. Ein Untergeschossbild ist nur ein Renderfixture mit unverändertem Stations-HUD und wird **nicht** als Produktbild empfohlen.

Belege: `output/n4-world/results.json`, je Bild ein bestätigter Snapshot als JSON. Unveränderte Fenster-PNGs:

- `base.png`: Räume, sechs Betten, transparente Frontwände, gebogener Basisweg; Aufnahme vor der anschließenden kleinen Schrankversetzung.
- `crew-equipment.png`: Ida mit Rüstung, Rucksack und Mining-Werkzeug, Jaro als Vergleich ohne diese Nachrüstung.
- `entersaebel.png`, `turret-occupied.png`: Fahrzeug auf dem Pad; getrennte Turmrolle.
- `orbit.png`: tatsächlicher separater Orbit mit Planet und fliegendem Schiff.
- `rust.png`, `bunker_surface.png`, `distribution.png`, `tradepost.png`, `station.png`: aktive Karten im Überblick.
- `space-contact.png`: tatsächlich ausgelöster Piratenkontakt während Stationsreise.

Die ergänzende Headless-Geometrieprobe `world_footprint_probe.gd` prüft die erhöhten sichtbaren Meshumrisse interaktiver Einrichtungen gegen das gemeinsame Rechteck samt 0,6-m-Crewabstand. Beim Satelliten wurde ein überstehendes Trümmerteil eingerückt und die Panelgruppe im vorhandenen Rechteck eingepasst. AA-Geometrie gehört zur separaten Gegnerprojektion; die Probe zählt sie nicht als geprüfte Landmarke. Detailergebnisse liegen in `output/n4-world/footprints.json`.

Ergebnis dieser Geometrieprobe: **21 Prüfungen, keine Fehler**. Zusätzlich importierte ein isolierter Minimalcheckout mit ausschließlich kuratierten Assets den aktuellen Renderer: `world_ship_delivery_probe.gd` bestätigte **8 Prüfungen, keine Fehler** für fehlende private Modelle, korrekte Fallbackquelle, Profile sowie echte Turmdrehung und Schützenprojektion. Import- und Probelog enthalten keine Enginefehler. Dabei wurde der optionale Zugriff auf Geier-Turmmetadaten korrigiert; der Geier besitzt keinen Turm. Evidence: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-n4-ship-fallback-90f4af7045744aa58b3f23ec578f25cb/` (`import.log`, `probe.log`). Der genaue Pfad ist zusätzlich in `output/n4-world/fallback-path.txt` gespeichert. Dies ist eine gezielte Assetprüfung, kein vollständiger Portable-Build-Lauf.

### Frischer vollständiger Quellstand ohne private Assets

Der abschließend aktualisierte `tests/asset_delivery_test.gd` berücksichtigt die Modellpriorität N4-Entersäbel → früherer lokaler Entersäbel → Kenney und prüft maximale Breite **und** Länge bei erhaltenen Proportionen. Im Arbeitsprojekt bestanden **9/9 Prüfungen**, mit tatsächlicher Auswahl der N4-Datei sowie Freibeuter und Geier.

Ein neuer isolierter Snapshot kopierte **244 Quelldateien / 2.756.993 Byte** aus dem aktuellen Arbeitsstand; `.godot`, `assets/local`, `output` und Git-Metadaten waren nicht enthalten. Ein eigenes `override.cfg` setzt ein frisches, getrenntes Godot-Nutzerverzeichnis. Import, Assettest mit `--require-curated` (**12/12**), N4-Profil-/Turmtest (**8/8**), Hauptmenü-Headless-Start und Start der echten `scenes/game.tscn` endeten jeweils mit Exit 0; die Logs enthalten keine Engine-/Parsefehler. Alle drei Schiff-IDs verwenden darin tatsächlich `assets/curated/space/craft_cargoA.glb`.

Evidence-Verzeichnis: `C:/Users/bjoer/AppData/Local/Temp/sternenbuergerchen-n4-full-source-delivery-2ed01e27250144a3a258a449a45a1fc9/`. Darin `delivery-manifest.json`, `import.log`, `asset-test.log`, `n4-profile-test.log`, `boot.log`, `game-boot.log`. Verweis zusätzlich in `output/n4-world/full-delivery-path.txt`. Die Auslieferungsprobe öffnete kein Fenster und verwendete keine normale Nutzerkarriere. Sie ist ein Quellstand-/Startnachweis; den Windows-Paketlauf prüft die separate Exportabnahme.

### Begrenzte Leistungsstichprobe

Je drei Sekunden bei ruhendem bestätigtem Snapshot, RTX 4070 Ti SUPER, gemeinsamer Desktop, ungefähr 240-Hz-Begrenzung. Die Zahlen sind Frameabstände des konkreten Laufs; kein Versprechen für andere Geräte, Kämpfe oder eine ganze Kampagne.

| Karte | Samples | p95 | Nodes | Draw Calls | Navrechtecke |
|---|---:|---:|---:|---:|---:|
| Basis | 720 | 4,488 ms | 1.131 | 681 | 282 |
| Orbit | 720 | 4,260 ms | 392 | 195 | 0 |
| Rostwelt | 721 | 4,260 ms | 560 | 442 | 238 |
| Bunkeroberfläche | 720 | 4,234 ms | 589 | 392 | 240 |
| Distribution | 721 | 4,246 ms | 716 | 858 | 243 |
| Handelsposten | 721 | 4,256 ms | 577 | 323 | 251 |
| Station | 721 | 4,267 ms | 1.022 | 599 | 19 |

## Gestaltungsreferenzen und Suchgrenze

Die neue Nutzerlenkung für Außenposten/Bunker wird als Bethesda/Starfield-Referenz umgesetzt: gekapselte Hab-Module, erkennbare Schleuse, konstruktive Rippen, Versorgungstechnik, Container und getrenntes Landepad. Offizielle Quelle: [Bethesda – Outpost Management](https://help.bethesda.net/app/answers/detail/a_id/61081/~/outpost-management---tips-%26-tricks---starfield), insbesondere das dort verlinkte [Functional-Outpost-Bild](https://esohelpportal.s3.amazonaws.com/Starfield/Outposts/OutpostBuilding/Starfield_OutpostBuilding_FunctionalOutpost.jpg). Die Bildseite und Bildsuchreferenz wurden recherchiert; es wurden keine fremden Texturen oder Gebäudegeometrien importiert. Die hier gelieferten Spielbilder wurden direkt visuell geprüft.

Distribution behält die Richtung aus [Inside Star Citizen: Distribution Allocution](https://www.youtube.com/watch?v=8VKzP-T8mIA) und dem [RSI-Monatsbericht März 2024](https://robertsspaceindustries.com/en/comm-link/transmission/19869-Star-Citizen-Monthly-Report-March-2024): unterschiedliche Funktionskörper, Frachtgassen, separate Sicherheitszone und lesbare Torrahmen, als eigene vereinfachte Lowpoly-Module.

Die gezielte lokale Bildinventur in `C:/dev/KlabsCom` einschließlich verborgener/ignorierter Bilddateien außerhalb von Build-/Dependency-Verzeichnissen fand Stanton-, Pyro-, Nyx- und Fallow-Field-Karten sowie Handbuchscreenshots, jedoch keine Bethesda-/Starfield-Außenpostenbilder. An den KlabsCom-Anwendungen wurde nichts verändert. Externe Uploads oder nicht lokal vorhandene Bildsammlungen wurden damit nicht ausgeschlossen.

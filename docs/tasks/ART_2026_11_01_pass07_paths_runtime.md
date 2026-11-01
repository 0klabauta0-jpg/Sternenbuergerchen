# ART Pass07: Wegeanschluesse und erster Grafikumbau-Slice

## Auftrag / Problem
Der Nutzer sieht einen signifikanten Fortschritt in Pass06, verlangt aber
geradere, passende Wege zu Eingaengen und die Korrektur einzelner Grafikfehler.
Danach soll der Grafikumbau im bestehenden Spielaufbau beginnen.

## Ursache / Vorgehen
Wege bisher mit unabhaengigen festen Koordinaten und universellen Kurventangenten
gebaut: Endtangenten und Eingangsmittelpunkte werden nicht zusammen geprueft.
LoadingApron, Rampen und Linien besitzen getrennte Oberflaechenlagen. Konkrete
Bildfehler zuerst isolieren; geerbte Fehler nicht als neue Regression ausgeben.
Anschliessend ein kleiner vorhandener MapData-/Registry-/View-Integrationsslice,
keine Uebernahme der Test-Fixture als neue Gameplay-Wahrheit.

## Umfang / Nicht-Ziele
- Gerade letzte Wegstuecke rechtwinklig und mittig an Eingang/Apron/Rampe.
- Durchgehende ebene Anschluesse, klare Abzweige, weniger willkuerliche Kurven;
  keine schwebenden Markierungen oder fehlerhaften Flaechen/Schattensaeume.
- Wiederverwendbare deklarierte Bau-/Eingangsanker statt weiterer unabhaengiger
  Zahlenkopien; Visuals liefern Huellen, Fixture/Mapdaten besitzen Fakten.
- Erster begrenzter Grafikumbau ueber vorhandenen Karten-/Themen-/Objektpfad;
  Topologie bis in MapEditor-/MissionTestSetup-Registries durchreichen; aktuell
  verlieren diese bestehenden Aufrufer den optionalen Hex-Parameter. Ein neuer
  explizit thematisierter Hex-Kartenabschnitt startet ueber den regulaeren
  Kartenpfad, nicht ueber den Test-Fixture-Driver. Alte Karten bleiben square8.
- Keine neue Basisbau-/Innenraum-/Tuer-/Flug-/Wirtschaftssimulation, keine
  Schiffsuebernahme aus Astra, kein pauschaler Gameplay-/Releaseumbau oder Merge.

## Basis / Contracts
Bewusste Fortsetzung des unintegrierten task/grafikreferenzen-20261101 auf501201b0c.
PROJECT_BRIEF, ARCHITECTURE, CODEX_RULES, IMPLEMENTATION_STATUS, TASK_ROADMAP;
graphics_reference_revision_contract, html_report_workbench_contract,
terrain_truth_visual_audit_contract, hex_grid_v1_contract und relevante Theme-/Mapcontracts.

## Betroffene Dateien / Besitz
Root: frontier_art_dressing.gd, Wege-/Ankerhelper, Preview/Capture/Integrationstest.
Read-only-Reviewer: Pad-/Gebaeudeanker, sichtbare Fehlerursache und Runtime-Einstieg.
Separater Runtime-Slice nach Audit: MapEditor/MissionTestSetup und bestehender
TerrainMapData/Registry/View-Themenpfad plus eine kleine authorierte Hexkarte.
Report: neuer P07-Bereich, bytegleiches P06-Archiv und Kamera-Vergleiche/BrowserQA.
Geologie/Schiffs-/Citizenquellen und Referenzen bleiben erhalten.

## Akzeptanz / lokale Pruefung
- P06-Bilder und neue native gleiche Kameras wirklich oeffnen; Eingangslage,
  letzte Tangente, Rampenueberlappung, Markierungsauflage und Normalen pruefen.
- Grafikfehler mit isoliertem Renderer-/Layer-Vergleich diagnostizieren und
  passend regressionssichern. Keine blind abgeschwaechten alten Tests.
- C, Hex-Picking/Bewegung, GLB-/Geologiehuellen, Autoritaet und alte Karten
  bleiben gueltig. Neue Grafik nur einmalig/dirty aufgebaut, keine Hotpathscans.
- Runtime-Integration in einer echten Mapinstanz gegen bestehende Facts testen;
  keine still aktivierte Totalmigration und keine Test-UI als Spielarchitektur.
- Offline-HTML, Notizen/JSON-Export und Desktop/Mobil frisch pruefen; alte
  Bilder/HTML bytegleich sichern. Technische Gates und Nutzerurteil trennen.
- Relevante Quellen, Doku und Belege committen/pushen; unintegrierten Branch benennen.

## Umgesetzt / Pruefstand
- Gemessene Eingangs-/Padanker gemeinsam genutzt; Halle um37cm korrigiert,
  letzte Kurvenabschnitte gerade. Apron/Rampentoe14mm und Tritt57mm verbunden.
  Neutraler Tritt im C-Schnitt schliesst den Anschluss ohne doppelte Deckflaeche.
- Schwarzer Saum als Normalenfehler an Union-Mikroslivern reproduziert;
  UP-Normalen beseitigen ihn bei aktiven Schatten/SSAO. Padleisten aus echtem
 3D-Span abgeleitet. Wege23/23, Rails56/56; alle20finalen Previewbilder geoeffnet.
- Regulaere gespeicherte24x20Hexkarte mit thematisiertem Boden/Pflaster, einem
  Utility-Katalogmodell und sieben gespeicherten Reservierungen. Map/Editor/
  Registry/Mission haben dieselbe Topologie; normale Units/FTL statt Previewactors.
  Native40/40 und vier echte Editor-/Missionskontrollen; Leaderbewegung645px
  ueber13legaleHexzellen ohne Spruenge oder reservierteZellen.3xDiagnosetempo,
  kein vollstaendiger Missions-/Deployment-/Performance-Abnahmelauf.
-27fokussierte strengeChecks bestehen als explizite Kombination aus26Gates
  und gruenemHex-Bewegungsretry. Der urspruengliche FileOpen-Timeout bleibt
  unveraendert erhalten; nur der Verifier-Evidencewriter erhielt optionalen
  privatenAusgabepfad/Close/Fehlerausstieg, keine geaenderte Simulationsassertion.
  Nachweis: output/grafik_20261101/pass07_paths_check_runs/verified_combined/metadata/report.json.
- TASK158/159 bleiben mit13/6Fehlern rot. Isolierter ausgefuehrter501201b0c-
  Vergleich belegt dieselbenLabels in gleicherFolge, keine zusaetzlichenFehler.
  Nicht als grueneGates verkaufen. Beleg: pass07_runtime/legacy_baseline_comparison.json.
- NeueFlatmap von480Cliff-Hinweisen bereinigt(edge_type=none); verbleibend
  ein no_cover_tiles-Authoringhinweis. Keine erfundene Cover-/Basisbaumechanik.

## HTML-Abschluss
P06-HTML und20Vorher-PNGs bytegleich archiviert. P07-Workbench mit39Bildern,
12festenPreviewpaaren und4getrennten regulaerenKartenkontrollen, Quellstatus,
Notizen/Entscheidungen undJSONexport.238/238frischeBrowserchecks samtSichtpruefung,
78Derivate,37geoeffneteScreenshotlayouts,3echteDownloads; keine externenRequests,
Console-/Pagefehler. ErstesQA-Archivpfad-Oracle korrigiert, Erstlauf erhalten,
HTMLbytes blieben unveraendert. ExakterSHA256:
9b24e1089961ad58c6f21dcb99f7fd299458e755469114bd066be946f96c03c0.
Code278c5b61fb6a1584420fbfaa4e526c30640fea69 erfolgreichgepusht;
Bericht/Browserbelege eigenesUebergabepaket, keine Main-Integration.

## Verbleibende Grenzen
Die Formulierung Grafik-/Spielaufbau wird als Grafikumbau im bestehenden Spiel
verstanden, nicht als Auftrag fuer neue Bau-Gameplaymechanik. Der erste Slice
ersetzt nicht die gesamte Kampagnen-/Editor-/Assetmigration oder Releaseabnahme.

## Begrenzter Runtime-Slice: Versorgungshof (ship_sources)
- Eigene Dateien: `scripts/terrain/terrain_map_3d_view.gd` (gespeichertes Theme
  und expliziter Profiloverride), `data/terrain_surface_visual_theme_catalog.json`,
  `data/terrain_tile_catalog.json`, `data/terrain_3d_asset_mapping.json`,
  Registry-Aufrufe in `scripts/editor/map_editor.gd` und
  `scripts/tests/mission_test_setup.gd`.
- Neuer Inhalt: `maps/frontier_workyard_24x20.json`,
  `data/mission_scenarios/frontier_workyard_24x20.json`, reproduzierbarer Generator
  `scripts/tools/generate_frontier_workyard_24x20.gd` und enger Verifier
  `scripts/tests/frontier_runtime_map_slice_verifier.gd`. Genau ein vorhandenes
  `structures_pass04/utility_fuel_01.glb`; keine neuen Modellbytes.
- Hex/Theme werden gespeichert; feste Utility-Footprintzellen werden beim
  Authoring einmalig gesetzt. Renderer liest die Fakten, kein Runtime-BBox->Nav.
  Profilwahl: explizites true/false vor CLI-Default vor Karten-Theme;
  Override zuruecksetzen folgt wieder CLI/Theme. Keine Renderrekursion.
- Echte Editor-Save/Reload-/Live-Missioninstanzen und FTL-Bewegung pruefen;
  keine Preview-Akteure oder Teleports als Integrationsbeleg. Alte square8-Karten
  und explizite Preview-Profilwahl bleiben erhalten. Eigene native Bilder/JSON
  unter `output/grafik_20261101/pass07_runtime/`, Quellen-/QA-Doku unter
  `art/frontier_illustrated_20261101/environment/pass07/runtime/`.
- Nicht Teil dieses Slices: mehrzelliges Gebaeude-/Pad-Authoring, Rampen-Gameplay,
  vollstaendige Hexmigration aller Editorwerkzeuge, Meta-/Multiplayer-Adoption,
  Root-Preview/Wege/Report/Git.
- Die tatsaechliche regulaere Missions-PackedScene setzt schon vor diesem Slice
  `defer_friendly_runtime_activation=false`; der Meta-Pfad waehlt seinen Wert
  separat. Die Editor-Live-Test-API und Startpolicy bleiben deshalb unveraendert.
  LZ/Dropship-Deployment werden nicht als durch diesen Authoringlauf bewiesen
  ausgegeben. Die Profilroute unterscheidet gespeichertes graugruenes Pflaster
  vom Rostboden; generische Strassen erben keine positionsgebundenen Previewspuren.
- Runtime-Ergebnis:40/40headless und40/40native, vier geoeffnete regulaere
  Editor-/Missionkontrollen. Flatmap-Authoringfehler480xCliff korrigiert,0Errors
  und1ehrlicher No-Cover-Hinweis. Eigene12erMatrix effektiv10Pass/2Altfehler;
  TASK15829/13 undTASK15986/6 exakt mit ausgefuehrter501201b0c-Baseline verglichen.
  Kein pauschales Allgreen. Aktuelle fokussierte27Gates bestehen konsolidiert
  aus26Pass plus privatem25/25Hexbewegungsretry; Originalreports bleiben erhalten.
  Paket: `art/frontier_illustrated_20261101/environment/pass07/runtime/manifest.json`.

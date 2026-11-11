# Polisa R07: Basis-Pad als verbindlicher Massstab

## Ziel / Ursache
Nutzer bemerkt unplausible Pad-/Hexgroessen, versetzte Ringe, geknickt wirkende Ausleger und kein erkennbares Hexraster. owningQuelle maps/homebase_frontier_exploration.json.homebase_exploration.landing_pads[0/1].size ist8x6 bei hex_axial_v1. R06-S18x20 war7.5fach so gross in der Flaeche. R06 wurde noch nicht committed; seine Aufnahmen bleiben historischer Zwischenstand, kein akzeptierter Massstab.

## Umfang / Nicht-Ziele
Einen Globusraum mit fuenf Shops, sieben Pads, zwei Ringen und aeusseren Auslegern erhalten. S exakt8x6 aus kanonischer Heimatbasis-Authoringquelle ableiten. VorlaeufigM12x12,L16x24 als davon abgeleitete Spielgroessen (L doppelte M-Laenge). Komplex passend zu unveraenderten Figuren kompakter anordnen, keine Menschen oder Schiffe heimlich skalieren. Lokale Map512x256, A/B/C512x256, Sternkarte256x256 unveraendert. Keine Schiffsdocking-/Komponenten-/Save-/Tabletopowner-Erweiterung.

## Vertraege / Quellen
graphics_reference_revision_contract.md, polisa_static_deck_visual_contract.md, polisa_ship_equipment_contract.md; maps/homebase_frontier_exploration.json und scripts/meta/base_capacity_layout.gd bestaetigen8x6 fuer vorhandene und neue Basispads. R06-KI-Konzept bleibt Stilhilfe, kein Groessenbeleg. R06-Task ist in der Geometrie ueberholt.

## Akzeptanz
- S-Pad hat exakt dieselbe Weltflaeche und Kantenlaenge wie Heimatbasis-Pad. Quelle/Hash und Ableitung dokumentieren; kein anderer Hex-/Render-Massstab.
- M/L sind transparent von S abgeleitet; L-Laenge=2xM. 7Padanker bleiben, alle gespeicherten Fusswege/Blocker stammen aus gemeinsamem Layout.
- Zwei parallele Ringe haben exakt dieselbenY-/Z-Mittelpunkte auf einer geradenX-Stationsachse; dickere Ringquerschnitte. Ausleger/Verzweigungen sind gerade/orthogonal ohne Hoehenknicke.
- Hauptblick zeigt Shops, Globusraum und Anordnung; zusaetzlicher naher Raster-/Padvergleich macht echte einzelne Hexzellen lesbar. Keine gerenderte Dekortextur als Hexnachweis.
- GanzeMap bleibt erreichbar; Figurengroessen unveraendert. Gefuehl grosser Station entsteht aus Form/Masse, nicht aus riesigen Padflaechen.

## Dateien / Aufteilung
Artagent privat art/polisa_r07_20261111 und output/native_glut_maps/polisa_r07_20261111. Root danach maps/polisa_station.json, Produktvisual, Buildskript, bestehende Kamerafunktionen und begrenzte docs/qa/polisa_r07_20261111. Produktkarten38bc35468 und ausgelieferter Korridorcache bleiben gueltig. Keine fremden Ownerdateien bearbeiten.

## Lokale Pruefung / Risiken
Nur kleine Quelle-/Groessen-/Graph-/Compilechecks sowie angeforderte native Bilder; grosse Tests bleiben spaeter. Gefahr erneuter Einheitenverwechslung: Basis-/Polisa-Pad im identischen Camera-/Grid-Massstab gegenueberstellen. Zoombedingte Subpixel-Hexe sind keine lesbare Nahansicht. Keine Lande-/Schiffsfitfreigabe fuer neue Modelle aus Padabmessungen ableiten.

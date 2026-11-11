# Polisa R06: ein kompakter Stationskomplex

Status: Geometrie nach Nutzerfeedback in R07 ueberarbeiten. R06-S18x20 entspricht nicht dem kanonischen8x6-Heimatbasis-Pad. R06 blieb uncommittet; aktueller Auftrag POLISA_HOME_PAD_SCALE_R07_2026_11_11.md.

## Ziel / Ursache
Nutzerkorrektur: 1024 ist zu gross. Statt dreier wiederholter Sektoren nur ein schoener, maechtiger Globusraumkomplex mit Ringen und Auslegern; gute KI-Illustration als Leitbild. R05-Stationsgeometrie ist verworfen, nicht produktiv integriert. R05-Produktkarten38bc35468 bleiben gueltig.

## Umfang und Nicht-Ziele
512x256 lokale Stationskarte, EIN Globusraum, fuenf von derselben Kamera einsehbare Shops, zwei gerade grosse Ringe und aeussere Solar-/Dockingausleger. Sieben Pads nach zuletzt gewuenschtem Muster: L mittig (80 lang), zwei M links nebeneinander (40 lang), vier S rechts in2x2. Keine verkleinerten Menschen; Figuren-/Ausrustungsmodelle unveraendert. A/B/C512x256 und strategische Sternkarte256x256 bleiben bestehen. Kein neues Docking-/Komponenten-/lokales Schiffslieferungs-Gameplay, keine Tabletopowner-Arbeit in diesem Task.

## Referenzen / Vertraege
graphics_reference_revision_contract.md, polisa_ship_equipment_contract.md, R05-Task als verworfener Geometrievorlaeufer. art/polisa_r06_20261111/references/station_concept_ai.png ist neuer KI-Entwurf, keine native Evidenz; Eingabe war R05-KI-Konzept, eingebautes imagegen am2026-11-11. Prompt daneben, Originalausgabe exec-03a76cc0-aeac-4e59-b03e-0119a289be2a.png im Codex-generated_images-Ordner erhalten. Fan-/Originalreferenzen aus art/polisa_r05_20261111/references ergaenzen nur den Stil.

## Akzeptanz
- Gemeinsame Layoutquelle fuer Karte, Blocker, Anker und native statische Geometrie; technische Fuellbereiche bleiben gesperrt.
- Ein zentraler Globusraum, fuenf Shops, sieben Pads, zwei gerade Ringe, aussen Ausleger; normaler Blick zeigt Waren ohne Drehung.
- 512x256 mit kleinem freien Vorfeld; ganze Station durch regulaeren Zoom erreichbar.
- Lesbares echtes Deck-Hexraster; statischer lebender Deckowner vermeidet doppelte H0-Kappen und kamerabedingten Rasterneuaufbau. Kein neuer Navigationsstate.
- Native Nah-/Ganzkartenbilder oeffnen, wenige Source-/Compile-/Layoutchecks. Groessere Tests bleiben wie beauftragt spaeter.

## Betroffene Dateien / Verantwortung
Artagent: art/polisa_r06_20261111 und privates output/native_glut_maps/polisa_r06_20261111. Root integriert maps/polisa_station.json, scripts/terrain/polisa_station_visual.gd, tools/build_polisa_station.py, data/singleplayer/locations.json und begrenzte Visual-/Kamerafunktionen in TerrainMap3DView/MissionTestSetup. Rootmenue bleibt bestehender Commandconsumer.

## Lokale Pruefung / Risiken
Kaltes Deckowner-/Rastercacheverhalten, sichere Zoomgrenzen, Vorfeld-Panning und unveraenderte Nichtstationsgrenzen klein pruefen; Artgraph/Compile plus angeforderte native Ansichten. Riesiger R05-Zwischenstand bleibt historisch, nicht als Produktabnahme zeigen. Keine Main-/EXE-/Gefechts-/Performancefreigabe aus Artbildern.

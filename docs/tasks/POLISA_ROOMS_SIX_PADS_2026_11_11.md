# Polisa R03: groessere Station mit Raeumen und sechs Pads

## Ziel / Ursache
Nutzerkorrektur11.11.2026: Port Olisar ist das deutlich staerkere Formziel. Polisa soll groesser werden, echte Ladenraeume mit ausgestellten Waren/Ruestungen erhalten und auf der Hexkarte gezeigt werden. Die vorherige offene kleine Kioskhalle entspricht diesem Ziel nicht.

## Verbindlicher Umfang
- Laengsachse links/rechts im gezeigten Bild entspricht WeltX: dort Ringe und Solarzellen, keine Pads.
- Vorne und hinten je drei Pads: zwei kleine und ein grosses, insgesamt sechs.
- Grosse Pads erhalten eine geometrisch begruendete Reserve fuer eine spaetere Caterpillar. Das Schiff wird dadurch weder importiert noch spielbereit.
- Echte verbundene Raumflaechen mit Waenden, Tueroeffnungen und ausgestellten Gegenstaenden; Lesbarkeit durch Cutaway.
- Gemeinsame Layoutdatei speist Karte, Blocker, Marker und Visual. Bestehende Orts-/Service-/Rueckkehr-IDs bleiben erhalten, sechs Padmarker werden angeboten.
- Polisa darf ein groesseres eigenes lokales Hexraster erhalten; A/B/C512x256 und Sternkarte256x256 unveraendert.
- Sichtbares natives Hexraster; dessen Linien duerfen nicht unter dem Stationsdeck liegen.

## Quellen und Grenzen
Port-Olisar-Referenzen aus art/polisa_lookdev_20261111, bestehender R02-Stand f06ae7f69 und native Bilder in docs/qa/polisa_lookdev_20261111. graphics_reference_revision_contract, explicit_hex_ramps_contract, bestehende Orts-/Orbit-/Supplyvertraege. Kein neues Schiffsausrustungssystem, kein lokaler Schiffskauf, keine Tabletop-Owneraenderung.

## Dateien / Vorgehen
Privater Kandidat art/polisa_r03_20261111 und output/native_glut_maps/polisa_r03_20261111; nach Sichtung gezielte Integration in Stationsmap/-builder/-visual. Root bindet Pads in data/singleplayer/locations.json an. Enger TerrainMap3DView-Fix ausschliesslich fuer stationaere Hexlinienhoehe. Vorherquelle bleibt inGit/Art erhalten.

## Akzeptanz / lokale Pruefung
Gemeinsame Layoutdaten, erreichbare Raum-/Padmarker und endliche zusammenhaengende Decks pruefen. Wenige native Ansichten: gesamte Station mit sichtbaren Hexen sowie Laden-/Ruestungsnahansicht. Bilder oeffnen, Unterschied zur Referenz und offene Punkte benennen. Nur enges Compile und kleine Datenpruefung, keine grossen Reise-/Gefechts-/Save-/FPS-Matrizen.

## Risiken / spaeter
Das grosse Pad ist eine Platzreserve, keine nachgewiesene Caterpillar-Landung. Neue Stationsgeometrie benoetigt spaeter echte Reise-/Shop-/Aussteigenabnahme. Gebaeudecaps und Rasterdarstellung bleiben Leseschichten; Navigation stammt aus MapData.

Erstbildkorrektur: Raster lag nicht nur unter Deck, sondern wurde im Gesamtbild durch den bisherigen Distanzfade auf8Prozent Kontrast reduziert. Optionaler Shaderparameter distant_contrast_floor behaelt Default0.08 fuer andere Karten; nur Stationsmaterial mit eigenem Cachekey nutzt0.5 und eine passende Linienfarbe. Native Endansichten pruefen sichtbare Hexe.

Durch die nachfolgende Nutzerkorrektur auf R04 ersetzt: fuenf Frontpads und zentrale Globuslobby. R03 ist nur historischer Art-/Layoutkandidat; nicht als aktueller Produktstand verwenden.

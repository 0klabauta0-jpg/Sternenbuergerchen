# Polisa R07: Heimatbasis-Massstab und lesbares Raster

R06 war in der Padflaeche ueberdimensioniert (S18x20 statt8x6). R07-S liest8x6 direkt aus maps/homebase_frontier_exploration.json.homebase_exploration.landing_pads; die normale und erweiterte Basis verwenden dieselbe Groesse. Alle vier S-Pads haben diesen Umriss einschliesslich Randgeraeten. M12x12/L16x24 sind transparent abgeleitet. Lobby28x20, Shops12x12, keine Figurenskalierung. Lokale Map512x256 bleibt.

R07-Grundform wurde vom Nutzer als gut/sehr gut bestaetigt. AnschlussauftragR08: Ringe/Solars/Ausleger moderat vergroessern, Achse etwas nach hinten unter den Weg, Ports sichtbar zeigen, gefasste Wand-/Tuerdurchgaenge. R07 ist deshalb ein gesicherter Grundformcheckpoint, keine Behauptung aller Anschlusswuensche.

Root-Produktion: maps/polisa_station.json, bestehender Produkt-Scenepfad und scripts/terrain/polisa_station_visual.gd aus R07. tools/build_polisa_station.py liefert Layoutableitungen, kamerafocus/preset und Kamerabounds. Keine neue Gameplaywahrheit; Wuerfe/Blocker/Picking bleiben MapData/Registry. Das ganze statische Deckraster bleibt resident und erzeugt keine Kamerarebuilds; erhoehte Tilevisuals/Objekte bleiben erhalten.

Stationsraster wurde wirklich kontrastreicher und mit2.2Pixel-Mindestbreite gezeichnet. Keine Hex-/Weltgroessenveraenderung. Frische native PRODUKT-Aufnahmen (native_product_station) geoeffnet: Standardansicht zeigt nun einzelne Hexe, Padnahbild macht S-Felder klar erkennbar; komplette512erKarte separat. Exit0/errors0/warnings0. 21720statischeDreiecke/10Batches plus22472R07Schaukastendreiecke/6Meshes; echtesRaster15590Dreiecke/1Mesh, keine Einzel-Tilenodes. Keine FPSabnahme.

pad_scale_comparison.png ist ein expliziter isolierter Vergleichsaufbau mit den echten Basis-/Polisa-Padbuildern, identischer Orthokamera und kanonischen HexGrid.corners. Die Polisa-Deckplatte entspricht unveraendert dem Deckfact; Vergleichsraster liegt fuer beide sichtbar ueber der Platte. Keine Kampagnenszene und keine Behauptung, dass das Basis-UI standardmaessig dieses Raster zeigt. Finaler Lauf native_pad_scale_layout_fixed Exit0/errors0/warnings0, Bild geoeffnet; erste Aufnahme hatte falsch platzierte Vergleichstexte, nur deren Position wurde korrigiert.

18Offlinechecks gruen:4486Tiles/2358begehbar verbunden/2128gesperrt, alle7Pad-/5Raumanker und Globusumlauf. Basisquellenhash und exakt8x6 kontrolliert. deck_camera_check10/0 fuer Owner/Fallback/erhoehteKappe/Bounds/Zoom und Nichtstationsgrenzen. Keine grossen Reise-/Save-/Netz-/Gefechts-/Performancepruefungen; Main/EXE separat.

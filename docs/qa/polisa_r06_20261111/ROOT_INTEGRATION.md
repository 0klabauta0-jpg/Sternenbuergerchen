# Polisa R06: kompakte native Integration

Neueste Nutzerkorrektur umgesetzt: nur ein Globusraum-/Shopkomplex auf512x256. R05 mit drei Sektoren und1024x512 wurde verworfen und nie als Produktkarte integriert. Bestehende Produktkarten38bc35468 gelten weiter; neue Station hat sieben Pads nach dem letzten gewuenschten Muster.

Produktion verwendet maps/polisa_station.json und scenes/terrain/polisa_station_visual.tscn mit scripts/terrain/polisa_station_visual.gd. tools/build_polisa_station.py baut aus art/polisa_r06_20261111/layout.json/Compiler; baseline_r04 ist lokal archiviert und keine untracked Output-Abhaengigkeit. Props werden genau einmal an den Stationsorigin verschoben, presentation.pads bleibtleer. locations.json bindet alle sieben Padmarker an. Pad01/02=M,03=L,04..07=S; Spawn/Rueckkehr bleiben auf01. Keine neue Landungs-/Schiffsdockingfreigabe.

Root-Ergaenzungen gegenueber Artkandidat: Produkt-Scenepfad/Name, station_camera_focus und station_initial_camera aus dem Layout, visual-only space_bounds_plane auch in place_presentation fuer den Kameraconsumer. Tile-/Blocker-/Raum-/Padfakten und native Geometrie sind dieselben. Separates root_integration_manifest.json dokumentiert integrierte Bytes; das Artmanifest bleibt historischer Freeze.

Kleine lokale Pruefung:15 Offline-Authoringchecks gruen (30384Tiles,17365begehbar verbunden,13019gesperrt; Anker/Padreserven/Globusumlauf erreichbar). deck_camera_check.gd:10/0 fuer lebenden Owner, ganzes residentes Raster, keine doppelten H0-Kappen, erhoehte Kappe bleibt, Vorfeldbounds, fehlendenOwner-Fallback, begrenztes/ungueltiges Zoomlimit und unveraenderte Nichtstationsgrenze. Kein grosser Testlauf.

Root-Nativlauf `native_product_station`: echte PRODUKTKARTE und PRODUKTSCENE, D3D12/Forward+, Exit0/errors0/warnings0. Beide PNGs wurden geoeffnet. Standardbild zeigt die fuenf Shoparten ohne Drehung, Globusraum und sieben Pads; Ring-/Solarteile liegen in dieser Nahansicht ausserhalb. Ganze Karte zeigt Rahmen, beide Solar-/Portarme und freies Vorfeld. Einmaliges gebatchtes Deckraster; echte Hexe sind im weiten Blick klein. 28320statische Dreiecke/10Batches +22472R07-Schaukastendreiecke/6Meshes; drei bestehende deaktivierte Rigs, keine neuen Kollisionen. Raster108328Dreiecke/1Mesh. Das ist keine Frameratefreigabe.

Gestalterische Grenze: die Grundform folgt dem KI-Leitbild, das native Primitive-Modell erreicht dessen feine Konturen/Moeblierung noch nicht vollstaendig. Die fuenf grossen Innenraeume wirken im weiten Blick leerer; Figuren-/Waren-/Globusdetails sind klein. Keine persoenliche Stilabnahme behauptet. KI-Bild ist Konzept, nicht nativer Screenshot.

Keine echten Flug-/Lande-/Kauf-/Save-/Gefechts-/Netztests in diesem Paket. Produktmenue und einzelner Kaufbutton wurden separat im privaten Supply-Stand belegt (R05-MENU_README). Main/EXE bleiben separate Schritte; grosse Tests wie beauftragt spaeter.

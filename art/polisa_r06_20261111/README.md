# Polisa R06 — eingefrorener privater Kandidat

Ein großer Stationskomplex auf 512×256 ersetzt den ausdrücklich verworfenen R05-Entwurf mit drei Sektoren. Root-UI38bc35468 bleibt gültig. Dieses Paket ist ein Integrationskandidat, keine Nutzerabnahme. Der Artagent hat keine Produktionsdateien geändert und weder committed noch gepusht.

## Ergebnis und Bildsichtung

Beide finalen nativen Bilder wurden tatsächlich geöffnet:
- `output/native_glut_maps/polisa_r06_20261111/polisa_r06_station_near.png`
- `output/native_glut_maps/polisa_r06_20261111/polisa_r06_whole_map.png`

Der zentrale Globusraum, alle fünf offenen Shopräume einschließlich Fracht, sieben Pads und zwei große gerade Ringe sind umgesetzt. Die Nahkamera zeigt alle Raumarten ohne Drehung; große Ringe dürfen am Bildrand angeschnitten sein. Figuren und einzelne Waren bleiben bei diesem weiten Blick klein. Das echte Hexraster liegt vollständig über dem Deck und ist als feines Muster sichtbar; in der Ganzkartenaufnahme sind einzelne Felder durch den größeren Abstand kaum getrennt auflösbar. Die Übersicht zeigt den kompletten Kartenrahmen, beide Solargruppen, beide äußeren Ports und das freie Vorfeld. Keine Aussage über ästhetische Freigabe oder detaillierte Rüstungserkennbarkeit aus der Gesamtkarte.

R06 übernimmt aus dem neuen, tatsächlich geöffneten KI-Konzept kräftige Fasen an den Ringquerschnitten, segmentierte Ringblenden, Cyan-Inlays, geschichtete Tragglieder und Tanks unter dem Koncourse. Technische Rückflächen sind kompakter als bei R05. Die Umsetzung bleibt ein stilisiertes Godot-Modell aus gebatchten Primitives; sie ist kein pixelgleicher Nachbau der Illustration.

## Verbindliche Geometrie

- Lobby72×44, fünf Shops je28×28; eine blaue Globuskonsole mit freiem Umlauf. Hinterwände3.3hoch, seitliche Cutaway-Wände1.05, vordere Schaufensterbrüstungen.65. Wand-/Möbelrechtecke bilden dieselben Blocker wie die Karte.
- Ein L-Pad40×80 in der Mitte; links zwei M-Pads28×40 nebeneinander; rechts vier S-Pads18×20 in2×2. Die L-Länge ist exakt die doppelte M-Länge. Freie Innenreserve jeweils3Einheiten von den Deckrändern. Keine Caterpillar-Landungsfreigabe.
- Zwei YZ-Ringebenen beiX±120, Yaw0, Durchmesser112; RinghubY−30/Z46. Verbleibende Speichen liegen unter dem Deck, kein Hindernis durch den Koncourse.
- Äußere Solarflächen beiX±177, je44×44. Zwei Ports beiX±227 mit geometrischer Reserve42×98 ablokalemZ82 bis180. Die Reserve beginnt vor den eigenen Greifarmen. Keine neue Dockingmechanik oder Schiffsauslieferung.
- Stationsorigin(0,−48), deklarierte Weltraumgrenze[-256,−90,256,132]. Rückseite bislokalZ−42, L-PadfrontWeltZ84, ungefähr48Einheiten freies Vorfeld. Keine Änderungen an A/B/C oder Sternkarte.

## IDs, Fakten und Integration

`polisa_pad_01` und02 sind die beiden M-Pads;03 ist L;04/05 sind die hintere S-Reihe,06/07 die vordere. IDs01..05 bleiben aus R04 erhalten, ihre Klassen folgen der neuen Nutzeranordnung. `spawn_alpha` und `ship_return` liegen auf01, `spawn_bravo` auf05. `trade_service` und `objective_point` bleiben in der einzigen Lobby. Exakte Hex-/Isoanker stehen in `offline_checks.json`. Interner SektornameB dient nur der historischen ID-Zuordnung; das Visual zeigt keine Mehrsektorenbeschriftung.

`place_presentation.pads=[]` verhindert doppelte Frontier-Paddarstellung. Propcenter=origin_plane wird genau einmal angewandt. Root bindet die sieben Landing-Pads in locations.json an. Der nach erfolgreichem Bodenbau gesetzte Node-Metawert `station_deck_owns_flat_ground=true` erlaubt dem RootView, doppelte H0-Kappen zu vermeiden und das eine gemeinsame Raster resident zu halten. Er erzeugt keinen neuen Gameplayowner.

Standardkamera: Size135, Yaw24, Pitch50, Fokus lokal(0,44), Weltplane(0,−4), Iso(256,−128). Übersicht: Size320, Yaw0, Pitch68, Weltplane(0,21), Iso(−1344,672). `station_camera_max_size=360` ist kartenspezifisch. Native Dateien sind1280×720, D3D12/Forward+, Godot4.6.2, privates absolutes Profil, verborgenes Fenster.

## Reproduktion und Quellen

1. `python art/polisa_r06_20261111/author_layout.py` erzeugt die gemeinsame editierbare layout.json.
2. `python art/polisa_r06_20261111/build_candidate.py` erzeugt layout_compiled.json, die private Kandidatenkarte und Offlinechecks.
3. `python art/polisa_r06_20261111/build_layout_svg.py` erzeugt die abgeleitete Draufsicht.

Die zwei eingefrorenen R04-Inputs unter baseline_r04 sind im Paket enthalten. Kein Buildinput stammt aus untracked Output. Die komplette reproduzierbare R04-Archivquelle bleibt zusätzlich unter art/polisa_r05_20261111/baseline_r04 erhalten; ihr Reproduktionshash wurde in R05 exakt bestätigt. R05 selbst bleibt ausdrücklich verworfen. GDScript+ArrayMeshes sind die editierbare Modellquelle.

Neue R06-KI-Referenz: `references/station_concept_ai.png`, Root-Prompt daneben. Frühere Port-Olisar-Quellen und Sichtungsgrenzen sind in art/polisa_r05_20261111/SOURCE_REFERENCE_NOTES.md dokumentiert. Keine externen Meshimporte. Vorhandener operator.glb plus personnel_armor_visual.gd verwenden unveränderte R07-Körper-/Rüstungsassets, drei Idle-Schaukästen in Originalgröße mit deaktivierter Verarbeitung. Keine statischen Duplikate oder NPC-Gameplayowner nötig.

## Prüfung und Grenzen

30384 gespeicherte Hexe:17365 begehbar und13019 gesperrt. Eine begehbare Komponente; alle sieben Padanker, fünf Raumanker, Service-/Spawnmarker und Globusumlauf erreichbar. Padreserven und äußere Portreserve frei; technische Zonen vollständig gesperrt. Alle kleinen Offlinechecks grün, Godotcheck-only Exit0. Das ist keine tatsächliche Reise-, Laufweg-, Save- oder Gefechtsabnahme.

Finaler nativer Lauf `r06_final`: Exit0, errors0, warnings0. Statische Station28320Dreiecke/10Materialbatches; R07-Schaukästen22472Dreiecke/6Meshes, zusammen50792Dreiecke/16Meshes. Drei deaktivierte Rigs,0CollisionObjects,0dynamische Lichter. Echtes Raster: ein Mesh mit108328Dreiecken,54164Kanten, BoundsX[-120.02,120.02]/Z[-75.07285,83.73315]/Y.074. Streaming=false, alle17365begehbaren Deckzellen im Darstellungspfad; keine Einzelmesh-Erzeugung pro Hex.

Es gab zwei gezielte R06-Bildpaare; das erste bleibt als r01_* erhalten. Die einzige Korrektur danach war die angeschnittene Rahmenbeschriftung und das Entfernen der alten Sektor-B-Beschriftung. GPU nach Sichtung freigegeben. Keine größere Testmatrix und keine Performance-/Releasefreigabe aus diesen Bildern.

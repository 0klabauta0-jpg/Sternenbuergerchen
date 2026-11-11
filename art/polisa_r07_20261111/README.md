# Polisa R07 — Heimatbasismaßstab

Privater eingefrorener Kandidat auf Rootstand472f1ad8f. R07 korrigiert die übergroßen Pads und leeren Räume aus R06. Keine Personenverkleinerung, keine Produktionsdateiänderung und kein Commit/Push durch den Artagenten. Root besitzt Produktintegration und den zusätzlichen Heimatbasisvergleich.

## Maßquelle und sichtbares Deck

`author_layout.py` liest die owning Quelle `maps/homebase_frontier_exploration.json`, JSON-Pointer `/homebase_exploration/landing_pads/0/size`, und verlangt Übereinstimmung mit Pad1. Beide besitzen aktuell8×6 in derselben `hex_axial_v1`-Welt. Der Quellenhash lautet `ef39df8b1028f98f7b9710886966c79e97e012ec61614c87da28a5e22865dcb1`. Pfad, Pointer, Hash und Ableitungsfaktoren werden in layout.json gespeichert und vom Compiler nochmals geprüft.

| Klasse | Ableitung von S | Deck | Innenreserve |
|---|---|---|---|
| S | owning Heimatbasispad | 8×6 | 6.7×4.7 |
| M | Breite×1.5, Tiefe×2 | 12×12 | 10.7×10.7 |
| L | Breite×2, Tiefe×4 | 16×24 | 14.7×22.7 |

Die Reserve lässt0.65 pro Seite frei. L ist doppelt so lang wie M. Das sind Layoutreserven, keine Schiffsfit- oder Dockingfreigabe. 8×6 beschreibt Weltmaße, nicht die Behauptung eines rechteckigen8×6-Hexindexes.

S-Deck, Fase und Unterbau halten exakt die8×6-Hülle ein. Es gibt keine außen angehängten Gerätekästen, welche das kleine Pad optisch vergrößern. Die0.18breiten Beacons liegen innerhalb des Randes; Serviceflächen sitzen unter Deck. Kleine Labels mit pixel_size.022 ersetzen die großen R06-Texte; zusätzliche Strichgruppen wurden entfernt. Das tatsächliche Mapraster bleibt unverändert groß.

## Komplex und Achse

Ein Globusraum28×20 mit fünf Shops12×12 ersetzt Lobby72×44 und Shops28×28. Die existierende Globuskonsole, drei R07-Schaukästen und operator.glb bleiben in derselben Originalgröße. Rückwände3.3hoch, niedrige seitliche/Front-Cutaways und3.6breite Türen zeigen alle fünf Raumarten ohne Kameradrehung. Frachtwaren sind im rechten Raum sichtbar. Beim Offlinecheck gefundene isolierte Möbelzwischenräume wurden durch kleine Möbelverschiebungen an die Laufwege angeschlossen.

Zwei parallele YZ-Ringe stehen beiX±42. Beide lesen dieselbe MitteY−12/Z21, Radius24 und Breite3.2, Yaw0. Eine einzige gerade X-Achse läuft von−82 bis82 durch beide Hubs; es gibt keine abgesetzte Hauptachse auf anderer Höhe. Solarstreben verlaufen orthogonal inZ beiX±60 und exaktY−12. Solarpanelaufbau hat nur seine natürliche Materialdicke darüber. Äußere Ports stehen beiX±76 aufderselbenAchse; ihre Vorwärtsreserve18×42 ablokalemZ34 ist rein geometrisch. Radiale Ringspeichen bleiben unter dem Laufdeck.

Stationsorigin(0,−70), technische Rückkante lokal−20/Welt−90, deklarierter Weltraumrahmen[-256,−90,256,132]. 512×256 bleibt beibehalten. Die Station nimmt im ehrlichen Gesamtbild deshalb weniger Raum ein; das wurde nicht durch Skalieren von Menschen oder Ändern des Hexrasters verdeckt.

## IDs und Produktionsübergabe

Pad01/02 sind links M,03 mittig L,04/05 rechts die hintere S-Reihe,06/07 die vordere. `spawn_alpha` und `ship_return` liegen auf01, `spawn_bravo` auf05; `trade_service` und `objective_point` liegen im Globusraum. Alle Marker werden auf begehbare Hexmitten gesetzt. Exakte Grid-/Plane-/Isoanker stehen in output/offline_checks.json.

`place_presentation.pads=[]` verhindert zusätzliche Frontier-Padmodelle. Der Visualprop erhält origin_plane genau einmal als Platzierung. `station_deck_owns_flat_ground=true` bleibt das lebende reine Darstellungsmetadatum für RootView; kein neuer Navigationsowner. `station_camera_max_size=360` bleibt kartenspezifisch.

Nahkamera: Size62, Yaw24, Pitch50, Fokus lokal(0,14), Weltplane(0,−56), Iso(3584,−1792). Übersicht: Size320, Yaw0, Pitch68, Weltplane(0,21), Iso(−1344,672). Für den optionalen isolierten Padvergleich kann Root `_build_pad(pad04)` und `_flush()` vor dem Einhängen des Visualnodes aufrufen; bereits vorhandene Kinder verhindern den automatischen Gesamtbau. Das isolierte Pad braucht zusätzlich die unveränderte8×6-Deckplatte aus der gemeinsamen Strukturprojektion, da `_build_pad` selbst nur Hülle/Markierung/Beacons zeichnet.

## Reproduktion / Referenzen

1. `python art/polisa_r07_20261111/author_layout.py`
2. `python art/polisa_r07_20261111/build_candidate.py`
3. `python art/polisa_r07_20261111/build_layout_svg.py`

Die aktuelle Heimatbasisdatei ist absichtlich owning Buildinput. Die historische R04-Metadatenkarte liegt eingefroren unter baseline_r04; kein Input stammt aus untracked Output. GDScript/ArrayMeshes sind die editierbare Modellquelle. Referenz ist die tatsächlich betrachtete R06-KI-Illustration unter art/polisa_r06_20261111/references: Materialgliederung, Ringfasen und offene Shops bleiben Stilziel; ihre Proportionen werden durch die neue owning Maßquelle und layout_target.svg ersetzt. Frühere Port-Olisar-Provenienz bleibt in den R05-Referenznotizen erhalten. Keine Fremdmeshimporte oder neue Rüstungsversion.

## Prüfung, native Bilder und Grenzen

4486 gespeicherte Hexe:2358 begehbar,2128 gesperrt. Eine begehbare Komponente; sieben Pads, fünf Raumanker, Marker und Globusumlauf erreichbar. S-Maße/Quellenhash, freie Padreserven, gesperrte Technik und gemeinsame Ringachse geprüft. Alle kleinen Offlinechecks grün. Ein enger unabhängiger Read-only-Review prüfte owning Padquelle, sichtbaren S-Umriss, gemeinsame Achse und Möbelblocker ohne konkreten Befund. Godot4.6.2check-only Exit0; finaler versteckter D3D12/Forward+-Artlauf `r07_final` Exit0/errors0/warnings0 mit absolutem Privatprofil.

Beide finalen1280×720-Bilder wurden geöffnet:
- output/native_glut_maps/polisa_r07_20261111/polisa_r07_station_near.png
- output/native_glut_maps/polisa_r07_20261111/polisa_r07_whole_map.png

Die Nahansicht zeigt das Hexmuster auf den freien Padflächen sowie den unverkleinerten Globus und die Waren. Das Raster bleibt fein; Root besitzt den zusätzlich angeforderten direkten Basis-/S-Padvergleich bei identischer Kamera. Das Ganzkartenbild dokumentiert die tatsächliche kleine Stationsausdehnung innerhalb des512erRahmens. Es ist keine Detailansicht oder ästhetische Nutzerabnahme.

Native Station:21720 statische Dreiecke/10Batches. Drei deaktivierte R07-Rigs:22472Dreiecke/6Meshes. Zusammen44192Dreiecke/16Meshes,0CollisionObjects,0dynamischeLichter. Echtes Deckraster:1Mesh/15590Dreiecke/7795Kanten, alle2358begehbaren Zellen resident, Streaming=false. Keine Frame-Loops oder NPC-Gameplayowner. Zwei gezielte Bildpaare; die zweite Aufnahme entfernt nur eine überlappende redundante Raumbeschriftung. Erstbilder bleiben als r01_* erhalten. GPU nach Sichtung freigegeben.

Keine große Testmatrix, kein Reise-/Save-/Gefechts-/Performance- oder Schiffsfitnachweis aus diesem Artpaket.

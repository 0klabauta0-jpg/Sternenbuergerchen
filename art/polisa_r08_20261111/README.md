# Polisa R08 — eingefrorener privater Kandidat

R08 erhält die vom Nutzer gelobte R07-Grundform. Es ergänzt größere Ringe und Solarflächen, verlängerte gerade Ausleger, sichtbare Dockköpfe und offene Wanddurchgänge. Keine Produktionsdateien wurden durch diesen Artauftrag geändert, kein Commit/Push erstellt. Root besitzt Integration und Runtime-/UI-Abnahme.

## Änderungen gegenüber R07

- Zwei parallele YZ-Ringe bei X±42: Radius 28 / Durchmesser 56, Breite 3.2, Yaw 0. Beide Mittelpunkte liegen auf Y−12/Z19 statt Z21. Eine gerade X-Achse verbindet sie unter der rückwärtigen Hälfte des Koncourse und reicht bis X±88.
- Vier Solarflächen jeweils 14×22 bei X±63 und Z−7/+45; gerade orthogonale Z-Streben liegen auf Y−12. Keine schrägen Hauptachsenstücke.
- Dockköpfe bei X±82 mit kräftiger heller Einfassung, dunkler Öffnung, Cyan-/Gelbmarkierungen und lesbarem DOCK L/R. Freie Anflugrechtecke sind geometrische Entwurfsreserven, keine Dockingmechanik.
- Neue niedrige Hull-/Glaswand bei Z24 zwischen Pads und Koncourse: fünf offene Durchgänge, jeweils 2.5 breit. Die vorderen S-Pads nutzen ihre bestehenden Anschlüsse über die hintere Reihe.
- Lobbyfront bei Z20 mit 4.0 breitem mittigem Eingang und kurzen Seitenrückläufen. Alle Rahmen haben 2.3 lichte Höhe. Die niedrigen Wandseiten lassen Waren und Rüstungen aus der Standardkamera sichtbar.
- Das große redundante POLISA-Bodenwort wurde nach Bildsichtung entfernt, weil der Eingangsrahmen es zerschnitt. Das obere Stationsschild bleibt.

Die Durchgänge haben ausschließlich den dokumentierten Geometriestatus `open_geometry`. Es gibt keine Türzustände, Interaktionsowner, neuen CollisionObjects oder NPCs. Wände und Lücken stammen aus derselben `layout.json`; der Compiler erzeugt daraus die autoritativen gesperrten Hexfelder. Das Visual liest dieselben kompilierten Fakten.

## Unveränderte Maße und Quellen

S-Pad 8×6 aus `maps/homebase_frontier_exploration.json`, `/homebase_exploration/landing_pads/0/size`, mit geprüftem Peer 1. Owning Quellenhash: `ef39df8b1028f98f7b9710886966c79e97e012ec61614c87da28a5e22865dcb1`. M bleibt 12×12, L 16×24; Sicherheitsrand jeweils 0.65. Der sichtbare S-Deckumriss bleibt exakt 8×6, einschließlich der kleinen Beacons innerhalb der Kante. Keine angehängten Gerätekästen und keine Personenverkleinerung.

Globusraum 28×20, fünf Shops 12×12, mannshohe Globuskonsole und drei bestehende R07-Rüstungsschaukästen bleiben unverändert. Pad01/02 sind M links, 03 ist L mittig, 04/05 sind S rechts hinten, 06/07 S rechts vorn. Spawn/Return/Service-IDs und Markeranker bleiben erhalten; alle exakten Koordinaten stehen in `offline_checks.json`.

512×256 sparse Map, Origin (0,−70), Weltraumrahmen [−256,−90,256,132]. `place_presentation.pads=[]` vermeidet zusätzliches Frontier-Paddressing. `station_deck_owns_flat_ground=true` wird nach dem Bau am lebenden Visualnode gesetzt. Das ist Darstellungsmetadatum für den bestehenden RootView, kein zweiter Navigationsowner. Decktop 0.01 und Markierungen höchstens 0.052 liegen unter dem echten Viewraster auf 0.074.

## Quellen und Reproduktion

Die editierbare Modellquelle ist `polisa_r08_visual.gd` mit gebatchten Godot-Primitives. `author_layout.py` liest die aktuelle owning Heimatbasisquelle; `build_candidate.py` erzeugt daraus private Map, `layout_compiled.json` und Offlineprüfung. Die historische Metadatenbasis liegt innerhalb dieses Pakets unter `baseline_r04`; kein Buildinput hängt von einem untracked Output ab.

1. `python art/polisa_r08_20261111/author_layout.py`
2. `python art/polisa_r08_20261111/build_candidate.py`
3. `python art/polisa_r08_20261111/build_layout_svg.py`

`layout_target.svg` ist das vor Umsetzung erstellte 2D-Ziel, `layout_final.svg` die Ableitung aus den finalen Fakten. Beide sind Planzeichnungen, keine nativen Belege. Die unveränderte R07-Quelle einschließlich damaligem Manifest und privater Map liegt unter `approved_r07`. Dieser Ordner ist ein historischer Snapshot, kein alternativer aktiver Buildpfad.

Die zuvor tatsächlich betrachtete R06-KI-Illustration unter `art/polisa_r06_20261111/references/station_concept_ai.png` bleibt das Material-/Fasen-/Ring-Stilziel. Maßstab und Grundform folgen der freigegebenen R07-Basis und der aktuellen R08-Korrektur. Frühere Port-Olisar-Quellen/Provenienz bleiben in R05 erhalten. Keine Fremdmodelle übernommen; keine neue Rüstungsrevision.

## Prüfstatus und Ansichten

20 kleine Offlinechecks grün: 4486 gespeicherte Hexe, 2205 begehbar, 2281 blockiert, genau eine Laufkomponente. Alle sieben Pads, fünf Raumanker, Service-/Spawnmarker und Globusumlauf erreichbar. Alle sechs neuen Wandöffnungen wurden zusätzlich mit einem lokalen Graphpfad quer durch ihren jeweiligen Durchgang geprüft. Quellenhash, Padreserven, technische Blocker und gemeinsame Ringachse stimmen. Die zusätzliche Wandgeometrie sperrt gegenüber R07 153 Zellen; die Gesamtzahl gespeicherter Zellen bleibt gleich.

Godot 4.6.2 check-only wurde vor den Bildern mit Exit 0 ausgeführt. Finaler versteckter D3D12/Forward+-Artlauf `r08_final`: Exit 0, 0 Fehler, 0 Warnungen, absolutes Privatprofil, tatsächliche Bilder 1280×720. Alle drei finalen PNGs wurden geöffnet:

| Datei unter `output/native_glut_maps/polisa_r08_20261111/` | Kamera | Sichtbarer Beleg |
|---|---|---|
| `polisa_r08_station_near.png` | Size 62, Yaw 24, Pitch 50, Fokus lokal (0,14) | Echte Hexe, sieben Pads, offene Durchgänge, alle fünf Shopinhalte, Globus |
| `polisa_r08_station_ports.png` | Size 112, Yaw 12, Pitch 50, gleicher Fokus | Gesamte Station einschließlich DOCK L/R, Solars und gemeinsamer Achse |
| `polisa_r08_whole_map.png` | Size 320, Yaw 0, Pitch 68, Fokus Welt (0,21) | Vollständiger Kartenrahmen und freies Vorfeld |

Das Stationsbild verwendet Yaw 12, damit Ringtiefe und beide Dockköpfe gemeinsam lesbar sind. Es ersetzt nicht die Standard-Nahkamera. Die Nahansicht nutzt RootViews aktuelles echtes Hexraster mit 2.2-Pixel-Kern; kein zweites dekoratives Raster. Der archivierte R07-Artcapture verwendete noch die frühere Rasterdarstellung, daher sind die Rasterkontraste zwischen den Revisionen nicht als isolierter Modellvergleich zu lesen. Erstbilder bleiben als `r01_*` erhalten; der finale Bildsatz unterscheidet sich nur durch das entfernte große Lobby-Bodenwort.

Native Station: 23136 statische Dreiecke in 10 Meshbatches. Drei deaktivierte R07-Showcaserigs separat: 22472 Dreiecke in 6 Meshes. Zusammen 45608 Dreiecke in 16 Dressingmeshes, 0 CollisionObjects, 0 dynamische Lichter. Echt-Hexoverlay: ein Mesh mit 14956 Dreiecken / 7478 Kanten, alle 2205 Laufzellen resident, Streaming=false. Keine per-frame Schleifen oder SceneTree-Scans in der Station; die einmaligen Diagnose-Scans liegen ausschließlich im Capture-Script.

Keine große Testmatrix, Reise-/Save-/Gefechtsprüfung, FPS-Aussage, Schiffsfit- oder Dockingfreigabe. R07-Grundform wurde vom Nutzer gelobt; R08 ist ein geprüfter privater Artkandidat, keine behauptete ästhetische Endabnahme. GPU nach finaler Sichtung an Root zurückgegeben.

## Integration durch Root

Private Map: `output/native_glut_maps/polisa_r08_20261111/polisa_station_candidate.json`. Szene: `polisa_r08_visual.tscn`; sie referenziert den privaten GDScript- und Layoutpfad. Bei Übernahme die drei zusammengehörenden Ressourcen Map/Scene/Visual plus `layout_compiled.json` konsistent umlegen; Origin bleibt einmalige Propplatzierung. Die kleinen Compile-/Graphchecks und nativen Bilder belegen diesen privaten Stand, nicht automatisch die spätere Produktionskopie.

`manifest.json` enthält SHA-256 der konkreten Quellen, Archivdateien, aktuellen Abhängigkeiten und Belege. Die Abhängigkeitshashes beschreiben den Freezezeitpunkt im gemeinsam weiterbearbeiteten Worktree; sie sind keine Behauptung eines global unveränderten Root-Commits.

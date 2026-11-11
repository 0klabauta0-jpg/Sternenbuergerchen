# Native Glut-Karten · Godot 4.6.2

Stand 11.11.2026 · `task/native-glut-maps-20261110` · Basis `639a49d65`.
Auftrag und Datenkompatibilität stehen in
[MAP_WORLD_REBUILD_2026_11_10](../../tasks/MAP_WORLD_REBUILD_2026_11_10.md).

## Karten und native Ansichten

A erhält eine gewundene trockene Schlucht mit breiten Hochflächen bis H8.
B erhält getrennte Felsrücken, Freihafen, Feldlandefläche und das östliche
Lager. C erhält Verwerfungen, eine eigene Chip-Hochfläche, gebaute Decks und
zwei erreichbare Querungen. Beide ererbten Streumuster auf C sowie
isolierte H1-Erhebungen ohne Objekt wurden aus allen drei Karten entfernt.
Begehbare Nachbarfelder mit genau einer Stufe sind in beide Richtungen
verbunden. Eine triangulierte Bodenfläche schließt die Rampen bis in die
Ecken, mit kurzen Wandflächen an verbleibenden steilen Übergängen. Raster,
Picking, Nebel und die Höhe der dargestellten Infanterie folgen der Rampe.
Die
Decks besitzen je eine gespeicherte begehbare Höhe. Das darunter gezeichnete
Schluchtbett dient der Darstellung.

A/B/C speichern je **512 × 256 = 131.072** eindeutige Hexzellen. Die Sternkarte
stellt **256 × 256 = 65.536** strategische Zellen nativ dar. Sonne, Planet,
drei Monde, Orbitgürtel, volle Planetenbahn, projizierte A/B/C-Felder und ein
drehbares Schiffsmodell laufen im Spielrenderer. Glut 1 hat sechs Hexeinheiten
Durchmesser, seine drei Monde je 2,4. Die Ansicht öffnet näher am System
und bietet die Gesamtansicht als Rücksprung. Der sichtbare Flugweg, die
Schiffsposition und die Drehung folgen derselben quadratischen Kurve aus dem
Reiseowner. Quantum öffnet einen farbigen Ring, und die Cutlass zeigt im Flug
einen Triebwerksstrahl.
C und der bestehende Notruf behalten `planet_orbit`. Der Eintritt liegt
auf dem erweiterten Gürtel südöstlich von Glut 1. A und B haben eigene
Mondorbits.

### Lokale Bildbelege

- Vorher/Nachher an den drei Landeankern bei 1280 × 720 und 1920 × 1080,
  je Übersicht, Spielabstand und Nahansicht. Die Detailkamera bleibt gleich.
  [A](../../../output/native_glut_maps/A_matrix_review.jpg),
  [B](../../../output/native_glut_maps/B_matrix_review.jpg),
  [C](../../../output/native_glut_maps/C_matrix_review.jpg).

- [A vorher](../../../output/native_glut_maps/A_before_44.png) und
  [A mit geschlossenen Rampen](../../../output/native_glut_maps/A_ramp_contrast_44.png),
  gleicher Anker, Abstand und Kamerawinkel bei 1280 × 720.
- [A Schlucht und sichtbare Hexkanten](../../../output/native_glut_maps/A_final_canyon_18.png)
  und [A mit echtem Trupp, gelandetem Schiff und FT1](../../../output/native_glut_maps/A_landing_live_ramps.png).
- [B Lager](../../../output/native_glut_maps/B_depot_44.png) und
  [B Gesamtansicht](../../../output/native_glut_maps/B_depot_540.png)
  bei 1920 × 1080.
- [C Hauptquerung](../../../output/native_glut_maps/C_deck_final_44.png),
  [C nah](../../../output/native_glut_maps/C_deck_final_18.png) und
  [C Gesamtansicht](../../../output/native_glut_maps/C_deck_final_540.png)
  bei 1920 × 1080.
- Sternkarte [Startansicht](../../../output/native_glut_maps/star_final_tuned_system.png),
  [Quantum-Ring](../../../output/native_glut_maps/star_final_tuned_warp.png),
  [Flug](../../../output/native_glut_maps/star_final_tuned_route.png) und
  [Oberflächenfeld C](../../../output/native_glut_maps/star_final_tuned_surface.png)
  bei 1920 × 1080.
- [Kompakte Charakterkarte mit Rangsymbolen und Figur](../../../output/native_glut_maps/details_compact/details_1280.png).
- [Felsvergleich in Godot](../../../output/native_glut_maps/rock_native_comparison.png)
  bei gleicher Beleuchtung und Kamera. Links der integrierte 100-Dreieck-Fels
  aus der CC-BY-Quelle, rechts die lokale CC-BY-NC-Studie mit 288 Dreiecken.
  Bearbeitung, Attribution und SHA-256 in [SOURCES](../../../Assets/curated/glut_regional/SOURCES.md).

Die nativen Bilder wurden geöffnet. Besonders bei weitem Blick sind die
Terrassen klar voneinander getrennt. Die Nahansicht zeigt weiterhin die
polygonale Form der Hexkanten. Form und Material liegen näher am
Referenzmotiv, die dichten, unregelmäßig gebrochenen Felsformationen der
Konzeptbilder bleiben ein Abstand zur nativen Fassung. Die
gestalterische Nutzerabnahme steht aus.

### Referenzhashes

| Referenz | SHA-256 |
| --- | --- |
| A_512x256.png | `139d03b5a046e7a2b6cec4b33f7f3db839e6b8dde95081d817987daf077836a2` |
| B_512x256.png | `d69855fb1ec77dd1a4a384b67213da468202c72a1b94003a0aa29120f67a53c8` |
| C_512x256.png | `dc723b4253458b5fcd277de0a3d3a9ce2e510b56c2d79b9a6b4dec2632d7a333` |
| viewer_source.html | `1656d3ff4505ecabf5a803aac942a86bd4f4bd161d414c378397e8deb261d6af` |

## Technische Prüfungen

| Prüfung | Nachweis |
| --- | --- |
| Native Zellzahl und Kontur | Drei Karten mit exakt 131.072 Zellen, Grenzen in beide Richtungen geprüft, je 0 objektlose isolierte H1-Hexfelder |
| Reproduzierbarkeit | Zweiter Compilerlauf mit identischem SHA-256 für A, B und C |
| MapData SaveAs | 49/0, inklusive aller drei Orte |
| Runtime-Editor SaveAs und Reload | 49/0, inklusive aller drei Orte und Hochterrain |
| A*/HPA, Höhe, Sicht und Decks | Einstufen-Rampen in allen sechs Richtungen auf A/B/C, Klippen mit größerem Sprung gesperrt, legale Hauptrouten auf A/B/C, jede C-Querung ohne die jeweils andere erreichbar, LOS-Beispiele am echten Gelände, korrekte Platzierung eines Gebäudes auf Hochterrain |
| Kameraumkehr und Rendercache | Fernanforderung verworfen, Nachbaransicht und Rückschwenk verwenden fertige Geometrie, ausgeblendeter Viewport bleibt aus |
| Sternkarten-UI, Kamera und Orte | 91/0, 26/0 und 27/0, inklusive Klick auf einen Orbitgürtel |
| Reiseowner | A/B/C-Ankunft, Abbruch, Neustart, Anflug, Rückorbit und Heimlandung, beide Schiffe auf getrennten Orbits, kontinuierliche Kurve ohne Richtungswechsel auf demselben Sprung |
| Altpfadregression | Hex 41/0, Navigation 72/0, LOS 28/0, altes Hügel-Testfeld 83/0 |
| Kampagnenkarten und Gebäudeflächen | Inhalte 69/0. Gebäudeblocker auf B/C decken alle je 142 geprüften Felder ab, einschließlich der Frontwand der versetzten Außenposten. |
| Skirmish | Drei tatsächliche vorbereitete Starts, 97/0 |
| Vorhandener Save | Continue mit Kopie des vorhandenen Spielstands, gespeicherter Fortschritt und Ressourcen erhalten, Original bytegleich |
| Native Kampagne vor finaler Rampengeometrie | 55/0 bei 1× bis zum ersten Upload. Frischer nativer Durchlauf aller fünf Einsätze 230/0, einschließlich B, A-Wiederbesuch, C-Brücke, Chip-Upload, Orbitalrettung und Continue mit vier Personen und zwei Schiffen. |
| Geschlossene Rampen, erster Einsatz bei 1× | 61/0 im nativen Lauf mit regulärem GO von H0 auf H1 und wieder nach H0, Satellitendaten, Heimkehr, Upload und Checkpoint |
| Anflug und Landung | Flugvisual- und Rasterprobe 24/0 inklusive durchgehender Cutlass-Ausrichtung, stabiler Reisehöhe und Aufsetzen am Geländedatum |
| Kampagnenfortsetzung mit Rüstungsfach | 55/0 neuer erster Einsatz und Upload, 179/0 native Fortsetzung vom echten A-Checkpoint über B, A-Wiederbesuch, C-Upload und die Orbitalrettung bis Continue mit vier Personen und zwei Schiffen |
| Ausrüstung und Bestand | Leichte Startrüstung bietet ein Datenträgerfach. Rucksack für 40 Cr im Handelsaußenposten, +12 Plätze nach Anlegen. Altes Checkpoint-Fingerprint migriert mit allen fünf Aufträgen und Mengen. Handel 41/0, Dienste 26/0, Abbau mit gekauftem Rucksack 18/0. |
| FT1 und Figur | 50/0 Truppkarte bei 1280, 1920 und 3440. 84/0 tatsächliches Aufsitzen und erneutes Absetzen samt Upload. Gemeinsame Charakterkarte 74/0, Compact/Einsatz 28/0, Inventar 28/0 und Basisfenster 113/0. |

Der Rückweg von C verwendet reguläre Wegpunkte über das Deck. Ein früherer
Lauf mit einem einzelnen langen GO-Befehl lief dabei ins Zeitlimit. Der
Durchlauf setzte weder Positionen noch HP, Treibstoff oder Missionszeiten
für die Wegprüfung.

## Laufzeitmessung

Godot 4.6.2 D3D12 Forward+, RTX 4070 Ti SUPER, 1280 × 720.
A nach echter Landung bei 1× mit aktivem FoW `known_terrain` und zwei
echten Spielakteuren. Gemessen wurden 240 Frames mit Kameraschwenks und
144 Frames mit Zoomwechseln. Die Messung umfasst keine breiten Aussagen
zu FPS auf anderen Geräten.

| Probe | P95 | P99 | Maximum |
| --- | ---: | ---: | ---: |
| Schwenk vor zeitlich gestaffeltem Aufbau | 39,2 ms | 71,5 ms | 111,8 ms |
| Schwenk mit gestaffeltem Aufbau und geschlossenen Rampen | 38,1 ms | 44,5 ms | 68,0 ms |
| Zoomwechsel mit geschlossenen Rampen | 33,8 ms | 41,5 ms | 42,5 ms |

Godot meldete rund 1,36 GB statische Allokation und 830 MB
Videospeicher. Das Einlesen der Ortsdatei läuft während des Anflugs
außerhalb des Hauptthreads. Die Karte öffnet mit einem aufgebauten
Ausschnitt um den Landeanker. Weiter entfernte Kamerawechsel zeigen
bei Bedarf einen Aufbauhinweis. Die Zeit bis zur Einsatzinstanz lag
bei 8,75 s auf A und 7,60 s auf B in den nativen Proben.
In der separaten Headless-Last lagen die HPA-Graphaufbauten nach
Einstufen-Navigation um 8 s und einzelne Anfragen bei etwa 1,0–2,7 s.
Ein weiterer nativer 1×-Schwenk auf A nach B lag vor der zusätzlichen
Chunk-Retention bei P95 52,8 ms, P99 68,9 ms und maximal 87,1 ms.
Die Probe meldete 2,21 GB statische Allokation und 1,09 GB Videospeicher.

Die vollständige Karte bleibt für die Simulation geladen. Der Renderer
hält den sichtbaren Bereich und bis zu 64 zuletzt benutzte fertige
Ausschnitte. Ein Rückschwenk im nachgewiesenen Nahbereich baut keine
Geometrie erneut auf. Ausgeblendete Orts-Viewports bleiben aus.
Beim sichtbaren Ausschnittwechsel kann die Nebelmaske weiterhin Arbeit
verursachen. Parallele Ortslast, volle 3D-Residency und ein breiter
Langzeit-/Release-Nachweis stehen aus.

Die getrennte Ultra-Codeprüfung sieht zwei konkrete Kostenpfade.
Der Zeitrahmen des Renderers kann einen bereits laufenden vollständigen
Chunkaufbau nicht unterbrechen. Die Freigabe eines Ausschnitts baut die
sichtbare Nebelmaske neu auf. Eine Weganfrage kann synchron den kalten
HPA-Graphen aufbauen. Mehr Bodendetails lassen sich unabhängig von der
Kartengröße zuerst in Spielnähe budgetieren. Die getrennten Renderzeiten
werden mit dem nativen Godot-Viewport-Profiler erhoben.
[Godot 4.6 RenderingServer](https://docs.godotengine.org/en/4.6/classes/class_renderingserver.html#class-renderingserver-method-viewport-set-measure-render-time)

### Echtes Gefecht auf B bei 1×

Ein gewöhnlicher Fortsetzen-Start mit Kopie des nach dem A-Upload
erzeugten Checkpoints, anschließender Landung auf B und regulärem GO
zur Außenpostenwache. Zwei eigene Einheiten, eine Wache und acht
Schussereignisse. Godot 4.6.2 D3D12 Forward+, RTX 4070 Ti SUPER,
1280 × 720 Fenster und 1920 × 1080 taktischer Render-Viewport.
Die CPU- und GPU-Zeiten beziehen sich auf diesen Viewport, die
Frameabstände auf den gesamten beobachteten Prozess. Zwei identische
Schwenks ohne Qualitätsänderung, dann das echte Gefecht. Die
Profilinstrumentierung blieb für diese vier Phasen eingeschaltet.

| Phase | Frames | P50 | P95 | P99 | Maximum | GPU-P95 | Neu gebaute Chunks |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Stehende Kamera | 120 | 10,5 ms | 23,5 ms | 35,3 ms | 47,0 ms | 7,6 ms | 0 |
| Erster Schwenk | 240 | 10,7 ms | 33,2 ms | 46,7 ms | 52,1 ms | 7,8 ms | 20 |
| Identischer Rücklauf im warmen Bereich | 240 | 9,4 ms | 34,7 ms | 47,0 ms | 56,2 ms | 7,8 ms | 0 |
| GO und Annäherung | 1.470 | 22,8 ms | 300,5 ms | 496,3 ms | 8.574,0 ms | 7,6 ms | 5 |
| Erster Schuss bis zum kurzen Auslauf | 130 | 27,6 ms | 85,0 ms | 190,4 ms | 229,0 ms | 8,8 ms | 47 |

Im zweiten Schwenk sank das P99 der Skriptarbeit der Terrainansicht von
14,1 auf 6,8 ms. Die Frameabstände profitierten in dieser Einzelprobe
kaum. Bei der Annäherung erreichte die gemessene Command-Arbeit pro
Simulationstick P99 437,6 ms. Beim Gefecht waren es P99 131,1 ms.
Der längste Frame trat direkt bei GO auf, während der Viewport
7,8 ms GPU-Arbeit meldete. Die separate Headless-Messung des kalten
HPA-Graphen liegt in derselben Größenordnung. Der reale Kampf bestand
mit 34/0 Prüfungen. Das Ziel eines flüssigen Gefechts ist damit offen.

[Rohdaten](../../../output/native_glut_maps/B_battle_profile.json) ·
[Laufprotokoll](../../../output/native_glut_maps/battle_native_final.log)

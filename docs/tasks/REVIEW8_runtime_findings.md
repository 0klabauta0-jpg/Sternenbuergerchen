# Review 8: Runtime-Sicht und deckungsbewusste Pfade

## Ziel / Problem
Zwei am aktuellen Main `93c2e6810` nachvollzogene Korrektheitsbefunde beheben:
inkrementelle square8-FoW darf sichtbare Randzellen nach Bewegung nicht behalten
oder auslassen; deckungsbewusstes square8-A* muss die bewertete billigere Route
finden, statt wegen einer zu grossen Heuristik vorzeitig abzubrechen.

## Ursache / Sinn
- Die square8-Sichtregion teilt den Weltradius durch die Laenge eines projizierten
  Basisvektors. Gegenlaeufige Basisvektoren koennen sich aufheben; diese Formel
  begrenzt die benoetigten Gridkoordinaten daher nicht konservativ. Beim bereits
  verwendeten 16/8-Raster mit Sichtweite 640 liegen relevante Zellen ausserhalb
  des geschätzten Radius 38. Die vollstaendige Sichtberechnung besitzt den Fehler
  nicht und dient als unabhaengiger Ausfuehrungspfad fuer das Oracle.
- Die square8-A*-Heuristik setzt mindestens 0.7 Kosten je Schritt an. Aktive
  Cover-Kosten duerfen aber bis 0.05 sinken. Der Hexpfad beruecksichtigt diese
  Untergrenze bereits. Eine ueberhoehte Heuristik kann den offenen direkten Weg
  vor einer existierenden billigeren Deckungsroute abschliessen.

## Umfang / Nicht-Ziele
Nur `FogOfWarSystem`-Kandidatenbegrenzung und square8-A*-Heuristik korrigieren.
Bestehende Dirty-/Batch-Budgets, atomare Veroeffentlichung, Terrainwahrheit und
Hexverhalten erhalten. Kein neuer State-Owner, keine neuen Navigationssysteme,
keine Terrain-/Actor-/Timer-Aenderungen oder allgemeine FPS-/Release-Aussage.

## Relevante Dokumente
`REVIEW8_2026_11_05_code_ux_graphics.md`, `docs/ARCHITECTURE.md`,
`docs/dev/fog_of_war_modes_contract.md`, `docs/dev/hex_grid_v1_contract.md`,
`TASK_1189_fow_dirty_region_fanout.md`,
`TASK_129_deckungsbewusste_pfade_hpa_subgoals.md`.

## Akzeptanzkriterien
1. Neue Verifier gegen unveraenderte Produktion zuerst mit dem eigentlichen
   Fehler rot ausfuehren; erst danach kleinste gezielte Produktkorrektur.
2. Square8-Dirty-Sicht gleicht nach Bewegung, Rand-/Ueberlappungsfaellen und
   Observerentfernung dem Fullscan, auch bei anisotroper Iso-Projektion.
   Zwischenschritte bleiben atomar und jeder Slice haelt sein Arbeitsbudget.
3. Cover-aware square8-A* findet in der handpruefbaren 9x9-Fixture eine guenstigere
   gedeckte Route als die offene Gerade; Kosten entsprechen einem unabhaengigen
   Dijkstra-Oracle. Ohne Cover-Kosten bleibt die regulaere Routenauswahl erhalten.
4. Angrenzende FoW-/Sicht-/HPA-/Cover-Verifier und bestehende Performancebudgets
   seriell pruefen. Messbefunde getrennt von korrekter Sicht dokumentieren.

## Betroffene Dateien
- `scripts/core/fog_of_war_system.gd`
- `scripts/terrain/terrain_pathfinder.gd`
- `scripts/tests/review8_fow_projection_verifier.gd`
- `scripts/tests/review8_cover_path_verifier.gd`
- `scripts/tests/gm01_hex_hpa_pruning_verifier.gd` (Testkompilation des Altoracles)

## Lokale Pruefung
Godot 4.6.2, neue Verifier plus TASK1189, TASK129, TASK125/127/128 und Hex-/A5-
Nachbarn durch den zentralen Runner, isoliert und ohne parallele Engineprozesse.

## Risiken / offene Punkte
Korrekte FoW-Bounds koennen mehr legitime Kandidaten erfordern. Bereits
ueberlappende Regionen sollen keine unnoetige doppelte Sammlung verursachen;
Slice-/Stalenessbudgets unveraendert pruefen. Eine zulaessige kleinere A*-
Heuristik kann mehr Zellen untersuchen. Die Aenderung betrifft nur aktive
Cover-Kosten in square8; Deckungsgewicht und Gameplay-Regeln bleiben erhalten.

## Ergebnis
- RED auf unveraenderter Produktion: FoW 108 bestanden / 22 fehlgeschlagen,
  darunter die handgepruefte Randzelle und Observerentfernung; Cover 8/4,
  einschliesslich der echten lokalen HPA-Abfrage. Logs unter
  `output/review_graphics_20261105/red/20261105T051523Z-22cda4e9/`.
- Kleinste Korrektheitsfixes bestehen im zentralen Godot-Runner: FoW 130/130,
  Cover 12/12. Noch kein Abschluss der angrenzenden Performancepruefung.

### Nachgewiesene Performancefolge vor der zusaetzlichen Korrektur
Der unveraenderte TASK1189 besteht mit korrekten Sichtbounds zunaechst 22/25.
Die alten/neuen, fast identischen Rechtecke werden doppelt gesammelt: bei
16/8 und R640 zweimal 95x95 = 18050 Gridpositionen. Das benoetigt im bestehenden
512er Budget neun Sammel- und zehn Auswertungsslices, geschaetzt 416.67 ms mit
dem vorhandenen 100-ms-Intervall statt erlaubter 350 ms. Bei 32x32/R128 ist
auch die geschaetzte Kandidatenregion durch diese Doppelung groesser als die
Karte. Rohlog:
`output/review_graphics_20261105/performance_fow/20261105T052032Z-75b2ecfd/fow_dirty1189.log`.

Vor der weiteren Produktkorrektur gilt deshalb: Nur zwei konservative,
ueberlappende square8-Samplebereiche desselben Observers zusammenfassen, wenn
deren gemeinsames Rechteck nicht groesser als beide Einzelrechtecke zusammen
ist. Eine Zelle bleibt Kandidat, wenn sie in der alten ODER neuen echten
Sichtreichweite liegt. Dadurch entfallen doppelte Lookups; die groessere korrekte
Sichtmenge, atomare Publikation, Slice-Budget, Stalenessgrenze und Hexroute bleiben
erhalten. Der neue Verifier protokolliert dazu echte Sammel-/Auswertungscounter.

### Historisches HPA-Vergleichsoracle
Der unveraenderte `gm01_stable_astar_frontier` besteht bereits. Der alte HPA-
Pruningvergleich meldet 327/331: Nur die beiden square8-Cover-Fixtures weichen
in Pfad und Kosten ab, weil ihr separat gepinnter alter Linearfrontier noch
die fehlerhafte Heuristik nutzt. Die gespeicherte historische Quell-/Hashdatei
bleibt unveraendert. Fuer diesen mechanischen Pruning-/Cachevergleich wird
allein die square8-Heuristik des im Test kompilierten alten Linearfrontiers
an denselben korrigierten Kostenfloor angeglichen. Exakte Pfade, Floats, Anzahl
der Suchaufrufe und alle Neutral-/Hex-Checks bleiben strenge Erwartungen.
Der neue Review8-Cover-Verifier kompiliert zusaetzlich die unveraenderte
Rohbaseline separat und haelt deren diagnostizierte fehlerhafte Kosten 8
gegenueber dem handgeprueften korrekten Wert 7.420710678 sichtbar fest.

### Aktuelle gezielte Nachpruefung
- `final_new/20261105T052357Z-8ffd2bbf/`: FoW 130/130 inklusive vier
  Projektionen, fraktionaler Observerpositionen, Rueckkehr, Kartenrand und
  Observerentfernung; Cover 16/16 inklusive unveraenderter historischer
  Bugbaseline, unabhaengigem Dijkstra und echter lokaler HPA-Abfrage.
- Echte FoW-Counter bei 128x128/16x8/R640 nach einem Gridschritt:
  9120 gesammelte Gridpositionen, 5114 ausgewertete legitime Tiles. Die
  regulaere 64x32-Projektion benoetigt 870 Lookups und 342 Kandidaten.
  Keine Absenkung der Sichtreichweite oder Erhoehung des Slice-Budgets.
- `final_adjacent/20261105T052416Z-6450e1dd/fow_dirty1189.log`: 25/25 bei
  unveraenderten Budgets. Die geschaetzte Veroeffentlichungsverzoegerung des
  bestehenden 512er Workloads betraegt fuer 128x128 und 256x256 jeweils
  350.00 ms. Die groessten gemessenen Auswertungsslices sind 7.30 ms bzw.
  11.39 ms gegen die bestehenden 16.7-ms-/33.3-ms-Grenzen.
- Der gleiche Nachbarlauf besteht im HPA-Pruningvergleich 332/332. Nur die
  testkompilierte historische square8-Heuristik wurde angeglichen; alle exakten
  Pfad-/Scoring-/Cache-Erwartungen bleiben bestehen. Der gespeicherte historische
  Terrain-Hash bleibt `190b34a0789734a967c28a57ee7b978973d2614849e50c5b476bc043ef701131`.
  `gm01_stable_astar_frontier_verifier.gd` bleibt unveraendert und besteht 114/114.
- Diese Werte belegen die benannten Headless-Fixtures; sie sind keine
  allgemeine FPS-, native Framezeit- oder Releasefreigabe. Der Root koordiniert
  den weiteren gemeinsamen Nachbar- und nativen Lauf.

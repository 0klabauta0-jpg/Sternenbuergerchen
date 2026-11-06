# R3: Spielkamera und visuelle Verdichtung der GM01

## Ziel und beobachtetes Problem

Untertask von `REFERENCE_POLISH_R3_2026_11_06.md`, Basis Main `173a1e3c3`.
Das normale native A5-Bild zeigt ein kleines Ensemble in viel freier
Sandflaeche. Das Original fuellt den Bildraum mit lesbaren Figuren, Gebaeuden,
Felsstaffelung und niedrigen Vegetationsgruppen. Das ist eine andere
Komposition und kein fehlender UI-Rahmen.

Die drei Bilder wurden direkt geoeffnet:

- Original: `docs/reports/assets/ui-2026-11-01/mockup_a5_mission_zweireihig.png`,
  SHA256 `fc9edb8b1d28921653ba5b438e7be8da4db3e0b32b8c751e9b18c4ef94918149`.
- Nativer Ist-Stand: `output/hud_architecture_20261106/final_native_audited/20261106T144051Z-f2bdfc4c/audited_captures/06_go_movement.png`.
  SHA256 `c1f289dbb8aba69f6db4f248a6bf0e88a5b407e64480d8e02510d7936f3ce6b0`.
- Derselbe normale Lauf, `07_outpost_overview.png`; anderer Bildausschnitt,
  ausdruecklich kein Kamera-Vorher/Nachherpaar.

Diese alten PNGs beschreiben den Ausgangspunkt. Roots neuer gepinnter R3-
Vorlauf und die spaeteren neuen nativen Vergleichsbilder bleiben separat.

## Ursache und gewaehlter Ansatz

`TerrainMap3DView.CAMERA_DEFAULT_SIZE` ist34 fuer alle Karten. MissionSetup
fokussiert nach Configure nur den Objective-Marker. Ein GM01-spezifischer
Startausschnitt mit Kameragroesse22 ist die erste begrenzte Korrektur. Er wird
einmal nach dem Laden aus echten authored Markern gesetzt. Manuelles Pan/Zoom
und der vorhandene einmalige Multiplayer-Kontaktfokus bleiben danach erhalten.
Editor, begehbare Basis und andere Karten behalten ihre bisherigen Rollen.

Die Szene erhaelt daneben wenige zusammenhaengende niedrige Gruppen an
bestehenden Outpost-/Service-Ensembles. Es werden vorhandene `DryAgave`- und
`ContactGravelBatch`-Meshressourcen wiederverwendet. Es entstehen keine neuen
Container, massiven Hindernisse oder lose grossen Felsen auf freiem Navraum.
Aktive Schiffs-/Portraitquellen und bestehende Gebaeude bleiben identisch.

## Umfang und Nicht-Ziele

- Neuer rein visueller Helper `scripts/terrain/frontier_reference_dressing.gd`.
  Reiner Plan aus echten Terrain-Daten, getrennte begrenzte Installation.
- Hoechstens160 Agaven und320 kleine Geroellteile in zwei statischen
  MultiMesh-Batches. Kein `_process`, keine eigenstaendige Simulation.
- Herkunftsgeometrie wird nicht editiert. Die teilweise absolut modellierten
  Pflanzenmeshes werden ueber ihren Quell-AABB zum lokalen Ursprung versetzt;
  SourceMesh und SourceMaterial werden nicht mutiert.
- Ausschliesslich echte walkable Hoehe0-Sand-/Groundzellen der GM01.
  Quellzelle und semantische ID bleiben Bestandteil jedes Planrecords.
- Authored Blocker, Tueren/Marker, Pads und Servicewege bleiben frei.
  Kandidaten an funktionalen Clustern, keine gleichmaessige Zufallsstreuung.
- Kartenjson, Height, Nav, LOS, Cover, Unit-/Enemy-/Mission-/Savewerte bleiben
  unveraendert. Die existierenden Dressing-/Worklife-Footprints werden nicht
  erweitert: diese werden beim Authoring als echte Blocker interpretiert.
- Keine Performancebehauptung aus engerem Kamerabild. Roots Vergleichskamera34
  und der neue normale Spielausschnitt22 werden separat gespielt und gemessen.

## Determinismus, Begrenzung und Grounding

Planentscheidungen folgen `(seed, q, r, fester salt, slot)` und einer stabilen
Rangfolge. Die Reihenfolge des Map-Arrays oder anderer Builder darf die
Platzierung nicht beeinflussen. Semantische IDs verwenden keine Instance-ID,
Node-Suffixe, Wandzeit oder gemeinsamen fortlaufenden Zufallsstrom.

Ein kalter Durchlauf sammelt relevante Zellen. Danach finden hoechstens512
Kandidaten-/Quellzellenpruefungen statt; keine Tilesuche je Instanz.
Paths nutzen ihre vorhandenen Samples/Breiten, Blocker ihre echten Rects und
Pads die tatsaechlichen PaintedLandingApron-Meshbounds. Die Access-Anchorbreite
beschreibt nur den Zugang und darf nicht als Padgroesse verwendet werden.
Sicherheitsabstaende gelten fuer den
vollstaendigen Footprint, nicht bloss den Mittelpunkt. Jeder Prop bleibt
vollstaendig in seinem Hex und sitzt mit seinem AABB-Minimum auf der echten
Bodenhoehe. Ungueltige Daten, fehlende Quelle und unbekannte Topologie erzeugen
keine erfundene Dekoration am Ursprung.

## FoW-Grenze

Der heutige authored Root besitzt keinen gemeinsamen Fragment-Maskshader:
Terrainwissen wird durch bestehende Hex-Overlay-Slots dargestellt. Es darf
deshalb keine neue `any_visible`-Freigabe der grossen MultiMesh-AABB geben.

Vorgesehener enger Consumer: vollstaendige Props liegen in ihrer gespeicherten
Quellzelle. Ein begrenzter Sichtpass liest die vorhandenen Terrain-Cellstates
einmal je Instanz und verbirgt unbekannte Slots einzeln. `known_terrain` zeigt
statisches Terrain, `unexplored_blackout` nur sichtbare/erkundete Zellen,
`off` alle. Neue Gegner-/Event-/Targetdaten werden weder gelesen noch erzeugt.
Es gibt keine zweite Wissensquelle. Root hat diese Route freigegeben; der
genaue Integrationshook folgt nach dem Performance-/Fog-Pass. Neue Slots sind
bis zur ersten echten Sichtpublikation versteckt. Ein Moduswechsel nach
Blackout darf alte `known`-States nicht als erkundet behandeln. Pro Publikation
erfolgen hoechstens480 Dictionary-Lookups; nur tatsaechlich geaenderte Slots
erhalten einen Transformwrite. Zaehler belegen diese Grenze. Der Consumer
laeuft nach einer bestehenden Batch-/Delta-/Full-Publikation, nie je Terraintile.

Die Quellressourcen bleiben identisch: `frontier_art_dressing.gd` SHA256
`aeb7b9d887a04d477f932265edfcae6b6a5a3afa4119b6c1f02481938471ffd0`,
`frontier_worklife.gd` SHA256
`15f26e2e951a34a60c111f3c69b36ab7490c0336e36065efa9a01721c9174656`.

Geplante enge API: `build_plan(map_data, visual_context, seed)`,
`install(parent, plan, sources)`, `apply_visibility(layer, mode, cell_states)`,
`get_snapshot(layer)`. Kontext enthaelt nur bestehende Blocker/Wege, gemessene
Padrects, Tuerpunkte und rein visuelle Clusterzentren. Quellen sind echte
Mesh-/Materialreferenzen. Install liefert eine lokale Layerreferenz und eine
kleine Receipt; Snapshot liefert nur skalare Diagnose. Slottransforms und
Quellzellen bleiben im rein visuellen Layercache.

## Betroffene Dateien und Besitz

- Root: `mission_test_setup.gd`, `terrain_map_3d_view.gd` und finale Hookup-
  Hunks; diese bleiben waehrend des Vorlaufs/Performancepasses eingefroren.
- Nach Freigabe World-Agent: neuer Helper, begrenzter optionaler Hook in
  `frontier_gm01_layout.gd`, neuer fokussierter Komponentenverifier.
- Bestehende Legacy-Builderaufrufe ohne Terrain-Daten bleiben kompatibel und
  erzeugen keine neue Dekoration. Same-layout Mapwechsel muessen die lokale
  Dekolayer frisch validieren/ersetzen statt einen alten Plan weiterzuzeigen.

## Akzeptanz und lokale Pruefung

1. Gleicher Seed und umgedrehte Zellreihenfolge liefern identische nichtleere
   Plaene; anderer Seed aendert Varianten/Positionen innerhalb derselben Regeln.
2. Jede Position liegt auf einer tatsaechlichen erlaubten Zelle und ausserhalb
   aller Blocker-/Pad-/Marker-/Wegausschluesse. Positive und negative Grids,
   fehlende Marker, Hoehe1, Road und unwalkable sind abgedeckt.
3. Map-/Tilewerte und TerrainRegistryrevision bleiben nach Plan/Installation
   exakt gleich. Keine Commands, Effects, CollisionObject oder GameplayNodes.
4. Maximal480 Instanzen, zwei Meshbatches und512 Kandidatenpruefungen;
   erneute unveraenderte Installation behaelt die vorhandenen Ressourcen.
5. Fehlende Meshquelle und unguelter Plan erzeugen keine Teilszene.
   Mapwechsel entfernt/ersetzt alte lokale Instanzen nachvollziehbar.
6. Sichtbarkeit pro Quellzelle, auch gemischte sichtbare/unbekannte Zellen in
   derselben Batch-AABB, Aenderung nur der Cellstates, Modus- und Teamwechsel.
   Bekannte statische Props sind keine aktuellen Enemyinformationen.
7. Root prueft die neue Layer im nativen GPU-FoW-Gate bei zwei Kamerawinkeln,
   matched Vorher/Nachherkamera und dem normalen neuen Spielabstand22.
8. Roots Kamera-/Picking-/Maprand-/MP-Nachbarn pruefen manual pan/zoom,
   fresh mission, Selection/Contact und echten Kartenrand. Der kameraseitige
   Test wird erst nach Einigung auf den exakten normalen Setup-Einstieg gebaut.

## Risiken und Status

Pflanzen koennen als visuelles Rauschen enden; wenige lesbare Cluster sind das
Ziel. Kleine Props muessen vollständig in einer Zelle bleiben, sonst reicht
ein Zell-Sichtpass nicht. AABB-Normalisierung darf keine Quellgeometrie
verschieben. Naeherer Zoom darf keine manuelle Kamerawahl staendig ersetzen.
Technische Tests sind keine menschliche Gestaltungs-/Spielspassabnahme.

Status: Helper, kalter Layout-Refresh und TerrainView-Publikationshooks sind
implementiert. Root bestaetigte den echten Helper-missing-RED
`world_red_corrected/20261106T190157Z-99847758` und danach den ersten CPU-GREEN
`world_green_first/20261106T231448Z-16f170db`:35PASS/0FAIL.
Eine zusaetzliche Reuse-Pruefung reproduzierte gezielt zwei fehlende Invarianten
(`world_reuse_red_corrected/20261106T231736Z-e91e8ad8`:35PASS/2FAIL).
Der begrenzte Fix validiert jetzt die kanonischen Placementrecords und die
tatsaechlichen Mesh-/Materialidentitaeten, bevor er die vorhandenen Batches
ohne Sicht- oder Transformarbeit wiederverwendet. Geaenderte Plaene ersetzen
die lokale Layer weiterhin verborgen und atomar.

Der zusaetzliche echte Wrapper-RED
`world_wrapper_red/20261106T232532Z-f17de236`:42PASS/1FAIL pruefte denselben
Vertrag am oeffentlichen Layout-Refresh statt nur am Installer. Der Wrapper
stellt jetzt ausschliesslich nach gueltiger Wiederverwendung die vorherige
`visible`-Eigenschaft wieder her; neue/ungueltige Plaene bleiben verborgen.
Root bestaetigte danach `world_wrapper_green/20261106T232701Z-3006f5cd`:
43PASS/0FAIL.

Die reine Permutation derselben Clusterzentren wurde zusaetzlich als konkrete
Determinismusgrenze reproduziert:
`world_center_order_red/20261106T232805Z-00ea3a52`:44PASS/1FAIL; beide
Quellkontexte blieben dabei unveraendert. Der Plan sortiert jetzt ausschliesslich
eine lokale Kopie gueltiger endlicher Zentren lexikographisch nach X/Y.
Die Reihenfolge des bestehenden Builders ist damit keine Zufallsquelle mehr.

Der native Verifier `reference_polish_r3_20261106_world_gpu_verifier.gd`
prueft in echtem Vollbild zwei Kamerawinkel mit Off, komplett unbekanntem
Blackout, gemischten sichtbaren/erkundeten/unbekannten Slots beider Batches
und Known-Terrain. Er schreibt acht echte PNGs und ein separates Manifest in
den explizit durch Root gelieferten neuen `--output-dir`-Pfad. Diese
kontrollierte Visualdiagnostik ist kein physischer Gameplay-/Missionbeweis.
Root bestaetigte `world_gpu_second/20261106T231945Z-a0f95cdf`:56PASS/0FAIL
mit acht PNGs; dieser Lauf liegt ausdruecklich vor dem spaeteren Wrapperfix
und ist daher kein nativer Beleg fuer dessen finalen Quellenpin.

Final bestaetigt und lokal gelesen: CPU
`output/reference_polish_r3_20261106/world_all_final_green/20261106T232912Z-4d0ad6cb`:
45PASS/0FAIL. Native GPU
`output/reference_polish_r3_20261106/world_gpu_final/20261106T232940Z-273e078e`:
56PASS/0FAIL laut finalem Log, Windows/Vulkan/Forward+,3440x1440 Vollbild,
zwei Winkel, acht PNGs. Beide Rootreports: Exit0, keine Enginefehler,
Isolation verifiziert, Quellpins vor/nach stabil, Rosterbytes/-groesse/-mtime
unveraendert. Das Bildmanifest speichert55PASS vor der anschliessenden
Datei-Oeffnen-Pruefung; deren PASS ergibt den finalen Logstand56PASS.
Die tatsaechliche GM01 installiert62 niedrige Props in zwei Batches und
prueft512 Kandidaten;480 ist die Obergrenze, kein aufgefuelltes Soll.

Finale SHA256: Helper
`b67d0a1756c82d44394ab518960125a8b60d8496c06d4342afc0ad568b1cd91a`,
Layout `7827ae90a46d842c19e0fee730f75bc840988feb02abaeb434ffd84d1d470d8f`,
TerrainView `e87cfe88e3723e973a2cce8d5092c28e3b3c2b5d4ef3c683c05d061ed85a5a75`.
CPU-Verifier `ad32367ad287af26970b9a552cfdbf3bb721b6f4d4891bc979e93a081a599968`,
GPU-Verifier `b954736817882ac965abd583f6b135ef4cb6c060c30770b69da98ff8d63b8e02`.

Produktquellen bleiben eingefroren. Normales Spiel, matched Kamera34-/Default22-
Vergleichsbilder und Performance, finale unabhaengige Gesamtabnahme sowie
Main-Integration sind noch keine bestaetigten World-Ergebnisse. Root besitzt saemtliche
Engine-/Import-/Gitlaeufe; der World-Agent hat keinen solchen Lauf gestartet.

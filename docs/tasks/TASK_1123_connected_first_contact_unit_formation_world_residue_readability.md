# TASK_1123 - Connected First Contact Unit Formation and World Residue Readability

## Ziel / Problem
Der verbundene Erstkontakt zeigt vier Fireteam-Proxies als schwer lesbare vertikale Reihe. Rechts neben dem fokussierten Kontakt steht ausserdem ein isolierter hoher Assetblock, dessen Herkunft und taktische Relevanz im Bild unklar sind.

## Sinnhaftigkeit / Ursache
Der Drei-Peer-Produktfixture setzt Einheiten mit 32-Pixel-Offsets entlang einer unter der isometrischen Kamera unguenstigen Tiefenachse. Das ist von der produktiven Fireteam-Formation zu trennen. Der isolierte Block darf erst nach einem Bounds-/Zellenabgleich veraendert werden, damit kein echtes Cover oder Stationsziel als vermeintlicher Renderrest entfernt wird.

## Umfang
- Read-only Diagnose der direkten `MapRoot3D`-Assetgrenzen mit Node-Name, Zelle, Weltposition und visueller AABB.
- Produktfixture nutzt eine isometrisch lesbare, realistische Viereraufstellung.
- Automatische Pruefung der projizierten Mindestabstaende im Erstkontakt.
- Identifizierten Weltrest an seiner Quelle korrigieren oder als beabsichtigtes Kartenasset dokumentieren und im lokalen Contact-Fokus lesbar behandeln.

## Nicht-Ziele
- Kein Rewrite der produktiven Fireteam-Bewegung oder Formation ohne reproduzierbaren Runtime-Befund.
- Keine Aenderung an Combat, Pathfinding, UnitRegistry, Netzwerkpayload oder autoritativem State.
- Kein per-frame Asset-Scan und kein pauschales Entfernen entfernter Kartenobjekte.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1122_connected_mission_world_camera_exposure_contact_cluster_readability.md`
- `docs/tasks/TASK_1119_connected_first_contact_three_peer_product_visual_playtest.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/ARCHITECTURE.md`

## Akzeptanzkriterien
- BLUE und GOLD zeigen vier unterscheidbare Fireteam-Proxies statt einer Tiefenlinien-Stapelung.
- Der Produktfixture prueft projizierte Mindestabstaende vor dem Capture.
- Bestehende Runtime-Formation-/Spacing-Verifier bleiben gruen.
- Der rechte Assetblock ist ueber Node/Zelle/AABB eindeutig identifiziert; eine Korrektur veraendert keine Gameplay-Wahrheit.
- Assetdiagnose ist explizit aufrufbar, read-only und nicht Teil des Frame-Hotpaths.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_1119_connected_first_contact_three_peer_product_visual_playtest.gd`
- `scripts/tests/task_1123_connected_first_contact_unit_formation_world_residue_readability.gd`
- Status-, Roadmap- und HTML-Berichtsdokumentation

## Lokale Pruefung
- TASK_1123 headless.
- TASK_1119 headless und Real-Window je BLUE/GOLD.
- Formation-/Spacing-Regressionen TASK_423, TASK_446, TASK_452 und TASK_475.
- TASK_1122, TASK_1104 und TASK_222 Performance-Gate.
- `git diff --check`.

## Risiken / offene Punkte
Eine bildlich isolierte Struktur kann ein gueltiges, weit entferntes Kartenasset sein. In diesem Fall ist nicht das Asset selbst, sondern das lokale Framing oder seine visuelle Prioritaet zu korrigieren. Diagnose-Bounds duerfen nicht in regelmaessige Render-Snapshots aufgenommen werden.

## Ergebnis / Verifikation
- Der TASK-1119-Fixture setzt BLUE und GOLD nicht mehr entlang einer isometrischen Tiefenlinie, sondern in einem symmetrischen Raster. Die Projektion prueft fuer die realen Drei-/Vierer-Roster Mindestdistanz sowie horizontale und vertikale Spannweite.
- Der bestehende TASK-1120-Vertrag fuer abgeschlossene, leere `to_fob`-Karten filtert dieselben Eintraege nun auch vor dem World-Dropship-Visual-Build. Aktive oder beladene Crafts bleiben unveraendert.
- Der Drei-Peer-Capture isoliert Ziel-Lobby, CanvasLayer und eingebetteten SubViewportContainer, ohne die anderen MultiplayerAPIs anzuhalten.
- `get_map_visual_bounds_snapshot()` bietet nur auf expliziten Aufruf read-only Bounds, Surface-/HeightEdge-Screenprojektionen und sichtbare Meshpfade. Der normale Render-Snapshot und Frame-Hotpath bleiben unberuehrt.
- TASK_1123 9/9, TASK_1119 27/27 headless und bis 32/32 Real Window, TASK_1120 11/11, TASK_1122 11/11, TASK_423 12/12, TASK_446 30/30, TASK_475 17/17, TASK_1104 31/31 und TASK_222 82/82.
- Offener Sichtbefund: Ein weisser Doppelblock bleibt im Contact-Capture sichtbar, obwohl Dropship-Worldcount null ist und am Bildort weder normales Zielwelt-Mesh noch registrierte Surface-/HeightEdge-Zelle liegt. Das wird als TASK_1124 weiter isoliert; keine spekulative Runtime-Loeschung in diesem Task.

# TASK_505 - Frontier Probe Large Map Playtest Hotfix

## Ziel / Problem
Der 192x192-Playtest zeigt, dass Rendering und Chunk-Streaming funktionieren, der Dropship-Anflug aber mit der kompletten Mapgroesse skaliert und dadurch auf grossen Karten zu langsam wird. Zusaetzlich wird die Map-Bounds-Berechnung im Dropship-Hotpath wiederholt ueber alle Terrain-Tiles gescannt.

## Sinnhaftigkeit / Ursache
Die Startmap soll gross sein, aber der Spielerpfad muss weiter sehr schnell reagieren: LZ setzen, Dropship rufen, Fireteam aussteigen lassen, Befehle geben, Kontakt sehen und Objective abschliessen. Offmap-Distanz darf deshalb nicht linear mit der Kartenkante wachsen, und Bounds duerfen nicht pro Drop-Frame als 36k-Tile-Scan laufen.

## Umfang
- Dropship-Offmap-Distanz auf einen schnellen Maximalwert begrenzen.
- Map-World-Bounds im Tactical Controller per TerrainRegistry-Revision cachen.
- Einen Frontier-Probe-Playtest-Runner ergaenzen, der die 192x192-Map mit Dropship, LZ, Orders, Kontakt und Victory durchlaeuft.
- Performance-Snapshots fuer Initialrender, Kamera-Chunkwechsel, Drop, Orders, Kontakt und Finale ausgeben.

## Nicht-Ziele
- Kein neues Missionsbalancing.
- Keine Aenderung an Dropship-Kapazitaet, Fireteam-Auswahl oder Kampfregeln.
- Keine neue Terrain-Streaming-Architektur.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/dev/terrain_truth_visual_audit_contract.md`
- `docs/tasks/TASK_504_startmap_expansion_performance_pass.md`

## Akzeptanzkriterien
- Frontier Probe laeuft mit `station_outpost_192x192.json` durch LZ, Dropship, Deboarding, Orders, Kontakt und Objective-Victory.
- Der Dropship-Sequence-Pfad erreicht `outbound` im schnellen Playtest-Fenster.
- Die 2.5D-Ansicht nutzt weiter Visual-Streaming und rendert nicht alle 36.864 Tiles.
- Kamera-Fokuswechsel ueber grosse Sektoren bleiben chunked.
- Der Dropship-Distanzpfad nutzt gecachte Map-Bounds statt wiederholter Vollscans.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`
- `docs/tasks/TASK_505_frontier_probe_large_map_playtest_hotfix.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_505_frontier_probe_large_map_playtest_hotfix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_504_startmap_expansion_performance_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_399_dropship_flow_contract_performance_pass.gd`
- `git diff --check`

## Risiken / offene Punkte
- Headless-Renderzeiten sind nur Smoke-Werte; ein sichtbarer F6-/Homebase-Sichttest bleibt fuer echtes Spielgefuehl sinnvoll.
- Die Factory-GLBs melden weiter bekannte UID-Warnungen beim Laden der Colormap, ohne den Test zu brechen.

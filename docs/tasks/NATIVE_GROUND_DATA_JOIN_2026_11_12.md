# Native ground data join 2026-11-12

## Ziel / Ursache
Der gemeinsame isolierte Integrationsstand enthaelt trotz uebernommener Rampenvertraege noch A/B/C mit jeweils 96x98 Zellen. Der verbindliche Originalauftrag verlangt exakt 512 breit x 256 hoch, 131072 echte persistierte Zellen pro Karte.

## Basis / Umfang / Nicht-Ziele
Gemeinsamer Branch codex/open-functions-release-20261112; Datenquelle ausschliesslich committed 1b924b640 (einschliesslich Plateau-/Rampenrevision 5204312c0). Port der drei Bodenkarten, begrenzter Python-Authoringpfad, fehlendes kuratiertes Sandsteinasset samt editierbarer Quelle und ausschliesslich fehlende glut-Katalogeintraege. Aktuelle Missions-/Job-/Ressourcen-IDs und Rootmetadaten erhalten. Keine Heimatbasis-, Polisa-, Sternkarten-, Runtime-, Renderer-, Shader- oder globale Hex-Optin-Aenderung; keine grossen Gefechtstests, kein Commit/Push durch diesen Teilauftrag.

## Vertraege / Dokumente
Original: C:/Users/bjoer/.codex/visualizations/2026/11/10/01a1c61f-714c-7b51-829d-277d83d7d62b/integration_handoff_20261110/INTEGRATIONSAUFTRAG.md.
MAP_WORLD_REBUILD_2026_11_10.md aus Quelle1b; hex_grid_v1_contract, graphics_reference_revision_contract, terrain_truth_visual_audit_contract, explicit_hex_ramps_contract, map_builder_tooling_spike_contract, persistent_location_runtime_contract. TerrainMapData besitzt SaveAs-Metadaten und Rampen; Registry besitzt den Checkpoint-Fingerprint.

## Akzeptanz / betroffene Dateien
maps/{satellite_crash_site,trade_outpost,fortified_outpost}.json: je 131072 eindeutige Axialzellen, odd-r Spalten -170..341 und Zeilen -108..147, H0..H8, explizite Rampen. Semantische Marker-, Strukturen-, Ressourcen- und Szenarioidentitaeten erhalten. B-Lager +66q, C-Chipcompound +91q/H4 entsprechen Originalquelle. data/terrain_tile_catalog.json und terrain_3d_asset_mapping.json erhalten nur fehlenden glut_sandstone_04-Eintrag. Assets/curated/glut_regional und art/glut_regional behalten Quellenbeleg. scripts/tools/build_native_glut_ground.py und curate_glut_rocks.py werden aus Git portiert. Legacy96-Exporte bleiben unter maps/legacy/native_ground_20261112/ erhalten.

## Lokale Pruefung
Kleine Python-Zell-/ID-/Metadaten-/Asset- und Rampenpruefung; deterministische A/B/C-Authoringkontrolle in separater Ausgabe, kein breiter Kapitelgenerator. Begrenzter echter TerrainMapData-SaveAs/Reload fuer alle drei Karten, sofern vorhandene Engine verfuegbar. Ergebnisse im lokalen QA-Nachweis.

## Risiken / Savepolitik
Die Kartenrevision aendert Geometrie und Registry-Fingerprint. Aktive Oberflaechensaves duerfen nicht still in geaenderte Karten geladen werden: bestehende Companion-Validierung muss map_fingerprint ablehnen, oder explizit die erhaltene Legacykarte laden; kein automatischer Aktorversatz. Urspruengliche Home-only-Checkpoints haben keine aktiven Oberflaechenpositionen und behalten semantische Orts-/Ressourcen-IDs. Legacy-JSON-Exporte sind Erhaltung, keine neue automatische Save-Routing-Funktion. Native Stil-, Performance- und Gefechtsabnahme bleiben separat offen.

## Ergebnis
Port und enge Pruefung abgeschlossen. A/B/C source- und deterministic-byteidentisch; alle131072 Zellen je Karte,75/85/65 Rampen. Godot4.6.2 SaveAs/Reload92 Checks0 Fehler; bestehende kanonische Marker-/Enemy-Normalisierung gesondert dokumentiert. Nachweise: docs/qa/native_ground_data_join_20261112/README.md. Kein Commit/Push durch diesen Teilauftrag.

# Used Asset Project Locality Audit

Datum: 2026-05-07
Status: TASK_247 Audit-Gate implementiert

## Ergebnis
Runtime local user path violations: 0

Das Gate trennt echte Runtime-Verstoesse von absichtlichen Pruef-Literalen und Dokumentationsnotizen. Genutzte Runtime-Assets muessen als `res://`-Pfad im Projekt liegen und per `ResourceLoader.exists()` oder `FileAccess` nachweisbar sein.

Lokaler Lauf:
- Godot-Gate: 27 Checks, 0 Fehler.
- PowerShell-Scan: 10536 Textdateien, 0 Runtime-Verstoesse, 19 Guard-Literale, 71 Dokumentations-/Source-Notes, 0 Import-Metadaten-Notes.

## Scan-Scope
- Runtime-Texte: `scenes/`, `scripts/` ohne `scripts/tests/`, `data/`, `maps/`, `project.godot`.
- Asset-Metadaten: katalogisierte Dateien unter `data/` plus genutzte `.tscn`-/Script-Referenzen.
- Dokumentations-/Quellnotizen: `docs/` und README-/License-Dateien unter `Assets/`.
- Test-Harness-Dateien werden nicht als Runtime gewertet, weil sie lokale Pfadmuster absichtlich als verbotene Testdaten enthalten koennen.

## Catalogs checked
- `data/audio_sfx_catalog.json`
- `data/background_image_catalog.json`
- `data/comic_bubble_asset_catalog.json`
- `data/curated_asset_catalog.json`
- `data/npc_unit_visual_mapping.json`
- `data/portrait_identity_catalog.json`
- `data/rank_particle_asset_catalog.json`
- `data/space_setpiece_catalog.json`
- `data/terrain_3d_asset_mapping.json`
- `data/ui_asset_catalog.json`
- `data/weapon_fire_vfx_catalog.json`

## ResourceLoader gate
- Runtime-Pfade muessen mit `res://` beginnen.
- Asset-Dateien muessen im Projekt existieren.
- Importierbare Assets (`png`, `jpg`, `jpeg`, `ogg`, `wav`, `glb`, `fbx`, `tscn`, `tres`) werden ueber `ResourceLoader.exists()` geprueft.
- Importierte Audio-, Bild- und Modellassets muessen `.import`-Metadaten besitzen.
- `res://`-Verzeichnisse wie `project_root` oder `source_root` werden als Verzeichnisse geprueft, nicht als Resource.
- Dynamische Runtime-Prefixe wie richtungsabhaengige Weapon-Sprite-Basen und beschreibbare Mission-Scenario-Zielpfade werden getrennt von Asset-Resources bewertet.

## Allowed documentation/source notes
Erlaubt sind lokale Quellpfade nur in reinen Dokumentations- oder Source-Hinweisen, zum Beispiel Inventar- oder README-Dateien. Sie duerfen nicht als Runtime-Fallback dienen.

Aktuell bekannte erlaubte Source-Hinweise:
- Asset-README-Dateien fuer Blaster Kit, Animated Characters, Rank/Particle Sources.
- Doku-Inventare, die `%USERPROFILE%` oder lokale Bilderordner nur als Importquelle nennen.
- Guard-Literale in Runtime-Resolvern, die lokale Pfade aktiv erkennen und ablehnen.

## Reported Corrections
- Kein Runtime-Asset musste fuer TASK_247 kopiert werden.
- Kein katalogisierter `res://`-Pfad musste ersetzt werden.
- Das Gate ist als wiederholbarer Godot-Test unter `scripts/tests/task_247_used_asset_project_locality_audit_gate.gd` und als PowerShell-Textscan unter `scripts/tests/run_task_247_asset_locality_scan.ps1` verfuegbar.

## Follow-Up
TASK_248 kann auf diesem Gate aufsetzen und Audio-/Visual-Assets in einem praktischen Load-/Playback-Smoke testen.

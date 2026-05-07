# TASK_247 - Used Asset Project Locality Audit Gate

## Ziel
Alle tatsaechlich genutzten Dateien muessen im Projektordner liegen und ueber `res://` erreichbar sein. Der Task baut ein Audit-Gate gegen lokale User-Pfade, versehentlich referenzierte Quellenordner und nicht importierte Assets.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_193 - Asset Source Inventory and Availability Matrix
- TASK_197 - Central Asset Catalog and Usage Gate
- TASK_242 - Audio SFX Source Inventory and Curated Import
- TASK_245 - Background Image Catalog and Screen Usage
- TASK_246 - Visual Scale Alignment Asset Pass

## Kontext
Die lokalen Quellen unter `%USERPROFILE%\Pictures\...` sind nur Importquellen. Sobald ein Asset im Spiel benutzt wird, muss es projektlokal sein. Das gilt fuer Sounds, Bilder, Modelle, UI-Assets, Portraits, Particles, Backgrounds, Waffen und NPC-Visuals.

## Umfang
1. Dateiquellen scannen:
   - `scenes/`, `scripts/`, `data/`, `Assets/`, `.tscn`, `.tres`, `.res`, `.import`.
   - Muster: `C:\`, `C:/Users`, `%USERPROFILE%`, `file://`, absolute Bild-/Audio-/Modellpfade.
   - Erlaubte Ausnahmen nur in reiner Doku/Manifest-Quelle, nicht in Runtime-Daten.
2. Kataloge pruefen:
   - `data/audio_sfx_catalog.json`
   - `data/background_image_catalog.json`
   - `data/npc_unit_visual_mapping.json`
   - zentrale Asset-Kataloge aus TASK_197.
3. ResourceLoader-Gate:
   - Jeder Runtime-Pfad beginnt mit `res://`.
   - Jede Resource existiert und ist importierbar.
   - Fehlende `.import`-/UID-Probleme sichtbar machen.
4. Used-vs-Unused-Regel:
   - "Genutzt" heisst: aus Szene, Code, Datenkatalog oder Mapping referenziert.
   - Nicht genutzte lokale Quellpfade duerfen nur in Doku stehen.
   - Doppelte Kopien oder Pack-Massenreste markieren.
5. Report:
   - `docs/reviews/used_asset_project_locality_audit.md`
   - Liste aller geprueften Kataloge, gefundenen Verstoesse, erlaubten Doku-Ausnahmen.

## Nicht-Ziele
- Kein neuer Asset-Import ausser kleinen Fixkopien fuer fehlende genutzte Dateien.
- Keine Loeschaktion grosser ungenutzter Asset-Bestaende ohne eigenen Cleanup-Task.
- Kein Lizenz-Audit ueber die bereits dokumentierte Quelle hinaus.

## Akzeptanzkriterien
- [x] Runtime-Dateien referenzieren keine lokalen User-Pfade.
- [x] Alle genutzten Audio-, Background-, Model-, Particle-, UI- und Portrait-Dateien liegen im Projektordner.
- [x] Alle Runtime-Pfade sind `res://`-Pfade und per ResourceLoader pruefbar.
- [x] Doku/Manifest-Ausnahmen fuer lokale Quellen sind klar getrennt.
- [x] Ein TASK_247-Gate kann nach kuenftigen Asset-Imports erneut laufen.
- [x] Der Report nennt konkrete Dateien und Korrekturen.

## Erwartete Dateien
- `docs/reviews/used_asset_project_locality_audit.md`
- `scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`
- optional `scripts/tests/run_task_247_asset_locality_scan.ps1`
- `docs/tasks/TASK_247_used_asset_project_locality_audit_gate.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_247_used_asset_project_locality_audit_gate.gd`
- [x] `powershell -ExecutionPolicy Bypass -File scripts/tests/run_task_247_asset_locality_scan.ps1`
- [x] `git diff --check`

## Umsetzung
- `scripts/tests/task_247_used_asset_project_locality_audit_gate.gd` prueft 11 Asset-/Runtime-Kataloge, Runtime-Textpfade, Scene-/Script-`res://`-Referenzen, Import-Metadaten und dokumentierte Ausnahmen.
- `scripts/tests/run_task_247_asset_locality_scan.ps1` bietet einen schnellen wiederholbaren Textscan fuer lokale Pfadmuster ohne Godot.
- `docs/reviews/used_asset_project_locality_audit.md` dokumentiert Scope, gepruefte Kataloge, ResourceLoader-Regeln, erlaubte Dokumentations-/Source-Notes und Ergebnis.

## Risiken
- Godot-Importmetadaten koennen Quellinfos enthalten; das Gate muss Runtime-Pfade hart pruefen und Doku-/Import-Hinweise bewusst unterscheiden.
- Zu breite Suchmuster koennen alte Dokumentationshistorie melden. Der Report soll deshalb Pfadtyp und Schweregrad ausweisen.
- Fehlende Projektkopien duerfen nicht durch stilles Laden aus lokalen Quellen kaschiert werden.

## Naechster Schritt
Nach TASK_247 kann TASK_248 alle importierten Audio-/Visual-Assets in einem Playback-/Load-Smoke testen.

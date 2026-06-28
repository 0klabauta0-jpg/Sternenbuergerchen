# Export Runtime Package Contract

## Zweck
Der Runtime-Export soll ein spielbares Release-Paket bauen, nicht die lokale Godot-Editor-/Authoring-Umgebung ausliefern.

`export_presets.cfg` bleibt lokal ignoriert, weil Godot dort nutzer- und rechnernahe Exportdetails speichern kann. Der versionierte Release-Pfad ist `scripts/tools/export_runtime_release.ps1` plus `data/export_runtime_package_contract.json`.

## Runtime-Exclude-Grenze
Aus dem Runtime-Paket ausgeschlossen sind:
- Editor-Plugins, die nur Authoring/Docks bereitstellen.
- Referenzprojekte mit eigenem `project.godot`.
- Dokumentation, Reports und Task-Dateien.
- Headless-Verifier, Test-Harnesses und Generierungstools.
- Temporaere Arbeitsordner.

Nicht ausgeschlossen werden Runtime-Addons und GDExtensions, die im Spielpfad gebraucht werden koennen:
- `addons/limboai`
- `addons/terrain_3d`
- `addons/netfox`
- `addons/netfox.internals`

## Workflow
1. Das Script liest den lokalen `export_presets.cfg`.
2. Es schreibt einen Backup-Snapshot.
3. Es ersetzt nur den `exclude_filter` fuer den Exportlauf.
4. Es ruft Godot mit dem gewaehlten Preset auf und schreibt Godot-stdout/stderr als normales Export-Log.
5. Es stellt den lokalen Preset wieder her, ausser `-KeepPatchedPreset` ist explizit gesetzt.

## Regeln
- Keine privaten Codesigning- oder User-Pfade in getrackte Dateien schreiben.
- Exclude-Pattern nur ueber `data/export_runtime_package_contract.json` erweitern.
- Nach Export-Hygiene-Aenderungen mindestens den TASK_511-Verifier und `git diff --check` ausfuehren.
- Ein echter Release-Export soll das Pack-Log stichprobenartig gegen ausgeschlossene Pfade pruefen.
- Eine Godot-Scanwarnung fuer ein zweites `project.godot` in einem ausgeschlossenen Referenzprojekt ist kein Export-Abbruch; der Script-Exit haengt am nativen Godot-Exitcode.

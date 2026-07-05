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
6. Nach dem Export kann `scripts/tools/release_runtime_start_check.ps1` den vertraglichen Spieleordner read-only pruefen und ein Manifest unter `tmp/release_runtime_start_check.json` schreiben.

## Release-Startcheck
Der Startcheck ist kein Launcher und keine Taskleisten-Reparatur. Er liest `data/export_runtime_package_contract.json`, loest `runtime_export_path` auf und prueft:
- Release-EXE
- Console-EXE
- PCK
- erlaubte Runtime-GDExtension-DLLs
- laufende Prozesse aus genau diesem Release-Pfad
- Windows-Temporaerdateien nach ueberschriebenen/gesperrten Runtime-Dateien

Fehlende Pflichtdateien sind ein hartes Fail-Gate. Laufende Prozesse oder `~RF*.TMP`-Dateien erzeugen ein Review-Gate, weil Codex sie ohne explizite Freigabe nicht beendet oder entfernt.

## Gepruefter Release-Start
`scripts/tools/start_release_runtime_checked.ps1` ist der explizite Playtest-Startgriff fuer den geprueften Runtime-Ordner. Ohne Schalter fuehrt er nur Vor- und Nachcheck aus. Mit bewussten Schaltern darf er:
- `-StopRunningReleaseProcess`: nur Prozesse beenden, deren Pfad exakt aus dem Release-Startcheck kommt.
- `-CleanTempFiles`: nur die vom Startcheck gemeldeten `~RF*.TMP`-Dateien entfernen.
- `-Launch`: die EXE aus `runtime_export_path` mit dem Release-Ordner als Working Directory starten.

Der Helfer schreibt `tmp/release_runtime_checked_launcher.json` und ersetzt keinen menschlichen Sichttest.

## Regeln
- Keine privaten Codesigning- oder User-Pfade in getrackte Dateien schreiben.
- Exclude-Pattern nur ueber `data/export_runtime_package_contract.json` erweitern.
- Nach Export-Hygiene-Aenderungen mindestens den TASK_511-Verifier und `git diff --check` ausfuehren.
- Ein echter Release-Export soll das Pack-Log stichprobenartig gegen ausgeschlossene Pfade pruefen.
- Eine Godot-Scanwarnung fuer ein zweites `project.godot` in einem ausgeschlossenen Referenzprojekt ist kein Export-Abbruch; der Script-Exit haengt am nativen Godot-Exitcode.
- Der Startcheck darf keine Prozesse starten, keine laufenden EXEs beenden und keine Shortcuts veraendern.
- Der gepruefte Launcher darf Prozesse nur mit explizitem Schalter und nur aus dem vertraglichen Release-Pfad beenden.

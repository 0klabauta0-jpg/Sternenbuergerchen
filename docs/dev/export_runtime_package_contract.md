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

Der sichtbare Mission-Controller liegt historisch noch unter `scripts/tests/`.
Bis ein eigener Extraction-Task diesen Legacy-Bridge-Pfad migriert, ist
`scripts/tests/` deshalb als explizite Runtime-Script-Abhaengigkeit im
Exportvertrag dokumentiert und darf nicht pauschal ausgeschlossen werden.

## Kompatible Originalportraets
Die 42 `legacy_paths` des Portraetkatalogs sind vom Runtimeexport ausgeschlossen;
ihre Quellen bleiben im Repository erhalten. Die uebrigen 57 Originale unter
`Assets/Char` bleiben fuer alte individuelle Auswahlen verfuegbar. Kein
pauschaler Ordnerausschluss und keine Umschreibung gespeicherter IDs/Pfade.

Direkte Portraet- und Emblemverbraucher loesen ausschliesslich bekannte Aliasse
vor einer Existenzpruefung oder einem Load auf. Unbekannte Pfade und deren
bisherige Leer-/Fehlerbehandlung bleiben erhalten. Da der Godot-Exportfilter
Kommas als Trenner verwendet, stehen in den 40 betroffenen Dateinamen einzelne
`?` anstelle der Kommas. Alle 42 Filter muessen gemeinsam genau diese 42
Originale und keines der 57 weiteren Bilder treffen.

`python scripts/tests/altlasten_portrait_export_probe.py --backend exporter
--phase final --filters production --label final --run` prueft diese Grenze
mit dem echten Godot-Exporter in einem isolierten Mini-Projekt. Es startet mit
allen 99 Originalen, ihren kopierten Importdateien und den aktuellen Atlanten;
der anschliessende PCK-Lauf darf keine losen Quelldateien finden. Alte
Import-Sidecars und Texturpayloads muessen fehlen, waehrend 42 Aliasidentitaeten,
57 weitere Originale und gespeicherte Emblemauswahlen weiter funktionieren.
Die Verbrauchermethoden werden unveraendert aus dem aktuellen Code extrahiert;
vollstaendige Szenenregressionen und eine Releasefreigabe bleiben getrennt.

## Workflow
1. Das Script liest den lokalen `export_presets.cfg`.
2. Es schreibt einen Backup-Snapshot.
3. Es ersetzt nur den `exclude_filter` fuer den Exportlauf.
4. Es ruft Godot mit dem gewaehlten Preset auf und schreibt Godot-stdout/stderr als normales Export-Log.
5. Nach einem erfolgreichen Export schreibt es `release_build_provenance.json` neben EXE und PCK. Die Datei enthaelt den vollen Git-Commit, Branch, Exportzeit, PCK-Groesse und SHA-256 des PCK.
6. Es stellt den lokalen Preset wieder her, ausser `-KeepPatchedPreset` ist explizit gesetzt.
7. Nach dem Export kann `scripts/tools/release_runtime_start_check.ps1` den vertraglichen Spieleordner read-only pruefen und ein Manifest unter `tmp/release_runtime_start_check.json` schreiben.

Der Export verweigert bewusst getrackte, nicht committete Aenderungen. Lokale untracked Arbeitsordner bleiben davon unberuehrt. So kann die Provenance nicht eine Commit-ID behaupten, waehrend der PCK noch uncommitteten Code enthaelt.

## Release-Startcheck
Der Startcheck ist kein Launcher und keine Taskleisten-Reparatur. Er liest `data/export_runtime_package_contract.json`, loest `runtime_export_path` auf und prueft:
- Release-EXE
- Console-EXE
- PCK
- erlaubte Runtime-GDExtension-DLLs
- laufende Prozesse aus genau diesem Release-Pfad
- Windows-Temporaerdateien nach ueberschriebenen/gesperrten Runtime-Dateien

Fehlende Pflichtdateien sind ein hartes Fail-Gate. Laufende Prozesse oder `~RF*.TMP`-Dateien erzeugen ein Review-Gate, weil Codex sie ohne explizite Freigabe nicht beendet oder entfernt.

Zusatzlich ist die Build-Provenance Pflicht: Fehlende oder unlesbare Provenance, ein anderer Git-Commit oder ein abweichender PCK-Hash sind harte Fehler. Der Startcheck berechnet den PCK-Hash absichtlich nur als manuellen Release-Gate, nie im Spiel oder einem Runtime-Hotpath.

## Gepruefter Release-Start
`scripts/tools/start_release_runtime_checked.ps1` ist der explizite Playtest-Startgriff fuer den geprueften Runtime-Ordner. Ohne Schalter fuehrt er nur Vor- und Nachcheck aus. Mit bewussten Schaltern darf er:
- `-StopRunningReleaseProcess`: nur Prozesse beenden, deren Pfad exakt aus dem Release-Startcheck kommt.
- `-CleanTempFiles`: nur die vom Startcheck gemeldeten `~RF*.TMP`-Dateien entfernen.
- `-Launch`: die EXE aus `runtime_export_path` mit dem Release-Ordner als Working Directory starten.

Der Helfer schreibt `tmp/release_runtime_checked_launcher.json` und ersetzt keinen menschlichen Sichttest.

Wenn `-Launch` gesetzt ist, darf der Nachcheck den dadurch gestarteten Prozess als erwarteten Lauf behandeln. Weitere laufende Release-Prozesse bleiben Warnungen, damit ein Altfenster nicht als erfolgreicher Neustart durchrutscht.

## Regeln
- Keine privaten Codesigning- oder User-Pfade in getrackte Dateien schreiben.
- Exclude-Pattern nur ueber `data/export_runtime_package_contract.json` erweitern.
- Nach Export-Hygiene-Aenderungen mindestens den TASK_511-Verifier und `git diff --check` ausfuehren.
- Ein echter Release-Export soll das Pack-Log stichprobenartig gegen ausgeschlossene Pfade pruefen.
- Eine Godot-Scanwarnung fuer ein zweites `project.godot` in einem ausgeschlossenen Referenzprojekt ist kein Export-Abbruch; der Script-Exit haengt am nativen Godot-Exitcode.
- Der Startcheck darf keine Prozesse starten, keine laufenden EXEs beenden und keine Shortcuts veraendern.
- Der gepruefte Launcher darf Prozesse nur mit explizitem Schalter und nur aus dem vertraglichen Release-Pfad beenden.
- Der gepruefte Launcher darf einen gestarteten Release-Prozess nur dann als Erfolg werten, wenn seine Prozess-ID im Nachcheck wiedergefunden wird und keine weiteren unerwarteten Release-Prozesse laufen.

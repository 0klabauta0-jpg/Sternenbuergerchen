# TASK_511 - Export Runtime Package Hygiene

## Ziel / Problem
Der aktuelle Windows-Export laeuft, packt aber mit `export_filter="all_resources"` und leerem `exclude_filter` Editor-/Authoring-Inhalte mit in das Release. Im letzten Export waren unter anderem Asset-Placer-, Godot-MCP- und Open-RTS-Referenzdateien im Pack-Log sichtbar.

## Sinnhaftigkeit / Ursache
Das Spiel soll Richtung fertig/releasefaehig wachsen. Ein Release-Paket darf keine Editor-Plugins, Referenzprojekte, Test-Harnesses, Tools oder Dokumentationsartefakte mitschleppen. Diese Inhalte vergroessern Exportzeit und PCK-Groesse, erzeugen Warnungen wie das zweite `project.godot` im Referenzordner und machen Performance-/Deploy-Checks unklar.

## Umfang
- Getrackten Runtime-Export-Contract anlegen.
- Getracktes Export-Script anlegen, das den lokal ignorierten `export_presets.cfg` nur temporaer fuer den Runtime-Export patcht.
- Editor-/Authoring-/Test-/Docs-Pfade aus dem Runtime-Paket ausschliessen.
- Verifier fuer Contract, Script und Pattern-Guards anlegen.

## Nicht-Ziele
- Kein Umbau des Godot-Projekts.
- Kein Entfernen von Editor-Plugins aus dem Repo.
- Kein neues Installer-/Patch-System.
- Kein Tracking privater Codesigning- oder User-Exportdaten.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/performance/performance_regression_gate.md`
- `docs/tasks/TASK_487_install_godot_asset_placer.md`
- `docs/tasks/TASK_433_install_third_party_godot_plugins.md`

## Akzeptanzkriterien
- Runtime-Export-Excludes sind versioniert und pruefbar.
- Der Export-Workflow kann lokal laufen, ohne den ignorierten `export_presets.cfg` dauerhaft zu veraendern.
- Editor-/Authoring-Pfade wie `addons/asset_placer`, `addons/godot_mcp`, `addons/godot_open_rts_reference`, `addons/map_builder_workbench`, `docs`, `scripts/tests` und `scripts/tools` sind im Runtime-Export ausgeschlossen.
- Runtime-kritische Addons wie `limboai`, `terrain_3d`, `netfox` und `netfox.internals` werden nicht ausgeschlossen.

## Betroffene Dateien
- `data/export_runtime_package_contract.json`
- `docs/dev/export_runtime_package_contract.md`
- `scripts/tools/export_runtime_release.ps1`
- `scripts/tests/task_511_export_runtime_package_hygiene.gd`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_511_export_runtime_package_hygiene.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1 -SkipExport`
- Release-Export: `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `git diff --check`

## Ergebnis / Messung
- Der Release-Workflow endet mit `EXPORT_EXIT=0`.
- `Sternenbuergerchen_rel.pck` liegt nach dem gefilterten Export bei `194203876` Bytes statt zuvor `242312564` Bytes im breiten Roh-Export.
- Die Pack-Log-Stichprobe enthaelt keine gespeicherten `addons/asset_placer`, `addons/godot_mcp`, `addons/map_builder_workbench`, `scripts/tests`, `scripts/tools` oder `docs/`-Pfade.

## Risiken / offene Punkte
- Der lokale `export_presets.cfg` bleibt bewusst ignoriert. Der neue Release-Pfad ist das Script.
- Godot scannt vor dem Packen weiterhin das ausgeschlossene Referenzprojekt und meldet das zweite `project.godot`; das ist nach aktuellem Export kein Abbruch und keine Pack-Entry-Stelle.
- Godot-Exclude-Pattern-Verhalten muss bei spaeteren echten Exporten weiter im Pack-Log beobachtet werden; der Verifier prueft Contract und Script, nicht den gesamten PCK-Inhalt.

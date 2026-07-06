# BUGFIX - Release Export Mission Runtime Test Dependencies

## Problem
Der exportierte `Einzelspieler`-Klick zeigte nur die rohe Homebase mit `Operation: FOB Transfer`, leerem Flightdeck und `Start blockiert`. Die Console-EXE meldete beim Szenenwechsel, dass `res://scripts/tests/mission_*.gd` nicht gefunden wird und dadurch `scripts/meta/meta_layer_flow.gd` wegen des `mission_reactivity_test.tscn`-Preloads nicht geladen werden kann.

## Ursache
Der Runtime-Export-Vertrag schloss `scripts/tests/**` pauschal aus. Die aktuelle Live-Missionsszene liegt historisch noch unter `scenes/tests/mission_reactivity_test.tscn` und referenziert mehrere Skripte unter `scripts/tests/`. Solange diese Szene die reale Mission fuer MetaLayer/Singleplayer ist, sind diese Dateien keine reinen Testartefakte, sondern Runtime-Abhaengigkeiten.

## Umfang
- `scripts/tests/**` wird aus dem Runtime-Exclude-Filter entfernt.
- Der Export darf weiterhin Docs, Tools, Editor-Plugins und `tmp/` ausklammern.
- Der Fix ist bewusst als Uebergang markiert, bis die runtime-relevanten Mission-Skripte aus `scripts/tests/` in echte Runtime-Pfade umgezogen sind.

## Nicht-Ziele
- Kein grosser Move der Missionsszene oder ihrer Skripte.
- Kein Umbau des MetaLayer-Missionshosts.
- Kein Entfernen der Export-Hygiene fuer Docs, Tools oder Editor-Plugins.

## Relevante Contracts / Dokumente
- `data/export_runtime_package_contract.json`
- `docs/dev/export_runtime_package_contract.md`
- `docs/tasks/BUGFIX_singleplayer_release_mission_selection_guard.md`
- `docs/tasks/TASK_818_station_reentry_release_candidate_playable_build_acceptance.md`

## Akzeptanzkriterien
- Die exportierte `MetaLayerFlow`-Scene kann `mission_reactivity_test.tscn` laden, ohne an fehlenden `scripts/tests/mission_*.gd`-Dateien zu scheitern.
- `Einzelspieler` fuehrt in der Release-EXE wieder durch den MetaLayer-Bootstrap statt in die rohe HomebaseScreen-Default-Ansicht.
- Langfristige Folgearbeit bleibt sichtbar: Runtime-Missionsskripte gehoeren aus `scripts/tests/` herausgezogen.

## Betroffene Dateien
- `data/export_runtime_package_contract.json`
- `docs/tasks/BUGFIX_release_export_mission_runtime_test_dependencies.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_release_export_mission_runtime_dependencies.gd`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/export_runtime_release.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1 -StopRunningReleaseProcess -CleanTempFiles -Launch`
- Release-EXE sichtbar: `Einzelspieler` klicken und Homebase capturen.

## Risiken / offene Punkte
Das Runtime-Paket wird groesser und enthaelt voruebergehend auch Testskripte. Das ist fuer den aktuellen Release weniger riskant als ein kaputter Singleplayer-Start, sollte aber als Folgearbeit durch einen Move der Missionsruntime aus `scripts/tests/` bereinigt werden.

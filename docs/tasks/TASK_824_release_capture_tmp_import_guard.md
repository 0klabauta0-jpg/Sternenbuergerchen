# TASK_824 - Release Capture Tmp Import Guard

## Ziel / Problem
Der frische Release-Export hat lokale Sichttest-PNGs aus `tmp/` vor dem eigentlichen Export als Godot-Assets importiert. Der Exportfilter schliesst `tmp/**` zwar aus dem Runtime-Paket aus, aber die lokale Importphase erzeugt unnoetige `.import`- und `.godot/imported`-Artefakte.

## Sinnhaftigkeit / Ursache
Release-Capture-Evidenz ist Arbeitsmaterial, kein Spielinhalt. Wenn Godot Screenshots als Projektassets behandelt, wird der Export lauter, langsamer und schwerer zu beurteilen. Das ist eine kleine, aber echte Release-Hygiene-Reibung.

## Umfang
- `tmp/.gdignore` als bewusst getrackter Godot-Import-Guard.
- Verifier fuer `.gdignore`, Exportfilter und Capture-Output-Pfade.
- Status/Roadmap auf den Guard aktualisieren.

## Nicht-Ziele
- Kein Aendern der Capture-Dateinamen.
- Kein Verschieben bestehender JSON-Manifeste.
- Kein Aendern des Runtime-Export-Pakets ausser der lokalen Importhygiene.
- Kein Gameplay-, UI- oder Multiplayer-Verhalten.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_822_release_singleplayer_visible_window_findings.md`
- `docs/tasks/TASK_823_release_singleplayer_visible_findings_polish.md`
- `data/export_runtime_package_contract.json`
- `scripts/tools/capture_release_singleplayer_visible_window.ps1`
- `scripts/tools/export_runtime_release.ps1`

## Akzeptanzkriterien
- `tmp/.gdignore` existiert im Repo.
- `.gitignore` ignoriert weiterhin lokale `tmp/`-Artefakte.
- Der Runtime-Package-Contract enthaelt `tmp/**` im Export-Exclude-Filter.
- Der sichtbare Release-Capture schreibt weiter in `tmp/`, aber diese Dateien werden von Godot nicht mehr als Assets gescannt.
- Der Guard hat keinen Einfluss auf Gameplay- oder UI-State.

## Betroffene Dateien
- `tmp/.gdignore`
- `scripts/tests/task_824_release_capture_tmp_import_guard.gd`
- `docs/tasks/TASK_824_release_capture_tmp_import_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_824_release_capture_tmp_import_guard.gd`
- `git diff --check`

## Risiken / offene Punkte
- Bereits erzeugte lokale Importreste muessen einmalig entfernt werden; der Guard verhindert danach neue Godot-Importe aus `tmp/`.
- `tmp/` bleibt absichtlich ein Arbeitsordner und ist nicht Teil des Runtime-Pakets.

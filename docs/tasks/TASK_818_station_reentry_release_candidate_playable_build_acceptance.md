# TASK_818 - Station Reentry Release Candidate Playable Build Acceptance

## Ziel / Problem
Der sichtbare EXE-Start muss reproduzierbar gegen den richtigen Spieleordner geprueft werden. Nach dem Singleplayer-Hotfix kann sonst weiterhin ein alter Taskleistenpfad, ein laufender Altprozess oder ein gesperrter Release-Ordner so aussehen, als waere der aktuelle Spielstand noch kaputt.

## Sinnhaftigkeit / Ursache
Der Export schreibt nach `../Sternenbuergerchen_rel`, waehrend lokale Builds, Taskleistenverknuepfungen und laufende Prozesse nebeneinander existieren koennen. Wenn eine EXE noch laeuft, bleiben beim naechsten Export `~RF*.TMP`-Dateien sichtbar und der echte Fensterblick ist nicht eindeutig.

## Umfang
- Read-only Release-Startcheck fuer den vertraglich definierten Runtime-Exportpfad.
- Pruefung der EXE, Console-EXE, PCK und benoetigten Runtime-DLLs.
- Pruefung laufender Release-Prozesse und `~RF*.TMP`-Dateien.
- JSON-Manifest unter `tmp/release_runtime_start_check.json`.
- Startkommando als Hinweis, ohne Prozesse zu starten oder zu beenden.

## Nicht-Ziele
- Keine neue Startlogik.
- Kein automatisches Beenden laufender EXE-Prozesse.
- Keine automatische Taskleisten-Verknuepfungsaenderung.
- Kein Gameplay-, UI-, Mission- oder Multiplayer-State.

## Relevante Contracts / Dokumente
- `docs/dev/export_runtime_package_contract.md`
- `data/export_runtime_package_contract.json`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/BUGFIX_singleplayer_release_exe_actionability_and_firefight_decision_guard.md`

## Akzeptanzkriterien
- `scripts/tools/release_runtime_start_check.ps1` liest den Export-Vertrag und loest den echten Release-Pfad auf.
- Fehlende Runtime-Dateien erzeugen ein hartes Fail-Gate.
- Laufende Release-Prozesse und `~RF*.TMP`-Dateien werden sichtbar gemeldet, aber defaultmaessig nicht als harter Fehler behandelt.
- Das Manifest enthaelt `read_only = true`, `kills_processes = false`, `starts_processes = false` und `updates_shortcuts = false`.
- Der Check ist lokal mit PowerShell ausfuehrbar und schreibt ein maschinenlesbares Manifest.

## Betroffene Dateien
- `scripts/tools/release_runtime_start_check.ps1`
- `docs/tasks/TASK_818_station_reentry_release_candidate_playable_build_acceptance.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/release_runtime_start_check.ps1`
- `git diff --check`

## Risiken / offene Punkte
- Der Check ersetzt keinen echten Sichttest nach dem Start.
- Bei laufender EXE bleibt das Gate bewusst `review`, weil Codex den Prozess nicht ohne explizite Freigabe beendet.
- Eine echte Taskleisten-Reparatur bleibt ein separater manueller Windows-Schritt oder eigener Tool-Task.

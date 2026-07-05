# TASK_819 - Release Runtime Checked Launcher

## Ziel / Problem
Nach einem Export soll der echte Spieleordner mit einem reproduzierbaren, sicheren Befehl gestartet werden koennen. Der letzte Fensterbefund zeigte, dass eine alte laufende Release-EXE und `~RF*.TMP`-Dateien den Eindruck erzeugen koennen, der aktuelle Singleplayer-Fix sei nicht angekommen.

## Sinnhaftigkeit / Ursache
TASK_818 prueft den Release-Zustand read-only. Fuer den praktischen Playtest fehlt ein bewusster naechster Griff: alte Release-Prozesse beenden, gesperrte Temp-Dateien entfernen und exakt die vertragliche EXE starten. Dieser Griff darf nicht automatisch im Check passieren, sondern muss explizit angefordert werden.

## Umfang
- Neuer PowerShell-Helfer `scripts/tools/start_release_runtime_checked.ps1`.
- Nutzt den TASK_818-Startcheck als Vor- und Nachpruefung.
- Optional:
  - `-StopRunningReleaseProcess`
  - `-CleanTempFiles`
  - `-Launch`
- Schreibt `tmp/release_runtime_checked_launcher.json`.

## Nicht-Ziele
- Keine Ingame-Startlogik.
- Keine Taskleisten-Verknuepfungen veraendern.
- Keine Prozessmutation ohne expliziten Schalter.
- Keine Gameplay-, Mission-, UI- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_818_station_reentry_release_candidate_playable_build_acceptance.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `data/export_runtime_package_contract.json`

## Akzeptanzkriterien
- Der Helfer laeuft ohne Schalter als Diagnose und startet/beendet nichts.
- Der Helfer kann mit expliziten Schaltern nur Prozesse aus dem vertraglichen Release-Pfad beenden.
- Temp-Dateien werden nur mit `-CleanTempFiles` entfernt.
- Der Helfer startet nur die EXE aus `runtime_export_path`.
- Das Manifest trennt Vorcheck, Nachcheck, angefragte Aktionen und tatsaechliche Aktionen.

## Betroffene Dateien
- `scripts/tools/start_release_runtime_checked.ps1`
- `docs/tasks/TASK_819_release_runtime_checked_launcher.md`
- `docs/dev/export_runtime_package_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `powershell -ExecutionPolicy Bypass -File scripts/tools/start_release_runtime_checked.ps1`
- `powershell -ExecutionPolicy Bypass -File scripts/tools/release_runtime_start_check.ps1`
- `git diff --check`

## Risiken / offene Punkte
- Der Helfer startet keinen menschlichen Playtest automatisch als bestanden.
- Mit `-StopRunningReleaseProcess` wird ein laufendes Release-Fenster beendet; deshalb bleibt der Default absichtlich nicht-mutierend.
- Eine echte Taskleisten-Reparatur bleibt separat.

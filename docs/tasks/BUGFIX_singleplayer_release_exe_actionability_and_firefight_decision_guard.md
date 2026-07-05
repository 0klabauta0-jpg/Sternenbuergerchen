# BUGFIX - Singleplayer Release EXE Actionability And Firefight Decision Guard

## Ziel / Problem
Der exportierte Einzelspieler-Pfad kann fuer den Spieler wie ein Dead-End wirken: Nach `Einzelspieler` ist ein Fireteam sichtbar, aber Flightdeck/Pilot/Boarding bleiben blockiert und `Start Mission` ist deaktiviert. Zusaetzlich kann der Firefight-Decision-Readout im Release-Log in eine Snapshot-Rekursion laufen.

## Ursache
Der Homebase-Direct-Payload-Seed war zu streng: Wenn die vom MetaLayer uebergebene Fireteam-ID nicht zur aktuell sichtbaren Homebase-Fireteam-Definition passte, wurde kein Payload gesetzt. Der bestehende Bootstrap blieb dann technisch vorhanden, aber der sichtbare Screen zeigte ein leeres Flightdeck. Die `NEXT/WHY`-Firefight-Zeile fragte ausserdem einen HUD-Snapshot ab, der ueber `get_command_feedback_snapshot()` wieder denselben Status-Text aufbauen konnte.

## Umfang
- Homebase-Direct-Seed darf bei einem stale Fireteam-ID-Handoff auf das erste sichtbare Fireteam mit Mitgliedern zurueckfallen.
- Der Fallback ist nur aktiv, wenn `seed_homebase_direct_launch_payload()` explizit aufgerufen wird.
- Firefight-Decision-Line bekommt einen read-only Rekursionsguard.
- Regressionstest fuer stale Payload-Seed ergaenzen.

## Nicht-Ziele
- Kein Save-Reset.
- Kein neues Kampagnen-/Roster-System.
- Kein neues Missions- oder Combat-System.
- Keine UI als Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/ARCHITECTURE.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_partial_save_actionability.md`

## Akzeptanzkriterien
- Ein sichtbares Homebase-Fireteam kann bei stale Seed-ID trotzdem ins Flightdeck-Payload fallen.
- Readiness wird wieder `ready`, `Start Mission` wird aktiv und das Flightdeck ist nicht leer.
- Firefight-Decision-Line erzeugt keine Stack-Overflow-Rekursion.
- Bestehende Singleplayer-Release-Smokes bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_singleplayer_release_exe_actionability_and_firefight_decision_guard.md`
- `docs/dev/mission_command_feedback_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_817_station_reentry_release_candidate_targeted_firefight_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Fensterblick muss nach frischem Export nochmal erfolgen, weil alte Taskleisten- oder EXE-Pfade weiterhin einen alten PCK laden koennen.

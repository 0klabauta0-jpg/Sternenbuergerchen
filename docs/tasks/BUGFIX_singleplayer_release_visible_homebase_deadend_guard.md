# BUGFIX - Singleplayer Release Visible Homebase Deadend Guard

## Problem
Der exportierte Einzelspieler-Pfad kann sichtbar in einer Homebase landen, die wie ein Dead-End wirkt: Fireteam-UI ist vorhanden, aber Flightdeck, Payload, Boarding und `Start Mission` bleiben leer oder blockiert.

## Ursache
Die bisherigen Headless-Smokes pruefen den normalen Bootstrap-Handoff, aber nicht den sichtbaren Rohzustand nach einem leeren oder stale Homebase-Refresh. Dadurch kann der interne Bootstrap gruen sein, waehrend die sichtbaren Homebase-Panels weiter `0 ops / 0 FT`, kein Schiff und keine startbare Mission zeigen.

## Umfang
- Singleplayer-Startguard im Meta-Layer ergaenzen.
- Den sichtbaren Dead-End-Zustand read-only gegen Homebase-Snapshots erkennen.
- Bei blockiertem sichtbaren Startzustand die bestehende Singleplayer-Bootstrap-Sortie aus Roster, Dropship, Pilot und Payload erneut herstellen.
- Regressionstest fuer den Screenshot-aehnlichen Zustand.

## Nicht-Ziele
- Kein neues Homebase-UI.
- Kein Dropship-, Combat- oder Missionssystem-Rewrite.
- Keine Gameplay-Wahrheit im HUD; der Guard repariert Meta-Staging-Daten und laesst die Homebase weiter nur rendern.

## Relevante Contracts / Dokumente
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_start_bootstrap.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_partial_save_actionability.md`
- `docs/tasks/BUGFIX_singleplayer_release_exe_actionability_and_firefight_decision_guard.md`

## Akzeptanzkriterien
- Der Singleplayer-Start landet nicht in einer sichtbaren Homebase mit leerem Flightdeck und leerer Payload.
- Wenn ein sichtbarer Dead-End erkannt wird, wird ein Default-Dropship mit Pilot und geboardetem Fireteam wiederhergestellt.
- `Start Mission` ist danach aktiv und der bestehende Homebase-to-Mission-Handoff bleibt gruen.
- Der bestehende Bootstrap-Test deckt den sichtbaren Dead-End als Regression ab.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_821_release_first_homebase_cta_emphasis.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Guard repariert nur den ersten Singleplayer-Release-Startzustand. Ein echter Fenster-Sichttest bleibt noetig, um zu bestaetigen, dass der sichtbare Export nach `Einzelspieler` wirklich das startbare Panel zeigt.

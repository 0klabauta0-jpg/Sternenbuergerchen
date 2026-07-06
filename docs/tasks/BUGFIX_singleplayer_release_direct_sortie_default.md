# BUGFIX - Singleplayer Release Direct Sortie Default

## Problem
Der exportierte `Einzelspieler`-Start landet sichtbar auf `Operation: FOB Transfer`. Das ist ein Transfer-/Planungspfad und wartet auf manuelle Roster-/Dropship-Schritte. Fuer den ersten Release-Griff wirkt das wie ein Freeze: `Start blockiert`, 0 Operatoren, leeres Flightdeck.

## Ursache
Der MetaLayer-Bootstrap stellte zwar Roster, Fireteam, Dropship und Payload her, aber die Default-Mission blieb `fob_transfer` und die Default-Planning-State hatte keine Direct-Drop-Quelle. Dadurch konnte die sichtbare Homebase weiter den alten FOB-Transfer-Arbeitsmodus rendern.

## Umfang
- Singleplayer-Release-Default auf die kleine spielbare `grid_sweep`-Sortie setzen.
- Default-Planning-State mit `mission_drop_source = homebase_direct` initialisieren.
- Bootstrap-Verifier erweitert: erster Singleplayer zeigt das kleine spielbare Direct-Sortie-Briefing und der Handoff bleibt Homebase-direct.

## Nicht-Ziele
- Kein Entfernen des FOB-Transfer-Workflows.
- Kein neues Missionssystem.
- Keine Aenderung am Multiplayer-/FOB-Transfer-Handoff ausserhalb des Release-Default-Starts.

## Relevante Contracts / Dokumente
- `docs/tasks/BUGFIX_singleplayer_release_homebase_post_show_actionability_guard.md`
- `docs/tasks/TASK_517_mission_scenario_vertical_slice.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`

## Akzeptanzkriterien
- `Einzelspieler` oeffnet standardmaessig `Operation: Grid Sweep`.
- Der erste Missionsstart nutzt `mission_drop_source = homebase_direct`.
- Der sichtbare Homebase-Start rendert Payload/Flightdeck/Start-Mission statt leerem FOB-Transfer-Setup.
- FOB-Transfer bleibt als Missionseintrag erhalten, ist aber nicht mehr der Release-Default.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_singleplayer_release_direct_sortie_default.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `git diff --check`
- Frischen Release exportieren, starten, `Einzelspieler` klicken und Homebase sichtbar capturen.

## Risiken / offene Punkte
Einzelspieler ist damit klarer auf eine kleine Direct-Sortie ausgerichtet. Die groessere Frontier-Probe-Slice bleibt wichtig fuer den Szenario-/Multiplayer-Block, ist aber fuer den allerersten Release-Klick zu schwerfaellig.

# BUGFIX - Singleplayer Release Homebase Post-Show Actionability Guard

## Problem
Im exportierten Release-Build kann `Einzelspieler` sichtbar in der Homebase landen, aber die Panels zeigen danach wieder einen leeren Arbeitszustand: keine Operatoren, kein Flightdeck, keine Payload und `Start blockiert`.

## Ursache
Der bestehende Singleplayer-Bootstrap stellt Roster, Fireteam, Dropship, Pilot und Payload vor dem View-Wechsel her. Der sichtbare Homebase-Show-Pfad refresht die UI aber noch einmal. Wenn lokale Save-/Frame-Zustaende oder ein spaeter Panel-Rebuild danach wieder leer wirken, greift kein zweiter Guard mehr.

## Umfang
- Einen verzögerten Post-Show-Guard im MetaLayer ergaenzen.
- Der Guard laeuft nur nach sichtbarer Homebase und nur, wenn der Singleplayer-Bootstrap aktiv ist.
- Der Guard nutzt den bestehenden sichtbaren Actionability-Check und repariert nur Meta-Staging-Daten ueber die vorhandene Bootstrap-Route.
- Snapshot-Metadaten fuer Tests und Release-Diagnose ergaenzen.

## Nicht-Ziele
- Kein neues Homebase-UI.
- Kein Mission-, Dropship- oder Combat-Rewrite.
- Keine Gameplay-Wahrheit im HUD; Homebase bleibt Anzeige/Command-Surface.

## Relevante Contracts / Dokumente
- `docs/dev/homebase_direct_dropship_flow_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/BUGFIX_singleplayer_release_visible_homebase_deadend_guard.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_start_bootstrap.md`

## Akzeptanzkriterien
- Nach `_show_homebase()` wird ein sichtbarer leerer Homebase-Zustand automatisch repariert.
- `Start Mission`, Payload, Flightdeck und Pilot sind danach startbar/lesbar.
- Der Guard laeuft nicht per Frame, sondern nur gezielt nach dem Homebase-Show.
- Der bestehende Bootstrap-Verifier enthaelt einen Post-Show-Dead-End-Fall.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_post_show_actionability_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `git diff --check`
- Frischen Release exportieren, starten, `Einzelspieler` klicken und sichtbaren Homebase-Zustand erneut capturen.

## Risiken / offene Punkte
Der Guard repariert den Startzustand, ersetzt aber nicht die spaetere UX-Arbeit: Homebase braucht weiterhin einen klareren "Sofort starten"-Flow, damit der erste Griff nicht wie ein Editor-/Planungsformular wirkt.

# BUGFIX - Singleplayer Release Mission Selection Guard

## Problem
Der exportierte `Einzelspieler`-Start konnte trotz Bootstrap-Payload sichtbar wieder auf `Operation: FOB Transfer` landen. Dann waren Roster, Dropship und Payload-Startlogik teilweise vorbereitet, aber die Homebase zeigte weiter den alten Transfer-Arbeitsmodus mit `Start blockiert`, 0 Operatoren und leerem Flightdeck.

## Ursache
Der sichtbare Homebase-Actionability-Guard pruefte Payload, Boarding, Flightdeck und Readiness, aber nicht die Mission-ID. Dadurch konnte ein spaeter oder lokaler `fob_transfer`-Auswahlzustand als "actionable genug" durchrutschen, obwohl er fuer den Release-Start der falsche Workflow ist.

## Umfang
- Singleplayer-Bootstrap stellt die Release-Default-Mission `grid_sweep` wieder her, wenn die Auswahl leer, unbekannt oder noch `fob_transfer` ist.
- Sichtbarer Homebase-Guard repariert die Mission-Auswahl vor der Actionability-Pruefung.
- Bootstrap-Snapshot nennt Mission-ID, Map-Pfad und ob die Mission-Auswahl repariert wurde.
- Regressionstest deckt den Screenshot-nahen Fall ab: Payload ist vorbereitet, aber die Mission-Auswahl steht wieder auf `fob_transfer`.

## Nicht-Ziele
- Kein Entfernen von `fob_transfer` aus dem Missionskatalog.
- Kein neues Missionsauswahl-/Save-System.
- Kein Override explizit anderer bekannter Missionen wie `frontier_probe_vertical_slice`.

## Relevante Contracts / Dokumente
- `docs/tasks/BUGFIX_singleplayer_release_direct_sortie_default.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_post_show_actionability_guard.md`
- `docs/tasks/BUGFIX_singleplayer_release_visible_homebase_deadend_guard.md`
- `docs/dev/homebase_direct_dropship_flow_contract.md`

## Akzeptanzkriterien
- `Einzelspieler` zeigt nach dem ersten Klick `Operation: Grid Sweep` statt `Operation: FOB Transfer`.
- `Start Mission` bleibt aktiv, wenn Bootstrap-Payload, Pilot und Boarding vorhanden sind.
- Der Guard repariert `fob_transfer` nur im Release-Startpfad und laesst andere bekannte Missionen unangetastet.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `docs/tasks/BUGFIX_singleplayer_release_mission_selection_guard.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_538_homebase_to_mission_launch_handoff_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_823_release_singleplayer_visible_findings_polish.gd`
- `git diff --check`
- Frischen Release exportieren, starten, `Einzelspieler` klicken und den sichtbaren Homebase-Zustand capturen.

## Risiken / offene Punkte
Der Guard ist bewusst release-start-spezifisch. Wenn spaeter eine echte gespeicherte Singleplayer-Kampagnenauswahl eingefuehrt wird, muss diese Auswahl explizit vom Bootstrap-Default getrennt werden.

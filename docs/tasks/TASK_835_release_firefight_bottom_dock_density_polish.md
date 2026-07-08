# TASK_835 - Release Firefight Bottom Dock Density Polish

## Ziel / Problem
Der erste Firefight ist im Release-Fenster unten im HUD noch zu schwer zu lesen. TASK_833/TASK_834 priorisieren die `NEXT ... | WHY ...`-Zeile im Selected-Fireteam-Panel, aber Mission Control / Bottom Dock kann weiterhin mit alten Statuszeilen beginnen. Der Spieler muss dadurch im Gefecht suchen, welcher Griff als naechstes sinnvoll ist.

## Sinnhaftigkeit / Ursache
Mission Control haengt Kampf- und Decision-Daten an einen allgemeinen Statusblock an. Fuer den ersten Release-Firefight ist das zu weich: der naechste Griff und der Grund muessen oben stehen, der kompakte Kampfstatus direkt darunter. Die Anzeige darf weiterhin nur bestehende Combat-/Decision-Snapshots lesen.

## Umfang
- Mission Control priorisiert bei aktivem Firefight dieselbe `NEXT ... | WHY ...`-Zeile wie Selected Fireteam.
- Der kompakte Kampf-Readout steht direkt darunter.
- Der Status bleibt auf maximal wenige Zeilen begrenzt, damit der Bottom Dock nicht weiter ueberlaeuft.
- `StrategicStatusLabel` bekommt einen eigenen TASK_835-Style-Marker mit groesserer Schrift, Outline, Wrap und ohne Clip.
- MetaLayer und TacticalController liefern einen read-only Snapshot fuer Regressionen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, Navigation, FireEvents oder DamageEvents.
- Keine neue Multiplayer-Wahrheit.
- Kein Umbau der Bottom-Dock-Panelstruktur.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_833_release_firefight_hud_readability_polish.md`
- `docs/tasks/TASK_834_release_firefight_hud_real_window_polish.md`

## Akzeptanzkriterien
- Mission Control beginnt im First-GO-Firefight mit der `NEXT ... | WHY ...`-Zeile.
- Die zweite Mission-Control-Zeile ist der kompakte Kampf-Readout.
- Die Anzeige ist auf wenige Zeilen begrenzt und gegen Abschneiden geschuetzt.
- Snapshot meldet `read_only = true` und keine Gameplay-Mutationen.
- Bestehende TASK_832/TASK_833/TASK_834-Regressionen bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_835_release_firefight_bottom_dock_density_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_835_release_firefight_bottom_dock_density_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_834_release_firefight_hud_real_window_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_833_release_firefight_hud_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_832_release_first_go_firefight_deeplink_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte Fensterblick bleibt wichtig, weil Bottom-Dock-Dichte stark von Aufloesung und Fensterlayout abhaengt.
- Die naechste sinnvolle Folgearbeit ist die Command-Matrix-Optik und Interaktionsklarheit im ersten Firefight.

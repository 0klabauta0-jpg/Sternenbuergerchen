# TASK_339 - Mission UI Dirty Refresh Pass

## Ziel
Das Mission-HUD soll Fireteam-, Mini-Card- und Dropship-Panels nicht mehr in festen Intervallen komplett neu bauen, wenn sich der zugrunde liegende Zustand nicht geaendert hat. Updates sollen ueber Dirty-Signaturen oder kleine Diffs laufen.

## Status: GEPLANT

## Voraussetzung
- TASK_219 - UI HUD Meta Comic Bubble Performance Pass
- TASK_282 - Tactical Overhaul Playability Performance Help Gate
- TASK_331 - Mission Tactical Controller Adapter Split First Slice
- TASK_337 - Architecture Performance UX Followup Gate

## Kontext
Die Review hat im Mission Controller einen regelmaessigen `CARD_REFRESH_INTERVAL_SECONDS`-Pfad gefunden, der ausgewaehlte Fireteam-Karten, Fireteam-Mini-Cards und das Mission-Dropship-Panel periodisch leert und neu instanziiert. Das erzeugt vermeidbare UI-Arbeit, Texture-Loads und moegliche Frame-Spitzen, obwohl UI laut Architektur nur lesen und gezielt aktualisieren soll.

## Umfang
1. Refresh-Audit:
   - `_process()`, `_update_ui()`, `_refresh_selected_fireteam_cards()`, `_refresh_fireteam_mini_cards()` und `_refresh_mission_dropship_panel()` verfolgen.
   - Zustandssignaturen fuer Auswahl, Team-Mitglieder, Portraitpfade, Bubble-Text, Dropship-Payload, LZ/Approach und Button-Status definieren.
2. Dirty-/Diff-Refresh:
   - Panels nur neu bauen, wenn ihre Signatur wirklich wechselt.
   - Bestehende Card-Nodes nach Moeglichkeit aktualisieren statt `queue_free()` + `instantiate()` im Idle-Refresh.
   - Portrait-/Texture-Lookups nicht wiederholt im Hotpath erzwingen.
3. Diagnose:
   - Debug-Snapshot oder lokaler Test-Counter fuer Rebuilds, Skips und Signaturwechsel.
   - Idle-Refresh muss nach initialem Aufbau messbar ruhig bleiben.
4. Regression:
   - Selection-Wechsel, Fireteam-Wechsel, Dropship-LZ und Payload-Aenderungen muessen weiterhin sichtbar aktualisieren.

## Nicht-Ziele
- Kein neues HUD-Design.
- Keine Aenderung an taktischer Befehlslogik.
- Keine neue Gameplay-Wahrheit in UI-Karten.
- Kein grosser Controller-Split; nur der Refresh-Pfad wird beruhigt.

## Akzeptanzkriterien
- [ ] Bei unveraendertem Mission-State werden Fireteam- und Dropship-Karten nicht periodisch komplett neu aufgebaut.
- [ ] Relevante Zustandsaenderungen erzeugen weiterhin genau sichtbare UI-Updates.
- [ ] Der Test weist mindestens einen Idle-Abschnitt nach, in dem Rebuild-Counter stabil bleiben.
- [ ] Keine neuen `SimulationRoot`-Commands oder Effects entstehen durch UI-Refresh.
- [ ] Performance-/Playability-Gates bleiben gruen.

## Erwartete Dateien
- `scripts/mission/mission_tactical_sandbox_controller.gd`
- optional `scripts/meta/npc_compact_card.gd`
- optional `scripts/tests/task_339_mission_ui_dirty_refresh_pass.gd`
- `docs/tasks/TASK_339_mission_ui_dirty_refresh_pass.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_339_mission_ui_dirty_refresh_pass.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_282_tactical_overhaul_playability_performance_help_gate.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [ ] `git diff --check`

## Risiken
- Zu grobe Signaturen koennen sichtbare Updates verschlucken; zu feine Signaturen bringen den alten Rebuild-Druck zurueck. Der Test muss deshalb sowohl Idle-Ruhe als auch echte Aenderungsfaelle abdecken.

## Naechster Schritt
Nach diesem Pass kann der Tactical Controller in weiteren kleinen Slices entkoppelt werden, ohne dass der HUD-Hotpath weiter rauscht.

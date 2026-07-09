# TASK_926 - Release First Exchange Followup Player Polish Tuning

## Ziel / Problem
TASK_925 trennt Smoke-Akzeptanz von belegter Restreibung. Ohne akzeptierten Sichtbefund bleibt der naechste sinnvolle Schritt kein Playability-Smoke, sondern ein enger Tuning-Schnitt fuer die erste Weltlesung im Fire-Exchange.

## Sinnhaftigkeit / Ursache
Der erste CONTACT-FIRE-Moment ist im HUD da, aber die Weltlesung darf nicht wieder von FIRE/CONTACT-Text, Zielhalo oder Raster-/Weltlinien gefressen werden. TASK_926 setzt deshalb nur die in TASK_925 benannte Restreibung um: Source-to-target-Fire-Lane zuerst, Richtunganker klarer, Label/Halo/Grid ruhiger.

## Umfang
- TASK_925-Findings als Quelle pruefen.
- TASK_923-Player-Polish als Basis erhalten.
- Primary3D-/Weapon-Fire-VFX-Werte enger tunen:
  - Lane/Core minimal staerker.
  - Source-/Target-Anker minimal klarer, aber nicht scheibenhaft.
  - Target-Halo leiser und kleiner.
  - FIRE/CONTACT-Weltlabel kleiner/leiser/weiter weg.
  - Raster-/Weltlinien weiter zurueck.
- Controller-Payload und Snapshot fuer den neuen Tuning-Modus bereitstellen.
- Status, Roadmap und Contract aktualisieren.

## Nicht-Ziele
- Kein Playability-Smoke.
- Kein neuer Recapture.
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_925_release_first_exchange_followup_player_polish_visual_findings.md`
- `docs/tasks/TASK_923_release_first_exchange_followup_world_read_player_polish.md`
- `docs/reports/spielstand_zwischenbericht_task925_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupPlayerPolishTuning.build_snapshot()` verlangt TASK_925-Restreibung und einen passierenden TASK_923-Player-Polish.
- `MissionTacticalSandboxController.get_release_first_exchange_followup_player_polish_tuning_snapshot()` liefert einen read-only Snapshot.
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_926-Style und effektive Lane-/Core-/Halo-/Anchor-/Label-/Noise-Werte.
- Weapon-Fire-VFX-Eintraege tragen denselben TASK_926-Style.
- TASK_926 meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_926_release_first_exchange_followup_player_polish_tuning.md`
- `scripts/mission/release_first_exchange_followup_player_polish_tuning.gd`
- `scripts/tests/task_926_release_first_exchange_followup_player_polish_tuning.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_926_release_first_exchange_followup_player_polish_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_925_release_first_exchange_followup_player_polish_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_923_release_first_exchange_followup_world_read_player_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_926 bleibt ein enger Visual-/Presentation-Slice. Er ersetzt keinen echten Playability-Smoke und keinen frischen Fenster-Recapture. Danach ist ein TASK_927-Recapture sinnvoll, bevor der Smoke freigegeben wird.

## Naechster Schritt
TASK_927 - Release First Exchange Followup Player Polish Tuning Recapture.

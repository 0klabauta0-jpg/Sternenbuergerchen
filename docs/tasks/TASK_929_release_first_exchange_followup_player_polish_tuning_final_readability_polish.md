# TASK_929 - Release First Exchange Followup Player Polish Tuning Final Readability Polish

## Ziel / Problem
TASK_928 trennt den TASK_927-Tuning-Recapture sauber in Smoke-Freigabe oder Restreibung. Ohne akzeptierten Spielerblick soll kein Playability-Smoke auf Verdacht laufen. TASK_929 setzt deshalb die letzte belegte Lesereibung eng als Presentation-Polish um.

## Sinnhaftigkeit / Ursache
Der erste CONTACT-FIRE-Moment ist technisch vorhanden, aber die Weltlesung bleibt empfindlich: FIRE/CONTACT-Text, Target-Halo, Grid und Weltlinien koennen die Source-to-target-Fire-Lane weiter ueberstrahlen. Ein letzter schmaler Polish soll die Lane als erste Bewegung staerken, ohne neue Combat- oder HUD-Wahrheit zu erzeugen.

## Umfang
- TASK_928-Findings als Quelle verlangen.
- TASK_926-Tuning als Basis verlangen.
- Finalen TASK_929-Style fuer Primary3D einfuehren:
  - Fire-Lane/Core minimal staerker.
  - Target-Halo, Statuslabel, Grid und Weltlinien weiter zuruecknehmen.
  - Source-/Target-Anker leicht staerken, aber nicht scheibenhaft machen.
- Mission-Controller-Payload um den neuen read-only Presentation-Style erweitern.
- `TerrainMap3DView` so erweitern, dass Render-Snapshot und Fire-VFX-Eintrag den TASK_929-Style melden.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neuer Capture.
- Kein Smoke-Run.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-Aenderung.
- Kein Combat-, LOS-, Pathfinding- oder Event-Log-Rewrite.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_928_release_first_exchange_followup_player_polish_tuning_visual_findings.md`
- `docs/tasks/TASK_927_release_first_exchange_followup_player_polish_tuning_recapture.md`
- `docs/tasks/TASK_926_release_first_exchange_followup_player_polish_tuning.md`
- `docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupPlayerPolishTuningFinalReadabilityPolish.build_snapshot()` blockt falsche TASK_928-/TASK_926-Quellen.
- Der Mission-Controller stellt `get_release_first_exchange_followup_player_polish_tuning_final_readability_polish_snapshot()` read-only bereit.
- `TerrainMap3DView` meldet `task_929_release_first_exchange_followup_player_polish_tuning_final_readability_v1`.
- TASK_929-Lane/Core sind staerker als TASK_926, waehrend Label/Halo/Grid/Weltlinien leiser bleiben.
- Source-/Target-Anker tragen die Richtung, ohne zu gross zu werden.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.md`
- `scripts/mission/release_first_exchange_followup_player_polish_tuning_final_readability_polish.gd`
- `scripts/tests/task_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task926_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_928_release_first_exchange_followup_player_polish_tuning_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_926_release_first_exchange_followup_player_polish_tuning.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_929 ist weiter ein Presentation-Slice, kein Beweis im echten Fenster. Danach braucht es TASK_930 als frischen Recapture, bevor der Playability-Smoke wieder freigegeben wird.

## Naechster Schritt
TASK_930 - Release First Exchange Final Readability Recapture.

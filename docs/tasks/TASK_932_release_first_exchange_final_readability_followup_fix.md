# TASK_932 - Release First Exchange Final Readability Followup Fix

## Ziel / Problem
TASK_931 trennt den finalen TASK_930-Spielerblick sauber in Smoke-Freigabe oder Restreibung. Ohne akzeptierten Sichtbefund darf kein Playability-Smoke auf Verdacht starten. TASK_932 setzt deshalb nur den engen belegten Folgefix fuer den ersten CONTACT-FIRE-Weltblick um.

## Sinnhaftigkeit / Ursache
Die Source-to-target-Fire-Lane ist technisch vorhanden, konkurriert im echten Spielerblick aber noch mit FIRE/CONTACT-Text, Target-Halo, Raster und Weltlinien. Der naechste Schritt muss die bestehende TASK_929-Weltlesung minimal staerken, ohne Combat-, HUD- oder Multiplayer-Wahrheit zu oeffnen.

## Umfang
- TASK_931-Findings als Quelle verlangen.
- TASK_929-Final-Readability-Polish als Basis verlangen.
- Eigenen TASK_932-Style fuer Primary3D einfuehren:
  - Fire-Lane/Core minimal klarer als TASK_929.
  - Label/Halo/Grid/Weltlinien minimal leiser als TASK_929.
  - Source-/Target-Anker tragend, aber weiter unter der Scheiben-Grenze.
- `TerrainMap3DView` so erweitern, dass Render-Snapshot und Fire-VFX-Eintrag den TASK_932-Style melden.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neuer Combat-Resolver.
- Keine neuen FireEvents, DamageEvents oder Movement-Commands.
- Kein neues HUD-Wahrheitsmodell.
- Kein Playability-Smoke in diesem Slice.
- Kein Map-Editor-/Asset-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_931_release_first_exchange_final_readability_visual_findings.md`
- `docs/tasks/TASK_930_release_first_exchange_final_readability_recapture.md`
- `docs/tasks/TASK_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.md`
- `docs/reports/spielstand_zwischenbericht_task931_ausblick_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFinalReadabilityFollowupFix.build_snapshot()` blockt falsche TASK_931-/TASK_929-Quellen.
- TASK_932-Lane/Core sind minimal staerker als TASK_929, waehrend Label/Halo/Grid/Weltlinien leiser bleiben.
- Source-/Target-Anker bleiben unter oder gleich `0.22`, damit sie nicht als grosse Scheiben gelesen werden.
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_932-Style und effektive Werte.
- Weapon-Fire-VFX-Eintraege tragen denselben TASK_932-Style.
- TASK_932 meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_932_release_first_exchange_final_readability_followup_fix.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_task931_ausblick_2026_07_09.html`
- `scripts/mission/release_first_exchange_final_readability_followup_fix.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_932_release_first_exchange_final_readability_followup_fix.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_932_release_first_exchange_final_readability_followup_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_931_release_first_exchange_final_readability_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_929_release_first_exchange_followup_player_polish_tuning_final_readability_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_932 ist weiter ein Presentation-Slice. Er ersetzt keinen echten Fenster-Recapture und keinen Playability-Smoke. Danach ist TASK_933 als frischer Recapture sinnvoll, bevor der Smoke freigegeben wird.

## Naechster Schritt
TASK_933 - Release First Exchange Followup Fix Recapture.

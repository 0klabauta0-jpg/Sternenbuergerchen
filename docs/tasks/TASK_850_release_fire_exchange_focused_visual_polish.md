# TASK_850 - Release Fire Exchange Focused Visual Polish

## Ziel / Problem
TASK_849 hat den frischen Release-Fensterbefund als `ready_for_polish` markiert: Der erste Fire-Exchange ist technisch nachweisbar, aber im echten Fenster konkurrieren Start-/Automatik-Overlay, dominante Weltlinien und zu schwache FireTrace-/Impact-VFX mit dem eigentlichen Kampfereignis.

Ziel dieses Tasks ist ein enger Visual-Focus-Polish fuer den aktiven Release-Fire-Exchange-Moment.

## Sinnhaftigkeit / Ursache
Der Combat-Pfad ist nicht das Problem. Die sichtbare Reibung liegt darin, dass der Spieler im ersten Feuerwechsel nicht sofort erkennt: Dort wurde geschossen, dort war der Einschlag, und #17/#18/#19 bestaetigen denselben Moment. Deshalb wird nur der bestehende Visual-/Snapshot-Pfad geschaerft.

## Umfang
- Neuer stabiler Style-Schalter `task_850_release_fire_exchange_focused_visual_polish_v1`.
- `MissionTacticalSandboxController` setzt im Primary3D-Payload einen read-only Focus-Schalter, wenn TASK_847-Visibility-Persistence aktiv ist.
- `TerrainMap3DView`:
  - macht FireTrace, Impact, Impact-Cross und Target-Focus im Focus-Modus staerker sichtbar
  - gewichtet Friendly-Aim-/LOS-Linien im gleichen Moment herunter
  - meldet Focus-Status und konkrete Visual-Parameter im Render-Snapshot
- MetaLayer reicht den TASK_850-Snapshot fuer Release-/QA-Pruefung weiter.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Schoenheitsentscheid.
- Kein neues HUD-System und kein neues Tutorialfenster.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_849_release_fire_exchange_visual_polish_findings.md`
- `docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `get_release_fire_exchange_focused_visual_polish_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_focused_visual_polish.v1` und `task_id = TASK_850`.
- Snapshot verlinkt TASK_849 als Befundquelle und TASK_847 als Visibility-Quelle.
- Primary3D-Render-Snapshot meldet `release_fire_exchange_focused_visual_polish_active = true` und die TASK_850-Style-ID.
- Fire-VFX-Parameter sind im Focus-Modus groesser/lesbarer als die Basiswerte:
  - Trace-Breite groesser als `WEAPON_FIRE_TRACE_WIDTH`
  - Impact-Radius groesser als `WEAPON_FIRE_IMPACT_RADIUS`
  - Target-Focus-Radius groesser als `WEAPON_FIRE_TARGET_FOCUS_RADIUS`
- Welt-/LOS-Linien sind im Focus-Modus gedimmt, ohne Pre-GO-LZ-/Dropship-Lesbarkeit zu entfernen.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_850_release_fire_exchange_focused_visual_polish.gd`
- `docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_850_release_fire_exchange_focused_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_849_release_fire_exchange_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_847_release_fire_exchange_visibility_persistence.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_850 verbessert Headless-verifizierbare Visual-Parameter. Der echte Fensterblick muss danach erneut exportiert und gecaptured werden, weil nur der reale Screenshot zeigt, ob die Gewichtung fuer den Spieler tatsaechlich stimmt.

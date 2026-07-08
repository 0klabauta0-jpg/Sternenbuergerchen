# TASK_889 - Release First Exchange HUD Density And Fire Visual Polish

## Ziel / Problem
TASK_888 zeigt: Der echte Post-Final-Fensterframe liest CONTACT FIRE in #17 Selected Fireteam, #18 Mission Control und #19 Event Log, aber der erste Spielerblick ist noch zu dicht. Bottom-HUD, #18-Text, #19-Overlay, FireTrace/Impact und Member-Cards konkurrieren weiter um Aufmerksamkeit.

## Sinnhaftigkeit / Ursache
Die technische CONTACT-FIRE-Wahrheit ist inzwischen belegt. Der naechste Fortschritt fuer Spielbarkeit ist deshalb kein Combat-Rewrite, sondern ein kleiner Lesbarkeits-Polish: CONTACT FIRE soll sofort als Moment, Schussrichtung, Zielbezug und naechster Griff lesbar sein.

## Umfang
- #17/#18 CONTACT-FIRE-Statuszeilen fuer den bestaetigten First-Exchange-Moment kuerzen.
- #19 Event Log im TASK_889-Modus groesser, ruhiger und mit weniger sichtbarer Dichte rahmen.
- Primary3D bekommt einen TASK_889-Schalter, der den bestehenden TASK_880-FireTrace/Impact/Target-Focus weiter priorisiert.
- Snapshot/Verifier pruefen, dass diese Aenderungen read-only bleiben und keine Gameplay-Wahrheit erzeugen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Damage-, FireEvent-, Movement-, Contact-, Command- oder Multiplayer-Wahrheit.
- Keine neuen grossen HUD-Systeme.
- Kein neuer Capture-Pfad und kein manueller Sichttest als automatisch bestanden behauptet.
- Kein Editor-/Mapbuilder-Polish in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_888_release_first_exchange_player_readability_polish_review.md`
- `docs/tasks/TASK_887_release_first_exchange_real_window_hud_render_frame_sync_fix.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `get_release_first_exchange_hud_density_fire_visual_polish_snapshot()` meldet TASK_889 aktiv, wenn die TASK_883-/TASK_876-CONTACT-FIRE-Quelle aktiv ist.
- #17 und #18 nutzen eine kompaktere CONTACT-FIRE-Erstlesung mit maximal wenigen Zeilen.
- #19 Event Log meldet den TASK_889-Stil, groessere Mindestflaeche, groessere Textzeilen und einen reduzierten sichtbaren Event-Cap.
- `TerrainMap3DView.get_render_snapshot()` meldet den TASK_889-Fire-Visual-Stil und staerkere Trace-/Impact-/Target-Focus-Werte als TASK_880.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_889_release_first_exchange_hud_density_and_fire_visual_polish.md`
- `scripts/mission/release_first_exchange_hud_density_and_fire_visual_polish.gd`
- `scripts/tests/task_889_release_first_exchange_hud_density_and_fire_visual_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/ui/tactical_event_log_panel.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_889_release_first_exchange_hud_density_and_fire_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_888_release_first_exchange_player_readability_polish_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_887_release_first_exchange_hud_render_frame_sync_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_889 verbessert die Headless-/Runtime-Lesbarkeitsparameter und bereitet den naechsten echten Fensterblick vor. Ob es sich im nicht-headless Playtest wirklich angenehm anfuehlt, muss danach per frischem Capture oder manuellem Sichttest entschieden werden.

## Naechster Schritt
TASK_890 - Release First Exchange HUD Density Real Window Recapture.

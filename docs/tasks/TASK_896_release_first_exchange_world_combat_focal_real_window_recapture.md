# TASK_896 - Release First Exchange World Combat Focal Real Window Recapture

## Ziel / Problem
TASK_895 ist headless/runtime-gruen, aber noch nicht im echten Release-Fenster belegt. Wir brauchen einen neuen Window-Handle-Recapture, der prueft, ob Source-to-target-Lane, Source-Glow, Target-Halo und gedimmtes Umfeld im Spielerblick wirklich als eine Kampfaktion lesbar sind.

## Sinnhaftigkeit / Ursache
Der letzte Engpass war visuelle Hierarchie im Weltbild. Headless-Snapshots beweisen, dass der Visual-Pfad aktiv ist, aber nicht, dass der echte Fensterblick angenehm und schick genug ist. Deshalb folgt nach dem Polish wieder ein Capture-/Review-Slice.

## Umfang
- Eigenen TASK_896-Capture-Wrapper anlegen.
- Den bestehenden TASK_893/TASK_890/TASK_887 Window-Handle-Pfad wiederverwenden.
- Eigenes Manifest und eigene Screenshotpfade unter `tmp/` schreiben.
- Erwartete TASK_895-Schema-/Style-ID festhalten.
- Pflichtchecks fuer CONTACT FIRE, Source-to-target-Lane, Source-Glow, Target-Halo, Dimming und keine neue Gameplay-Wahrheit definieren.
- Analyzer/Verifier fuer review-ready vs. accepted bereitstellen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein weiterer Visual-Polish.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein automatisches visuelles Akzeptieren ohne Sichtbefund.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish.md`
- `docs/tasks/TASK_893_release_first_exchange_fire_direction_impact_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_world_combat_focal_real_window_recapture.ps1` erzeugt ein TASK_896-Manifest und eigene Desktop-/Window-Screenshotpfade.
- `ReleaseFirstExchangeWorldCombatFocalRealWindowRecapture.build_snapshot()` trennt `review_ready` von `accepted`.
- Das Manifest nennt TASK_895 als Quelle und erwartet Style-ID `task_895_release_first_exchange_world_combat_focal_hierarchy_v1`.
- Der Snapshot verlangt trusted `window_handle_print`, Post-Final-Capture nach `deeplink_final`, finalen CONTACT-FIRE-Source-Snapshot und vorhandenen Window-Screenshot.
- Ohne manuelle Checks bleibt der Snapshot `review_ready`, nicht `accepted`.
- Read-only-Grenzen bleiben explizit: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_896_release_first_exchange_world_combat_focal_real_window_recapture.md`
- `scripts/tools/capture_release_first_exchange_world_combat_focal_real_window_recapture.ps1`
- `scripts/mission/release_first_exchange_world_combat_focal_real_window_recapture.gd`
- `scripts/tests/task_896_release_first_exchange_world_combat_focal_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_896_release_first_exchange_world_combat_focal_real_window_recapture.gd`
- Optionaler echter Capture: `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_world_combat_focal_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_895_release_first_exchange_world_combat_focal_hierarchy_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_896 erzeugt den Belegrahmen und kann ein neues PNG schreiben. Der menschliche Spielerbefund bleibt bewusst offen, bis das Bild als TASK_897 read-only bewertet wird.

## Naechster Schritt
TASK_897 - Release First Exchange World Combat Focal Visual Findings.

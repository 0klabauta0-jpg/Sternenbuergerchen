# TASK_899 - Release First Exchange Combat Focal Elegance Real Window Recapture

## Ziel / Problem
TASK_898 ist headless/runtime-gruen, aber noch nicht im echten Release-Fenster belegt. Wir brauchen einen neuen Window-Handle-Recapture, der prueft, ob die weichere Source-to-target-Lane, der kleinere Target-Halo und der dezente Source-Glow im Spielerblick natuerlicher wirken.

## Sinnhaftigkeit / Ursache
TASK_898 reduziert den Debug-Look des Weltkampf-Fokus. Headless-Snapshots beweisen die Werte und den Runtime-Pfad, aber nicht, ob der echte Fensterblick angenehmer und schicker wirkt. Deshalb folgt wieder ein Capture-/Review-Slice.

## Umfang
- Eigenen TASK_899-Capture-Wrapper anlegen.
- Den bestehenden TASK_896/TASK_893/TASK_887 Window-Handle-Pfad wiederverwenden.
- Eigenes Manifest und eigene Screenshotpfade unter `tmp/` schreiben.
- Erwartete TASK_898-Schema-/Style-ID festhalten.
- Pflichtchecks fuer CONTACT FIRE, weichere Lane, kleineren Target-Halo, dezenten Source-Glow, keine stale NO-FIRE-Erstlesung und keine neue Gameplay-Wahrheit definieren.
- Analyzer/Verifier fuer `review_ready` vs. `accepted` bereitstellen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein weiterer Visual-Polish.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein automatisches visuelles Akzeptieren ohne Sichtbefund.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_898_release_first_exchange_combat_focal_elegance_polish.md`
- `docs/tasks/TASK_896_release_first_exchange_world_combat_focal_real_window_recapture.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `capture_release_first_exchange_combat_focal_elegance_real_window_recapture.ps1` erzeugt ein TASK_899-Manifest und eigene Desktop-/Window-Screenshotpfade.
- `ReleaseFirstExchangeCombatFocalEleganceRealWindowRecapture.build_snapshot()` trennt `review_ready` von `accepted`.
- Das Manifest nennt TASK_898 als Quelle und erwartet Style-ID `task_898_release_first_exchange_combat_focal_elegance_v1`.
- Der Snapshot verlangt trusted `window_handle_print`, Post-Final-Capture nach `deeplink_final`, finalen CONTACT-FIRE-Source-Snapshot und vorhandenen Window-Screenshot.
- Ohne manuelle Checks bleibt der Snapshot `review_ready`, nicht `accepted`.
- Read-only-Grenzen bleiben explizit: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_899_release_first_exchange_combat_focal_elegance_real_window_recapture.md`
- `scripts/tools/capture_release_first_exchange_combat_focal_elegance_real_window_recapture.ps1`
- `scripts/mission/release_first_exchange_combat_focal_elegance_real_window_recapture.gd`
- `scripts/tests/task_899_release_first_exchange_combat_focal_elegance_real_window_recapture.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_899_release_first_exchange_combat_focal_elegance_real_window_recapture.gd`
- Optionaler echter Capture: `powershell -ExecutionPolicy Bypass -File scripts/tools/capture_release_first_exchange_combat_focal_elegance_real_window_recapture.ps1 -Launch -StopRunningReleaseProcess -CleanTempFiles -WaitSeconds 52`
- `godot_console.exe --headless --path . --script scripts/tests/task_898_release_first_exchange_combat_focal_elegance_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_899 erzeugt den Belegrahmen und kann ein neues PNG schreiben. Der menschliche Spielerbefund bleibt bewusst offen, bis das Bild als TASK_900 read-only bewertet wird.

## Naechster Schritt
TASK_900 - Release First Exchange Combat Focal Elegance Visual Findings.

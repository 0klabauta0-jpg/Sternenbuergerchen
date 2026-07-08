# TASK_868 - Release First Exchange LOS Setup Polish

## Ziel / Problem
TASK_867 hat den echten Fensterbefund festgehalten: Der Release-First-Exchange wird im UI weiter als `NO_LOS` / `CONTACT PRESSURE` gelesen, obwohl die fruehere TASK_844-Kette headless FireEvent-Evidence erzeugt.

## Sinnhaftigkeit / Ursache
Der Release-Deep-Link durfte fuer den ersten Kontakt mehrere Gegner gleichzeitig als erkannt markieren. Dadurch konnte der Combat-Loop nach dem validierten Setup wieder einen anderen, nicht sauber positionierten Gegner zuerst auswerten. Der sichtbare Readout fiel dann ehrlich auf `NO_LOS`, waehrend die HUD-Polishes weiterhin CONTACT FIRE erwarteten.

## Umfang
- Gegnerplatzierung fuer `--release-singleplayer-first-go-firefight` als enges Release-Testpaar validieren.
- Den ersten Exchange auf das validierte Zielpaar begrenzen, damit der Readout nicht auf einen anderen Gegner kippt.
- Zielgegner fuer den Release-Testmoment stabilisieren.
- Read-only Snapshot fuer LOS-/Range-/Attackable-Setup bereitstellen.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Damage-, FireEvent-, Command-, Movement-, Contact- oder Multiplayer-Wahrheit ausserhalb des bestehenden Release-Deep-Link-Setups.
- Kein neuer Capture in diesem Task.
- Kein UI-Text-Override.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_867_release_fire_exchange_runtime_text_status_visual_findings.md`
- `docs/tasks/TASK_844_release_first_exchange_tension_tuning.md`

## Akzeptanzkriterien
- Der Release-Deep-Link waehlt ein durch bestehende Combat-Readouts validiertes Fireteam-/Enemy-Testpaar.
- Der Force-Schritt oeffnet Detection nur fuer den validierten Zielgegner.
- Der TASK_868-Snapshot meldet `placement_verified_attackable`, `in_range`, nicht blockierte LOS und fired Diagnostics.
- Snapshot bleibt read-only und erzeugt keine FireEvents, DamageEvents, Commands oder Multiplayer-Wahrheit.
- TASK_844 bleibt gruen.

## Betroffene Dateien
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_868_release_first_exchange_los_setup_polish.gd`
- `docs/tasks/TASK_868_release_first_exchange_los_setup_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_task868_verified_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_868_release_first_exchange_los_setup_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_844_release_first_exchange_tension_tuning.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_867_release_fire_exchange_runtime_text_status_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_868 verbessert den reproduzierbaren Release-Deep-Link und dessen Setup-Evidence. Der echte Fensterbeweis bleibt Folgearbeit: TASK_869 sollte neu exportieren/capturen und pruefen, ob #17/#18/#19 nun wirklich CONTACT FIRE statt `NO_LOS` / `CONTACT PRESSURE` lesen.

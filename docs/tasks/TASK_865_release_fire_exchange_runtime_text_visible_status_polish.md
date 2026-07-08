# TASK_865 - Release Fire Exchange Runtime Text Visible Status Polish

## Ziel / Problem
TASK_864 hat den echten TASK_863-Fensterbefund festgehalten: #17/#18 lesen im Release-Capture weiter `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`, obwohl TASK_862 den Runtime-Text headless auf CONTACT FIRE-first bringt.

TASK_865 poliert den sichtbaren Statuspfad eng an der Ursache: Die Release-Fire-Exchange-Sichtbarkeit durfte nicht mit einer Frame-basierten Pseudozeit laufen, weil Release-Fenster mit hoeherer Framerate die 45s-Persistenz zu schnell verbrauchen.

## Sinnhaftigkeit / Ursache
Die Persistenz-Uhr nutzte `Engine.get_process_frames() * 16` als 60-FPS-Annahme. Im echten Release-Fenster kann die Framerate deutlich hoeher liegen. Dadurch laeuft die vermeintliche 45s-Anzeige schneller ab, und beim 38s-Capture gewinnt wieder der aktuelle LOS-/NO-FIRE-Status.

## Umfang
- Release-Fire-Exchange-Persistenz auf echte Millisekunden via `Time.get_ticks_msec()` umstellen.
- TASK_865-Verifier ergaenzen, der die Clock-Quelle gegen Frame-basierte Zeit absichert.
- TASK_847-Read-only-Grenzen statisch absichern und TASK_864 als direkte Findings-Regression gruen halten.
- Doku, Roadmap, Status und Zwischenbericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein neues HUD-System.
- Kein Shortcut- oder Export-Preset-Umbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_864_release_fire_exchange_runtime_text_visual_findings.md`
- `docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `_release_fire_exchange_visibility_clock_msec()` nutzt echte Zeit via `Time.get_ticks_msec()`.
- Der Controller enthaelt keine `Engine.get_process_frames() * 16`-Clock fuer die Release-Fire-Exchange-Persistenz.
- TASK_847-Persistenz bleibt als read-only Contract-/Snapshot-Pfad erhalten.
- TASK_864-Findings bleiben reproduzierbar, bis ein neuer echter Capture den sichtbaren Erfolg beweist.
- Der Task erzeugt keine UI-, Command-, Combat-, Damage-, Movement-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_865_release_fire_exchange_runtime_text_visible_status_polish.gd`
- `docs/tasks/TASK_865_release_fire_exchange_runtime_text_visible_status_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_865_release_fire_exchange_runtime_text_visible_status_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_864_release_fire_exchange_runtime_text_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_865 repariert die Zeitbasis fuer die sichtbare Persistenz. Ein neuer echter Fenster-Recapture bleibt danach noetig, um zu beweisen, dass der Spieler CONTACT FIRE im Release-Fenster wirklich zuerst liest.

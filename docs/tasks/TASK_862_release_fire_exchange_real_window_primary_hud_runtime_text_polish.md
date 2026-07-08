# TASK_862 - Release Fire Exchange Real Window Primary HUD Runtime Text Polish

## Ziel / Problem
Der echte TASK_860-Fensterblick zeigt trotz TASK_859-Source-Binding weiter zuerst stale HUD-Zeilen wie `NEXT LOS/RANGE KORRIGIEREN`, `Kampf NO FIRE NO_LOS` und `CONTACT PRESSURE`.

Ziel ist, dass #17 Selected Fireteam und #18 Mission Control im aktiven Release-Fire-Exchange-Fenster den vorhandenen `CONTACT FIRE | ...`-Text als erste Spielerlesung zeigen.

## Sinnhaftigkeit / Ursache
TASK_859 bindet den Snapshot-/Source-Pfad, aber der sichtbare Runtime-Label-Updatepfad setzt die echten Labels weiter direkt aus `_build_fireteam_status_text()` und `_build_strategic_status_text()`. Dadurch kann der Headless-Snapshot korrekt wirken, waehrend das echte Fenster weiter stale Primaertext liest.

## Umfang
- Kleinen read-only Runtime-Text-Service fuer TASK_862 anlegen.
- #17/#18 sichtbare Labels nach dem bestehenden Textbau an die vorhandene CONTACT-FIRE-Primaerquelle binden.
- Snapshot fuer den Runtime-Labelpfad bereitstellen.
- Doku, Roadmap, Status und Verifier synchronisieren.

## Nicht-Ziele
- Kein neues Kampfsystem.
- Keine neuen FireEvents, DamageEvents, Commands oder Kontakte.
- Keine neue Multiplayer-Wahrheit.
- Kein grosser HUD-Refactor.
- Kein Ersatz fuer einen anschliessenden echten Fenster-Recapture.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_861_release_fire_exchange_real_window_contact_fire_visual_findings.md`
- `docs/tasks/TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.md`
- `docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md`

## Akzeptanzkriterien
- Bei aktiver `visibility_persistence_active` beginnt #17 mit `CONTACT FIRE | ...`.
- Bei aktiver `visibility_persistence_active` beginnt #18 mit `CONTACT FIRE | ...`.
- `NO FIRE`-/LOS-/Range-Diagnostik darf weiter im Detailtext bleiben, aber nicht vor CONTACT FIRE stehen.
- Die Runtime-Bindung nutzt direkte Label-NodePaths und keine SceneTree-Vollscans.
- Der Task erzeugt keine Commands, FireEvents, DamageEvents, Movement-, Contact-, UI- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_862_release_fire_exchange_real_window_primary_hud_runtime_text_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_861_release_fire_exchange_real_window_contact_fire_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task beweist den Runtime-Textpfad headless. Der echte Fensterbeweis bleibt ein anschliessender Recapture-Slice, weil nur der reale Screenshot zeigt, ob die Spielerlesung nun wirklich stimmt.

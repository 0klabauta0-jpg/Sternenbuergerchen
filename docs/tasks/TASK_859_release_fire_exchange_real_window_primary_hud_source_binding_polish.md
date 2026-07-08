# TASK_859 - Release Fire Exchange Real Window Primary HUD Source Binding Polish

## Ziel / Problem
TASK_858 hat belegt, dass der echte TASK_857-Fensterblick trotz gruenem TASK_856-Primary-HUD-Snapshot weiter `NO FIRE NO_LOS` / LOS-Korrektur statt CONTACT FIRE als erste #17/#18-Lesung zeigt. TASK_859 bindet den echten Real-Window-HUD-Text fuer #17 Selected Fireteam und #18 Mission Control eng an die vorhandene TASK_856-CONTACT-FIRE-Primaerquelle.

## Sinnhaftigkeit / Ursache
Die CONTACT-FIRE-Primaerzeile wird bereits aus vorhandener FireEvent-/Visibility-Persistence-Evidence gebaut. Der echte Snapshot-/Fensterpfad liest aber teils rohe Labeltexte, die im Update-/Snapshot-Zeitpunkt noch stale sein koennen. Dadurch ist der Contract gruen, waehrend das Fenster fuer den Spieler weiter Debug-/Korrekturtext priorisiert.

## Umfang
- Eine kleine Source-Binding-Schicht setzt bei aktiver Release-Fire-Exchange-Persistence die vorhandene `CONTACT FIRE | ...`-Primaerzeile vor stale #17/#18-Labeltexte.
- `get_command_feedback_snapshot()` liefert fuer `selected_fireteam_status_label_text` und `mission_control_status_text` den gebundenen Real-Window-Text.
- TacticalController und MetaLayer expose einen TASK_859-Snapshot.
- Status-, Roadmap-, Contract- und Berichtssync.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Movement-, Contact-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture in diesem Task; der Folge-Task soll den echten Fensterblick erneut belegen.
- Kein Pixel-/OCR-Autourteil.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_858_release_fire_exchange_contact_fire_primary_hud_visual_findings.md`
- `docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFireExchangeRealWindowPrimaryHudSourceBindingPolish` meldet Schema `sternenbuergerchen.release_fire_exchange_real_window_primary_hud_source_binding_polish.v1` und `task_id = TASK_859`.
- Bei aktiver Visibility-Persistence beginnt der gebundene #17- und #18-Real-Window-Text mit der vorhandenen `CONTACT FIRE | ...`-Primaerzeile.
- `NO FIRE`-/LOS-/Range-Diagnostik bleibt im Detailtext erreichbar, darf aber nicht vor CONTACT FIRE stehen.
- TacticalController und MetaLayer expose read-only TASK_859-Snapshots.
- Der Task erzeugt keine UI-, Command-, Combat-, Damage-, Movement-, Contact-, Multiplayer- oder Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_real_window_primary_hud_source_binding_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.gd`
- `docs/tasks/TASK_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_859_release_fire_exchange_real_window_primary_hud_source_binding_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_858_release_fire_exchange_contact_fire_primary_hud_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_856_release_fire_exchange_contact_fire_primary_hud_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_859 beweist die Source-Bindung im Code-/Snapshot-Pfad. Der echte Fensterbeweis bleibt Folgearbeit: TASK_860 soll nach frischem Release-Export und Recapture pruefen, ob der sichtbare PNG-Blick nun wirklich CONTACT FIRE als erste Lesung transportiert.

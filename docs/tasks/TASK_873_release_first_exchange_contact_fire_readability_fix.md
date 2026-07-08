# TASK_873 - Release First Exchange CONTACT-FIRE Readability Fix

## Ziel / Problem
Im korrekten Release-Fenster ist der erste Exchange nach TASK_872 noch nicht als Spielmoment lesbar. #17 Selected Fireteam, #18 Mission Control und #19 Event Log koennen weiter stale `NO_LOS` / `CONTACT PRESSURE` zeigen, obwohl der Deep-Link vorhandene First-Exchange-/Fire-Event-Evidence bereits seeded.

## Sinnhaftigkeit / Ursache
Die CONTACT-FIRE-Evidence wird im Deep-Link nach dem Immediate-Exchange-Snapshot gesetzt, aber die sichtbaren Runtime-Surfaces werden danach nicht zwingend sofort aus dieser Evidence neu aufgebaut. Bei echten Fenster-Captures kann deshalb ein alter UI-Refresh-Zustand dominieren.

## Umfang
- Einen engen Controller-Hook fuer TASK_873 bereitstellen.
- Vorhandene Fire-Exchange-Evidence per `record_release_fire_exchange_visibility_evidence()` lesen.
- Direkt danach World-Overlays, Runtime-HUD und Event-Log refreshen.
- Einen read-only Snapshot fuer #17/#18/#19-Lesbarkeit liefern.
- MetaLayer-Deep-Link auf den neuen Hook umstellen.
- Status, Roadmap und Contract synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Movement-, Contact- oder Multiplayer-Wahrheit.
- Kein kosmetisches CONTACT-FIRE-Masking ohne vorhandene First-Exchange-Evidence.
- Kein neuer Export oder echter Fenster-Recapture in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_872_release_correct_window_first_exchange_visual_findings.md`
- `docs/tasks/TASK_868_release_first_exchange_los_setup_polish.md`
- `docs/reports/spielstand_zwischenbericht_task873_contact_fire_2026_07_08.html`

## Akzeptanzkriterien
- Der neue Hook arbeitet nur mit vorhandener `sternenbuergerchen.release_first_exchange_tension_tuning.v1`-Evidence.
- Nach dem Seeding werden sichtbare HUD-/Event-Surfaces sofort aktualisiert.
- Snapshot zeigt, ob #17 und #18 mit `CONTACT FIRE` beginnen.
- Snapshot zeigt, ob #19/Event-Log `CONTACT FIRE` enthaelt.
- Snapshot meldet `primary_lines_contain_debug_no_fire_before_contact_fire = false`.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.
- Bestehende TASK_872/TASK_871-Verifier bleiben gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_873_release_first_exchange_contact_fire_readability_fix.gd`
- `docs/tasks/TASK_873_release_first_exchange_contact_fire_readability_fix.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task873_contact_fire_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_873_release_first_exchange_contact_fire_readability_fix.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_872_release_correct_window_first_exchange_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_871_release_window_identity_capture_target_fix.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_873 beweist den Runtime-/Snapshot-Pfad, aber noch nicht den finalen menschlichen PNG-Eindruck. Der naechste sinnvolle Schritt ist ein frischer echter Window-Handle-Recapture, der prueft, ob CONTACT FIRE, FireTrace/Impact oder eine klare Blockade-Erklaerung im Release-Fenster wirklich lesbar sind.

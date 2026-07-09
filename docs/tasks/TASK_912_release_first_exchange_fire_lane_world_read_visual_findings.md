# TASK_912 - Release First Exchange Fire Lane World Read Visual Findings

## Ziel / Problem
TASK_911 stellt den echten Release-/Window-Handle-Recapture-Rahmen fuer den TASK_910-World-Read-Micro-Polish bereit. Der Screenshot-/Manifest-Befund muss als Spielerblick bewertet werden, ohne sofort weitere Visual-, Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
TASK_910 hat die Weltbild-Hierarchie enger poliert: Label/Halo/Marker treten zurueck, Fire-Lane-Core und Source-/Target-Anker tragen staerker. TASK_912 entscheidet read-only, ob das im echten Fenster reicht oder ob noch ein enger Folge-Polish noetig ist.

## Umfang
- TASK_911-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: trusted Window-Handle-Capture, CONTACT FIRE in #17/#18/#19, TASK_910-World-Read-Micro-Pfad belegt, leiseres Weltlabel, zuruecktretender Target-Halo, vorhandene Fire-Lane-Core-/Anchor-Signale, bedienbare Command-Surfaces.
- Restreibung konkret benennen:
  - Fire-Lane wird noch nicht als erste Weltbewegung gelesen.
  - Label/Halo/Marker konkurrieren noch.
  - Source-/Target-Anker tragen die Blickfuehrung noch nicht genug.
  - Bottom-HUD bleibt im ersten Feuerblick dicht.
- Konkreten Folge-Task vorschlagen, ohne Combat-, Damage-, Movement-, Contact-, UI- oder Multiplayer-Wahrheit anzufassen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Visual-Polish in diesem Task.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture.
- Kein automatisches Release-Akzeptieren nur wegen sichtbarem CONTACT FIRE.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_911_release_first_exchange_fire_lane_world_read_real_window_recapture.md`
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneWorldReadVisualFindings.build_snapshot()` akzeptiert das TASK_911-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und den sichtbaren TASK_910-World-Read-Micro-Recapture.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Fire-Lane, Label/Halo/Marker oder Anker die erste Weltlesung stoeren.
- Der Snapshot empfiehlt einen engen Folge-Task fuer World-Read-Acceptance-Polish, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_912_release_first_exchange_fire_lane_world_read_visual_findings.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_visual_findings.gd`
- `scripts/tests/task_912_release_first_exchange_fire_lane_world_read_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_912_release_first_exchange_fire_lane_world_read_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_911_release_first_exchange_fire_lane_world_read_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_912 bewertet nur. Der naechste Polish muss eng bleiben: erste Weltlesung und Fire-Lane-Hierarchie staerken, ohne wieder mehr CONTACT-FIRE-Text oder Combat-Logik zu bauen.

## Naechster Schritt
TASK_913 - Release First Exchange Fire Lane World Read Acceptance Polish.

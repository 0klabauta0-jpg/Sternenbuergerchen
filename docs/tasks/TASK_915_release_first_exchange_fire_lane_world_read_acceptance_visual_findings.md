# TASK_915 - Release First Exchange Fire Lane World Read Acceptance Visual Findings

## Ziel / Problem
TASK_914 stellt den Recapture-/Acceptance-Rahmen nach dem TASK_913-World-Read-Acceptance-Polish bereit. Der Befund muss jetzt als Spielerblick bewertet werden: Reicht die Fire-Lane als erste Weltbewegung fuer den naechsten Playability-Smoke, oder braucht es noch einen letzten engen Visual-Polish?

## Sinnhaftigkeit / Ursache
TASK_913 hat Fire-Lane-Core und Source-/Target-Anker gestaerkt und Label/Halo/Weltlinien weiter beruhigt. TASK_914 trennt den echten Fensterbeweis sauber von automatischer Akzeptanz. TASK_915 schneidet daraus read-only die Findings, damit nicht wieder Combat-, HUD- oder Damage-Wahrheit geoeffnet wird.

## Umfang
- TASK_914-Snapshot/Manifest und Review-Notizen read-only bewerten.
- Positive Befunde festhalten:
  - finaler Source-Snapshot meldet CONTACT FIRE in #17/#18/#19.
  - Window-Handle-Capture ist trusted.
  - TASK_913-Acceptance-Style ist die erwartete Quelle.
  - TASK_910-World-Read-Micro-Basis bleibt belegt.
  - optional: Fire-Lane als erste Weltbewegung, Richtunganker, ruhiges Label/Halo-Cluster und bedienbare Command-Surfaces.
- Restreibung konkret benennen:
  - Fire-Lane wird noch nicht als erste Weltbewegung gelesen.
  - Source-/Target-Anker tragen Richtung noch nicht sicher genug.
  - Label/Halo konkurrieren weiter mit der Lane.
  - Bottom-HUD bleibt fuer den ersten Feuerblick dicht.
- Naechsten Schritt als Playability-Smoke bei Akzeptanz oder engen Final-Polish bei Restreibung benennen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein neuer Capture.
- Kein Visual-Polish in diesem Task.
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.md`
- `docs/tasks/TASK_913_release_first_exchange_fire_lane_world_read_acceptance_polish.md`
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneWorldReadAcceptanceVisualFindings.build_snapshot()` akzeptiert den TASK_914-Snapshot/Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19, trusted Window-Handle-Capture und die sichtbare TASK_913-Acceptance-Quelle.
- Der Snapshot markiert ohne menschlichen Sichtbefund nicht automatisch Akzeptanz.
- Der Snapshot kann bei sauberem Review `accepted_for_first_exchange_playability_smoke` melden.
- Der Snapshot empfiehlt bei Restreibung einen engen Folge-Polish, ohne Combat-, Damage-, Movement-, Contact-, UI- oder Multiplayer-Wahrheit anzufassen.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_915_release_first_exchange_fire_lane_world_read_acceptance_visual_findings.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_acceptance_visual_findings.gd`
- `scripts/tests/task_915_release_first_exchange_fire_lane_world_read_acceptance_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_915_release_first_exchange_fire_lane_world_read_acceptance_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_914_release_first_exchange_fire_lane_world_read_acceptance_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_915 bewertet nur. Wenn der echte Fensterblick noch nicht akzeptabel ist, muss der naechste Polish eng bei Weltbild-Hierarchie, Fire-Lane und Ankern bleiben. Wenn der Befund akzeptiert wird, sollte nicht weiter an der Lane gefeilt werden, sondern ein kleiner First-Exchange-Playability-Smoke folgen.

## Naechster Schritt
Bei Akzeptanz: TASK_916 - Release First Exchange Playability Smoke. Bei Restreibung: TASK_916 - Release First Exchange Fire Lane World Read Final Polish.

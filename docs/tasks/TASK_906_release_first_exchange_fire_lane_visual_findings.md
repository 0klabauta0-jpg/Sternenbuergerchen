# TASK_906 - Release First Exchange Fire Lane Visual Findings

## Ziel / Problem
TASK_905 hat nach TASK_904 einen frischen echten Release-/Window-Handle-Capture erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort weitere Visual-, Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
Der echte TASK_905-Fensterblick bestaetigt CONTACT FIRE in #17/#18/#19 und zeigt, dass die Fire-Lane nach TASK_904 besser sichtbar ist. Der verbleibende Engpass ist die erste Weltlesung: FIRE/CONTACT-Label, Halo und kleine Marker sitzen noch als Cluster im Zielbereich, waehrend die Source-to-target-Lane zwar vorhanden ist, aber nicht klar genug als primaere Schussbewegung fuehrt.

## Umfang
- TASK_905-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: trusted Window-Handle-Capture, CONTACT FIRE in #17/#18/#19, sichtbarer Event Log, sichtbare Fire-Lane, Fire-Lane-Core, Source-/Target-Anker, nutzbare Command-Surfaces.
- Restreibung konkret benennen: Label-/Halo-Cluster ist noch erste Lesung, Fire-Lane ist sichtbar aber nicht primaere Weltlesung, Source-/Target-Anker tragen die Blickfuehrung noch nicht stark genug.
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
- `docs/tasks/TASK_905_release_first_exchange_fire_lane_real_window_recapture.md`
- `docs/tasks/TASK_904_release_first_exchange_fire_lane_readability_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneVisualFindings.build_snapshot()` akzeptiert das TASK_905-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und den sichtbaren TASK_904-Fire-Lane-Polish.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Label-/Halo-Cluster, nicht-primaere Fire-Lane oder zu schwache Source-/Target-Anker stoeren.
- Der Snapshot empfiehlt einen engen Folge-Task fuer Label-Cluster-/Fire-Lane-Hierarchie, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_906_release_first_exchange_fire_lane_visual_findings.md`
- `scripts/mission/release_first_exchange_fire_lane_visual_findings.gd`
- `scripts/tests/task_906_release_first_exchange_fire_lane_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_906_release_first_exchange_fire_lane_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_905_release_first_exchange_fire_lane_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_906 bewertet nur. Der naechste Polish muss eng bleiben: Label-/Halo-Cluster und Fire-Lane-Hierarchie klarer machen, ohne erneut mehr CONTACT-FIRE-Text oder Combat-Logik zu bauen.

## Naechster Schritt
TASK_907 - Release First Exchange Fire Lane Label Cluster Polish.

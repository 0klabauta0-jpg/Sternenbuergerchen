# TASK_909 - Release First Exchange Fire Lane Label Cluster Visual Findings

## Ziel / Problem
TASK_908 hat nach TASK_907 einen frischen echten Release-/Window-Handle-Capture erzeugt. Der Screenshot muss als Spielerblick bewertet werden, ohne sofort weitere Visual-, Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
Der echte TASK_908-Fensterblick bestaetigt den Fortschritt: CONTACT FIRE ist in #17/#18/#19 sichtbar, der Event Log liefert Rueckmeldung und der Weltkampf ist nicht mehr unsichtbar. Der verbleibende Engpass ist enger: Die Fire-Lane ist vorhanden, aber FIRE/CONTACT-Welttext, Halo und kleine Marker bilden weiterhin den ersten Blickfang.

## Umfang
- TASK_908-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: trusted Window-Handle-Capture, CONTACT FIRE in #17/#18/#19, sichtbarer Event Log, vorhandene Fire-Lane, ruhigerer Halo, bedienbare Command-Surfaces.
- Restreibung konkret benennen: Label-/Halo-Cluster bleibt erste Lesung, Fire-Lane-Core traegt noch nicht allein genug, Source-/Target-Anker bleiben zu klein fuer Blickfuehrung, Bottom-HUD bleibt dicht.
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
- `docs/tasks/TASK_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.md`
- `docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireLaneLabelClusterVisualFindings.build_snapshot()` akzeptiert das TASK_908-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und den sichtbaren TASK_907-Label-Cluster-Recapture.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Label-/Halo-Cluster, nicht-primaere Fire-Lane oder zu schwache Source-/Target-Anker stoeren.
- Der Snapshot empfiehlt einen engen Folge-Task fuer Weltbild-Hierarchie, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_909_release_first_exchange_fire_lane_label_cluster_visual_findings.md`
- `scripts/mission/release_first_exchange_fire_lane_label_cluster_visual_findings.gd`
- `scripts/tests/task_909_release_first_exchange_fire_lane_label_cluster_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_909_release_first_exchange_fire_lane_label_cluster_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_908_release_first_exchange_fire_lane_label_cluster_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_909 bewertet nur. Der naechste Polish muss eng bleiben: Weltbild-Hierarchie und Fire-Lane-First-Read staerken, ohne wieder mehr CONTACT-FIRE-Text oder Combat-Logik zu bauen.

## Naechster Schritt
TASK_910 - Release First Exchange Fire Lane World Read Micro Polish.

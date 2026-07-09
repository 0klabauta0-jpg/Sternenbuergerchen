# TASK_910 - Release First Exchange Fire Lane World Read Micro Polish

## Ziel / Problem
TASK_909 hat den frischen TASK_908-Fensterblick bewertet: CONTACT FIRE ist in #17/#18/#19 sichtbar und der Weltkampf ist vorhanden, aber FIRE/CONTACT-Welttext, Halo und kleine Marker bleiben der erste Blickfang vor der Fire-Lane.

## Sinnhaftigkeit / Ursache
Der naechste Schritt darf nicht wieder mehr Combat-Text oder neue Feuerlogik bauen. Die Reibung liegt im Weltbild: Die Source-to-target-Bewegung muss den ersten Blick fuehren, waehrend Label/Halo/Marker weiter in den Hintergrund treten.

## Umfang
- Bestehenden TASK_907-Label-Cluster-Pfad erweitern, nicht ersetzen.
- Fire-Lane-Core und Source-/Target-Anker leicht staerken.
- Welt-Fire-Statuslabel weiter verkleinern, leiser machen und weiter aus dem Target-Cluster schieben.
- Target-Halo weiter beruhigen, damit er nicht als Marker-Scheibe liest.
- Grid-/World-Line-Noise minimal weiter dimmen.
- Runtime-/Controller-Snapshot fuer TASK_910 read-only bereitstellen.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Bewegungen.
- Keine neue HUD-Wahrheit.
- Kein neuer echter Fenster-Capture in diesem Task; der folgt als eigener Recapture-Slice.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_909_release_first_exchange_fire_lane_label_cluster_visual_findings.md`
- `docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `TerrainMap3DView.get_render_snapshot()` meldet `task_910_release_first_exchange_fire_lane_world_read_micro_v1`.
- TASK_910 ist nur aktiv, wenn TASK_907 aktiv ist.
- World-Fire-Statuslabel wird kleiner/leiser und weiter vom Target-Halo weg verschoben.
- Target-Halo bleibt kleiner/leiser als TASK_907.
- Fire-Lane-Core und Source-/Target-Anker tragen die Schussbewegung staerker als TASK_907, ohne grosse Marker-Discs zu erzeugen.
- Controller liefert `get_release_first_exchange_fire_lane_world_read_micro_polish_snapshot()` read-only.
- Verifier bestaetigt: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_910_release_first_exchange_fire_lane_world_read_micro_polish.md`
- `scripts/mission/release_first_exchange_fire_lane_world_read_micro_polish.gd`
- `scripts/tests/task_910_release_first_exchange_fire_lane_world_read_micro_polish.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_910_release_first_exchange_fire_lane_world_read_micro_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_909_release_first_exchange_fire_lane_label_cluster_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_910 ist noch kein echter Fensterbeweis. Der naechste Slice muss wieder frisch exportieren/capturen und pruefen, ob die Fire-Lane jetzt wirklich vor Label/Halo/Marker gelesen wird.

## Naechster Schritt
TASK_911 - Release First Exchange Fire Lane World Read Real Window Recapture.

# TASK_907 - Release First Exchange Fire Lane Label Cluster Polish

## Ziel / Problem
TASK_906 hat den echten TASK_905-Fensterblick bewertet. CONTACT FIRE und die TASK_904-Fire-Lane sind sichtbar, aber die erste Weltlesung bleibt noch zu stark FIRE/CONTACT-/Halo-/Marker-Cluster statt klare Source-to-target-Schussbewegung.

## Sinnhaftigkeit / Ursache
Der Spieler soll den ersten Feuerwechsel im Weltbild zuerst als Bewegung von Quelle zu Ziel lesen. Noch mehr CONTACT-FIRE-Text oder neue Combat-Logik wuerde die falsche Ebene staerken. Der naechste Slice muss deshalb den vorhandenen Primary3D-Visualpfad eng polieren: Weltlabel leiser, Halo kleiner, Lane/Core und Source-/Target-Anker etwas tragfaehiger.

## Umfang
- Bestehenden TASK_904-Fire-Lane-Pfad erweitern, nicht ersetzen.
- FIRE/CONTACT-Statuslabel im Weltbild kleiner/leiser und leicht aus dem Zielcluster heraus versetzen.
- Target-Halo weiter beruhigen, damit er nicht als Marker-Scheibe liest.
- Fire-Lane-Core und Source-/Target-Anker minimal staerken, ohne grosse Marker-Discs zu erzeugen.
- Runtime-/Controller-Snapshot fuer TASK_907 read-only bereitstellen.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Bewegungen.
- Keine neue HUD-Wahrheit.
- Keine Multiplayer-Wahrheit oder Shortcut-Aenderung.
- Kein neuer echter Fenster-Capture in diesem Task; der folgt als eigener Recapture-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_906_release_first_exchange_fire_lane_visual_findings.md`
- `docs/tasks/TASK_904_release_first_exchange_fire_lane_readability_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `TerrainMap3DView.get_render_snapshot()` meldet `task_907_release_first_exchange_fire_lane_label_cluster_v1`.
- TASK_907 ist nur aktiv, wenn TASK_904 aktiv ist.
- World-Fire-Statuslabel wird kleiner/leiser und aus dem Target-Halo-Cluster verschoben.
- Target-Halo bleibt kleiner/leiser als TASK_904.
- Fire-Lane-Core bleibt sichtbar und etwas staerker als TASK_904, Source-/Target-Anker bleiben klein, tragen aber mehr Richtung.
- Controller liefert `get_release_first_exchange_fire_lane_label_cluster_polish_snapshot()` read-only.
- Verifier bestaetigt: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_907_release_first_exchange_fire_lane_label_cluster_polish.md`
- `scripts/mission/release_first_exchange_fire_lane_label_cluster_polish.gd`
- `scripts/tests/task_907_release_first_exchange_fire_lane_label_cluster_polish.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_907_release_first_exchange_fire_lane_label_cluster_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_906_release_first_exchange_fire_lane_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_907 ist noch kein echter Fensterbeweis. Der naechste Slice muss frisch exportieren/capturen und pruefen, ob die Weltlesung wirklich zuerst die Schussbewegung und nicht den Label-/Halo-Cluster zeigt.

## Naechster Schritt
TASK_908 - Release First Exchange Fire Lane Label Cluster Real Window Recapture.

# TASK_904 - Release First Exchange Fire Lane Readability Polish

## Ziel / Problem
TASK_903 hat den echten TASK_902-Fensterblick bewertet. CONTACT FIRE ist in #17/#18/#19 sichtbar und der TASK_901-Marker-/World-Noise-Polish ist belegt, aber die Source-to-target-Fire-Lane liest sich im Weltbild noch zu subtil.

## Sinnhaftigkeit / Ursache
Der Spieler soll den ersten Feuerwechsel zuerst als Kampfbewegung lesen: Quelle, Schussbahn, Ziel. Noch mehr HUD-Text wuerde die richtige Ebene verschieben. Der naechste sinnvolle Schritt ist deshalb ein enger Primary3D-Visual-Polish auf der bestehenden TASK_901-Kette.

## Umfang
- Bestehenden TASK_901-Visualpfad erweitern, nicht ersetzen.
- Fire-Lane klarer machen: weichere breite Fuehrung plus schmaler heller Kern.
- Target-Halo und Source-Glow weiterhin klein halten, damit kein neuer Marker-Disc-Look entsteht.
- Grid-/World-Line-Noise weiter ruhig halten.
- Runtime-/Controller-Snapshot fuer TASK_904 read-only bereitstellen.
- Doku, Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Bewegungen.
- Keine neue HUD-Wahrheit.
- Keine Multiplayer-Wahrheit oder Shortcut-Aenderung.
- Kein neuer echter Fenster-Capture in diesem Task; der folgt als eigener Recapture-Slice.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_903_release_first_exchange_combat_marker_scale_visual_findings.md`
- `docs/tasks/TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `TerrainMap3DView.get_render_snapshot()` meldet `task_904_release_first_exchange_fire_lane_readability_v1`.
- Die Fire-Lane ist aktiver als TASK_901: breitere Fuehrung, zusaetzlicher Kern und kleine Source-/Target-Anker.
- Target-Halo bleibt kleiner/leiser als TASK_901, damit der Kontaktbereich nicht wieder als Marker-Scheibe liest.
- Controller liefert `get_release_first_exchange_fire_lane_readability_polish_snapshot()` read-only.
- `ReleaseFirstExchangeFireLaneReadabilityPolish.build_snapshot()` prueft TASK_903-Findings, TASK_901-Quelle, Primary3D-Renderwerte und read-only-Grenzen.
- Verifier bestaetigt: keine Commands, FireEvents, DamageEvents, Movement- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_904_release_first_exchange_fire_lane_readability_polish.md`
- `scripts/mission/release_first_exchange_fire_lane_readability_polish.gd`
- `scripts/tests/task_904_release_first_exchange_fire_lane_readability_polish.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_904_release_first_exchange_fire_lane_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_903_release_first_exchange_combat_marker_scale_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_901_release_first_exchange_combat_marker_scale_world_noise_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_904 ist noch kein echter Fensterbeweis. Der naechste Slice muss frisch exportieren/capturen und pruefen, ob die Lane im Spielerfenster wirklich intuitiver wirkt.

## Naechster Schritt
TASK_905 - Release First Exchange Fire Lane Real Window Recapture.

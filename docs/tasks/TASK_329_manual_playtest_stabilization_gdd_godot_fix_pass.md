# TASK_329 - Manual Playtest Stabilization GDD Godot Fix Pass

## Ziel
Die nach dem grossen Audit gefundenen Playtest-Rueckschritte sollen direkt stabilisiert werden, ohne neue Architekturwahrheiten in UI oder Docs zu erzeugen.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Der Audit vom 2026-05-10 zeigte rote Stellen in Dropship-Visualisierung, Dropship-Sequencing, RMB-Order-Zielen, Feedback-Bubble-Deduplizierung, FOB-Loadout-Charakterzugriff, Multiplayer-Lobby-Layout, Editor-Palette sowie in der Godot-/GDD-Dokumentationswahrheit.

## Umfang
1. Dropship und Mission:
   - Dropship-Visual-Signatur reparieren.
   - Planned-LZ-Marker auch dann sichtbar halten, wenn kein Tile-Marker platziert werden kann.
   - Mehrere Dropship-Karten/Payloads ohne stale Selected-Card-State weiterreichen.
   - Inbound/RTB/Outbound-Visuals fuer aktive und geplante Dropships stabilisieren.
   - Die aktive Drop-Sequenz bleibt an ihr Craft, ihre LZ, ihren Approach und ihre Payload-Fireteam-IDs gebunden, waehrend Mission Control ein anderes Dropship auswaehlen und planen kann.
   - Bei belegter Air Lane wird ein weiterer Drop sichtbar geblockt statt als versteckte Queue zu laufen.
   - Geplante LZs werden pro Dropship benannt; eine neue LZ ersetzt nur die alte LZ desselben Dropships.
   - Wartende Mission-Dropships bleiben offscreen und werden nicht mehr als Modell bei der Dropship-Karte/Map-Kante geparkt.
2. Befehle und Feedback:
   - Rechtsklick-Testziele ohne doppeltes Tile-Center-Snapping pruefen.
   - Feedback-Bubbles erst nach Visual-Tauglichkeit deduplizieren.
3. UI:
   - FOB-Loadout nutzt kompakte Name/Portrait-Karten als Character-Sheet-Oeffner.
   - Multiplayer-Lobby bleibt in einem festen 720x560-Panel und scrollt intern.
   - Map-Editor-Palette behaelt Gruppen und erhaelt `Alle` als vollstaendige Langliste.
4. Docs:
   - Projektziel auf Godot 4.6.2 vereinheitlichen.
   - Performance-Budget-Contract auf denselben Projektzielstand ziehen.
   - `sternenbuerger-gdd.docx` als Alt-GDD/Inspiration statt bindender zweiter Wahrheit dokumentieren.

## Lokale Pruefung
- [x] `godot --headless --path . --script scripts/tests/task_258_fixed_window_clipping_scrollbar_playability_audit.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`
- [x] `godot --headless --path . --script scripts/tests/task_259_character_card_roster_switching_playability.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_character_team_editor_usability_pass.gd`
- [x] `godot --headless --path . --script scripts/tests/task_310_fob_flightdeck_fireteam_userology_smoke.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_mission_multi_dropship_cards.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_mission_dropship_plans_and_facing.gd`
- [x] `godot --headless --path . --script scripts/tests/task_313_dropship_arrival_visibility_feedback_smoke.gd`
- [x] `godot --headless --path . --script scripts/tests/task_279_lz_security_air_asset_tactical_playability_smoke.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_mission_right_click_order_flow.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- [x] `godot --headless --path . --script scripts/tests/task_158_verifier.gd`
- [x] `godot --headless --path . --script scripts/tests/task_160_tactical_playability_verifier.gd`
- [x] `godot --headless --path . --script scripts/tests/task_186_mission_map_unit_presence_registry_audit.gd`
- [x] `godot --headless --path . --script scripts/tests/task_192_mission_map_npc_behavior_playability_smoke.gd`
- [x] `godot --headless --path . --script scripts/tests/task_250_asset_audio_background_playability_smoke.gd`
- [x] `godot --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `godot --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [x] `godot --headless --path . --script scripts/tests/task_222_performance_regression_gate_and_manual_profile_checklist.gd`

## Risiken
- FullHD-Sichtcheck bleibt fuer finale optische Balance sinnvoll.
- UPnP/Internet-Hosting kann lokal nur technisch vorbereitet, aber nicht als echte NAT-/Router-Erreichbarkeit bewiesen werden.
- Das DOCX bleibt als Ideenspeicher im Repo. Neue Uebernahmen daraus brauchen weiter eine explizite Markdown-Entscheidung.

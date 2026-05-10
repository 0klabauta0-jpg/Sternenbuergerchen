# TASK_327 - Manual Playtest Right Click Orders Tactics Dropship Visibility

## Ziel
Rechtsklick-Kommandos, taktische Nachsicherung und Dropship-Planung sollen im Mission-Playtest direkter und weniger widerspruechlich reagieren.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Playtest fuehlte sich die Mission Map bei Befehlen traege an: neue Rechtsklick-Kommandos haengten sich an alte Wegpunkte, statt den naechsten Befehl zu ersetzen. Area-Auswahl sollte per gedrueckter rechter Maustaste entstehen und erst beim Loslassen das Kontextmenue oeffnen. Gleichzeitig drifteten NPC-Modellrichtung und Sicht-/Feueranzeige auseinander, und inbound Dropships wurden noch als Modelle im Spielerbereich sichtbar.

## Umfang
1. Command Input:
   - Rechtsklick-Klick markiert das Ziel-Tile und oeffnet beim Loslassen das Kontextmenue.
   - Rechtsklick-Drag rahmt die gezogenen Tiles als Area und oeffnet beim Loslassen das Area-Kontextmenue.
   - Ohne Shift ersetzt ein neuer Rechtsklick den naechsten noch nicht erledigten Befehl des Fireteams.
   - Mit Shift wird der neue Befehl als Folgebefehl angehaengt.
2. Command Cleanup:
   - Abgearbeitete Wegpunkte sollen aus der 3D-Visualisierung verschwinden.
   - Nach erledigter Kette faellt das Fireteam wieder in Sicherung.
3. Taktik/Facing:
   - Post-Drop-Sicherung priorisiert Deckung und Objective-Richtung staerker.
   - Sicht-/Feuerbereich und sichtbare NPC-Drehung nutzen dieselbe Facing-Quelle.
4. Dropships:
   - Inbound/Offmap Dropships werden nicht als Modell im Spielerbereich gerendert.
   - Geplante LZs und Approach-Linien bleiben pro Dropship sichtbar.
   - Approach-Aenderungen aktualisieren die geplante Linie sofort pro Craft.
5. Connectivity:
   - Lokaler ENet-Connectivity-Smoke dokumentiert die technische Host/Join-Basis.

## Erwartete Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tactical/fireteam_movement_controller.gd`
- `scripts/tests/bugfix_mission_right_click_order_flow.gd`
- `scripts/tests/bugfix_mission_dropship_plans_and_facing.gd`
- `scripts/tests/bugfix_multiplayer_enet_connectivity_smoke.gd`
- `docs/tasks/TASK_327_manual_playtest_right_click_orders_tactics_dropship_visibility.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_mission_right_click_order_flow.gd`
- [x] `bugfix_mission_dropship_plans_and_facing.gd`
- [x] `bugfix_multiplayer_enet_connectivity_smoke.gd`
- [x] `bugfix_mission_multi_dropship_cards.gd`
- [x] `bugfix_dropship_mission_flow_verifier.gd`
- [x] `bugfix_mission_fire_sector_overlay.gd`
- [x] `git diff --check`

## Risiken
- Die genaue Auswahl der Befehlsnamen im Kontextmenue bleibt ein UI-Balancing-Thema.
- Echte Internet-Verbindung ueber Router/NAT kann lokal nicht voll verifiziert werden; der Smoke prueft nur die ENet-Basis auf localhost.

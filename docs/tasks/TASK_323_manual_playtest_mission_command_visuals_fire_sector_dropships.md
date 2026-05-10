# TASK_323 - Manual Playtest Mission Command Visuals Fire Sector Dropships

## Ziel
Mission-Kommandos, Sicht-/Feuerbereiche und Dropship-Auswahl sollen im manuellen Mission-Playtest klarer und pro Craft/Fireteam nachvollziehbar sein.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Playtest waren Feuerlinien, Sicht/Facing und Befehlsketten schwer unterscheidbar. Fireteams sollten per Kartenklick/Doppelklick schneller zentrierbar sein. Dropship-Karten auf der rechten Seite sollten das jeweilige Craft fuer Mission Control selektieren, damit LZ/Drop nicht global oder ausgegraut wirkt.

## Umfang
1. Fireteam-/Tile-Auswahl:
   - Ausgewaehlte Tiles und Fireteam-Ziele werden deutlicher dargestellt.
   - Karteninteraktion zielt auf schnelleres Zentrieren und Auswaehlen.
2. Command Matrix:
   - Go/Plan-Kontext wurde in Richtung `#16 COMMAND MATRIX` nachgezogen.
   - Alte doppelte/unklare Go-Pfade wurden reduziert.
3. Fire Sector:
   - Feuerbereich ist tile-orientiert statt als unruhiges frei schwebendes Overlay gedacht.
   - Blockierende LOS-Tiles werden im Snapshot/Visual-Pfad unterscheidbar.
   - Facing-Linie und Feuerbereich werden getrennt erfasst.
   - LOS-/Fire-Sector-Scans sind auf den Waffenradius begrenzt und nutzen einen einfachen Blocker-Cache.
   - Facing/Sichtbereich folgt der sichtbaren 3D-Proxy-Drehung, damit Kegel und NPC-Blick nicht auseinanderlaufen.
4. Dropship Control:
   - Mission-Dropship-Karten koennen das aktive Craft fuer LZ/Drop-Kommandos setzen.
   - Waiting-Dropships sollen vollfarbig und kommandierbar bleiben.
   - Offmap-Dropships werden nicht neben der Karte gerendert; Inbound/RTB bleibt ueber Karten-Progress sichtbar.
   - Nach dem Absetzen wird ein outbound Dropship in den RTB-Kartenstatus uebergeben, damit ein zweites Dropship den naechsten Drop starten kann.

## Nicht-Ziele
- Keine komplette neue KI-Taktik.
- Keine echte Ballistik.
- Kein abschliessendes Balancing von 70/90-Grad-Feuerbereichen.

## Akzeptanzkriterien
- [x] Feuerbereich ist tile-aligned dokumentiert.
- [x] Facing-/Aim-Linie und Fire-Sector-Visuals sind im Snapshot getrennt.
- [x] Fire-Sector-LOS ist auf einen radiusbegrenzten Scan mit begrenzten Blocker-Linien umgestellt.
- [x] Dropship-Auswahl ist pro Mission-Craft fuer Mission Control relevant.
- [x] Offmap-Inbound zeigt Fortschritt auf der Karte, aber kein Schiff neben der Map.
- [x] Ein zweites Mission-Dropship kann nach dem ersten Drop starten, waehrend das erste als RTB weiterverfolgt wird.
- [x] Alte `ready/php/plan`-Unklarheiten sind als Folgeentscheidung sichtbar.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- `docs/tasks/TASK_323_manual_playtest_mission_command_visuals_fire_sector_dropships.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_mission_fire_sector_overlay.gd`
- [x] `bugfix_mission_multi_dropship_cards.gd`
- [x] `task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `task_230_flight_altitude_layer_and_air_visibility_audit.gd`
- [x] `task_313_dropship_arrival_visibility_feedback_smoke.gd`
- [x] `task_312_dropship_command_matrix_lz_go_layout.gd`
- [x] `bugfix_dropship_mission_flow_verifier.gd`
- [x] `git diff --check`

## Risiken
- Die taktische Semantik von Move/Take/Hold/Flag/Target/Clear braucht weiter eine eigene UI-Erklaerung und ggf. Command-Hierarchy-Folgearbeit.
- Fire-Sector-Winkel und genaue Lesbarkeit brauchen weiterhin echten Sichtcheck im Live-Missionsfenster.

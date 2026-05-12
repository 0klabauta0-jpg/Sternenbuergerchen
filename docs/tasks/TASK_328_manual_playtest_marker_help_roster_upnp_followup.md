# TASK_328 - Manual Playtest Marker Help Roster UPnP Followup

## Ziel
Auswahl-/Befehlsmarker, Charakterwert-Hilfen und Multiplayer-Startsetup sollen im Playtest eindeutiger und weniger fehleranfaellig werden.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Mission-Playtest wirkten gelbe Auswahlmarker versetzt und teilweise ausserhalb der nutzbaren Karte. Im Team-/Charakter-Editor waren Werte, Traits und Rang-Badges noch nicht ausreichend erklaert. Fuer Multiplayer soll jeder Spieler standardmaessig den eigenen lokalen Roster mitbringen koennen; UPnP soll als erreichbare Host-Option verfuegbar sein.

## Umfang
1. Mission Marker:
   - Tile-Auswahl ignoriert Offmap-Positionen und dedupliziert Tile-Koordinaten.
   - Bewegungs-/Sicherungsmarker werden auf echte Map-Tiles gesnappt.
   - Marker ausserhalb der Karte werden nicht mehr als freischwebende Rauten gerendert.
2. Character-/Team-Hilfe:
   - Werte, Plattformwerte, Traits/Rollen und abgeleitete Funktionswerte erhalten ausfuehrlichere Hilfetexte.
   - Rang-Badges wie Shooter, Leader, Pilot, Medic, Heavy, Engineer und Enemy tragen dynamische Hover-Infos mit Quelle, Schwelle und Score-Zusammensetzung.
   - FOB/Homebase-Karten koennen dieselben Badge-Hilfen fuer laengeren Hover nutzen.
3. Multiplayer:
   - Multiplayer startet standardmaessig mit lokalen Spieler-Rostern statt Host-Roster.
   - Die Lobby waehlt den aktiven lokalen Roster als Default.
   - UPnP ist als Verbindungsmodus sichtbar und versucht beim Hoststart eine UDP-Portfreigabe am Gateway.

## Erwartete Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/meta/npc_rank_badge_resolver.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/npc_compact_card.gd`
- `scripts/meta/npc_meta_card.gd`
- `scripts/meta/fob_screen.gd`
- `scripts/ui/main_menu_screen.gd`
- `scripts/ui/multiplayer_lobby_screen.gd`
- `scripts/multiplayer/multiplayer_roster_contract.gd`
- `scripts/multiplayer/multiplayer_session.gd`
- `data/contextual_help_catalog.json`
- `scripts/tests/bugfix_character_team_editor_usability_pass.gd`
- `scripts/tests/bugfix_mission_dropship_plans_and_facing.gd`
- `scripts/tests/bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`

## Lokale Pruefung
- [x] `godot --headless --path . --check-only --script scripts/terrain/terrain_map_3d_view.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/npc_rank_badge_resolver.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/character_sheet_formatter.gd`
- [x] `godot --headless --path . --check-only --script scripts/ui/main_menu_screen.gd`
- [x] `godot --headless --path . --check-only --script scripts/multiplayer/multiplayer_session.gd`
- [x] `godot --headless --path . --check-only --script scripts/ui/multiplayer_lobby_screen.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/character_sheet_view.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/npc_compact_card.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/npc_meta_card.gd`
- [x] `godot --headless --path . --check-only --script scripts/meta/fob_screen.gd`
- [x] `bugfix_character_team_editor_usability_pass.gd`
- [x] `bugfix_mission_dropship_plans_and_facing.gd`
- [x] `bugfix_multiplayer_lobby_setup_and_asset_catalog_followup.gd`

## Risiken
- UPnP kann nur funktionieren, wenn Router, Betriebssystem-Firewall und Netzwerkprofil es zulassen; lokal ist nur die Godot-API-/Setup-Seite pruefbar.
- Badge-Tooltip-Formeln beschreiben den aktuellen Resolver-Stand. Balancing-Aenderungen muessen diese Texte mitziehen.

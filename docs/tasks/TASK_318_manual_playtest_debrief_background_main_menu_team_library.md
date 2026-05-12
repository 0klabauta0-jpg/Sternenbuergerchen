# TASK_318 - Manual Playtest Debrief Background and Main Menu Team Library

## Ziel
Mission Debrief und Hauptmenue sollen die im Playtest gewuenschte visuelle Einbettung und Team-Auswahl bekommen, ohne daraus ein neues Kampagnen- oder Multiplayer-Slot-System zu machen.

## Status: IMPLEMENTIERT

## Kontext
Im Mission Debrief fehlte ein Hintergrundbild. Im Startscreen sollte unter der Teamwahl sichtbar sein, welche Teams existieren, welches Team aktiv ist und welche Teams geloescht werden koennen.

## Umfang
1. Mission Debrief:
   - Debrief nutzt ein katalogisiertes Hintergrundbild.
   - Das Debrief-Fenster ist transparenter, damit der Hintergrund sichtbar bleibt.
2. Main Menu Team Library:
   - Erstellte Teams werden im Hauptmenue gelistet.
   - Das aktive Team ist sichtbar markiert.
   - Archivierte Teams koennen geloescht werden.
   - Das aktive Team ist gegen versehentliches Loeschen geschuetzt.
3. UI-Vertrag:
   - Teamliste bleibt eine Ansicht auf vorhandene lokale Roster-/Archive-Daten.
   - Es wird keine neue Persistenz-Wahrheit erfunden.

## Nicht-Ziele
- Kein persistentes PvP-Team-System.
- Kein Kampagnen-Slot-System.
- Kein Umbau der Multiplayer-Lobby.

## Akzeptanzkriterien
- [x] Debrief rendert mit Hintergrundbild und Lesbarkeits-Dimmung.
- [x] Hauptmenue zeigt vorhandene Teams unter der Teamwahl.
- [x] Aktives Team ist erkennbar.
- [x] Loeschen ist fuer Archivteams moeglich und fuer das aktive Team geschuetzt.

## Erwartete Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/tests/bugfix_debrief_background_and_main_menu_team_library.gd`
- `scripts/tests/task_245_background_image_catalog_and_screen_usage_verifier.gd`
- `data/ui_asset_catalog.json`
- `docs/tasks/TASK_318_manual_playtest_debrief_background_main_menu_team_library.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_debrief_background_and_main_menu_team_library.gd`
- [x] `task_245_background_image_catalog_and_screen_usage_verifier.gd`
- [x] `task_234_persistent_player_roster_save_and_reset.gd`
- [x] `git diff --check`

## Risiken
- Die Teamliste ist ein UI-Komfort auf dem lokalen Save-/Archivstand. Sie ist noch kein vollwertiger Team-/Kampagneneditor.

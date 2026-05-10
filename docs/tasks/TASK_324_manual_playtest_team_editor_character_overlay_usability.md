# TASK_324 - Manual Playtest Team Editor Character Overlay Usability

## Ziel
Team-Erstellung und Charakterbearbeitung sollen als eigenstaendige Editor-Ansicht funktionieren, statt das Hauptmenue mit grossen Portraits oder unfertigen Controls zu ueberdecken.

## Status: IMPLEMENTIERT IM ARBEITSSTAND

## Kontext
Im Startscreen verdeckte der Teambereich die Hauptbuttons. Gewuenscht war ein eigener Team-Editor wie der Map-Editor: leere Charakterkarten, Ansichten fuer 6er/9er/volle Charakterblaetter, Name/Portrait aenderbar, Punktebudget fuer Rookies und besser erklaerte abgeleitete Werte.

## Umfang
1. Main Menu Einstieg:
   - Team-Erstellung wird aus dem Hauptmenue in eine eigene Ansicht ausgelagert.
   - Hauptbuttons bleiben sichtbar und werden nicht durch Editor-Portraits verdeckt.
2. Team Editor:
   - Neue/generierte Teams koennen im Editor geoeffnet werden.
   - Bestehende Teams koennen per Auswahl/Doppelklick bearbeitet werden.
   - Teamname und Portrait/Icon koennen geaendert werden.
3. Character Editor:
   - Werte sind mit Plus/Minus-Bedienung aenderbar.
   - Abgeleitete Werte aktualisieren live.
   - Punktebudget, Mindest-/Maximalwerte und Rookie-Grenze werden sichtbar gemacht.
   - Kurzbeschreibung wurde aus dem Fokus genommen; letzte Ausruestung wandert nach unten.
4. Help:
   - Werte, Traits, Rollen, Skills und abgeleitete Werte bekommen Hilfe-Popups.
   - Texte sollen kurz umbrechen und die Wirkung der Werte erklaeren.
5. Flight-Skills:
   - Zusaetzliche Piloten-/Flugwerte sind als Designbedarf dokumentiert.

## Nicht-Ziele
- Kein finales Balancing des Team-Punktebudgets.
- Kein persistentes PvP-Team-System.
- Keine endgueltige Skill-Matrix fuer Dropship-Piloten.

## Akzeptanzkriterien
- [x] Hauptmenue bleibt bedienbar, Team-Editor ist eigene Ansicht.
- [x] Bestehende Teams koennen zur Bearbeitung geoeffnet werden.
- [x] Name und Portrait koennen im Editor geaendert werden.
- [x] Abgeleitete Werte reagieren live auf Werteanpassungen.
- [x] Punktebudget und Wertgrenzen sind sichtbar.
- [x] Help-Popups sind fuer Werte/Rollen/Traits vorgesehen.

## Erwartete Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/meta/character_sheet_view.gd`
- `scripts/meta/character_sheet_formatter.gd`
- `scripts/meta/start_roster_generator.gd`
- `data/contextual_help_catalog.json`
- `scripts/tests/bugfix_character_team_editor_usability_pass.gd`
- `docs/tasks/TASK_324_manual_playtest_team_editor_character_overlay_usability.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`

## Lokale Pruefung
- [x] `bugfix_character_team_editor_usability_pass.gd`
- [x] `task_235_character_sheet_roster_gameplay_expansion.gd`
- [x] `task_259_character_card_roster_switching_playability.gd`
- [x] `task_265_character_sheet_loadout_help_content_pass.gd`
- [x] `git diff --check`

## Risiken
- Das Punktebudget ist noch ein Rookie-Authoring-Vertrag, kein finaler Progressions-/Balancingvertrag.
- Die drei Flugwerte fuer gute Dropship-Piloten muessen in einem Folge-Task fachlich festgelegt werden.

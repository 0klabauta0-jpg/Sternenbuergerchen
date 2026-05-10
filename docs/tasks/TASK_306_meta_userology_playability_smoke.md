# TASK_306 - Meta Userology Playability Smoke

## Ziel
Nach TASK_299 bis TASK_305 soll ein Playability-Smoke pruefen, ob Teamnamen, Main-Menu-Rueckwege, NPC-Karten, Badges, Dropship, FOB-Dragdrop, Transit-Ghosting und Fireteam-Staging zusammen bedienbar bleiben.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_299 - Team Identity Name Generation Userology
- TASK_300 - App Shell Return To Main Menu Navigation
- TASK_301 - NPC Card Drag Z-Order Badges Tooltips
- TASK_302 - Dropship Flight Deck Boarding Rename Userology
- TASK_303 - FOB Transfer Dragdrop Card Readability
- TASK_304 - Unified Transit Progress Ghosting Homebase FOB
- TASK_305 - Fireteam Staging Copy Cohesion Status

## Kontext
Viele kleine UX-Fixes koennen sich gegenseitig stoeren: globaler Drag-Layer, Tooltips, Fenster-Z-Order, Transfer-State und Main-Menu-Navigation muessen gemeinsam getestet werden. Dieser Task ist der Abschlussgate fuer die Userology-Reihe.

## Umfang
1. Automatisierter Smoke:
   - Neues Team erstellen, Namen generieren/aendern/speichern.
   - Von Einzelspieler, Multiplayer, Editor, Einstellungen zum Hauptmenue zurueck.
   - NPC-Karte ziehen: Drag-Layer vor Fenstern.
   - Badge-Tooltip/Character-Sheet-Tooltip.
   - FOB Transfer Dragdrop und kleine Remove-Aktion.
   - Dropship umbenennen, Pilotstatus anzeigen, Team boarden.
   - Transit-Ghosting Quelle/Ziel mit Progress.
   - Fireteam-Staging und Cohesion-Anzeige.
2. Manuelle Checkliste:
   - Fixed FullHD.
   - Keine abgeschnittenen Texte.
   - Graue Texte lesbar.
   - Drag and Drop fuehlt sich direkt an.
   - Popups erklaeren, ohne zu stoeren.
3. Regression-Gate:
   - Bestehende Meta-/Roster-/FOB-/Dropship-Verifier laufen weiter.
   - Performance-/Warning-Budget pruefen.

## Nicht-Ziele
- Keine neuen Features im Smoke.
- Keine finale UI-Art-Direction.
- Kein Multiplayer-Zwei-Client-Handtest, ausser separat gewuenscht.

## Akzeptanzkriterien
- [x] TASK_306-Smoke laeuft gruen.
- [x] Manuelle Checkliste fuer Homebase, FOB, Dropship und Hauptmenue ist angelegt.
- [x] Keine Regression bei Roster, FOB, Dropship und Contextual Help im fokussierten Gate.
- [x] Offene Restpunkte sind als manuelle Checkpunkte dokumentiert.

## Erwartete Dateien
- `scripts/tests/task_306_meta_userology_playability_smoke.gd`
- `docs/manual_checks/meta_userology_playability_smoke.md`
- optional `docs/reports/meta_userology_playability_report.md`
- `docs/tasks/TASK_306_meta_userology_playability_smoke.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_306_meta_userology_playability_smoke.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_267_contextual_help_coverage_layout_verifier.gd`
- [ ] `git diff --check`

## Risiken
- Der Smoke darf nicht selbst grosse UI-Reworks enthalten.
- Wenn Headless-Checks Z-Order nur indirekt pruefen, bleibt der manuelle Dragcheck Pflicht.

## Naechster Schritt
Nach TASK_306 folgt Phase 18Y fuer die vertieften FOB-/VB-/Flight-Deck-Details.

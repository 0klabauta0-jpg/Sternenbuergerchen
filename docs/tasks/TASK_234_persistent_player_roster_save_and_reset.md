# TASK_234 - Persistent Player Roster Save and Reset

## Ziel
Das erzeugte Startteam soll dauerhaft gespeichert werden. Spieler sollen ihr Roster ueber Missionen hinweg behalten und bei Bedarf bewusst ein neues Team erzeugen koennen.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_096 - Recovery Loop
- TASK_114 - Meta Recovery Integration
- TASK_199 - Main Menu Shell and Background Image
- TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay
- TASK_232 - Start Roster Generation Contract
- TASK_233 - Portrait Identity Catalog and Roster Presentation

## Kontext
Character-Gameplay funktioniert nur, wenn NPCs nicht nach jedem Start verschwinden. Das Roster braucht einen klaren Speichervertrag: `user://`, Versionierung, Migration/Fallback, Reset mit Bestaetigung und Trennung von Singleplayer-/Multiplayer-Profilen.

## Umfang
1. Save-Vertrag:
   - Roster-Save unter `user://profiles/...`.
   - Format-Version.
   - Generator-Seed.
   - NPC-Profile, Portrait-ID, Skills, Traits, Status, Fireteam-Historie.
2. Laden:
   - Existierender Save wird beim App-/Meta-Start geladen.
   - Fehlt ein Save, wird TASK_232-Generator angeboten oder automatisch gestartet.
   - Fehlerhafte Saves liefern Diagnose und sicheren Fallback.
3. Reset/New Team:
   - Button `Neues Team generieren`.
   - Bestaetigung, dass vorhandenes Roster ersetzt wird.
   - Optional alten Save archivieren statt direkt loeschen.
4. Multiplayer:
   - Spielerprofil/Roster ist lokal.
   - Host/Join bekommen klare Zuordnung, ob eigenes Roster genutzt wird oder Host-Szenario-Roster.
5. Recovery:
   - Verletzte/downed/recovering Units bleiben zwischen Missionen erhalten, sobald entsprechende Systeme angebunden sind.
6. Verifier:
   - Save/Load/Roundtrip.
   - Reset erzeugt neues Seed/Roster.
   - alte/fehlende Version wird abgefangen.

## Nicht-Ziele
- Kein Cloud Save.
- Kein Accountsystem.
- Kein Recruiting-/Entlassungsmarkt.
- Kein Savegame-UI-Manager mit Slots, ausser minimaler Profilpfad ist noetig.

## Umsetzung
- `scripts/meta/player_roster_store.gd` speichert V1-Roster unter `user://profiles/<profile>/roster_v1.json`, validiert Format, Seed, Profil-ID und Roster-Inhalt.
- `scripts/ui/main_menu_screen.gd` laedt ein vorhandenes Roster, erzeugt bei fehlendem/ungueltigem Save ein neues Roster und schreibt Reset/New-Team erst nach Bestaetigung.
- Reset archiviert den bisherigen Save unter `user://profiles/<profile>/archive/`, bevor der neue Seed gespeichert wird.
- `scripts/meta/meta_layer_flow.gd` kann beim Meta-Start ein gueltiges lokales Roster aus `local_player` fuer Homebase/FOB uebernehmen; sonst bleiben die bisherigen Presets Fallback.
- `docs/dev/player_roster_save_contract.md` dokumentiert Save-Pfad, Schema, Unit-Felder, Reset-Archiv und Multiplayer-Profilgrenze.

## Akzeptanzkriterien
- [x] Ein erzeugtes Roster wird in `user://` gespeichert und geladen.
- [x] Format-Version und Generator-Seed sind enthalten.
- [x] Reset/New-Team-Button ersetzt Roster nur nach Bestaetigung.
- [x] Save/Load roundtrippt MetaUnitProfile-Daten inklusive Portrait und Traits.
- [x] Multiplayer-Profilgrenze ist dokumentiert.
- [x] Ein TASK_234-Verifier prueft Save, Load, Reset, Version und Fehlerfall.

## Erwartete Dateien
- `scripts/meta/player_roster_store.gd`
- `scripts/meta/start_roster_generator.gd`
- `scripts/ui/main_menu_screen.gd`
- `scripts/meta/homebase_screen.gd`
- `docs/dev/player_roster_save_contract.md`
- `scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- `docs/tasks/TASK_234_persistent_player_roster_save_and_reset.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_234_persistent_player_roster_save_and_reset.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_232_start_roster_generation_contract.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_231_app_shell_game_setup_integration_and_open_items_review.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_233_portrait_identity_catalog_and_roster_presentation.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [ ] Manueller Start/Reset-Sichtcheck.
- [x] `git diff --check`

## Risiken
- Save-Vertraege werden spaeter schwer aenderbar. V1 braucht Versionierung.
- Reset darf nicht versehentlich beim ersten Menue-Klick Daten verlieren.

## Naechster Schritt
Nach TASK_234 kann TASK_235 das Character Sheet fuer Character-Gameplay erweitern.

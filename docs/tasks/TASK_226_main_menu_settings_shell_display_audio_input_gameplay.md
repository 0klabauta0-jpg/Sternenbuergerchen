# TASK_226 - Main Menu Settings Shell Display Audio Input Gameplay

## Ziel
Das Hauptmenue bekommt ein brauchbares Einstellungsmenue mit den wesentlichen Platzhaltern und ersten echten Optionen: Anzeige, Fenster/Vollbild, Audio, Eingabe und Gameplay inklusive Fog of War.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_195 - UI Input and Cursor Asset Availability Pass
- TASK_199 - Main Menu Shell and Background Image
- TASK_211 - Comic Bubble Toggles Cooldowns and Settings
- TASK_223 - Fog of War Modes Contract and Settings

## Kontext
TASK_199 legt nur eine kleine Settings-Shell an. Fuer ein Spielmenue braucht es danach die ueblichen Einstellungen: Aufloesung, Fenster/Vollbild, VSync, Audio, Eingabe, Gameplay-Optionen und FoW-Modus. V1 darf klein sein, soll aber nicht wie ein Testscreen wirken.

## Umfang
1. Display:
   - Aufloesungsauswahl oder Anzeige aktueller Aufloesung mit sicheren Presets.
   - Windowed, Borderless, Fullscreen.
   - VSync an/aus, falls bereits sinnvoll.
2. Audio:
   - Master Volume.
   - Music und SFX als Platzhalter oder echte Bus-Slider, je nach Projektstand.
3. Eingabe:
   - Liste wichtiger Actions: Kamera, Auswahl, Befehle, Thought-Hold, Escape/Zurueck.
   - V1 muss nicht komplett rebindable sein, aber die Struktur vorbereiten.
4. Gameplay:
   - Fog of War: `off`, `known_terrain`, `unexplored_blackout`.
   - Comic-Bubbles: off/minimal/normal aus TASK_211.
   - Optional Debug-/Accessibility-Platzhalter klar als deaktiviert markieren.
5. Persistenz:
   - Settings in einem zentralen Settings-Contract speichern.
   - Defaults ohne vorhandene Config sicher laden.
   - Apply/Cancel/Reset Defaults.
6. Verifier:
   - Settings-Screen instanziert aus Hauptmenue.
   - Werte roundtrippen.
   - FoW-Modus landet im Settings-Vertrag.
   - Keine Gameplay-State-Mutation beim Menue-Oeffnen.

## Nicht-Ziele
- Kein komplettes Keybinding-Menue.
- Kein Grafikqualitaetsmenue mit vielen Presets.
- Kein Savegame-System.
- Kein Accessibility-Komplettpaket.

## Akzeptanzkriterien
- [x] Settings-Menue ist vom Hauptmenue erreichbar und wieder schliessbar.
- [x] Display-, Audio-, Input- und Gameplay-Sektionen sind sichtbar.
- [x] FoW-Modus kann gewaehlt und gespeichert werden.
- [x] Comic-Bubble-Modus kann angezeigt oder gesetzt werden, wenn TASK_211 aktiv ist.
- [x] Defaults, Apply und Reset funktionieren strukturell.
- [x] Ein TASK_226-Verifier prueft Settings-Roundtrip und Hauptmenue-Anbindung.

## Erwartete Dateien
- `scripts/ui/main_menu_screen.gd`
- `scripts/ui/settings_screen.gd`
- `scripts/ui/game_settings_contract.gd`
- `scenes/ui/main_menu.tscn`
- optional `scenes/ui/settings_screen.tscn`
- `scripts/tests/task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`
- `docs/tasks/TASK_226_main_menu_settings_shell_display_audio_input_gameplay.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- [ ] Manueller Hauptmenue-Settings-Sichtcheck.
- [x] `git diff --check`

## Risiken
- Settings duerfen nicht mehr versprechen als sie wirklich speichern.
- Aufloesung/Vollbild kann lokal nervig sein; Verifier sollte strukturell pruefen und manuelle Tests klar trennen.

## Umsetzung
- `GameSettingsContract` speichert jetzt Display, Audio und Gameplay zentral: Resolution-Preset, Window Mode, VSync, Master/Music/SFX und FoW-Modus.
- `MainMenuScreen` baut das Settings-Menue als V1-Shell mit Anzeige-, Audio-, Eingabe- und Gameplay-Sektionen auf. Apply/Cancel/Reset arbeiten ueber Draft-Settings, damit Menue-Oeffnen keinen Gameplay-State mutiert.
- `scripts/ui/settings_screen.gd` buendelt kleine UI-/Snapshot-Helfer fuer Settings-Sektionen und OptionButton-Metadaten.
- Comic-Bubble-Settings bleiben im TASK_211-Vertrag, werden aber im Gameplay-Bereich der Settings-Shell angezeigt und zusammen mit Apply/Reset gespeichert.
- `task_226_main_menu_settings_shell_display_audio_input_gameplay.gd` prueft Contract-Roundtrip, Hauptmenue-Anbindung, sichtbare Sektionen, Apply/Reset/Cancel, FoW- und Bubble-Persistenz sowie keine SimulationRoot-Erzeugung.

## Naechster Schritt
Nach TASK_226 kann TASK_227 den Multiplayer-Einstieg aus dem Hauptmenue produktiver machen.

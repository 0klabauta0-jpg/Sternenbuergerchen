# TASK_391 - Global Escape Menu and Button SFX

## Ziel
Jeder Bedienbereich soll per Escape ein einheitliches Shell-Menue oeffnen koennen. Das Menue bietet Rueckkehr ins Spiel, Einstellungen, Mission-Slot speichern/laden, Rueckkehr ins Hauptmenue und Spiel beenden. Buttons ausserhalb der bereits manuell vertonten Hauptmenue-/Lobby-Screens sollen denselben UI-Klicksound bekommen wie die vorhandenen Hauptmenue-Aktionen.

## Sinnhaftigkeit
Der Spieler braucht jederzeit einen sicheren Ausweg und zentrale Einstellungen, ohne zu wissen, in welchem UI-Unterbaum er gerade steckt. Button-Feedback darf nicht nur im Hauptmenue vorhanden sein; Meta-Layer, Mission, Editor und neue Popups sollen sich gleich anfuehlen.

## Umfang
- Globaler Autoload-Shell-Layer fuer Escape-Menue.
- Automatische UI-SFX-Installation fuer `BaseButton`-Controls in Spiel-, Meta- und Editor-Screens.
- Compact Settings im Escape-Menue mit Apply/Back und bestehendem `GameSettingsContract`.
- Shell-Slot Save/Load als V1: speichert zunaechst den aktuellen Szenenpfad mit Zeitstempel und laedt diesen Pfad wieder.
- Hauptmenue erhaelt sichtbare Mission-Speichern-/Mission-Laden-Zugaenge, die denselben Shell-Slot verwenden.
- Headless-Verifier fuer Escape-Toggle, Button-SFX-Hook, Settings-Apply, Main-Menu/Save/Load-Aktionen und Quit-Request ohne echtes Beenden.

## Akzeptanz
- Escape oeffnet/schliesst das Shell-Menue in einer beliebigen Szene.
- Das Menue enthaelt Resume, Einstellungen, Speichern, Laden, Hauptmenue und Beenden.
- Einstellungen koennen aus dem Escape-Menue heraus gespeichert werden und aktualisieren den AudioEventBus.
- Ein dynamisch erzeugter Button bekommt automatisch UI-Klicksound, sofern sein Screen nicht bereits eigene UI-SFX verwaltet.
- Hauptmenue zeigt Mission speichern/laden als Bedienpfad.
- Quit wird im Testmodus nur als Request markiert; im Spiel ruft er `SceneTree.quit()`.

## Betroffene Dateien
- `docs/tasks/TASK_391_global_escape_menu_button_sfx.md`
- `docs/TASK_ROADMAP.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `project.godot`
- `scripts/ui/global_escape_menu.gd`
- `scripts/ui/main_menu_screen.gd`
- `scripts/tests/task_391_global_escape_menu_button_sfx.gd`

## Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_391_global_escape_menu_button_sfx.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_244_combat_movement_ui_sfx_integration_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_226_main_menu_settings_shell_display_audio_input_gameplay.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Der Save/Load-Slice ist bewusst ein Shell-Slot fuer den aktuellen Szenenpfad, noch kein vollstaendiges Mission-Simulation-Savegame. Ein echter Mission-State-Save bleibt ein eigener Folge-Task.
- Hauptmenue und Multiplayer-Lobby haben bereits manuelle SFX-Hooks; der globale Installer laesst diese Screens aus, um doppelte Klicksounds zu vermeiden.

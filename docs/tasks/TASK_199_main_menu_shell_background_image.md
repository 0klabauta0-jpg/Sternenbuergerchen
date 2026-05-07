# TASK_199 - Main Menu Shell and Background Image

## Ziel
Das Projekt bekommt ein echtes Hauptmenue als Einstiegspunkt. Der Spieler kann dort `Einzelspieler`, `Multiplayer`, `Editor` und `Einstellungen` auswaehlen.

Das vom User bereitgestellte Bild wird als Hauptmenue-Hintergrund in das Projekt uebernommen und ueber einen stabilen Projektpfad verwendet.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_164 - UI Theme and Component Library
- TASK_167 - Multiplayer Session and Lobby Extraction
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_193 - Asset Source Inventory and Availability Matrix
- bestehender Editor unter `res://scenes/editor/map_editor.tscn`

## Bildquelle
Lokale Quelle:

`C:\Users\bjoer\Pictures\Sternenbürger\Use AI Image Apr 18, 2026, 23_16_45.jpeg`

Geplanter Projektpfad:

`res://Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg`

Die Runtime darf den lokalen `C:\Users\...`-Pfad nicht referenzieren. Der lokale Pfad ist nur Importquelle und Dokumentation.

## Kontext
`project.godot` startet aktuell noch direkt in einen Test-/Meta-Pfad. Fuer einen spielbaren Build braucht das Projekt einen eigenen App-Shell-Einstieg, der bestehende Zielpfade sauber verdrahtet:

- Einzelspieler: bestehender Meta-/Homebase-/FOB-/Mission-Flow.
- Multiplayer: bestehender Lobby-/Session-Flow.
- Editor: bestehender Map-Editor.
- Einstellungen: eigenes Settings-Panel/Shell, ohne falsche Persistenzversprechen.

## Umfang
1. Hintergrund-Asset importieren:
   - Bild aus der lokalen Quelle ins Projekt kopieren.
   - Stabiler ASCII-Dateiname.
   - Optional kleine `README.md` oder Manifest-Zeile mit Quelle, Datum, Zweck.
   - Godot-Import pruefen.
2. Main-Menu-Szene:
   - Neue Szene, z. B. `res://scenes/ui/main_menu.tscn`.
   - Neues Script, z. B. `res://scripts/ui/main_menu_screen.gd`.
   - Full-HD-Layout als erstes Ziel.
   - Bild als vollflaechiger Hintergrund mit professionellem Zuschnitt.
   - Menueeintraege: `Einzelspieler`, `Multiplayer`, `Editor`, `Einstellungen`.
   - Keine Marketing-Landingpage, direkt bedienbares Menue.
3. Menuefuehrung:
   - `Einzelspieler` startet den bestehenden Singleplayer-Meta-Flow, nicht direkt zufaellige Testlogik.
   - `Multiplayer` startet den bestehenden Lobby-/Session-Pfad. Wenn noch ein Testscreen genutzt wird, muss der Task das bewusst als Adapter dokumentieren.
   - `Editor` oeffnet `res://scenes/editor/map_editor.tscn`.
   - `Einstellungen` oeffnet ein Settings-Panel im Hauptmenue.
4. Settings-Shell:
   - V1 mindestens: Audio-Master, Fenster/Vollbild-Schalter oder Anzeige der aktuellen Window-Option, Zurueck.
   - Wenn Einstellungen noch nicht persistiert werden, muss das UI klar klein bleiben und der Verifier darf keine falsche Speicherung verlangen.
   - Keine Gameplay-State-Mutation.
5. Projekt-Einstieg:
   - `project.godot` erst auf das Hauptmenue umstellen, wenn alle vier Menuepfade im Verifier strukturell abgesichert sind.
   - Bestehende Test-Szenen duerfen erreichbar bleiben, aber nicht mehr Build-Einstieg sein.
6. Verifier:
   - Hauptmenue-Szene instanziert ohne Fehler.
   - Hintergrund-Asset existiert als `res://`-Projektpfad und ist loadbar.
   - Keine lokale absolute Bildquelle in Runtime/Data/Tests.
   - Vier Menuebuttons existieren und routen auf erlaubte Pfade oder Settings-Panel.
   - `project.godot` `run/main_scene` zeigt nach Umsetzung auf das Hauptmenue.

## Nicht-Ziele
- Kein neues Kampagnen-/Savegame-System.
- Kein kompletter Settings-Screen mit allen Optionen.
- Kein Multiplayer-Netzwerk-Rework.
- Kein Editor-Umbau.
- Keine UI-Fenster-Responsive-Experimente ausserhalb des Menues.
- Kein direkter Gameplay-State in Main-Menu-Buttons.

## Designregeln
- Hauptbild ist First-Viewport-Signal und darf nicht nur kleines Thumbnail sein.
- Buttons bleiben klar und gross genug, aber die Figur und Szene im Bild muessen sichtbar bleiben.
- Text nicht in grosse dekorative Karten legen, wenn ein ruhiger Menueblock reicht.
- Keine langen Feature-Erklaertexte im Menue.
- Fokus-/Hover-/Disabled-Zustaende muessen sichtbar sein.
- Menue soll per Maus bedienbar sein; Tastatur/Gamepad-Fokus ist optional, aber willkommen.

## Akzeptanzkriterien
- [x] Das Bild liegt unter `Assets/curated/main_menu/` im Projekt.
- [x] Das Hauptmenue nutzt das Bild als Hintergrund ueber `res://...`.
- [x] `Einzelspieler`, `Multiplayer`, `Editor` und `Einstellungen` sind sichtbar und klickbar.
- [x] Einzelspieler, Multiplayer und Editor routen auf die bestehenden erlaubten Zielpfade.
- [x] Einstellungen oeffnet ein lokales Settings-Panel und kann wieder geschlossen werden.
- [x] `project.godot` startet nach Umsetzung in das Hauptmenue.
- [x] Keine Runtime-/Data-/Test-Datei referenziert den lokalen `C:\Users\...`-Bildpfad.
- [x] Ein TASK_199-Verifier deckt Asset, Buttons, Routing und Main-Scene-Eintrag ab.
- [ ] Manueller Sichtcheck bestaetigt Lesbarkeit des Menues mit dem Hintergrundbild.

## Erwartete Dateien
- `Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg`
- optional `Assets/curated/main_menu/README.md`
- `scenes/ui/main_menu.tscn`
- `scripts/ui/main_menu_screen.gd`
- `scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- `project.godot`
- `docs/tasks/TASK_199_main_menu_shell_background_image.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --import`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_199_main_menu_shell_background_image_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_167_multiplayer_session_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_164_ui_theme_component_verifier.gd`
- [ ] Manueller Sichtcheck: Hauptmenue starten, vier Buttons testen, Settings oeffnen/schliessen.
- [x] `git diff --check`

## Umsetzung
- Das Hintergrundbild wurde nach `Assets/curated/main_menu/sternenbuerger_main_menu_bg.jpeg` kopiert und importiert.
- `scenes/ui/main_menu.tscn` ist der neue FullHD-first App-Shell-Einstieg mit vollflaechigem Hintergrund, ruhiger linker Menueleiste und vier Buttons.
- `scripts/ui/main_menu_screen.gd` routet `Einzelspieler` auf `res://scenes/meta/meta_layer_test.tscn`, `Multiplayer` bewusst auf den bestehenden TASK_167-Lobby-Adapter `res://scenes/tests/lobby_test.tscn`, `Editor` auf `res://scenes/editor/map_editor.tscn` und `Einstellungen` auf ein lokales Settings-Panel.
- Das Settings-Panel bietet Master-Audio, Vollbild-Schalter und Zurueck, ohne Persistenz oder Gameplay-State zu versprechen.
- `project.godot` nutzt jetzt `res://scenes/ui/main_menu.tscn` als `run/main_scene`.

## Offene manuelle Pruefung
- Der manuelle GUI-Sichtcheck fuer Lesbarkeit, Buttonklicks und Settings-Panel ist noch offen.

## Risiken
- Das Bild ist 16:9 und wirkt fuer Full-HD gut, kann aber bei anderen Seitenverhaeltnissen falsch beschnitten werden. Der Task soll Full-HD zuerst absichern und den Crop bewusst waehlen.
- Wenn `Multiplayer` direkt auf einen Testscreen zeigt, muss der Adapter klar dokumentiert sein, damit spaeter ein produktiver Lobby-Screen nachgezogen werden kann.
- Settings duerfen nicht mehr versprechen als sie speichern. V1 darf klein bleiben.

## Naechster Schritt
Nach TASK_199 hat das Projekt einen echten Build-Einstieg. Danach koennen Settings, Multiplayer-Lobby-Politur und Singleplayer-Kampagnenstart als getrennte Folgeaufgaben geschnitten werden.

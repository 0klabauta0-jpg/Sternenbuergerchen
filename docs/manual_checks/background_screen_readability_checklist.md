# Background Screen Readability Checklist

## Ziel
TASK_245 prueft die Backgrounds headless auf Projektpfade und Katalogvertrag. Dieser Check ist fuer die erste echte Full-HD-Sichtpruefung.

## Setup
- Godot im Fenster starten.
- Auf 1920x1080 oder borderless Full-HD pruefen.
- Master/UI-SFX koennen aus bleiben; dieser Check bewertet nur Bilder und Lesbarkeit.

## Main Menu
- `main_menu_shell` bleibt sichtbar.
- Linke Menueleiste, Settings-Panel und Status-Text bleiben gut lesbar.
- Keine lokalen Bildpfade oder leeren Backgrounds.

## Multiplayer Lobby
- `multiplayer_lobby_hangar` wird vollflaechig geladen.
- Center-Panel, Labels, SpinBoxes und Buttons bleiben lesbar.
- Shade wirkt ruhig; Schiff-/Hangardetails duerfen nicht mit Text konkurrieren.

## Spaetere Setup-Kontexte
- `mission_select_desert_outpost`: nur mit Panel/Rail-Text verwenden.
- `loading_asteroid_flight`: geeignet fuer kurze Loading-/Travel-Flachen.
- `debrief_desert_explosion_base`: nur stark gedimmt oder mit Panel, weil Explosion sehr kontrastreich ist.

## Ergebnis notieren
- Zu hell/dunkel:
- Schlechter Crop:
- Text unlesbar:
- Performance/Stutter beim Screenwechsel:

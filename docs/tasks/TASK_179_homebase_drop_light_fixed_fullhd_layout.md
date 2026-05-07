# TASK_179 - Homebase Drop Light Fixed FullHD Layout

## Ziel
Der Homebase-Screen wird nach der Vorlage `b_homebase.svg` auf ein festes Full-HD-Layout uebertragen.

Homebase bleibt Roster-, Team- und Fahrzeug-Staging. Es wird keine begehbare Basis und keine zweite Gameplay-Wahrheit.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_178 - FOB Drop Light Fixed FullHD Layout

## Referenz
- `C:\Users\bjoer\Documents\Codex\2026-05-05\sternenbuergerchen-figma-setup-status-layout-arbeitsvorlage\penpot_sternenbuergerchen_layout\drop_light\b_homebase.svg`

## Umfang
1. Fester Full-HD-Frame:
   - Ziel-Viewport `1920 x 1080`.
   - feste Topbar.
   - feste Hauptfenster.
   - Hauptfenster muessen nach dem Layout-Pass auch tatsaechlich an den Contract-Positionen liegen.
   - Nicht ausreichend: nur `custom_minimum_size`, Stretch-Ratio oder `drop_light_rect`-Metadaten setzen.
2. Roster-Fokus:
   - Available Operators bleibt Hauptfokus.
   - kompakte NPC-Karten nach `drop_light`.
3. Transfer-Team:
   - Staging-Team als feste Spalte/Fenster.
   - aktive Transfers sichtbar, aber nicht als Gameplay-State in UI.
4. Flightdeck/Fahrzeuge:
   - vorhandene Projekt-Fliegerassets nutzen.
   - Pilotenzuordnung und Cargo-Auswahl bleiben bestehender Datenfluss.
   - Boarding-/Transferstapel visuell klarer darstellen.
   - Das Flightdeck bekommt eine echte read-only Visual-Buehne: Pad-/Craft-/Stack-Darstellung als Spiegelung vorhandener Transportdaten.
   - Keine SVG- oder Mockup-Platzhalter als Runtime-Inhalt.
5. Character Sheet:
   - bestehendes Character-Sheet in feste Fensterlogik einpassen.
   - keine neue Skill- oder Combat-Logik.

## Nachziehpflicht aus TASK_178
- Falls TASK_178 nur Mindestgroessen oder Metadaten prueft, muss TASK_179 den strengeren Layout-Nachweis einfuehren.
- Der Homebase-Verifier muss nach mindestens einem `process_frame` echte `global_position` und `size` gegen `DropLightLayoutContract.get_homebase_layout()` pruefen.
- Die festen Fenster muessen als sichtbare Fenster funktionieren, nicht nur als Containerwuensche innerhalb alter dynamischer Layouts.
- Lange Roster-, Transfer- und Character-Sheet-Inhalte werden ueber gezielte Scrollbereiche geloest, nicht durch wieder dynamische Hauptfenster.
- Buttons duerfen keine nicht-funktionalen Versprechen machen: sichtbare Homebase-Actions muessen entweder an bestehende Pfade gebunden sein oder klar read-only/disabled erklaert werden.

## Nicht-Ziele
- Keine Aenderung am FOB-Layout in diesem Task.
- Keine Aenderung am Mission-HUD in diesem Task.
- Keine neue Fahrzeugmechanik.
- Keine persistente Teamlogik.
- Keine dynamische responsive Layoutlogik.

## Akzeptanzkriterien
- [x] Homebase rendert in einem festen Full-HD-Layout.
- [x] Roster, Transfer-Team, Flightdeck und Character-Sheet haben feste Fensterpositionen.
- [x] Der Verifier prueft echte `global_position`/`size` der Hauptfenster gegen den Contract, nicht nur Mindestgroessen oder Metadaten.
- [x] Flightdeck/Fahrzeuge werden als read-only Visual-Buehne mit Projektassets dargestellt.
- [x] Projekt-Fliegerassets ersetzen Mockup-Platzhalter.
- [x] Teamtransfer-, Pilot- und Cargo-Flows bleiben kompatibel.
- [x] Sichtbare Action-Buttons sind an bestehende Pfade gebunden oder werden nicht als aktive Befehle dargestellt.
- [x] Keine absolute Assetpfade werden eingefuehrt.

## Ergebnis
- `HomebaseTestScreen` setzt die Hauptfenster nach dem `DropLightLayoutContract` als echte top-level-Fenster auf Contract-Position und -Groesse.
- Der TASK-179-Verifier prueft nach mehreren Frames `global_position` und `size` fuer Topbar, Mission Brief, Roster, Transfer Team, Flightdeck und Character Sheet.
- `#05 FLIGHT DECK` hat eine read-only Visual-Buehne mit Pad-/Craft-/Stack-Spiegelung aus bestehenden Transportdaten.
- Visual Stage und Shipcards nutzen Projektassets unter `res://Assets/kenney_space-kit/Isometric/...`.
- Cargo/Frachter nutzt fuer Homebase jetzt die isometrische Projektgrafik statt der alten Side-Ansicht.
- Teamtransfer-, Pilot-, Cargo- und Mission-Start-Callbacks bleiben die bestehenden Pfade; die Visual-Buehne nimmt keinen Input an und speichert keinen eigenen Gameplay-State.

## Erwartete Dateien
- `scenes/meta/homebase_test_screen.tscn`
- `scripts/meta/homebase_screen.gd`
- `scripts/meta/meta_ui_skin.gd`
- `scripts/meta/transport_craft_card_ui.gd`
- optional `scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- `docs/tasks/TASK_179_homebase_drop_light_fixed_fullhd_layout.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_179_homebase_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_114_meta_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [ ] Manueller Godot-Sichtcheck Homebase in Full HD.
- [x] `git diff --check`

## Risiken
- Feste Fenster koennen bestehende lange Roster-/Transfertexte sichtbarer abschneiden; dafuer sind gezielte Scrollbereiche statt dynamischer Hauptfenster noetig.
- Vehicle-/Pilot-Staging darf nicht zu einer zweiten Transport-State-Maschine werden.

## Naechster Schritt
Nach Homebase folgt TASK_180 fuer das Mission-HUD nach `d_mission.svg`.

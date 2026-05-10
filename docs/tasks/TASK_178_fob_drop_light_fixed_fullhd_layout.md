# TASK_178 - FOB Drop Light Fixed FullHD Layout

## Ziel
Der FOB-Screen wird nach der Vorlage `c_fob.svg` als festes Full-HD-Layout umgesetzt.

Der Screen soll sich wie ein fester 1920x1080-Arbeitsplatz anfuehlen: einmal korrekt eingerueckt, feste Fensterpositionen, feste Panelgroessen, keine dynamischen Fensterbreiten als Primaerlogik.

## Status: IMPLEMENTIERT

## Voraussetzung
- TASK_177 - Drop Light Fixed UI Layout Contract
- TASK_176 - FOB Loadout Weapon Preview Selector

## Referenz
- `C:\Users\bjoer\Documents\Codex\2026-05-05\sternenbuergerchen-figma-setup-status-layout-arbeitsvorlage\penpot_sternenbuergerchen_layout\drop_light\c_fob.svg`

## Kontext
FOB ist der wichtigste naechste UI-Screen fuer den eigentlichen Spielablauf: Fireteams zusammenstellen, Loadout pruefen, Dropship/Flightdeck bedienen und dann Mission vorbereiten.

Die Vorlage bleibt fachlich fuehrend. Die letzte reine Theme-/Skin-Aenderung ist nicht der Ausgangspunkt fuer diesen Layout-Umbau. Sie darf nur erhalten bleiben, wenn sie dem festen `drop_light`-Layout nicht widerspricht.

## Layout-Regeln
- Ziel-Viewport: `1920 x 1080`.
- Alle Hauptfenster haben feste Position und feste Groesse.
- Kein Auto-Resize als Primaerlayout fuer die Hauptfenster.
- Panels werden einmal sauber eingerueckt und bleiben danach stabil.
- `#14 FLIGHTDECK` darf und soll breiter werden als in der aktuellen Godot-FOB-UI.
- `#13 LOADOUT` soll weniger breit werden als im ersten Mockup, damit `#14` mehr Raum fuer echtes Flightdeck bekommt.
- Die unteren Action-Buttons sind quadratisch.
- Medbay/Respawn wird nicht in das Flightdeck-Feld gemischt.

## Zielaufteilung
1. Topbar:
   - Screen-Titel links.
   - Homebase/FOB/Mission-Navigation als feste Buttons.
   - Status-Badges rechts.
2. Linke Spalte:
   - `#10 FIRETEAMS`
   - kompakte Fireteam-Karten.
3. Mittlere Spalte:
   - `#13 LOADOUT`
   - kompakter als Vorlage, aber weiterhin gut lesbar.
   - SMG und Medictool bleiben die einzigen sichtbaren Waffenoptionen aus TASK_176.
   - Preview-Bilder bleiben reine UI-Hilfe.
4. Rechte Spalte:
   - `#14 FLIGHTDECK`
   - deutlich breiter.
   - Pad Field mit echten Projektassets.
   - Dropship/Shuttle/Frachter mit vorhandenen Kenney-Space-Kit-Assets.
   - NPC Stack Cards ueber/bei den Schiffen.
5. Untere Leiste:
   - Boarding Status.
   - Actions.
   - alle Command-/Action-Buttons quadratisch.

## Asset-Regeln
- Flieger und Flightdeck nutzen Projektassets unter `res://Assets/...`.
- Keine SVG-Platzhalter aus der Vorlage als Runtime-Asset.
- Keine absoluten Pfade auf `C:\Users\...` im Projektcode.
- Erlaubte Asset-Familien:
  - `res://Assets/kenney_space-kit/Isometric/platform_large_NW.png`
  - `res://Assets/kenney_space-kit/Isometric/craft_speeder*.png`
  - `res://Assets/kenney_space-kit/Isometric/craft_cargo*.png`
  - vorhandene Blaster-Preview-Assets aus TASK_176

## Datenfluss
- Fireteam-, Loadout-, Boarding- und Transport-State bleiben in den bestehenden Meta-Datenpfaden.
- UI darf Staging-Aktionen ausloesen, aber keine Gameplay-Wahrheit halten.
- Mission-Start-/Dropship-Handoff bleibt kompatibel mit TASK_096, TASK_114 und TASK_176.

## Nicht-Ziele
- Keine neue Waffenmechanik.
- Keine neuen Combat-Werte.
- Keine Dropship-Physik.
- Keine dynamische responsive Layoutlogik.
- Keine Mission-HUD-Aenderungen in diesem Task.
- Keine Homebase-Aenderungen in diesem Task.

## Akzeptanzkriterien
- [x] FOB rendert in einem festen Full-HD-Layout.
- [x] `#14 FLIGHTDECK` ist breiter als im bisherigen FOB und zeigt echte Projekt-Fliegerassets.
- [x] `#13 LOADOUT` ist schmaler und bleibt mit SMG/Medictool bedienbar.
- [x] Untere Action-Buttons sind quadratisch.
- [x] Boarding Status und Actions sitzen unten in festen Fenstern.
- [x] Kein Gameplay-State wird in UI-Callbacks als Wahrheit eingefuehrt.
- [x] Bestehende Loadout-, Recovery- und Dropship-Verifier bleiben gruen.

## Ergebnis
- `FOBTestScreen` wendet den `DropLightLayoutContract` jetzt beim Start auf den FOB-Screen an.
- Die alten Runtime-Datenpfade bleiben erhalten: Fireteams, Loadout, Boarding und Transport-Craft-State werden weiterhin aus den bestehenden Meta-State-Feldern gelesen.
- Die bisherige Available-Operators-Spalte wurde in TASK_314 als festes `#09 NPC POOL` links neben `#10 FIRETEAMS` reaktiviert; `#13 LOADOUT` ist dadurch schmaler, `#14 FLIGHTDECK` bleibt breit.
- `#14` nutzt die vorhandenen Transport-Craft-Karten mit echten `res://Assets/kenney_space-kit/...`-Texturen.
- Eine feste Bottom-Row fuer Boarding Status und Actions wurde als UI-Schicht ergaenzt; Board/Send triggern nur die vorhandenen FOB-Callbacks, halten aber keinen eigenen Gameplay-State.
- Transport-Craft-Actionbuttons und Bottom-Actionbuttons sind quadratisch.

## Erwartete Dateien
- `scenes/meta/fob_test_screen.tscn`
- `scripts/meta/fob_screen.gd`
- `scripts/meta/meta_ui_skin.gd`
- `scripts/meta/transport_craft_card_ui.gd`
- optional `scripts/meta/fob_flightdeck_view.gd`
- optional `scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`
- `docs/tasks/TASK_178_fob_drop_light_fixed_fullhd_layout.md`
- `docs/IMPLEMENTATION_STATUS.md`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_178_fob_drop_light_fixed_fullhd_layout_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_176_fob_loadout_weapon_preview_selector_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_096_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_114_meta_recovery_verifier.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_dropship_mission_flow_verifier.gd`
- [ ] Manueller Godot-Sichtcheck FOB in Full HD.
- [x] `git diff --check`

## Risiken
- Feste Groessen koennen bestehende Scroll-/Drag-Pfade freilegen, die vorher durch dynamische Container kaschiert wurden.
- Breiteres Flightdeck kann alte Panel-Pfade in Verifiern brechen, wenn Nodes umbenannt statt nur neu angeordnet werden.
- Projektassets muessen visuell skaliert werden, ohne neue absolute Pfade oder Mockup-Platzhalter einzufuehren.

## Naechster Schritt
Nach manueller FOB-Sichtpruefung folgt TASK_179 fuer Homebase nach `b_homebase.svg`.

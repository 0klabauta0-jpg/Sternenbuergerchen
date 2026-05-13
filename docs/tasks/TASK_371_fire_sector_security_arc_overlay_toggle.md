# TASK_371 - Fire Sector Security Arc Overlay Toggle

## Ziel
Feuer-/Security-Sektoren sollen als schaltbares Missions-Overlay sichtbar werden, damit Deckungsrichtung, Overwatch und Sector-Security auf der Karte lesbar sind.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review nennt `CombatFireDecisionResolver` als Ort fuer Fire-Sectors. Im aktuellen Code liegen passende Sektorlogik und Visualisierung eher bei `FireteamSecurityController`, `OverwatchController` und `FireteamOrderVisualizer._draw_sector()`. Der Task ist sinnvoll, muss aber diese vorhandenen Pfade wiederverwenden.

## Problem
Spieler sehen nicht zuverlaessig, welche Richtung ein Fireteam gerade sichert oder wo Overwatch wirkt.

## Ursache
Security-/Sector-Daten koennen visualisiert werden, sind aber nicht als klarer, steuerbarer Overlay-Modus im HUD verfuegbar.

## Umfang
- Overlay-Toggle fuer Security-/Fire-Sektoren einbauen.
- Bestehende `security_dicts` und `member_assignments` aus dem FireteamOrderVisualizer nutzen.
- Selected-Fireteam-Filter respektieren.
- In-Sector/Out-of-Sector-Enemy-Hervorhebung nur, wenn Contact/FoW das erlaubt.
- Keine Combat-Hit-Entscheidung in der Darstellung berechnen.

## Akzeptanzkriterien
- [ ] Toggle schaltet Sektor-Overlay an/aus.
- [ ] 360, facing/sector und overwatch-ready werden unterscheidbar dargestellt.
- [ ] Nicht ausgewaehlte Fireteams werden reduziert oder ausgeblendet, ohne Zustand zu verlieren.
- [ ] Overlay respektiert FoW/Contact-Sichtbarkeit.
- [ ] Verifier prueft Render-Snapshot-Zaehler und UI-Truth-Grenze.

## Erwartete Dateien
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_371_fire_sector_security_arc_overlay_toggle.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_371_fire_sector_security_arc_overlay_toggle.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Overlay kann die Karte ueberladen. Der Task soll deshalb Transparenz, Selection-Filter und eine klare Default-Aus-Option pruefen.


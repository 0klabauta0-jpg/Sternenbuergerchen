# TASK_371 - Fire Sector Security Arc Overlay Toggle

## Ziel
Feuer-/Security-Sektoren sollen als schaltbares Missions-Overlay sichtbar werden, damit Deckungsrichtung, Overwatch und Sector-Security auf der Karte lesbar sind.

## Status: IMPLEMENTIERT

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
- [x] Toggle schaltet Sektor-Overlay an/aus.
- [x] 360, facing/sector und overwatch-ready werden unterscheidbar dargestellt.
- [x] Nicht ausgewaehlte Fireteams werden reduziert oder ausgeblendet, ohne Zustand zu verlieren.
- [x] Overlay respektiert FoW/Contact-Sichtbarkeit.
- [x] Verifier prueft Render-Snapshot-Zaehler und UI-Truth-Grenze.

## Umsetzung
- `FireteamOrderVisualizer` besitzt jetzt einen expliziten `security_overlay_enabled`-Toggle und zeichnet Security-Sektoren nur, wenn der Overlay-Modus aktiv ist.
- Der Visualizer liefert `get_security_overlay_snapshot()` mit sichtbaren/selection-gefilterten Sektoren, 360-/Sector-/Overwatch-Counts und dokumentierter Contact/FoW-Policy.
- `mission_tactical_sandbox_controller.gd` synchronisiert den Toggle in den 2D-Visualizer und spiegelt `get_fire_sector_overlay_snapshot()` im Command-Feedback.
- 360-Sektoren werden als Kreis statt als TAU-Polygon gezeichnet, damit die Render-Triangulation stabil bleibt.

## Erwartete Dateien
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_371_fire_sector_security_arc_overlay_toggle.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_371_fire_sector_security_arc_overlay_toggle.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/bugfix_mission_fire_sector_overlay.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Overlay kann die Karte ueberladen. Der Task soll deshalb Transparenz, Selection-Filter und eine klare Default-Aus-Option pruefen.
- Enemy-In-Sector-Hervorhebung bleibt bewusst an Contact/FoW-Sichtbarkeit gebunden und wird nicht als neue Hit-Entscheidung in der Darstellung berechnet.

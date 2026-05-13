# TASK_375 - Waypoint Intent Preview

## Ziel
Geplante, noch nicht ausgefuehrte Waypoints sollen vor dem GO sichtbar machen, wohin der FTL voraussichtlich laeuft und wie lang/risikoreich der Weg ungefaehr ist.

## Status: GEPLANT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, weil Commander-Intent vor Ausfuehrung besser lesbar wird. Das Projekt hat mit `FireteamOrderVisualizer` und Area-Order-Preview bereits passende Visual-Grundlagen.

## Problem
Spieler setzen Wege/Orders, sehen aber vor dem Ausfuehren nicht ausreichend, welche Route, Distanz und Ankunftslogik daraus wird.

## Ursache
Bestehende Preview-Flaechen zeigen Area-/Order-Markierungen, aber keine kompakte ETA-/Intent-Auswertung fuer Waypoints.

## Umfang
- Preview-Payload fuer pending Waypoints erweitern: Ghost-FTL-Position, Richtung, Distanz, ETA-Schaetzung.
- ETA nur als Estimate markieren und aus vorhandenen Movement-/Speed-Werten ableiten.
- Morale-/Fatigue-Warnungen nur anzeigen, wenn dafuer echte Daten vorhanden sind.
- Anzeige vor GO, nicht nach Commit.
- Keine Pathfinding- oder Movement-Entscheidung im Visualizer treffen.

## Akzeptanzkriterien
- [ ] Pending Waypoints zeigen Ghost-Pfad und Richtung.
- [ ] ETA/Distanz wird fuer einfache Waypoint-Ketten angezeigt.
- [ ] Unbekannte Risiken werden nicht als erfundene Moralstrafe dargestellt.
- [ ] Preview verschwindet nach Commit/Cancel korrekt.
- [ ] Headless-Test prueft Preview-Snapshot und keine SimulationRoot-Mutation.

## Erwartete Dateien
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- ggf. `scripts/tactical/waypoint_intent_preview_resolver.gd`
- `scripts/tests/task_375_waypoint_intent_preview.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_375_waypoint_intent_preview.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- ETA kann irrefuehrend sein, wenn Kampfkontakt oder FTL-Ausbrueche eingreifen. Der Task soll diese Zahl klar als Planungsestimate behandeln.


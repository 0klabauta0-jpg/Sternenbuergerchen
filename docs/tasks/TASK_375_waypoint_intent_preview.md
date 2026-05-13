# TASK_375 - Waypoint Intent Preview

## Ziel
Geplante, noch nicht ausgefuehrte Waypoints sollen vor dem GO sichtbar machen, wohin der FTL voraussichtlich laeuft und wie lang/risikoreich der Weg ungefaehr ist.

## Status: IMPLEMENTIERT

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
- [x] Pending Waypoints zeigen Ghost-Pfad und Richtung.
- [x] ETA/Distanz wird fuer einfache Waypoint-Ketten angezeigt.
- [x] Unbekannte Risiken werden nicht als erfundene Moralstrafe dargestellt.
- [x] Preview verschwindet nach Commit/Cancel korrekt.
- [x] Headless-Test prueft Preview-Snapshot und keine SimulationRoot-Mutation.

## Umsetzung
- `WaypointIntentPreviewResolver` baut read-only Preview-Eintraege aus bestehenden Order-Plans, Fireteam-Ankern und Speed-Schaetzungen der Fireteam-Mitglieder.
- `mission_tactical_sandbox_controller.gd` veroeffentlicht die Preview im Command-Feedback und reicht denselben Payload an `FireteamOrderVisualizer` und Primary3D-Order-Payloads weiter.
- `FireteamOrderVisualizer` zeichnet nur den fertigen Payload als Ghost-Pfad, Ghost-FTL-Position, Richtung und kompakte ETA/Distanz-Label. Er trifft keine Pathfinding- oder Movement-Entscheidung.
- Risiko bleibt `unknown`, solange keine echten Moral-/Fatigue-Daten fuer diesen Preview-Kontext existieren.

## Erwartete Dateien
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tactical/waypoint_intent_preview_resolver.gd`
- `scripts/tests/task_375_waypoint_intent_preview.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_375_waypoint_intent_preview.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_315_mission_grid_tile_selection_command_gate.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- ETA kann irrefuehrend sein, wenn Kampfkontakt oder FTL-Ausbrueche eingreifen. Der Task soll diese Zahl klar als Planungsestimate behandeln.

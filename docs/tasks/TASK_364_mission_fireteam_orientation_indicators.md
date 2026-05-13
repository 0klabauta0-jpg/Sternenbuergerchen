# TASK_364 - Mission Fireteam Orientation Indicators

## Ziel
Fireteams sollen in der Mission auf der Mini-/Uebersichtsansicht oder auf den bestehenden Mission-Map-Markern eine kleine Richtungsanzeige bekommen, damit FTL-Facing und Bewegungsrichtung auf einen Blick lesbar sind.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist sinnvoll, aber im aktuellen Projekt gibt es eher `FireteamMiniPanel`, Fireteam-Karten und Map-Visuals als eine isolierte klassische Mini-Map-Komponente. Der Task soll deshalb an die bestehende Missionsuebersicht andocken und keine zweite Kartenwahrheit einfuehren.

## Problem
Fireteam-Positionen sind sichtbar, aber die Blick-/Bewegungsrichtung ist nur indirekt ueber Unit-Visuals, Fire-Events oder Order-Linien erkennbar. Spieler koennen schwer beurteilen, ob ein Fireteam eine Flanke deckt oder nur unterwegs ist.

## Ursache
Die aktuellen HUD-/Map-Snapshots transportieren Fireteam-Anker und Auswahlzustand, aber keinen stabilen, UI-tauglichen `heading_direction` pro Fireteam-Marker.

## Umfang
- Read-only Heading-Snapshot pro Fireteam aus FTL-/Leader-Position, aktueller Bewegung oder Security-Facing ableiten.
- Kleinen Pfeil an vorhandene Fireteam-Uebersichtsmarker anbinden.
- Unbekanntes Facing sauber behandeln: Pfeil ausblenden oder Bewegungsrichtung als Fallback nutzen.
- Pfeilgroesse und Kontrast fuer FullHD und kleine Kartenansicht begrenzen.
- Keine SimulationRoot-Commands, keine Bewegungsentscheidung und keine neue Fireteam-State-Quelle im UI.

## Akzeptanzkriterien
- [x] Fireteam-Marker zeigen eine Richtung, wenn ein valides Facing bekannt ist.
- [x] Auswahl, Teamfarbe und bestehende Marker bleiben lesbar; der Pfeil verdeckt keine Kartenlabels.
- [x] Snapshot/Verifier prueft mindestens zwei Fireteams mit unterschiedlichen Richtungen.
- [x] Wenn kein Facing bekannt ist, bleibt die Anzeige stabil und erzeugt keine Nullvektor-Artefakte.
- [x] UI-Refresh erzeugt keine SimulationRoot-Commands oder Effects.

## Umsetzung
- `mission_tactical_sandbox_controller.gd` liefert einen read-only `get_fireteam_orientation_snapshot()` und erweitert die Fireteam-Anker um `heading_direction`, `heading_angle` und `heading_source`.
- `fireteam_order_visualizer.gd` rendert die Richtungsanzeige direkt an den bestehenden 2D-Fireteam-Markern und filtert fehlende oder leere Heading-Vektoren.
- `terrain_map_3d_view.gd` spiegelt dieselben Orientation-Snapshots im Primary-3D-Renderpfad und meldet `fireteam_orientation_visual_count` fuer Verifier.
- Der neue Verifier prueft Blue/Gold mit unterschiedlichen Richtungen, Invalid-Heading-Filter und dass reine Visual-Refreshes keine `SimulationRoot` Commands oder Effects erzeugen.

## Erwartete Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tactical/visuals/fireteam_order_visualizer.gd`
- ggf. `scripts/ui/mission_fireteam_orientation_marker.gd`
- `scripts/tests/task_364_mission_fireteam_orientation_indicators.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_364_mission_fireteam_orientation_indicators.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Anzeige sitzt jetzt in den bestehenden 2D-/3D-Order-Visuals, nicht in einer separaten Mini-Map-Komponente.
- Heading-Prioritaet ist bewusst Snapshot-basiert: Fireteam-Facing-Metadaten, aktive Movement-/Security-Signale und geplante Zielpunkte bleiben lesende Inputs; UI schreibt keinen Gameplay-Zustand.

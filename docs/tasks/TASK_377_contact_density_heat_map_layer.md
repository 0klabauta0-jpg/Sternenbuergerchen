# TASK_377 - Contact Density Heat Map Layer

## Ziel
Eine optionale Contact-Density-Heatmap soll Regionen mit vielen bekannten oder zuletzt bekannten Kontakten auf der Uebersichtskarte sichtbar machen.

## Status: IMPLEMENTIERT

## Sinnhaftigkeitscheck
Der Review-Punkt ist als spaeterer Awareness-Layer sinnvoll, aber niedriger priorisiert. Wegen Fog of War darf die Heatmap nur bekannte, sichtbare oder freigegebene Last-Known-Kontakte verwenden.

## Problem
Mehrere Kontakte in einem Bereich sind schwer als Schwerpunkt zu erkennen, wenn nur einzelne Marker sichtbar sind.

## Ursache
Contact-Tracker und FoW speichern Contact-Informationen, aggregieren sie aber nicht zu einem UI-Layer.

## Umfang
- Kontaktpositionen aus current/last-known Contact-Snapshots lesen.
- Grid-/Tile-basierte Aggregation mit Update-Intervall statt pro Frame.
- Overlay nur optional oder debug/commander-intel.
- FoW-Regeln strikt respektieren.
- Snapshot-Zaehler fuer Heat-Zellen und Quellen.

## Akzeptanzkriterien
- [x] Heatmap zeigt nur erlaubte Contact-Quellen.
- [x] Aggregation ist bounded und aktualisiert nicht in jedem Frame.
- [x] Toggle schaltet den Layer ohne Kontakt-State-Mutation.
- [x] Mindestens zwei Contact-Cluster werden im Verifier unterscheidbar.
- [x] Keine unsichtbaren Feinde werden durch Heatmap enttarnt.

## Umsetzung
- `ContactDensityOverlay` aggregiert erlaubte Contact-Snapshots in bounded Heat-Zellen. Kontakte werden pro Target dedupliziert und nach World-Cell gebucketed.
- `FogOfWarSystem.filter_contact_density_sources_for_team()` liefert nur sichtbare aktuelle Kontakte plus aufgezeichnete Last-Known-Kontakte und gibt versteckte Kontakte nur als Count aus.
- `TerrainMap3DView` zeichnet den optionalen Heatmap-Layer in einem separaten Root, nutzt ein Update-Intervall statt Frame-Rebuilds und exportiert Source-/Hidden-/Heat-Cell-Zaehler im Render-Snapshot.
- `MissionTacticalSandboxController` reicht einen read-only Toggle an die Primary3D-Order-Payload weiter und meldet den Heatmap-Snapshot im Command-Feedback.

### Visual-Lifecycle-Follow-up 2026-11-03
Ein vollstaendiger Map-/Streaming-Rebuild loescht die abgeleiteten Heatmap-Meshes.
`render_map()` stellt diesen Layer deshalb ueber den bestehenden erzwungenen
Heatmap-Rebuild wieder her, auch wenn die Contact-Signatur gleich geblieben ist.
Contact-State wird dabei nicht mutiert; FoW-Quellenfilter und deaktivierter Layer
bleiben erhalten. Die Regression prueft echte Meshes und deren Sichtbarkeit fuer
Square/Hex statt nur die weiterhin vorhandenen Snapshot-Zaehler.

Nach einem FoW-Delta bleibt die unterdrueckte Heatmap beim getakteten
Contact-Refresh verborgen, solange ihre alten Zellen noch nicht erneut als
zulaessig bestaetigt sind. Sichtbar wird sie erst bei gleicher aktuell erlaubter
Quellsignatur oder nach einer tatsaechlichen Neuberechnung. Das bestehende
Updateintervall bleibt erhalten; ein normaler spaeterer Refresh stellt erlaubte
Current-/Last-Known-Zellen wieder her, ohne alte verborgene Feinde aufzudecken.

## Erwartete Dateien
- `scripts/core/fog_of_war_system.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- ggf. `scripts/tactical/visuals/contact_density_overlay.gd`
- `scripts/tests/task_377_contact_density_heat_map_layer.gd`

## Lokale Pruefung
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_377_contact_density_heat_map_layer.gd`
- [x] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [x] `git diff --check`

## Risiken / offene Punkte
- Die Heatmap kann taktische Spannung aus FoW nehmen. Default sollte aus oder nur fuer passende Intel-Modi sichtbar sein.
- Manueller Sichtcheck bleibt offen, weil Headless nur Snapshot, Toggle, Bounding und FoW-Sanitization bewertet.

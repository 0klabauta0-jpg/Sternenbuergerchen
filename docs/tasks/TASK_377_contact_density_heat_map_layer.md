# TASK_377 - Contact Density Heat Map Layer

## Ziel
Eine optionale Contact-Density-Heatmap soll Regionen mit vielen bekannten oder zuletzt bekannten Kontakten auf der Uebersichtskarte sichtbar machen.

## Status: GEPLANT

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
- [ ] Heatmap zeigt nur erlaubte Contact-Quellen.
- [ ] Aggregation ist bounded und aktualisiert nicht in jedem Frame.
- [ ] Toggle schaltet den Layer ohne Kontakt-State-Mutation.
- [ ] Mindestens zwei Contact-Cluster werden im Verifier unterscheidbar.
- [ ] Keine unsichtbaren Feinde werden durch Heatmap enttarnt.

## Erwartete Dateien
- `scripts/core/fog_of_war_system.gd`
- `scripts/terrain/terrain_map_3d_view.gd`
- ggf. `scripts/tactical/visuals/contact_density_overlay.gd`
- `scripts/tests/task_377_contact_density_heat_map_layer.gd`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_377_contact_density_heat_map_layer.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
- Die Heatmap kann taktische Spannung aus FoW nehmen. Default sollte aus oder nur fuer passende Intel-Modi sichtbar sein.


# TASK_635 - Frontier Probe Callout Sight Findings

## Ziel / Problem
Der echte TASK_634-Fensterlauf hat einen konkreten Sichtbefund geliefert: Die Route-Callouts sind technisch vorhanden und LZ/CARGO sind getrennt, wirken im echten Missionsbild aber zu leise. Das zentrale Mission-Result-Label konkurriert mit den Callouts und die Route ist ohne zusaetzliche Verbindungslinie schwer als Ablauf zu lesen.

## Sinnhaftigkeit / Ursache
Headless- und Snapshot-Gates konnten nur beweisen, dass Marker und Labeldaten existieren. Das reale FullHD-Bild zeigt die naechste Ebene: Lesbarkeit, visuelle Prioritaet und Konflikte mit anderen Statuslabels.

## Umfang
- Route-Callout-Labels im Primary3D-Visualpfad kontrastreicher, groesser und hoeher rendern.
- Route-Beats mit einer dezenten Verbindungslinie verbinden.
- Mission-Result-Label bei aktiven Route-Callouts vom Callout-Schwerpunkt wegsetzen und kleiner halten.
- Render-Snapshot um Style-/Linien-Felder ergaenzen.
- Reports und Verifier auf TASK_635 fortschreiben.

## Nicht-Ziele
- Keine neue Gameplay-Route oder Missionslogik.
- Keine Objective-, Cargo-, Command-, Movement-, Combat- oder Multiplayer-Mutation.
- Kein kompletter HUD-Redesign-Slice.
- Kein automatischer Ersatz fuer den naechsten menschlichen Spielgefuehltest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_634_frontier_probe_real_f6_callout_sight_review.md`
- `scripts/terrain/terrain_map_3d_view.gd`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `TerrainMap3DView` exportiert `route_callout_label_visual_style_id = task_635_high_contrast_route_callouts`.
- Alle Route-Callout-Eintraege melden groessere Label-Metadaten: Font >= 18, Outline >= 7, Label-Hoehe >= 2.2.
- Mindestens drei Route-Verbindungslinien werden im Primary3D-Snapshot gezaehlt.
- LZ/CARGO bleiben am gleichen Marker und ihre Labels bleiben getrennt.
- Das Mission-Result-Label weicht aus, sobald Route-Callouts aktiv sind.
- Der Verifier schreibt ein read-only Manifest unter `tmp/frontier_probe_callout_sight_findings.json`.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_635_frontier_probe_callout_sight_findings.gd`
- `docs/tasks/TASK_635_frontier_probe_callout_sight_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_635_frontier_probe_callout_sight_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_634_frontier_probe_real_f6_callout_sight_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_633_frontier_probe_callout_layout_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_635 behebt den belegten Callout-Sichtbefund, ersetzt aber keinen laengeren echten Playtest.
- Wenn der naechste echte Fensterblick zeigt, dass Linien zu laut sind oder das HUD weiter stoert, sollte ein weiterer kleiner Findings-Slice folgen statt ein breiter UI-Umbau.

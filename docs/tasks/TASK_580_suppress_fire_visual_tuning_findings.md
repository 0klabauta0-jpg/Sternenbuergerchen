# TASK_580 - Suppress Fire Visual Tuning Findings

## Ziel / Problem
TASK_578 macht die `SUP AREA`-Preview technisch sichtbar und TASK_579 stellt den manuellen F6-Sichtreview bereit. Die aktuelle lokale Evidence unter `tmp/suppress_fire_visual_evidence.png` zeigt aber einen belegbaren Lesbarkeitsfund: Die Suppress-Area geht im dichten Iso-Raster und im hellen Stations-Set leicht unter.

## Sinnhaftigkeit / Ursache
Die Area ist nur als transparente Flaeche gezeichnet. Auf grauen/hellen Bodenplatten und zwischen Pfad, Ghost, Raster und HUD ist sie als eigenstaendiger Zielbereich zu schwach unterscheidbar. Der Spieler soll vor `GO` erkennen, dass `SUP` nicht nur eine Fire-Rule, sondern eine Zielbereichsentscheidung ist.

## Umfang
- `suppress_area_v1` visuell auf `suppress_area_v2` tunen.
- Fuellebene etwas klarer, aber weiter transparent halten.
- Zusaetzliche read-only Ring-/Achsenmarkierung und Boundary-Ticks fuer den Suppress-Bereich im Preview-Overlay-Hoehenbereich rendern.
- Render-Snapshot um Tuning-Metadaten erweitern, damit die Lesbarkeit maschinell pruefbar bleibt.
- HTML-Zwischenbericht, Contract, Roadmap und Status aktualisieren.

## Nicht-Ziele
- Keine echte Suppression-Wirkung.
- Kein Ammo-Verbrauch.
- Kein Combat-/Movement-Commit.
- Keine Aenderung an ThreatAnalyzer, Movement oder Fire-Rule-Semantik.
- Kein automatischer Abschluss des menschlichen Sichtreviews.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_579_suppress_fire_manual_f6_review.md`
- `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Primary3D meldet weiterhin genau eine Suppress-Area fuer die SUP-Move-Preview.
- Die Area-Entry meldet `visual_key = suppress_area_v2`.
- Die Area-Entry meldet `outline_visible = true`, `axis_line_count >= 2`, `boundary_marker_count >= 4`, `fill_alpha`, `outline_alpha` und Overlay-Hoehenwerte.
- Die Preview bleibt read-only und mutiert keine Command-Queue.
- TASK_578/TASK_579 bleiben gruen oder werden auf die neue Visual-ID kompatibel aktualisiert.
- Der HTML-Zwischenbericht nennt TASK_580 als erledigten Tuning-Slice und einen sinnvollen naechsten Anschluss.

## Betroffene Dateien
- `scripts/terrain/terrain_map_3d_view.gd`
- `scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`
- `scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`
- `docs/tasks/TASK_580_suppress_fire_visual_tuning_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_579_suppress_fire_manual_f6_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der visuelle Tuning-Slice verbessert Lesbarkeit, ersetzt aber keinen finalen menschlichen Playtest.
- Echte Suppression-Wirkung, Ammo-Verbrauch und AAR-Messwerte bleiben Folgearbeit.
- Wenn der Bereich spaeter zu dominant wirkt, sollte der naechste Slice nur Alpha/Outline-Staerke weiter kalibrieren.

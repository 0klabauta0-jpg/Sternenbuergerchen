# TASK_577 - Suppress Fire Visual Evidence Pass

## Ziel / Problem
TASK_576 macht `SUP` vor `GO` als `SUP AREA`-Preview lesbar. Es fehlt noch ein reproduzierbarer F6-/Visual-Beleg, der zeigt, ob Ghost, Pfad, Risikozeile und Suppress-Text zusammen im Missionsbild ankommen.

## Sinnhaftigkeit / Ursache
Der laufende HTML-Zwischenbericht soll nicht nur Chat-Notizen sammeln, sondern konkrete lokale Evidence nennen. Fuer `SUP` ist das besonders wichtig, weil es weiterhin nur ein Fire-Rule-/Preview-Zustand ist und nicht versehentlich als fertiges Suppression-/Ammo-System verstanden werden darf.

## Umfang
- Capture-Smoke fuer den bestehenden Frontier-Probe-Missionspfad.
- Lokale Artefakte unter `tmp/suppress_fire_visual_evidence.png` und `tmp/suppress_fire_visual_evidence.json`.
- Manifest mit SUP-Preview-Gate, Read-only-Grenze, Viewport-Readback-/Evidence-Board-Status und Primary3D-Preview-Zaehlern.
- HTML-Zwischenbericht auf TASK_577 aktualisieren.

## Nicht-Ziele
- Kein neues Suppression-, Ammo- oder AAR-System.
- Keine neue Combat-/Movement-Wahrheit im HUD.
- Kein GO-Commit im Capture.
- Kein grosses Redesign des Missions-HUD.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_576_suppress_fire_preview_readability_spike.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Capture-Smoke erzeugt PNG und JSON-Manifest.
- Das Manifest meldet `capture_type = suppress_fire_visual_evidence`, `read_only = true` und `ui_sets_gameplay_truth = false`.
- TASK_576-SUP-Preview-Gate bleibt gruen.
- Primary3D meldet vor `GO` mindestens Pfad/Ghost-Preview-Zaehler.
- Der HTML-Zwischenbericht nennt die neuen Artefaktpfade und den naechsten Follow-up.

## Betroffene Dateien
- `scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd`
- `docs/tasks/TASK_577_suppress_fire_visual_evidence_pass.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --path . --script scripts/tests/task_577_suppress_fire_visual_evidence_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_576_suppress_fire_preview_readability_spike.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_575_fire_rule_evidence_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Capture ersetzt keinen finalen menschlichen Spielgefuehl-Test.
- Falls der Lauf headless erfolgt, ist das PNG ein markiertes Evidence-Board, kein echter F6-Screenshot.
- Echte Suppression-Wirkung, Munitionsverbrauch und AAR-Messwerte bleiben Folgearbeit.

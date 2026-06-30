# TASK_689 - Mission Interaction Visual Polish Findings

## Ziel / Problem
TASK_688 schreibt FullHD-Evidence, aber daraus entsteht noch keine klare maschinenlesbare Bewertung: Ist das Visualbudget konservativ, fehlen Visuals, ist ein echter Sichtlauf offen, und was ist der naechste konkrete Polish-Schritt?

## Sinnhaftigkeit / Ursache
Damit das Spiel angenehmer und schicker wird, brauchen wir nicht nur Artefakte, sondern eine kleine Entscheidungsgrundlage. TASK_689 fasst Render-Snapshot und Evidence in Polish-Findings zusammen, ohne daraus Gameplay-Wahrheit zu machen.

## Umfang
- Neuer Service `MissionInteractionVisualPolishFindings`.
- Verifier `task_689_mission_interaction_visual_polish_findings.gd`.
- Bewertung von Visualstate-, Object-Reaction-, Route-Callout- und Visualbudget-Zaehlern.
- Trennung von Blockern, Warnungen und manuellen Sichtentscheid-Hinweisen.
- JSON-Manifest unter `tmp/`.
- Doku, Roadmap, Status und HTML-Handbuch fortschreiben.

## Nicht-Ziele
- Kein automatischer visueller Freispruch.
- Kein echter menschlicher FullHD-Sichtentscheid.
- Kein Door-/Asset-Swap.
- Kein Gameplay-State-Commit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_688_mission_interaction_fullhd_evidence.md`
- `docs/tasks/TASK_687_mission_interaction_object_reaction.md`

## Akzeptanzkriterien
- Snapshot nennt Schema, `read_only = true` und `ui_sets_gameplay_truth = false`.
- Fehlende Visualstate-/Object-Reaction-Eintraege werden als Blocker gewertet.
- Visualbudget ueber Limit wird als Blocker gewertet.
- Offener menschlicher Sichtentscheid wird als manueller Hinweis, nicht als technischer Blocker, gewertet.
- Manifest nennt `blocking_issue_count`, `warning_count`, `manual_review_open` und `recommended_next_task`.

## Betroffene Dateien
- `scripts/mission/mission_interaction_visual_polish_findings.gd`
- `scripts/tests/task_689_mission_interaction_visual_polish_findings.gd`
- `docs/tasks/TASK_689_mission_interaction_visual_polish_findings.md`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_689_mission_interaction_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_688_mission_interaction_fullhd_evidence.gd`
- `git diff --check`

## Risiken / offene Punkte
- Die Findings beweisen nur die technische Lesbarkeitsstruktur. Echte visuelle Abnahme braucht weiterhin einen menschlichen Fensterlauf.

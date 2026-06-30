# TASK_631 - Frontier Probe Mini Scenario Visual Feel Polish

## Ziel / Problem
TASK_630 macht die Frontier-Probe-Mini-Mission als Route pruefbar, aber die Route ist noch zu stark ein Daten-/Verifier-Artefakt. Der Spieler soll vor dem eigentlichen Balancing sehen, wo LZ, AA-Bedrohung, Computer-Hold und Cargo-Touch-and-Go im Szenario liegen.

## Sinnhaftigkeit / Ursache
Die Mini-Mission soll sich als kleine spielbare Idee lesen: landen, AA ausschalten, Computer halten, Cargo anlanden lassen und wieder weg. Wenn diese Beats nur im Manifest stehen, bleibt unklar, ob Map, HUD und Mission Control dieselbe Geschichte vermitteln.

## Umfang
- Read-only Visual-/Feel-Snapshot fuer die TASK_630-Route.
- Kompakte Route-Callouts fuer LZ, AA, Computer-Hold und Cargo.
- Stabiler Status-/Legendensatz fuer Visual- und Report-Artefakte.
- Kleiner Verifier, der Callouts, Labels, Tones, Mission-Control-Zusammenfassung und Read-only-Grenzen prueft.
- Dokumentations-/Report-Status aktualisieren.

## Nicht-Ziele
- Kein neuer Missionssystem- oder Objective-Rewrite.
- Kein neues Gameplay-State-Ownership im HUD.
- Kein Balancing der AA-/Cargo-/Computerzeiten.
- Kein echter manueller Sichttest; dieser Task bereitet dafuer lesbare Evidence vor.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_630_frontier_probe_mini_scenario_feel_route.md`

## Akzeptanzkriterien
- Die vier Mini-Szenario-Beats haben stabile Callouts mit Zielmarker, Kurzlabel, Ton/Farbe und Spielabsicht.
- Die Callouts bleiben read-only und setzen keine Gameplay-Wahrheit.
- Mission Control bekommt eine kompakte route-readable Zusammenfassung.
- Der Verifier reproduziert die Callouts auf der Frontier-Probe-Map und schreibt ein Evidence-Manifest.
- Bestehende TASK_630-Route bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_631_frontier_probe_mini_scenario_visual_feel_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_631_frontier_probe_mini_scenario_visual_feel_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_630_frontier_probe_mini_scenario_feel_route.gd`
- `git diff --check`

## Risiken / offene Punkte
- Das ist noch kein finaler F6-Playtest. Ein echter Sichtlauf muss danach entscheiden, ob die Callouts wirklich angenehm wirken oder ob Layout-/Farbpolish noetig ist.

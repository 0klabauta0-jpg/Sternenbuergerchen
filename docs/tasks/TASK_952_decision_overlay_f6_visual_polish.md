# TASK_952 - Decision Overlay F6 Visual Polish

## Ziel / Problem
TASK_951 macht die Decision-Preview sprachlich lesbar. Fuer den naechsten echten F6-Sichtcheck fehlt aber noch ein klarer Visual-Polish-Vertrag: Welche Segmente sollen wie gewichtet, gefaerbt und als kompakte HUD-Information gelesen werden?

## Sinnhaftigkeit / Ursache
Die Preview soll nicht als weiterer Textblock im Mission-Control-Fenster versanden. Der Spieler braucht drei ruhige, sofort unterscheidbare Signale: sicher, riskant, Killzone. Gleichzeitig darf der HUD-Pfad keine UI-Baeume rebuilden oder Gameplay-State besitzen.

## Umfang
- TASK_951-Review-Daten werden in drei kompakte Badge-Segmente normalisiert.
- Badge-Reihenfolge: safe, risky, suicidal.
- Farbrollen: green, yellow, red.
- Layout-Vertrag: kompakt, eine Mission-Control-Zeile, kein UI-Tree-Rebuild.
- Command Feedback exportiert den TASK_952-Polish-Snapshot.

## Nicht-Ziele
- Kein neues HUD-Panel.
- Keine manuelle Screenshot-Abnahme.
- Kein Command-, Movement-, Fire-, Damage- oder Multiplayer-State.
- Kein neues Combat- oder Pathfinding-System.

## Relevante Contracts / Dokumente
- `docs/dev/tactical_decision_clarity_contract.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_951_decision_overlay_real_f6_visual_review.md`

## Akzeptanzkriterien
- `get_decision_overlay_f6_visual_polish_snapshot()` liefert drei kompakte Badges.
- Badges sind stabil geordnet: safe/green, risky/yellow, suicidal/red.
- Labels und Microcopy enthalten keine rohen Choice-IDs.
- Layout bleibt `compact`, eine Zeile, kein UI-Tree-Rebuild.
- Snapshot bleibt read-only und markiert weiter `manual_review_required`.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_952_decision_overlay_f6_visual_polish.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_952_decision_overlay_f6_visual_polish.gd`
- `godot_console.exe --headless --path . --script res://scripts/tests/task_951_decision_overlay_real_f6_visual_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_952 beschreibt und prueft den Visual-Polish-Vertrag automatisiert. Der echte Fensterbeweis bleibt Folgearbeit: Position, Kontrast und Rhythmus muessen in einem Real-Window-Recapture beurteilt werden.

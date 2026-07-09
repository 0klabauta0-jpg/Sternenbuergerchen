# TASK_1010 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Player Feel Polish

## Ziel / Problem
TASK_1009 benennt Player-Feel-Reibung oder akzeptierten Spielerblick, liefert aber noch keine konsumierbare Leseschicht fuer HUD, Command Feedback und naechsten Griff. TASK_1010 uebersetzt diese Findings in klare, kurze Surface-Specs fuer `START`, `ROUND/NEXT/GO`, Feedback, GO-Grenze, HUD-Ruhe und Multiplayer-Grenze.

## Sinnhaftigkeit / Ursache
Der Release-Loop soll sich nicht nur technisch korrekt, sondern wie ein kleines rundes Spiel anfuehlen: Start verstehen, Runde lesen, naechsten Griff sehen, `GO` bewusst ausloesen, Feedback bekommen und wieder bei `NEXT` landen. Dafuer braucht die UI stabile, menschenlesbare Texte und Rollen, ohne selbst Gameplay-Wahrheit zu fuehren.

## Umfang
- Neuer read-only Player-Feel-Polish-Service fuer TASK_1010.
- Bewertung eines polishbaren TASK_1009-Findings-Snapshots.
- Sechs Surface-Specs:
  - Entry/Start
  - Round-/Next-/GO-Rhythmus
  - Feedback -> naechster Griff
  - GO-Grenze
  - ruhige HUD-Fuehrung
  - Multiplayer-/Wahrheitsgrenze
- Kompakte `FEEL | NEXT | GO`-Zeile.
- `next_grip_line`, `go_boundary_microcopy`, `calm_hud_guidance` und Performance-Hinweis.
- Export im `MissionTacticalSandboxController` und Command-Feedback.

## Nicht-Ziele
- Kein neuer Button-Tree.
- Kein Screenshot.
- Kein Combat-, Movement-, Dropship- oder Multiplayer-Resolver.
- Keine Gameplay-Mutation im Snapshot.
- Kein per-frame UI-Rebuild.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_1009_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Akzeptanzkriterien
- TASK_1010 blockiert ehrlich, wenn TASK_1009 nicht polishbar oder nicht read-only ist.
- Rework-Findings erzeugen sechs konkrete Player-Feel-Surface-Specs.
- Akzeptierte Findings erzeugen weiterhin eine ruhige Acceptance-ready Leseschicht.
- Die Polish-Zeile benennt `FEEL`, `NEXT` und `GO`.
- `GO` bleibt als separate Ausfuehrungsgrenze lesbar.
- Der Controller exportiert TASK_1010 im Command-Feedback.
- Der naechste Follow-up ist `TASK_1011 - Release First Decision Loop Two Player Loop Micro Objective Round Loop Acceptance Slice`.

## Betroffene Dateien
- `scripts/mission/release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.gd`
- `scripts/tests/task_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/tactical_decision_clarity_contract.md`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script res://scripts/tests/task_1010_release_first_decision_loop_two_player_loop_micro_objective_round_loop_player_feel_polish.gd`
- Regression: TASK_1009, TASK_1008, TASK_1007
- `git diff --check`

## Risiken / offene Punkte
TASK_1010 erzeugt noch keine echten neuen Controls. Er macht aber den naechsten Schritt greifbar: TASK_1011 kann daraus den Round-Loop als Acceptance-Slice gegen die sichtbaren Runtime-Flaechen bewerten.

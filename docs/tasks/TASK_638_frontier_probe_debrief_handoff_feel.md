# TASK_638 - Frontier Probe Debrief Handoff Feel

## Ziel / Problem
TASK_637 zeigt nach abgeschlossener Frontier-Probe-Route `NEXT Debrief | Ergebnis pruefen | Homebase`. Der Spielmoment endet damit aber noch etwas weich: Der Spieler soll am Missions-HUD klar erkennen, dass die taktische Route fertig ist, der Debrief der naechste Review-Ort ist und danach die Rueckkehr zur Homebase folgt.

## Sinnhaftigkeit / Ursache
Die eigentliche Meta-Bruecke vom Debrief zur Homebase existiert bereits seit TASK_586. Was fehlt, ist die lokale Missionslesbarkeit am Ende der Frontier-Probe-Route. Ohne diese Handoff-Zeile fuehlt sich der Missionsabschluss eher wie ein weiterer Status an statt wie ein sauberer Loop-Uebergang.

## Umfang
- Einen read-only Frontier-Probe-Debrief-Handoff-Snapshot im Mission-Controller ergaenzen.
- #18 Mission Control bei abgeschlossenem Frontier-Probe-Endzustand um eine kompakte `HANDOFF ...`-Zeile erweitern.
- Den Handoff ausschliesslich aus dem TASK_637-Next-Interaction-Snapshot ableiten.
- `get_command_feedback_snapshot()` um dieselben Handoff-Daten erweitern.
- Reports, Roadmap, Contract und Verifier auf TASK_638 fortschreiben.

## Nicht-Ziele
- Kein neuer Debrief-Button im Missions-HUD.
- Kein automatischer Szenenwechsel in den Meta-Debrief.
- Kein Umbau von `MetaLayerFlow`, `DebriefTestScreen`, XP, AAR oder Homebase-Progression.
- Keine neue Objective-, Cargo-, Combat-, Movement-, Peer- oder Gameplay-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md`
- `docs/tasks/TASK_586_debrief_return_homebase_handoff.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `get_frontier_probe_debrief_handoff_feel_snapshot()` liefert `schema = sternenbuergerchen.frontier_probe_debrief_handoff_feel.v1`.
- Der Snapshot erkennt den TASK_637-Endzustand `open_debrief` als `handoff_ready = true`.
- #18 Mission Control enthaelt eine kompakte `HANDOFF Debrief bereit | danach Homebase`-Zeile.
- `get_command_feedback_snapshot()` exportiert dieselbe Handoff-Zeile read-only.
- Die Handoff-Kette enthaelt mindestens `mission_complete`, `debrief_review`, `return_homebase`.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_638_frontier_probe_debrief_handoff_feel.gd`
- `docs/tasks/TASK_638_frontier_probe_debrief_handoff_feel.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_638_frontier_probe_debrief_handoff_feel.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_637_frontier_probe_playfeel_next_interaction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_638 ist der Missions-HUD-Handoff-Hinweis, nicht der echte Meta-Debrief-Klicklauf.
- Wenn die zusaetzliche Handoff-Zeile im FullHD-HUD zu dicht wirkt, braucht es einen belegten UI-Dichte-Follow-up.
- Der naechste sinnvolle Schritt ist `TASK_639 - Frontier Probe Meta Debrief Route Smoke`, wenn der echte Meta-Debrief-Lauf mit Frontier-Probe-Resultat geprueft werden soll.

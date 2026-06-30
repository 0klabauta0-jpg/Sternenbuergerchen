# TASK_637 - Frontier Probe Playfeel Next Interaction

## Ziel / Problem
Nach TASK_636 ist die Frontier-Probe-Route als Callout-/Re-Capture-Paket sichtbar. Was fuer den Spielkomfort noch fehlt: #18 Mission Control soll knapp sagen, was der naechste sinnvolle Schritt ist, damit der Spieler nach AA, Computer, Cargo oder Missionsabschluss nicht im HUD suchen muss.

## Sinnhaftigkeit / Ursache
Die Route ist jetzt lesbarer, aber Lesbarkeit allein reicht nicht. Ein taktischer Flow fuehlt sich erst gut an, wenn der naechste erlaubte Schritt nach jedem Zustandswechsel eindeutig ist. Der Contract sagt bereits, dass #18 Mission Control die naechsten erlaubten Schritte anzeigen soll.

## Umfang
- Einen read-only Next-Interaction-Snapshot fuer Frontier Probe ergaenzen.
- #18 Mission Control um eine kompakte `NEXT ...`-Zeile erweitern.
- Die Ableitung ausschliesslich aus Scenario-Gates und CargoBridge-Snapshots lesen.
- Tests fuer AA offen, Computer-Hold, Cargo-Sicherung und Debrief-Endzustand anlegen.
- Reports, Roadmap und Contract auf TASK_637 fortschreiben.

## Nicht-Ziele
- Kein neuer Button und kein neuer Command.
- Kein Debrief-Handoff-Umbau.
- Keine neue Objective-, Cargo-, Movement-, Combat-, Peer- oder Gameplay-Wahrheit.
- Kein weiterer Callout-Visual-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_636_frontier_probe_real_f6_recapture.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- `get_frontier_probe_playfeel_next_interaction_snapshot()` liefert `schema = sternenbuergerchen.frontier_probe_playfeel_next_interaction.v1`.
- In der Frontier-Probe-Route erscheinen diese Next-States: `disable_air_defense`, `hold_station_computer`, `secure_cargo_touchdown`, `open_debrief`.
- #18 Mission Control enthaelt die kompakte `NEXT ...`-Zeile.
- `get_command_feedback_snapshot()` exportiert dieselbe Next-Interaction-Zeile read-only.
- Der Endzustand `open_debrief` setzt keine Navigation, sondern zeigt nur `NEXT Debrief | Ergebnis pruefen | Homebase`.
- `read_only = true` und `ui_sets_gameplay_truth = false` bleiben gesetzt.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_637_frontier_probe_playfeel_next_interaction.gd`
- `docs/tasks/TASK_637_frontier_probe_playfeel_next_interaction.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_637_frontier_probe_playfeel_next_interaction.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_636_frontier_probe_real_f6_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_637 macht nur die naechste Interaktion sichtbar. Der eigentliche Debrief-/Homebase-Handoff bleibt ein Folge-Slice.
- Wenn die Zeile im echten FullHD-Blick zu viel Dichte erzeugt, sollte das als belegter HUD-Polish-Fund nachgezogen werden.

# TASK_743 - Station Scenario Debrief Handoff Cue

## Ziel / Problem
Nach dem Cargo-Ende muss der kleine Stationsdrill klar zum Debrief und danach zur Homebase fuehren. TASK_742 poliert die Cargo-Endgame-Sprache, aber der Station-spezifische Abschluss ist noch nicht als eigener read-only Handoff-Snapshot abgesichert.

## Sinnhaftigkeit / Ursache
Der aeltere Frontier-Probe-Pfad kennt bereits einen Debrief-/Homebase-Handoff. Der aktuelle Station-Drill nutzt aber die neuere Route `AA > DOOR > COM > CARGO` samt Identity-Body und Route-Cue. Damit der Spielerpfad angenehm bleibt, braucht dieser Pfad einen eigenen Abschlussanker statt nur generischer Done-/Route-Texte.

## Umfang
- Station-Route-Endzustand als read-only Handoff-Snapshot zusammenfassen.
- Sichtbare Abschluss-Cue `CUE DONE: Cargo weg | Debrief` mit `HANDOFF Debrief bereit | danach Homebase` verbinden.
- Mission-Control-/Command-Feedback-Snapshot mit Station-Handoff-Feldern ergaenzen.
- Bestehende Route-/Cargo-Cues nicht ersetzen.

## Nicht-Ziele
- Kein neuer Debrief-Screen.
- Keine Navigation aus der Mission in den Debrief ausloesen.
- Keine MissionResult-, XP-, Skill- oder Homebase-Wahrheit schreiben.
- Kein Ersatz fuer den echten TASK_727-Fensterlauf.

## Relevante Contracts / Dokumente
- `docs/dev/mission_interaction_point_contract.md`
- `docs/tasks/TASK_742_station_scenario_cargo_endgame_cue_polish.md`
- `docs/tasks/TASK_727_station_scenario_f6_host_client_playtest_notes.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Akzeptanzkriterien
- Fertige Station-Route meldet `handoff_ready = true`.
- Handoff-Kette nennt Mission fertig, Debrief pruefen und Homebase-Rueckkehr.
- Mission Control enthaelt die Handoff-Zeile, ohne Navigation oder Commands zu erzeugen.
- Command-Feedback exportiert Station-Handoff-Snapshot und -Line.
- Snapshot bleibt `read_only = true` und `ui_sets_gameplay_truth = false`.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_743_station_scenario_debrief_handoff_cue.gd`
- `docs/dev/mission_interaction_point_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_current_state_handbook_2026_07_01.html`

## Lokale Pruefung
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_743_station_scenario_debrief_handoff_cue.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_742_station_scenario_cargo_endgame_cue_polish.gd`
- [ ] `godot_console.exe --headless --path . --script scripts/tests/task_638_frontier_probe_debrief_handoff_feel.gd`
- [ ] `git diff --check`

## Risiken / offene Punkte
TASK_743 macht den Abschluss lesbarer und pruefbar, ersetzt aber keine echte Debrief-Navigation und keine menschliche Sichtabnahme. Der naechste echte Spielgefuehl-Schritt bleibt ein TASK_727-Export oder ein daraus folgender sichtbarer Polish.

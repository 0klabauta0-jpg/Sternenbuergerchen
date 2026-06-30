# TASK_641 - Frontier Probe Homebase Next Sortie Readiness

## Ziel / Problem
TASK_640 zeigt nach dem Debrief-Return eine kompakte Homebase-Ergebniszeile. Der Spieler soll danach aber nicht im normalen Homebase-Zustand stehen bleiben, sondern sofort lesen koennen, welche Vorbereitung fuer die naechste Sortie als naechstes dran ist.

## Sinnhaftigkeit / Ursache
Der Core Loop ist nur dann angenehm, wenn Mission -> Debrief -> Homebase -> naechster Start nicht wie ein harter Zustandswechsel wirkt. Die vorhandenen Readiness- und Staging-Snapshots kennen bereits Briefing, Fireteam, Loadout, Dropship und Start-Blocker. TASK_641 fuehrt diese Daten read-only zusammen und macht daraus eine kleine Next-Sortie-Zeile.

## Umfang
- `HomebaseTestScreen` bekommt `get_frontier_probe_homebase_next_sortie_readiness_snapshot()`.
- Die Homebase zeigt nach Frontier-Probe-Debrief-Return eine kompakte `Next sortie: ... | now: ...`-Zeile.
- Die Zeile liest TASK_640-Summary, Pre-Mission-Readiness und Homebase-Direct-Staging.
- Verifier, Contract, Status, Roadmap und HTML-Berichte werden auf TASK_641 fortgeschrieben.

## Nicht-Ziele
- Keine neue Homebase-Navigation.
- Keine neue Startlogik und kein automatisches Mission-Starten.
- Keine neue Progression-/XP-Berechnung.
- Keine zweite Readiness-Wahrheit in der UI.
- Kein groesserer Homebase-Layoutumbau.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_640_frontier_probe_post_debrief_homebase_readability.md`
- `docs/tasks/TASK_534_pre_mission_readiness_checklist.md`
- `docs/tasks/TASK_594_post_mission_skill_delta_homebase_bridge.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Akzeptanzkriterien
- Der Snapshot liefert `schema = sternenbuergerchen.frontier_probe_homebase_next_sortie_readiness.v1`.
- `post_debrief_summary_gate = pass`, `frontier_probe_result_present = true` und `mission_result_preserved = true`.
- `readiness_steps` enthaelt `review_roster_gains`, `stage_fireteam`, `assign_loadout`, `prepare_transport` und `start_next_sortie`.
- Bei vorhandenem `progression_award_summary` ist `current_next_step_id = review_roster_gains`.
- Die sichtbare Zeile beginnt mit `Next sortie:` und stimmt mit dem Snapshot ueberein.
- `read_only = true`, `ui_sets_gameplay_truth = false`, `creates_navigation = false`, `creates_command = false`.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- `docs/tasks/TASK_641_frontier_probe_homebase_next_sortie_readiness.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_641_frontier_probe_homebase_next_sortie_readiness.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_640_frontier_probe_post_debrief_homebase_readability.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_586_debrief_return_homebase_handoff.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_641 macht den naechsten Homebase-Schritt lesbarer, ersetzt aber keinen echten sichtbaren Homebase-Fensterblick.
- Die Zeile ist bewusst read-only. Wenn spaeter echte Fuehrung per Button/Highlight gebraucht wird, sollte das ein eigener kleiner UI-Task werden.
- Naechster sinnvoller Schritt: `TASK_642 - Frontier Probe Homebase Visible Readiness Review`, wenn der echte Homebase-Blick nach TASK_641 visuell bewertet werden soll.

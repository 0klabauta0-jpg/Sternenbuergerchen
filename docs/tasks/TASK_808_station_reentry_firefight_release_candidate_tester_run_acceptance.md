# TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance

## Ziel / Problem
TASK_807 kann den echten Tester-Run auswerten, aber der Release-Candidate braucht noch eine enge Entscheidung: Ist dieser Lauf akzeptiert, oder muessen fehlende Checks, aktive Issues oder stale Release-Kontexte gezielt zurueck in Polish?

## Sinnhaftigkeit / Ursache
Nach dem Singleplayer-Startblocker reicht ein gruenes Export-/Handoff-Paket nicht. Der naechste Schritt muss festhalten, ob der Spielerpfad von frischer EXE ueber Einzelspieler/Homebase, Dropship, Missionstart, Host/Client, erste Preview, GO/Firefight und Exit/Debrief wirklich als Release-Candidate-Testlauf akzeptiert ist.

## Umfang
- Read-only Acceptance-Snapshot ueber TASK_807.
- Gates fuer Tester-Run-ready, bewusst abgeschlossen, reviewed, frische EXE, keine fehlenden Checks, keine aktiven Issues, Release-Kontext, Host/Client-Rollen, Kommandos und read-only-Grenzen.
- Routing zurueck zu TASK_807 bei offenem, unvollstaendigem oder polish-beduerftigem Tester-Run.
- Routing zu TASK_809 als naechstem echten Playability-/Polish-Backlog, wenn TASK_808 akzeptiert.

## Nicht-Ziele
- Kein automatisches Starten der EXE.
- Kein Screenshot-Parser und keine visuelle Schoenheitsbewertung.
- Keine neuen Gameplay-, UI-, Netzwerk- oder Multiplayer-Wahrheiten.
- Kein grosses neues Missionssystem und kein Combat-Rewrite.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_807_station_reentry_firefight_release_candidate_tester_run.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_807-Quelle blockiert.
- Offener Tester-Run routet zu TASK_807 zurueck.
- Unvollstaendige Checks erhalten konkrete `source_missing_check_ids`.
- Aktive Issues routen auf das erste konkrete Action Item.
- Ein sauberer Tester-Run setzt `accepted_for_release_candidate_tester_run = true`.
- Akzeptierter Snapshot empfiehlt `TASK_809 - Station Reentry Release Candidate Playability Polish Backlog`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_tester_run_acceptance.gd`
- `scripts/tests/task_808_station_reentry_firefight_release_candidate_tester_run_acceptance.gd`
- `docs/tasks/TASK_808_station_reentry_firefight_release_candidate_tester_run_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_808_station_reentry_firefight_release_candidate_tester_run_acceptance.gd`
- Regressionen TASK_807 und Singleplayer-Release-Start-Bootstrap
- `git diff --check`

## Risiken / offene Punkte
- TASK_808 akzeptiert Gate-Daten und Tester-Notizen; er ersetzt keinen neuen sichtbaren Playtest.
- TASK_809 muss danach die tatsaechlich beobachteten Reibungen in spielbaren, sichtbaren Polish umsetzen statt weitere reine Papier-Gates anzubauen.

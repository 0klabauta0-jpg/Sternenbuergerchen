# TASK_797 - Station Reentry Firefight Multiplayer Playable Slice Candidate

## Ziel / Problem
Die Kette bis TASK_796 akzeptiert den Multiplayer-Decision-Playtest-Slice, macht daraus aber noch keinen klaren spielbaren Kandidaten. TASK_797 buendelt den akzeptierten Stand zu einem konkreten Host/Client-Spielpfad mit Launch-/Capture-Kommandos, Spieler-Checkpoints und naechster Findings-Route.

## Sinnhaftigkeit / Ursache
Der Review-Wunsch ist nicht nur "Gates gruen", sondern ein angenehmer, spielbarer und multiplayer-faehiger Ablauf. Nach der Acceptance muessen wir wieder auf den echten Spielerfluss schauen: Homebase, Fireteam, Dropship, Mission, Ausstieg, Preview, Decision, Feuerwechsel, Exit/Debrief.

## Umfang
- Read-only Candidate-Snapshot ueber TASK_796-Acceptance.
- Konkrete Launch-, Capture-, Verifier- und Workbench-Kommandos.
- Spieler-Checkpoints fuer den Zwei-Fenster-Playable-Slice.
- Status `ready_for_multiplayer_playable_slice_candidate`, wenn Acceptance und Kontext passen.
- Folgeroute zu Real-Run-Findings.

## Nicht-Ziele
- Kein automatisches Starten der Fenster.
- Kein Netzwerk-Authority-Lasttest.
- Kein neues Missionssystem, kein Combat-Rewrite, keine UI-Mutation.
- Kein Ersatz fuer den echten manuellen Playtest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder nicht akzeptierte TASK_796-Quelle blockiert.
- Candidate enthaelt Szenario, Workbench, Launch-/Capture-Kommandos und Verifier-Kommandos.
- Candidate nennt konkrete Spieler-Checkpoints statt nur technische Gates.
- Candidate bleibt read-only und erzeugt keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-/UI-/Multiplayer-Wahrheit.
- Naechster Schritt ist ein Real-Run-Findings-Task fuer den spielbaren Kandidaten.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_playable_slice_candidate.gd`
- `scripts/tests/task_797_station_reentry_firefight_multiplayer_playable_slice_candidate.gd`
- `docs/tasks/TASK_797_station_reentry_firefight_multiplayer_playable_slice_candidate.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_797_station_reentry_firefight_multiplayer_playable_slice_candidate.gd`
- Regressionen TASK_796/TASK_795/TASK_794
- `git diff --check`

## Risiken / offene Punkte
- Der Candidate macht den Lauf reproduzierbar, beweist ihn aber nicht visuell. TASK_798 muss die echten Real-Run-Findings einsammeln.
- Schoenheit, HUD-Polish und Netzwerk-Last bleiben erst nach dem sichtbaren Kandidatenlauf belastbar.

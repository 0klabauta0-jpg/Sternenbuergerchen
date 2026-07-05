# TASK_798 - Station Reentry Firefight Multiplayer Playable Candidate Real Run Findings

## Ziel / Problem
TASK_797 macht den Multiplayer-Playable-Slice-Kandidaten startbar und pruefbar, sammelt aber noch keine echten Real-Run-Findings. TASK_798 wertet den sichtbaren Zwei-Fenster-Lauf read-only aus und uebersetzt Spielbarkeitsprobleme in konkrete Folgearbeit.

## Sinnhaftigkeit / Ursache
Das Ziel ist nicht nur ein gueltiges Manifest, sondern ein angenehmer, spielbarer und multiplayer-faehiger Ablauf. Dafuer muessen Homebase, Fireteam/Dropship, Mission, Preview, Decision, Feuerwechsel, HUD und Exit/Debrief als Spielerfluss sichtbar geprueft werden.

## Umfang
- Read-only Findings-Snapshot ueber TASK_797-Candidate und optionale Workbench-/Real-Run-Notizen.
- Pflichtchecks fuer den Spielerfluss aus TASK_797 plus Screenshot-/Workbench-Evidence.
- Issue-Flags fuer konkrete Follow-ups: Fireteam-Liste, Dropship-Payload, Mission-Insertion, Preview/Decision, Firefight-Performance, HUD-Overlap und Exit/Debrief.
- Status fuer blockiert, sichtbarer Real-Run offen, unvollstaendige Checks, gezielter Polish und Acceptance-Weitergabe.

## Nicht-Ziele
- Kein automatisches Screenshot-Parsing.
- Kein Starten oder Schliessen von Fenstern.
- Kein Gameplay-Commit und keine neue Multiplayer-Wahrheit.
- Kein UI-Polish in diesem Task; der Task erzeugt Findings und Routing.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_797_station_reentry_firefight_multiplayer_playable_slice_candidate.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlender oder ungueltiger TASK_797-Candidate blockiert.
- Offener Real-Run routet zurueck zum Kandidatenlauf.
- Fehlende Pflichtchecks werden mit IDs gemeldet.
- Aktive Issue-Flags erzeugen konkrete Action Items.
- Saubere Findings routen zu `TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.gd`
- `scripts/tests/task_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.gd`
- `docs/tasks/TASK_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.gd`
- Regressionen TASK_797/TASK_796/TASK_795
- `git diff --check`

## Risiken / offene Punkte
- Ohne echten Fensterlauf bleibt der Status korrekt offen.
- Screenshot-/Pixel-Pruefung bleibt Folgearbeit, wenn der Real-Run optisch strittig ist.
- Konkreter UI-/HUD-/Performance-Polish kommt erst aus den aktiven Issue-Flags.

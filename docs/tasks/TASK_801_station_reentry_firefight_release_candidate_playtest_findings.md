# TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings

## Ziel / Problem
TASK_800 erstellt ein Release-Candidate-Paket, wertet aber noch nicht aus, ob der Kandidat im echten Start-/Host-Client-Playtest funktioniert. TASK_801 sammelt diese sichtbaren Playtest-Findings read-only und macht daraus klare Status- und Folgearbeitsentscheidungen.

## Sinnhaftigkeit / Ursache
Der Weg zu einem angenehmen, spielbaren, schicken und multiplayer-faehigen Zustand braucht nicht nur Pakete, sondern belastbare Rueckmeldung aus dem echten Ablauf: Einzelspieler-Start, Host/Client, Fireteams, Dropship, Mission-Insertion, Preview/Decision, erster Feuerwechsel, Exit/Debrief, HUD und Performance-Gefuehl. Wenn dabei etwas hakt, muss daraus sofort ein konkreter naechster Task werden.

## Umfang
- Read-only Findings-Snapshot ueber TASK_800 Release-Candidate-Paket und optionale Workbench-/Playtest-Notizen.
- Pflichtchecks aus dem RC-Paket werden gezählt und fehlende Checks benannt.
- Issue-Flags fuer blockierten Singleplayer, unklare Fireteams, Dropship-Mix, Mission/Preview/Decision, Firefight-Stottern, HUD-Blocker, fehlenden Debrief, Host/Client-Desync und stale Export.
- Status-Routing fuer fehlendes Paket, offenen sichtbaren Playtest, unvollstaendige Checks, gezielten Polish und Acceptance-Bereitschaft.

## Nicht-Ziele
- Kein automatischer Screenshot-Entscheid.
- Kein Starten oder Steuern der EXE/Fenster.
- Kein automatischer Export.
- Keine Navigation, keine Commands, keine FireEvents, keine DamageEvents und keine UI-/Gameplay-/Multiplayer-Wahrheit.
- Keine Acceptance in diesem Task; das bleibt Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_800_station_reentry_firefight_multiplayer_release_candidate_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlendes oder ungueltiges TASK_800-Paket blockiert.
- Ohne bewusst erledigten sichtbaren Release-Candidate-Playtest bleibt der Status offen.
- Fehlende Pflichtchecks werden als `missing_check_ids` exportiert.
- Aktive Issue-Flags erzeugen konkrete Action Items.
- Ein sauberer Playtest setzt `status = ready_for_release_candidate_acceptance`.
- Snapshot bleibt read-only und setzt keine Gameplay-, UI- oder Multiplayer-Wahrheit.
- Das Manifest schreibt `recommended_next_task = TASK_802 - Station Reentry Firefight Release Candidate Acceptance`, wenn alle Gates gruen sind.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_playtest_findings.gd`
- `scripts/tests/task_801_station_reentry_firefight_release_candidate_playtest_findings.gd`
- `docs/tasks/TASK_801_station_reentry_firefight_release_candidate_playtest_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_801_station_reentry_firefight_release_candidate_playtest_findings.gd`
- Regressionen TASK_800/TASK_799/TASK_798
- `git diff --check`

## Risiken / offene Punkte
- TASK_801 wertet Notizen/Haken aus, erkennt aber keine Bildinhalte automatisch.
- Ein sauberer Snapshot beweist die dokumentierten Findings, nicht automatisch einen langen Netzwerk-Lasttest.
- Acceptance und moegliche Versand-/Build-Hygiene bleiben Folgearbeit in TASK_802.

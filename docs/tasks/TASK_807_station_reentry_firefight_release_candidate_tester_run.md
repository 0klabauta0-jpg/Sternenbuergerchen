# TASK_807 - Station Reentry Firefight Release Candidate Tester Run

## Ziel / Problem
TASK_806 macht den Release-Candidate weitergabefaehig, aber der echte Tester-Run gegen dieses Handoff-Packet ist noch nicht als Gate auswertbar. TASK_807 wertet den Lauf read-only aus: Wurde wirklich aus dem Handoff gestartet, war Einzelspieler handlungsfaehig, waren Host/Client lesbar, kam man in die Mission, funktionierten erster Move/Firefight und war der Exit/Debrief-Pfad sichtbar?

## Sinnhaftigkeit / Ursache
Das Spiel soll angenehm, spielbar, schick und multiplayer-faehig werden. Dafuer reicht ein Packet nicht; der naechste Schritt muss der reale Spielergriff sein. Damit der Test nicht wieder nur ein Chat-Eindruck bleibt, braucht er Pflichtchecks, Issue-Routing und einen klaren naechsten Polish-/Acceptance-Schritt.

## Umfang
- Read-only Snapshot ueber TASK_806-Handoff-Packet.
- Tester-Run-Checks fuer frisches Handoff, EXE-Start, Einzelspieler, Homebase, Dropship, Missionstart, Host/Client, Rollen, erste Preview, erster GO/Firefight, Exit/Debrief, Performance-Gefuehl und Report-Export.
- Issue-Flags mit Routing fuer stale Paket, blockierten Singleplayer, Dropship-/Missionstart-Probleme, Host/Client/Rollenprobleme, Preview-/Firefight-/Debrief-/Performance-/HUD-Polish.
- Manifestpfad fuer Tester-Run-Findings und naechste Acceptance.

## Nicht-Ziele
- Kein automatisches Starten oder Schliessen von Fenstern.
- Kein Screenshot-Parser und kein automatischer Sichtbeweis.
- Kein Gameplay, keine Navigation, keine Commands, keine FireEvents und keine DamageEvents.
- Kein finaler Release; nur Tester-Run-Auswertung fuer den aktuellen Release-Candidate.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_806_station_reentry_firefight_release_candidate_handoff_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_806-Quelle blockiert.
- Nicht handoff-ready Quellen werden nicht als tester-run-ready markiert.
- Ohne Tester-Run-Notizen bleibt der Status `needs_release_candidate_tester_run`.
- Unvollstaendige Tester-Run-Checks listen konkrete `missing_check_ids`.
- Aktive Issue-Flags erzeugen konkrete `action_items`.
- Vollstaendige, saubere Review setzt `release_candidate_tester_run_ready = true`.
- Ein sauberer Snapshot routet zu `TASK_808 - Station Reentry Firefight Release Candidate Tester Run Acceptance`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_tester_run.gd`
- `scripts/tests/task_807_station_reentry_firefight_release_candidate_tester_run.gd`
- `docs/tasks/TASK_807_station_reentry_firefight_release_candidate_tester_run.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_807_station_reentry_firefight_release_candidate_tester_run.gd`
- Regressionen TASK_806/TASK_805
- `git diff --check`

## Risiken / offene Punkte
- TASK_807 wertet Notizen und Gate-Daten aus; er ersetzt keinen echten menschlichen Blick auf Schoenheit und Spielgefuehl.
- Der naechste Schritt muss entscheiden, ob die Findings akzeptiert werden oder gezielt zurueck in Polish gehen.

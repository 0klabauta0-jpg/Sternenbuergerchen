# TASK_799 - Station Reentry Firefight Multiplayer Playable Candidate Acceptance

## Ziel / Problem
TASK_798 sammelt die echten Spielerfluss-Findings des Multiplayer-Playable-Candidates, entscheidet aber noch nicht, ob der Kandidat als naechster spielbarer Multiplayer-Release-Kandidat taugt. TASK_799 akzeptiert oder stoppt diesen Kandidaten mit engen read-only Gates.

## Sinnhaftigkeit / Ursache
Der Spielerfluss soll angenehm, spielbar, schick genug und multiplayer-faehig werden. Dafuer reicht ein Manifest nicht: Homebase, Fireteam/Dropship, Mission-Insertion, Preview/Decision, Feuerwechsel, HUD und Exit/Debrief muessen im TASK_798-Review ohne offene Pflichtchecks und ohne aktive Issues durchlaufen sein.

## Umfang
- Read-only Acceptance-Snapshot ueber TASK_798-Findings.
- Gates fuer valide Quelle, read-only-Grenze, Real-Run, fehlende Checks, aktive Issues, Szenario, Workbench, Host/Client-Rollen, Decision-Kontext und Export-/Capture-Kommandos.
- Status-Routing fuer fehlende Findings, offenen Real-Run, unvollstaendige Checks, gezielten Polish, offene Acceptance-Gates und akzeptierten Multiplayer-Playable-Candidate.
- Manifestpfad fuer die naechste Release-Candidate-Kette.

## Nicht-Ziele
- Kein automatischer Screenshot-Entscheid.
- Kein Starten, Schliessen oder Steuern von Fenstern.
- Kein neues Gameplay, keine Command-Erzeugung und keine neue Multiplayer-Wahrheit.
- Kein UI-Polish; aktive Issues routen nur auf konkrete Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_798_station_reentry_firefight_multiplayer_playable_candidate_real_run_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_798-Findings blockieren.
- Offener Real-Run routet zurueck zum sichtbaren TASK_797-Kandidatenlauf.
- Fehlende TASK_798-Pflichtchecks werden nicht akzeptiert.
- Aktive Issue-Flags routen zum ersten konkreten Action Item.
- Saubere Findings setzen `accepted_for_multiplayer_playable_candidate = true`.
- Akzeptierte Findings routen zu `TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_playable_candidate_acceptance.gd`
- `scripts/tests/task_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.gd`
- `docs/tasks/TASK_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.gd`
- Regressionen TASK_798/TASK_797/TASK_796
- `git diff --check`

## Risiken / offene Punkte
- TASK_799 beweist nur die TASK_798-Findings, nicht automatisch einen neuen langen Multiplayer-Livetest.
- Wenn der echte Fensterblick doch Reibung zeigt, muss TASK_798 mit Issues/Finding-Export aktualisiert werden statt TASK_799 gruen zu erzwingen.
- Das Release-Candidate-Paket bleibt Folgearbeit in TASK_800.

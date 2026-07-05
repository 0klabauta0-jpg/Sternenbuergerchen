# TASK_802 - Station Reentry Firefight Release Candidate Acceptance

## Ziel / Problem
TASK_801 sammelt Release-Candidate-Playtest-Findings, entscheidet aber noch nicht, ob der Kandidat als akzeptierter spielbarer RC gilt. TASK_802 akzeptiert oder stoppt diesen Stand mit engen read-only Gates.

## Sinnhaftigkeit / Ursache
Das Spiel soll angenehmer, spielbarer, schicker und multiplayer-faehig werden. Dafuer muss der Release-Kandidat nicht nur als Paket existieren, sondern anhand der echten Findings geprueft werden: sichtbarer Playtest erledigt, EXE/Host-Client gestartet, Pflichtchecks vollstaendig, keine aktiven Issues und keine UI-/Gameplay-Wahrheitsverletzung.

## Umfang
- Read-only Acceptance-Snapshot ueber TASK_801-Findings.
- Gates fuer valide Quelle, read-only-Grenze, sichtbaren Playtest, Release-EXE, Host/Client, fehlende Checks, aktive Issues, Release-Kontext, Rollen und Kommandos.
- Status-Routing fuer fehlende Findings, offenen Playtest, unvollstaendige Checks, gezielten Polish, offene Gates und akzeptierten Release-Candidate.
- Manifestpfad fuer die naechste Ship-/Readiness-Kette.

## Nicht-Ziele
- Kein automatischer Screenshot-Entscheid.
- Kein Starten, Schliessen oder Steuern von Fenstern.
- Kein Export-Start.
- Kein neues Gameplay, keine Command-Erzeugung und keine neue Multiplayer-Wahrheit.
- Kein finaler Produkt-Release; nur Acceptance des aktuellen spielbaren Kandidaten.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_801_station_reentry_firefight_release_candidate_playtest_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_801-Findings blockieren.
- Offener sichtbarer RC-Playtest routet zurueck zum TASK_800-Paketlauf.
- Fehlende TASK_801-Pflichtchecks werden nicht akzeptiert.
- Aktive Issue-Flags routen zum ersten konkreten Action Item.
- Saubere Findings setzen `accepted_for_release_candidate = true`.
- Akzeptierte Findings routen zu `TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_acceptance.gd`
- `scripts/tests/task_802_station_reentry_firefight_release_candidate_acceptance.gd`
- `docs/tasks/TASK_802_station_reentry_firefight_release_candidate_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_802_station_reentry_firefight_release_candidate_acceptance.gd`
- Regressionen TASK_801/TASK_800/TASK_799
- `git diff --check`

## Risiken / offene Punkte
- TASK_802 beweist nur die Findings-Kette und ihre Gates, nicht automatisch einen langen Multiplayer-Lasttest.
- Wenn der echte Fensterblick doch Reibung zeigt, muessen TASK_801-Notizen/Issue-Flags aktualisiert werden statt TASK_802 gruen zu erzwingen.
- Versand-/Weitergabe-Readiness bleibt Folgearbeit in TASK_803.

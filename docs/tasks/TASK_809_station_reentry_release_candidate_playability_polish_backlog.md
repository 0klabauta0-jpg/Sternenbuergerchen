# TASK_809 - Station Reentry Release Candidate Playability Polish Backlog

## Ziel / Problem
Nach TASK_808 ist der Release-Candidate-Tester-Run eng akzeptierbar, aber der erste sichtbare Griff nach `Einzelspieler` muss fuer den Spieler klarer sein. Der Screen darf nicht nur startbereit sein; er muss knapp sagen, was als naechstes zu tun ist.

## Sinnhaftigkeit / Ursache
Der Screenshot-Blocker zeigte, dass Datenpfad und sichtbarer Spielergriff auseinanderfallen koennen. TASK_809 macht daraus einen konkreten Polish: Die Homebase zeigt eine kurze Release-Run-Handlungskette direkt bei der Readiness, ohne neue Gameplay-Wahrheit anzulegen.

## Umfang
- Kleine CTA-Leiste im Homebase-MissionPanel unter der Pre-Mission-Readiness.
- Ready-Text: `Naechster Griff: Start Mission -> LZ waehlen -> Drop -> Preview lesen -> GO`.
- Warn-/Blocked-Texte nennen erst die zu loesenden WARN-/STOP-Chips.
- Read-only Snapshot `get_release_candidate_playability_polish_snapshot()`.
- Verifier fuer blockierten Homebase-Zustand und echten Main-Menu-`Einzelspieler`-Pfad.

## Nicht-Ziele
- Kein neuer Startbutton.
- Kein automatischer Missionstart.
- Keine neue Navigation, keine Commands, keine FireEvents, keine DamageEvents.
- Kein Layout-Grossumbau und kein neues Onboarding-System.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_808_station_reentry_firefight_release_candidate_tester_run_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Homebase zeigt eine sichtbare Release-Candidate-Action-Cue.
- Ready-Cue nennt die erste spielbare Kette von `Start Mission` bis `GO`.
- Blocked-Cue verweist auf STOP-Chips statt Erfolg zu behaupten.
- Startflow- und TASK_809-Snapshot tragen denselben Cue-Text.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.
- Main-Menu-`Einzelspieler`-Pfad bleibt startbereit und zeigt die Ready-Cue.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_809_station_reentry_release_candidate_playability_polish_backlog.gd`
- `docs/tasks/TASK_809_station_reentry_release_candidate_playability_polish_backlog.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_809_station_reentry_release_candidate_playability_polish_backlog.gd`
- Regressionen TASK_808 und Singleplayer-Release-Start-Bootstrap
- `git diff --check`

## Risiken / offene Punkte
- Die Cue ist absichtlich nur eine kleine Lesbarkeitsbruecke. Der echte Sicht-/Layout-Rauchtest bleibt TASK_810.
- Spaeteres Kampagnen-Onboarding sollte diesen Cue bewusst erweitern, nicht eine zweite Startlogik daneben setzen.

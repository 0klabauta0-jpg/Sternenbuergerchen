# TASK_800 - Station Reentry Firefight Multiplayer Release Candidate Packet

## Ziel / Problem
TASK_799 akzeptiert den Multiplayer-Playable-Candidate, liefert aber noch kein gebuendeltes Release-Candidate-Paket fuer den naechsten echten Start-/Weitergabe-Test. TASK_800 sammelt die akzeptierte Quelle, Export-Artefakte, Host/Client-Kommandos, Workbench und Pflichtchecks in einem reproduzierbaren read-only Manifest.

## Sinnhaftigkeit / Ursache
Der Weg Richtung angenehm spielbar, schick und multiplayer-faehig braucht einen klaren Paketgriff: Welche EXE soll gestartet werden, welche `.pck`/DLLs gehoeren dazu, welche Szene/Workbench ist die Quelle, welche manuellen Checks muessen im Host/Client-Lauf wirklich abgehakt werden. Ohne dieses Paket driftet der Playtest wieder in alte Exporte oder lose Fensterlaeufe.

## Umfang
- Read-only Release-Candidate-Packet ueber TASK_799-Acceptance.
- Paketdaten fuer Release-Ordner, EXE, PCK, Runtime-DLLs und Export-Workflow.
- Host/Client-Start-, Capture-, Export- und Workbench-Kommandos.
- Pflichtchecks fuer Einzelspieler-Start, Host/Client, Fireteam/Dropship-Konsistenz, Mission-Insertion, Preview/Decision, Firefight-Reaktion, Exit/Debrief, HUD und Performance-Gefuehl.
- Status-Routing fuer fehlende oder nicht akzeptierte TASK_799-Quelle, fehlende Paketdaten und fertiges RC-Paket.

## Nicht-Ziele
- Kein automatischer Export-Start in diesem Service.
- Kein Starten, Schliessen oder Steuern von Fenstern.
- Kein automatischer Screenshot-Entscheid.
- Keine neue Navigation, keine Commands, keine FireEvents, keine DamageEvents und keine UI-/Gameplay-/Multiplayer-Wahrheit.
- Kein Ersatz fuer einen echten menschlichen Release-Playtest.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_799_station_reentry_firefight_multiplayer_playable_candidate_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `data/export_runtime_package_contract.json`
- `scripts/tools/export_runtime_release.ps1`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_799-Acceptance blockiert.
- Nicht akzeptierte TASK_799-Quelle routet zurueck zur Acceptance/Findings-Kette.
- Akzeptierte Quelle erzeugt ein Release-Candidate-Paket mit Release-Ordner, EXE, PCK, DLL-Liste, Export-Workflow und Host/Client-Kommandos.
- Pflichtchecks decken Singleplayer-Start, Host/Client, Fireteam/Dropship, Mission, Preview/Decision, Firefight, Exit/Debrief, HUD und Performance ab.
- Paket bleibt read-only und setzt keine Gameplay-, UI- oder Multiplayer-Wahrheit.
- Das Manifest schreibt `recommended_next_task = TASK_801 - Station Reentry Firefight Release Candidate Playtest Findings`.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_release_candidate_packet.gd`
- `scripts/tests/task_800_station_reentry_firefight_multiplayer_release_candidate_packet.gd`
- `docs/tasks/TASK_800_station_reentry_firefight_multiplayer_release_candidate_packet.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_800_station_reentry_firefight_multiplayer_release_candidate_packet.gd`
- Regressionen TASK_799/TASK_798/TASK_797
- `git diff --check`

## Risiken / offene Punkte
- Das Paket beweist die Paketstruktur, nicht den erneuten menschlichen Release-Playtest.
- Wenn die EXE manuell aus einem alten Ordner gestartet wird, kann weiterhin ein stale Build getestet werden; das Paket nennt deshalb den konkreten Release-Ordner.
- Die echten Playtest-Findings und sichtbaren Reibungen bleiben Folgearbeit in TASK_801.

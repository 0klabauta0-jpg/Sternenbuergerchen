# TASK_796 - Station Reentry Firefight Multiplayer Decision Playtest Acceptance

## Ziel / Problem
TASK_795 kann den sichtbaren Multiplayer-Decision-Playtest auswerten, aber es fehlt noch ein enger Acceptance-Gate, der entscheidet, ob diese Findings wirklich als kleiner spielbarer Multiplayer-Decision-Slice gelten duerfen.

## Sinnhaftigkeit / Ursache
Ohne Acceptance-Gate koennte ein unvollstaendiger oder nur teilweise sichtbarer Host/Client-Playtest als Fortschritt weitergereicht werden. TASK_796 zwingt die Kette, zwischen offenem Sichttest, fehlenden Checks, konkretem Polish und akzeptiertem Playtest-Slice zu unterscheiden.

## Umfang
- Read-only Acceptance-Snapshot ueber TASK_795-Findings.
- Gates fuer valide Quelle, read-only-Grenzen, sichtbaren Playtest, Pflichtchecks, aktive Issues, Decision-Kern, Host-/Client-Rollen, No-Auto-Command, Playtest-Kontext und Packet-Disziplin.
- Manifest `tmp/station_reentry_firefight_multiplayer_decision_playtest_acceptance.json`.
- Regressionstest fuer blockiert, offener Playtest, unvollstaendige Checks, aktive Issues und akzeptierten Pfad.

## Nicht-Ziele
- Kein Screenshot-Parsing.
- Kein echter Netzwerk-Authority-Lasttest.
- Kein neues Missions-, Command-, Combat- oder UI-System.
- Keine Gameplay-, UI- oder Multiplayer-Wahrheit im Acceptance-Snapshot.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_795_station_reentry_firefight_multiplayer_decision_playtest_findings.md`
- `docs/tasks/TASK_794_station_reentry_firefight_multiplayer_decision_playtest_packet.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende, falsche oder nicht read-only TASK_795-Findings blockieren.
- Offener sichtbarer Playtest routet zurueck zu TASK_794.
- Fehlende Checks routen zur Check-Completion.
- Aktive Issues routen zum ersten konkreten Action Item.
- Saubere Findings setzen `accepted_for_multiplayer_decision_playtest_slice = true`.
- Der Snapshot erzeugt keine Navigation, Commands, FireEvents, DamageEvents oder Gameplay-/UI-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_multiplayer_decision_playtest_acceptance.gd`
- `scripts/tests/task_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.gd`
- `docs/tasks/TASK_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_796_station_reentry_firefight_multiplayer_decision_playtest_acceptance.gd`
- Regressionen TASK_795/TASK_794/TASK_793
- `git diff --check`

## Risiken / offene Punkte
- Acceptance beweist nicht, dass ein echter Mensch den Playtest schon durchgefuehrt hat; sie akzeptiert nur entsprechende, gesetzte Findings.
- Netzwerk-Authority-Last, Match-Start-Komfort und visuelle Schoenheit bleiben weitere Aufgaben.

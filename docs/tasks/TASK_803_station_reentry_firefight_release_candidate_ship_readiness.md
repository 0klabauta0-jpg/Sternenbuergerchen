# TASK_803 - Station Reentry Firefight Release Candidate Ship Readiness

## Ziel / Problem
TASK_802 akzeptiert den Release-Candidate, aber der Stand ist noch nicht als handhabbares Spielepaket fuer den naechsten sichtbaren Smoke beschrieben. TASK_803 buendelt die akzeptierte Quelle, Release-Dateien, Kommandos, Restrisiken und naechste Bedienanweisung in einem read-only Ship-Readiness-Snapshot.

## Sinnhaftigkeit / Ursache
Nach dem EXE-Blocker darf nicht wieder eine alte Verknuepfung oder ein stale Export getestet werden. Der Spieler soll einen konkreten Spieleordner starten koennen, und wir brauchen einen kleinen Vertrag, der sagt: Diese EXE/PCK/DLLs, diese Workbench, diese Kommandos, diese Risiken, dieser naechste sichtbare Test.

## Umfang
- Read-only Snapshot ueber TASK_802-Acceptance.
- Ship-Readiness-Items fuer EXE, PCK, Runtime-DLLs, Start-/Export-Kommandos, Workbench, Findings-/Acceptance-Manifeste, Restrisiken und naechste Bedienanweisung.
- Status-Routing fuer fehlende Acceptance, nicht akzeptierte Quelle, unvollstaendige Ship-Items und bereiten sichtbaren Ship-Smoke.
- Manifestpfad fuer die naechste sichtbare EXE-/Host-Client-Pruefung.

## Nicht-Ziele
- Kein Starten oder Schliessen von Fenstern.
- Kein Export-Aufruf.
- Kein Gameplay, keine Navigation, keine Commands, keine FireEvents und keine DamageEvents.
- Kein finaler Produkt-Release; nur Readiness fuer den naechsten sichtbaren Smoke.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_802_station_reentry_firefight_release_candidate_acceptance.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_802-Acceptance blockiert.
- Nicht akzeptierter Release-Candidate wird nicht als ship-ready markiert.
- Fehlende Ship-Readiness-Items werden konkret gelistet.
- Vollstaendige Ship-Readiness setzt `ship_readiness_ready = true`.
- Ein bereiter Snapshot routet zu `TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_ship_readiness.gd`
- `scripts/tests/task_803_station_reentry_firefight_release_candidate_ship_readiness.gd`
- `docs/tasks/TASK_803_station_reentry_firefight_release_candidate_ship_readiness.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_803_station_reentry_firefight_release_candidate_ship_readiness.gd`
- Regressionen TASK_802/TASK_801/TASK_800
- `git diff --check`

## Risiken / offene Punkte
- TASK_803 beweist Paket-Readiness, nicht den echten Fensterblick.
- Der frische lokale Build-Ordner bleibt bewusst untracked; Verknuepfungen koennen weiterhin auf alte EXEs zeigen, bis sie manuell aktualisiert sind.
- TASK_804 muss den sichtbaren EXE-/Host-Client-Smoke tatsaechlich pruefen.

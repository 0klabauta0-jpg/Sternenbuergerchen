# TASK_804 - Station Reentry Firefight Release Candidate Visible Ship Smoke

## Ziel / Problem
TASK_803 macht das Release-Paket ship-ready, aber der echte sichtbare EXE-/Host-Client-Smoke ist noch nicht als eigener Gate-Schritt beschrieben. TASK_804 wertet Ship-Readiness und Workbench-/Smoke-Notizen aus, damit stale EXE-Links, blockierte Homebase, Dropship-Payload-Probleme oder Host/Client-Sichtbarkeitsfehler nicht wieder im Bauchgefuehl verschwinden.

## Sinnhaftigkeit / Ursache
Der letzte EXE-Blocker kam aus genau dieser Luecke: Paket und Export konnten vorhanden sein, waehrend der Spieler nach `Einzelspieler` trotzdem vor einem nicht handlungsfaehigen Screen stand. Der sichtbare Smoke braucht deshalb einen kleinen read-only Vertrag, der sagt, welche Fenster-/Bedienhaken wirklich geprueft wurden und welche konkrete Folgearbeit daraus entsteht.

## Umfang
- Read-only Snapshot ueber TASK_803-Ship-Readiness.
- Pflichtchecks fuer frischen Spieleordner, EXE-Start, Einzelspieler, Homebase-Handlungsfaehigkeit, Dropship-Payload, Mission-Start, Host/Client-Fenster, Rollen-Unterscheidung, stale Link und gespeicherte Smoke-Notizen.
- Issue-Flags mit zielgerichtetem Routing fuer stale Export, Singleplayer-Blocker, Dropship-Payload, Mission-Start, Host/Client-Sichtbarkeit, Rollen-Verwechslung und Runtime-Startfehler.
- Manifestpfad fuer den sichtbaren Ship-Smoke und naechste Delivery-Review.

## Nicht-Ziele
- Kein automatisches Starten oder Schliessen von Fenstern.
- Kein Screenshot-Parser und kein behaupteter Sichttest.
- Kein Export-Aufruf.
- Kein Gameplay, keine Navigation, keine Commands, keine FireEvents und keine DamageEvents.
- Kein neuer Multiplayer-State und keine UI-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_803_station_reentry_firefight_release_candidate_ship_readiness.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_803-Ship-Readiness blockiert.
- Nicht ship-ready Quellen werden nicht als sichtbarer Ship-Smoke akzeptiert.
- Ohne Workbench-/Smoke-Notizen bleibt der Status `needs_visible_ship_smoke`.
- Unvollstaendige Pflichtchecks listen konkrete `missing_check_ids`.
- Aktive Issue-Flags erzeugen konkrete `action_items`.
- Vollstaendige, saubere Notizen setzen `visible_ship_smoke_ready = true`.
- Ein sauberer Snapshot routet zu `TASK_805 - Station Reentry Firefight Release Candidate Delivery Review`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_visible_ship_smoke.gd`
- `scripts/tests/task_804_station_reentry_firefight_release_candidate_visible_ship_smoke.gd`
- `docs/tasks/TASK_804_station_reentry_firefight_release_candidate_visible_ship_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_804_station_reentry_firefight_release_candidate_visible_ship_smoke.gd`
- Regressionen TASK_803/TASK_802
- `git diff --check`

## Risiken / offene Punkte
- TASK_804 bewertet Workbench-/Smoke-Notizen, nicht den Bildinhalt selbst.
- Ein echter sichtbarer Fensterlauf bleibt manuell, bis wir absichtlich eine robuste Window-Capture-/Review-Strecke bauen.
- TASK_805 muss daraus eine kleine Delivery-Review machen, bevor der Stand als weitergabefaehig gilt.

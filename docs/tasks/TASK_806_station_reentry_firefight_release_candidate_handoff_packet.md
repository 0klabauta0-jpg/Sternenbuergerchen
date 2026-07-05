# TASK_806 - Station Reentry Firefight Release Candidate Handoff Packet

## Ziel / Problem
TASK_805 entscheidet, dass der Release-Candidate delivery-ready sein kann. TASK_806 baut daraus ein konkretes, read-only Handoff-Packet: Welche EXE/PCK gehoeren dazu, wie startet man den Einzelspieler, wie startet man Host/Client, welche Rollen werden erwartet, welche Smoke-/Review-Gates sind Quelle und welche Restrisiken bleiben offen.

## Sinnhaftigkeit / Ursache
Ohne Handoff-Packet bleibt der Release-Candidate zwar intern geprueft, aber fuer den naechsten Testlauf zu lose: alte Verknuepfungen, falscher Spieleordner, unklare Host/Client-Rollen oder fehlende Report-Exports koennen wieder denselben Bedienfrust erzeugen. Das Packet macht den Stand weitergebbar, ohne selbst etwas auszufuehren.

## Umfang
- Read-only Snapshot ueber TASK_805-Delivery-Review.
- Handoff-Items fuer Release-Dateien, Startbefehl, Einzelspieler-Check, Host/Client-Check, Rollenhinweise, Workbench/Report, Risiken und naechste Tester-Aktion.
- Issue-Flags mit Routing fuer fehlende Delivery-Review, stale Paket, fehlende Startanleitung, unklare Rollen, fehlenden Report, nicht akzeptierte Risiken und offenen visuellen Polish.
- Manifestpfad fuer das Handoff-Packet und naechsten Test-Run.

## Nicht-Ziele
- Kein Export-Aufruf und kein Kopieren/Paketieren von Dateien.
- Kein Starten oder Schliessen von Fenstern.
- Kein Screenshot-Parser und kein automatischer Sichtbeweis.
- Kein Gameplay, keine Navigation, keine Commands, keine FireEvents und keine DamageEvents.
- Kein finaler Release; nur ein weitergabefaehiges Test-/Handoff-Packet.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_805_station_reentry_firefight_release_candidate_delivery_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- Fehlende oder ungueltige TASK_805-Quelle blockiert.
- Nicht delivery-ready Quellen werden nicht als handoff-ready markiert.
- Ohne Handoff-Notizen bleibt der Status `needs_handoff_packet`.
- Unvollstaendige Handoff-Items listen konkrete `missing_item_ids`.
- Aktive Issue-Flags erzeugen konkrete `action_items`.
- Vollstaendige, saubere Review setzt `release_candidate_handoff_ready = true`.
- Ein sauberer Snapshot routet zu `TASK_807 - Station Reentry Firefight Release Candidate Tester Run`.
- Snapshot bleibt read-only: keine Navigation, keine Commands, keine FireEvents, keine DamageEvents, keine UI-/Gameplay-/Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_firefight_release_candidate_handoff_packet.gd`
- `scripts/tests/task_806_station_reentry_firefight_release_candidate_handoff_packet.gd`
- `docs/tasks/TASK_806_station_reentry_firefight_release_candidate_handoff_packet.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_806_station_reentry_firefight_release_candidate_handoff_packet.gd`
- Regressionen TASK_805/TASK_804
- `git diff --check`

## Risiken / offene Punkte
- TASK_806 macht den Stand weitergebbar, fuehrt aber keinen echten Tester-Lauf aus.
- Der naechste Schritt muss das Handoff-Packet gegen einen realen Test-Run pruefen.

# TASK_810 - Station Reentry Release Candidate First Mission CTA Visual Smoke

## Ziel / Problem
Der `Einzelspieler`-Start muss nach dem Release-Bootstrap nicht nur technisch startbereit sein, sondern im ersten Homebase-Fenster auch widerspruchsfrei lesbar bleiben: CTA sichtbar, `Start Mission` aktiv, Flightdeck nicht leer, Fireteam-Payload geboardet.

## Sinnhaftigkeit / Ursache
Der EXE-Screenshot-Blocker zeigte, dass ein headless gruenes System trotzdem im Fenster wie blockiert aussehen kann. TASK_810 legt deshalb einen automatischen Control-/Snapshot-Smoke ueber den sichtbaren ersten Homebase-Griff, ohne echte Screenshot-Erkennung zu behaupten.

## Umfang
- Read-only Snapshot `HomebaseTestScreen.get_release_candidate_first_mission_cta_visual_smoke_snapshot()`.
- Main-Menu-`Einzelspieler`-Verifier, der den echten ersten Homebase-Pfad ausfuehrt.
- Pruefung von CTA, Startbutton, Readiness-Chips, Flightdeck, Dropship-Payload und CTA-Geometry.
- Dokumentation im Mission-Command-Feedback-Contract und Reentry-Handbuch.

## Nicht-Ziele
- Kein neuer Startbutton.
- Kein automatischer Missionstart.
- Keine Screenshot-/Pixelbewertung und kein F6-Sichttest.
- Keine neue Gameplay-, UI- oder Multiplayer-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_809_station_reentry_release_candidate_playability_polish_backlog.md`
- `docs/tasks/BUGFIX_singleplayer_release_homebase_partial_save_actionability.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- `Einzelspieler` routet in die Homebase und liefert den TASK_810-Smoke-Snapshot.
- Snapshot ist read-only und erzeugt keine Navigation, Commands, FireEvents oder DamageEvents.
- CTA lautet im Ready-Zustand exakt `Naechster Griff: Start Mission -> LZ waehlen -> Drop -> Preview lesen -> GO`.
- Startbutton ist `Start Mission` und aktiv.
- Sichtbare Readiness enthaelt keine `STOP Team`, `STOP Dropship`, `STOP Pilot` oder `STOP Boarding`-Widersprueche.
- Flightdeck zeigt mindestens eine Shipcard und nicht `Flight deck empty`.
- Payload hat Operatoren und diese sind geboardet.
- CTA-Control und Label liegen innerhalb des MissionPanels und haben lesbare Bounds.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.gd`
- `docs/tasks/TASK_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_810_station_reentry_release_candidate_first_mission_cta_visual_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_809_station_reentry_release_candidate_playability_polish_backlog.gd`
- `godot_console.exe --headless --path . --script scripts/tests/bugfix_singleplayer_release_homebase_start_bootstrap.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Smoke liest Control-Geometrie und Snapshots, aber keinen echten Screenshot. Der menschliche Fensterblick bleibt sinnvoll, wenn Layout-Schoenheit bewertet werden soll.
- Als naechster Griff bietet sich ein kleiner Live-Window-Polish-Findings-Task an, falls der echte Fensterblick trotz gruenem Smoke Reibung zeigt.

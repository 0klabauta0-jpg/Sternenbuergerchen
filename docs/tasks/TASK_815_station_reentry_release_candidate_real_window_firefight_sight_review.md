# TASK_815 - Station Reentry Release Candidate Real Window Firefight Sight Review

## Ziel / Problem
Nach dem frischen Release-Export muss der echte EXE-/Fensterpfad vom `Einzelspieler` bis zum ersten lesbaren Firefight als eigener Release-Gate nachvollziehbar werden.

## Sinnhaftigkeit / Ursache
Die automatischen TASK_810 bis TASK_814-Smokes pruefen den Singleplayer-Spine headless. Der gemeldete Blocker kam aber aus dem echten Release-Griff: falscher oder alter Shortcut, blockierte Homebase, leeres Dropship oder ein Firefight-HUD, das im Fenster nicht sofort lesbar ist.

## Umfang
- Read-only Snapshot `StationReentryReleaseCandidateRealWindowFirefightSightReview`.
- Meta-Snapshot `MetaLayerFlow.get_release_candidate_real_window_firefight_sight_review_snapshot()`.
- Release-Kontext fuer EXE/PCK, Taskleisten-Ziel und Pflichtchecks.
- Status-Routing fuer frischen Export, Shortcut, Homebase-Actionability, Drop/GO und ersten Firefight-Blick.
- Manifest-Export fuer `tmp/station_reentry_release_candidate_real_window_firefight_sight_review.json`.

## Nicht-Ziele
- Kein automatischer Screenshot-Beweis.
- Kein Combat-, Pathfinding-, LOS- oder UI-Rewrite.
- Kein neuer Gameplay-State im HUD.
- Kein Multiplayer-Authority-Pfad.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- TASK_814 bleibt als Quelle gruen und read-only.
- Snapshot prueft Release-EXE und PCK als vorhandenen Kontext.
- Snapshot erkennt einen abweichenden oder fehlenden Taskleisten-/Release-Shortcut als eigenes Gate.
- Pflichtchecks decken `Einzelspieler`, Homebase, `Start Mission`, LZ/Drop/Preview/GO und ersten Firefight-HUD-Blick ab.
- Ohne bewusst abgeschlossenen Fensterblick bleibt der Status bei `needs_real_window_firefight_review`.
- Mit vollstaendigen, issue-freien Review-Notizen routet der Snapshot zu `ready_for_release_candidate_iteration`.
- Snapshot erzeugt keine Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_release_candidate_real_window_firefight_sight_review.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_815_station_reentry_release_candidate_real_window_firefight_sight_review.gd`
- `docs/tasks/TASK_815_station_reentry_release_candidate_real_window_firefight_sight_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_815_station_reentry_release_candidate_real_window_firefight_sight_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der echte menschliche Sichttest bleibt ein manueller Haken. Dieser Task sorgt nur dafuer, dass Shortcut, Release-Ordner, Pflichtgriffe und Befunde nicht mehr im Chat verschwinden.

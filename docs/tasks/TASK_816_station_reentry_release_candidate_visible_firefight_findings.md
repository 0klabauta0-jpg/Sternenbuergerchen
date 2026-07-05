# TASK_816 - Station Reentry Release Candidate Visible Firefight Findings

## Ziel / Problem
Sichtbare Befunde aus dem echten TASK_815-Fensterlauf sollen nicht als lose Notizen stehen bleiben, sondern in konkrete, priorisierte Folgearbeit uebersetzt werden.

## Sinnhaftigkeit / Ursache
TASK_815 prueft, ob frische EXE, Shortcut, Homebase, LZ/Drop/GO und erster Firefight-Blick nachvollziehbar sind. Wenn dort etwas auffaellt, braucht der naechste Schritt sofort eine saubere Einordnung: Blocker, gezielter Polish oder Acceptance.

## Umfang
- Read-only Snapshot `StationReentryReleaseCandidateVisibleFirefightFindings`.
- Meta-Snapshot `MetaLayerFlow.get_release_candidate_visible_firefight_findings_snapshot(...)`.
- Uebersetzung von TASK_815-Issue-Flags und optionalen Findings-Notizen in Action Items.
- Status-Routing fuer offenen Fensterlauf, untriagierte Findings, gezielten Polish und issue-freie Acceptance.
- Manifest-Export fuer `tmp/station_reentry_release_candidate_visible_firefight_findings.json`.

## Nicht-Ziele
- Kein UI-, Combat-, Pathfinding- oder Performance-Rewrite.
- Keine automatische Pixel-/Screenshot-Auswertung.
- Kein Commit von Gameplay-State aus Review-Notizen.
- Kein Multiplayer-Authority-Umbau.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_815_station_reentry_release_candidate_real_window_firefight_sight_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- TASK_815 bleibt als Quelle read-only.
- Offene TASK_815-Fensterchecks blockieren TASK_816 sauber statt Findings zu erfinden.
- Aktive TASK_815-Issues und optionale Findings-Flags werden als `findings` und `action_items` ausgegeben.
- Fehlende Triage-Haken bleiben als `missing_check_ids` sichtbar.
- Issue-freie, bewusst reviewte Befunde routen zu Release-Candidate-Acceptance.
- Snapshot erzeugt keine Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/mission/station_reentry_release_candidate_visible_firefight_findings.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_816_station_reentry_release_candidate_visible_firefight_findings.gd`
- `docs/tasks/TASK_816_station_reentry_release_candidate_visible_firefight_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_816_station_reentry_release_candidate_visible_firefight_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_815_station_reentry_release_candidate_real_window_firefight_sight_review.gd`
- `git diff --check`

## Risiken / offene Punkte
- TASK_816 repariert noch keine sichtbaren Befunde. Er macht sie nur priorisierbar, damit der naechste Task gezielt poliert statt breit zu stochern.

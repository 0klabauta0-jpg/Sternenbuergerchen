# TASK_814 - Station Reentry Release Candidate Firefight Feel And HUD Polish Review

## Ziel / Problem
Nach dem ersten `GO` soll der erste Feuerwechsel nicht nur technisch passieren, sondern im HUD sofort lesbar und handlungsfaehig wirken.

## Sinnhaftigkeit / Ursache
TASK_813 beweist, dass Bewegung, Kontakt und Engagement-Feedback vorhanden sind. Was noch fehlt, ist die Spielerperspektive: Sieht man in Mission Control und am ausgewaehlten Fireteam schnell, wer feuert oder wartet, warum das passiert, welcher Kontext gilt und was der naechste Griff ist?

## Umfang
- Read-only Snapshot `TacticalController.get_release_candidate_firefight_feel_hud_polish_snapshot()`.
- Meta-Snapshot `MetaLayerFlow.get_release_candidate_firefight_feel_hud_polish_review_snapshot()`.
- Mission-Control zeigt den bestehenden kompakten Combat-HUD-Readout, wenn Feuer-/Kontakt-Entscheidungsdaten aktiv sind.
- Verifier laeuft den bestehenden TASK_813-Pfad bis zum ersten Feuerwechsel und prueft HUD-Dichte, Tooltip, Panel-Bounds und naechste Aktion.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue Treffer-, LOS-, Deckungs- oder Damage-Logik.
- Kein automatischer sichtbarer Fenster-Screenshot.
- Kein neuer Multiplayer-Authority-Pfad.

## Relevante Contracts / Dokumente
- `docs/PROJECT_BRIEF.md`
- `docs/ARCHITECTURE.md`
- `docs/CODEX_RULES.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/tasks/TASK_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Akzeptanzkriterien
- TASK_813 bleibt als Quelle gruen.
- Mission Control und Selected Fireteam zeigen denselben kompakten Combat-Readout.
- Der Readout bleibt kurz und enthaelt Fire-/Wait-/No-Fire-Status plus Cover/Range/LOS-Kontext.
- Tooltip-/Detaildaten erklaeren Feuerstatus, Cover, Range, LOS und Flank.
- Der Snapshot nennt einen klaren naechsten Spielergriff fuer den Feuerwechsel.
- HUD-Panels bleiben im FullHD-Audit innerhalb der Bounds und ueberlappen nicht.
- Alle neuen Snapshots bleiben read-only und erzeugen keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/meta/meta_layer_flow.gd`
- `scripts/tests/task_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.gd`
- `docs/tasks/TASK_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/project_current_state_handbook_reentry_2026_07_01.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_814_station_reentry_release_candidate_firefight_feel_hud_polish_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_813_station_reentry_release_candidate_first_go_firefight_actionability_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft automatisierte HUD-/Snapshot-Lesbarkeit. Der echte menschliche Fensterblick auf Timing, Drama und Schoenheit bleibt der naechste sinnvolle Griff.

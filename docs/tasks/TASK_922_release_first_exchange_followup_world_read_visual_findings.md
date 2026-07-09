# TASK_922 - Release First Exchange Followup World Read Visual Findings

## Ziel / Problem
TASK_921 stellt den Recapture-/Review-Rahmen nach dem TASK_920-Follow-up-Fix bereit. Noch fehlt der read-only Findings-Schnitt, der den echten Follow-up-Fensterblick als Spielerbefund bewertet und entscheidet, ob der First-Exchange-Playability-Smoke sinnvoll freigegeben werden kann.

## Sinnhaftigkeit / Ursache
Der TASK_921-Snapshot kann technisch `review_ready` sein, darf aber keinen menschlichen Sichtentscheid ersetzen. TASK_922 trennt deshalb positive Belege, offene Sichtpruefung, Restreibung und echte Akzeptanz. So vermeiden wir, wieder ins blinde Nachpolieren zu kippen.

## Umfang
- TASK_921-Snapshot/Manifest als Quelle pruefen.
- TASK_920-Follow-up-Style, TASK_917-Recapture-Basis, TASK_916-Final-Basis und TASK_918-Findings-Basis als erwartete Herkunft festhalten.
- Positive Befunde erhalten:
  - CONTACT FIRE in #17/#18/#19.
  - trusted Window-Handle-Capture.
  - TASK_920-Follow-up-Style ist als erwartete Weltbildquelle belegt.
  - TASK_916-Final-Basis bleibt nachvollziehbar.
- Sichtbefund aus Review-Notizen auswerten:
  - Follow-up-Fire-Lane als erste Weltbewegung.
  - Source-/Target-Anker tragen Richtung.
  - Welt-Fire-Label und Target-Halo bleiben hinter der Lane.
  - Raster-/Weltlinien konkurrieren nicht.
  - Command-Surfaces bleiben bedienbar.
- Ergebnis:
  - `accepted_for_first_exchange_playability_smoke`, wenn Spielerblick akzeptiert ist.
  - `ready_for_followup_world_read_player_polish`, wenn Restreibung belegt ist.
  - `needs_manual_review`, wenn der Sichtbefund fehlt.

## Nicht-Ziele
- Kein Combat-, Movement-, LOS-, Pathfinding- oder HUD-Truth-Rewrite.
- Kein neuer Visual-Polish in diesem Task.
- Kein echter Playability-Smoke-Run.
- Keine neuen Commands, FireEvents, DamageEvents oder Movement-Entscheidungen.
- Keine neue Multiplayer-Wahrheit.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_921_release_first_exchange_followup_world_read_recapture.md`
- `docs/tasks/TASK_920_release_first_exchange_final_world_read_followup_fix.md`
- `docs/tasks/TASK_918_release_first_exchange_final_world_read_visual_findings.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFollowupWorldReadVisualFindings.build_snapshot()` blockt fehlende oder falsche TASK_921-/TASK_920-/TASK_917-/TASK_916-/TASK_918-Metadaten.
- Ein technisch gueltiger TASK_921-Snapshot ohne Review-Notizen bleibt `needs_manual_review`.
- Ein positiver Sichtbefund wird `accepted_for_first_exchange_playability_smoke`.
- Ein negativer Sichtbefund nennt konkrete Issues und empfiehlt keinen Smoke.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.
- Der naechste Schritt wird als Smoke bei Akzeptanz oder als enger TASK_923-Polish bei Restreibung benannt.

## Betroffene Dateien
- `docs/tasks/TASK_922_release_first_exchange_followup_world_read_visual_findings.md`
- `scripts/mission/release_first_exchange_followup_world_read_visual_findings.gd`
- `scripts/tests/task_922_release_first_exchange_followup_world_read_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_922_release_first_exchange_followup_world_read_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_921_release_first_exchange_followup_world_read_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_922 bewertet nur den Follow-up-Fensterblick. Ohne echten Screenshot-Review bleibt der Task bewusst bei `needs_manual_review`. Wenn Restreibung bleibt, muss der naechste Slice eng und beleggebunden bleiben; kein erneutes Oeffnen von Combat- oder HUD-Wahrheit.

## Naechster Schritt
Bei Akzeptanz: TASK_923 - Release First Exchange Playability Smoke.

Bei Restreibung: TASK_923 - Release First Exchange Followup World Read Player Polish.

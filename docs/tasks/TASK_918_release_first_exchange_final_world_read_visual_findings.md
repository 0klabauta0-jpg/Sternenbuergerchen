# TASK_918 - Release First Exchange Final World Read Visual Findings

## Ziel / Problem
TASK_917 stellt den finalen Recapture-Rahmen nach TASK_916 bereit. TASK_918 bewertet daraus den echten Spielerblick read-only: Reicht die Fire-Lane jetzt als erste Weltbewegung fuer einen Playability-Smoke, oder gibt es noch belegte Restreibung?

## Sinnhaftigkeit / Ursache
Der letzte Schritt darf kein weiteres Polieren auf Verdacht sein. Erst muss der Screenshot-/Manifest-Befund sauber in positive Befunde, Blocker, offene Sichtpruefung und echte Akzeptanz getrennt werden.

## Umfang
- TASK_917-Snapshot/Manifest und Review-Notizen read-only bewerten.
- Positive Befunde erhalten: CONTACT FIRE in #17/#18/#19, trusted Window-Handle-Capture, TASK_916-Final-Style, TASK_913-Acceptance-Basis und korrektes Missionsfenster.
- Bei fehlendem Sichtbefund `needs_manual_review` melden.
- Bei akzeptiertem Spielerblick den Playability-Smoke empfehlen.
- Bei Restreibung nur belegte Follow-up-Fixes benennen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands oder Movement-Entscheidungen.
- Keine neue UI-, Contact-, Mission- oder Multiplayer-Wahrheit.
- Kein weiterer Visual-Polish ohne belegten TASK_917-Befund.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_917_release_first_exchange_final_world_read_recapture.md`
- `docs/tasks/TASK_916_release_first_exchange_fire_lane_world_read_final_polish.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFinalWorldReadVisualFindings.build_snapshot()` akzeptiert den TASK_917-Snapshot/Manifest als Quelle.
- Fehlende oder falsche TASK_917-/TASK_916-/TASK_914-Metadaten blocken.
- Ohne manuellen Sichtbefund ist der Status `needs_manual_review`.
- Bei voll akzeptierten Sichtnotizen ist der Status `accepted_for_first_exchange_playability_smoke` und der naechste Task ein Playability-Smoke.
- Bei Restreibung benennt der Snapshot konkrete Issues und empfiehlt nur einen engen Follow-up-Fix.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_918_release_first_exchange_final_world_read_visual_findings.md`
- `scripts/mission/release_first_exchange_final_world_read_visual_findings.gd`
- `scripts/tests/task_918_release_first_exchange_final_world_read_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_918_release_first_exchange_final_world_read_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_917_release_first_exchange_final_world_read_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_918 kann ohne echten TASK_917-Screenshot nur den offenen Review-Status modellieren. Ein Playability-Smoke ist erst sinnvoll, wenn der Spielerblick manuell akzeptiert wurde.

## Naechster Schritt
Bei Akzeptanz: TASK_919 - Release First Exchange Playability Smoke. Bei Restreibung: TASK_919 - Release First Exchange Final World Read Followup Fix.

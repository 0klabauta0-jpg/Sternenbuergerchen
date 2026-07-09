# TASK_919 - Release First Exchange Playability Smoke Gate

## Ziel / Problem
TASK_918 kann den finalen Spielerblick nach TASK_917 akzeptieren oder Restreibung melden. TASK_919 verhindert, dass ein Playability-Smoke gestartet wird, solange TASK_918 nicht wirklich akzeptiert ist.

## Sinnhaftigkeit / Ursache
Ein Smoke-Test ist erst sinnvoll, wenn der erste Feuerwechsel visuell lesbar genug ist. Ohne akzeptierten TASK_918-Befund wuerde ein Smoke dieselbe offene World-Read-Frage nur verdecken. Das Gate macht den naechsten Griff eindeutig: Smoke bei Akzeptanz, Follow-up-Fix bei Restreibung oder fehlendem Sichtbefund.

## Umfang
- TASK_918-Findings-Snapshot read-only bewerten.
- Fehlende/falsche TASK_918-Quelle blocken.
- Bei `accepted_for_first_exchange_playability_smoke` einen Smoke-Run bereit melden.
- Bei `needs_manual_review` oder `ready_for_final_world_read_followup_fix` den Smoke sperren und naechsten Fix/Review benennen.
- Smoke-Pflichtpunkte als Checkliste ausgeben:
  - EXE/Singleplayer startet.
  - Homebase-Direct-Sortie bleibt bedienbar.
  - Dropship/LZ/GO fuehren in die Mission.
  - CONTACT FIRE bleibt in #17/#18/#19 sichtbar.
  - Fire-Lane bleibt erste Weltbewegung.
  - Keine neue Gameplay-Wahrheit im HUD.
  - Keine groben Performance-Spikes im First-Exchange-Slice.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein echter Playability-Smoke-Run in diesem Task.
- Kein Combat-, Movement-, HUD- oder Visual-Polish.
- Keine neuen Commands, FireEvents, DamageEvents oder Gameplay-Mutationen.
- Keine neue Multiplayer-Wahrheit.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_918_release_first_exchange_final_world_read_visual_findings.md`
- `docs/tasks/TASK_917_release_first_exchange_final_world_read_recapture.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangePlayabilitySmokeGate.build_snapshot()` akzeptiert TASK_918 als Quelle.
- Fehlende oder falsche TASK_918-Metadaten blocken.
- `needs_manual_review` blockt den Smoke mit Review-Hinweis.
- `ready_for_final_world_read_followup_fix` blockt den Smoke mit Fix-Hinweis.
- `accepted_for_first_exchange_playability_smoke` meldet `smoke_ready`.
- Der Snapshot bleibt read-only und meldet keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Mutationen.

## Betroffene Dateien
- `docs/tasks/TASK_919_release_first_exchange_playability_smoke_gate.md`
- `scripts/mission/release_first_exchange_playability_smoke_gate.gd`
- `scripts/tests/task_919_release_first_exchange_playability_smoke_gate.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_task910_in_progress_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_919_release_first_exchange_playability_smoke_gate.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_918_release_first_exchange_final_world_read_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_919 ersetzt keinen echten Smoke-Test. Es verhindert nur, dass der Smoke ohne akzeptierten TASK_918-Befund gestartet oder als sinnvoller naechster Schritt behandelt wird.

## Naechster Schritt
Bei `smoke_ready`: TASK_920 - Release First Exchange Playability Smoke Run. Bei Blockade: TASK_920 - Release First Exchange Final World Read Followup Fix oder TASK_920 - Release First Exchange Manual Window Review.

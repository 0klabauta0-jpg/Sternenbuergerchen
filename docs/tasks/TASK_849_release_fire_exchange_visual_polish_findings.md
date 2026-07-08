# TASK_849 - Release Fire Exchange Visual Polish Findings

## Ziel / Problem
TASK_848 hat nach TASK_847 einen frischen Release-Export und echten Fenster-Capture als Acceptance-Paket festgehalten. Der Screenshot ist technisch review-ready, aber der erste Fire-Exchange ist fuer den Spieler noch nicht klar genug lesbar.

Ziel dieses Tasks ist ein enger, read-only Findings-Schnitt fuer den aktuellen Screenshot: Welche sichtbaren Reibungen verhindern, dass der erste Feuerwechsel sofort verstanden wird, und welcher kleine Polish-Task soll daraus folgen?

## Sinnhaftigkeit / Ursache
Der Kopf sagt technisch: Fire-Exchange ist erreichbar und nachweisbar. Das Auge sieht aber vor allem grosses Weltbild, dicke gruen/blaue Linien, ein sichtbares Start-/Automatik-Overlay und keine eindeutig priorisierte FireTrace-/Impact-/CONTACT-FIRE-Botschaft. Das ist ein UI-/Visual-Fokusproblem, kein Grund fuer einen Combat-Rewrite.

## Umfang
- Neuer read-only Analyzer `ReleaseFireExchangeVisualPolishFindings`.
- Auswertung des TASK_848-Acceptance-Manifests plus manueller Screenshot-Notizen.
- Positive Findings:
  - echter Fenster-Screenshot liegt vor
  - Terrain und Einheitengruppe sind grundsaetzlich lesbar
- Offene Findings:
  - `start_overlay_competes_with_combat`
  - `world_lines_dominate_exchange`
  - `fire_trace_or_impact_not_readable`
  - `hud_contact_fire_not_confirmed`
- JSON-Manifest unter `tmp/release_fire_exchange_visual_polish_findings.json`.
- Folgeempfehlung: TASK_850 - Release Fire Exchange Focused Visual Polish.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein automatischer Pixel- oder OCR-Entscheid.
- Keine Aenderung an Movement, Damage, FireEvents, Commands, Contact- oder Multiplayer-Wahrheit.
- Kein Markieren des TASK_848-Acceptance-Reviews als vollstaendig bestanden.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_848_release_first_exchange_recapture_acceptance.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Snapshot nennt Schema `sternenbuergerchen.release_fire_exchange_visual_polish_findings.v1` und `task_id = TASK_849`.
- Snapshot verlinkt `source_task_id = TASK_848`, `source_visibility_task_id = TASK_847` und `source_exchange_task_id = TASK_844`.
- TASK_848-Acceptance mit `ready_for_manual_acceptance`, `review_ready` und vorhandenem Window-Screenshot erzeugt keine technischen Blocker.
- Findings nennen `start_overlay_competes_with_combat`, `world_lines_dominate_exchange`, `fire_trace_or_impact_not_readable` und `hud_contact_fire_not_confirmed`.
- `primary_issue_id = start_overlay_competes_with_combat`.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit, keine Shortcut-Updates.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_visual_polish_findings.gd`
- `scripts/tests/task_849_release_fire_exchange_visual_polish_findings.gd`
- `docs/tasks/TASK_849_release_fire_exchange_visual_polish_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_849_release_fire_exchange_visual_polish_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_848_release_first_exchange_recapture_acceptance.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_849 ist bewusst ein Findings-Task. Die eigentliche sichtbare Verbesserung folgt in TASK_850. Der Befund stammt aus dem aktuellen Screenshot und soll bei einem neuen Capture erneut ueberprueft werden.

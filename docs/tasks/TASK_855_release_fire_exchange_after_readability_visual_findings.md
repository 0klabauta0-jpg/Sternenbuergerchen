# TASK_855 - Release Fire Exchange After Readability Visual Findings

## Ziel / Problem
TASK_854 hat nach TASK_853 einen frischen echten Fenster-Capture erzeugt. Das Paket ist technisch `review_ready`, aber der sichtbare Zustand liest sich weiterhin eher als `CONTACT PRESSURE` / `NO FIRE NO_LOS` statt als klarer `CONTACT FIRE`-Feuerwechsel.

Ziel dieses Tasks ist ein read-only Findings-Schnitt, der diese Reibung klar benennt und den naechsten engen Polish-Slice vorbereitet.

## Sinnhaftigkeit / Ursache
TASK_853 beweist im Headless-/Analyzer-Pfad, dass #17, #18 und #19 fuer aktive Fire-Evidence dieselbe `FIRE`/`CONTACT FIRE`-Lesung tragen koennen. Der echte TASK_854-Fensterblick zeigt aber, dass spaetere aktuelle LOS-/Range-Korrektur weiterhin die primaere Spielerlesung dominiert. Das ist eine Lesbarkeitsluecke zwischen technischer Fire-Evidence und sichtbarem Release-Fenster.

## Umfang
- `ReleaseFireExchangeAfterReadabilityVisualFindings` wertet TASK_854-Recapture und Review-Notizen aus.
- Findings nennen positive Evidence, offene Reibungen und den priorisierten Folge-Task.
- Das Ergebnis wird als `tmp/release_fire_exchange_after_readability_visual_findings.json` exportiert.
- Report, Status, Roadmap und Contract nennen TASK_855 und den naechsten Schritt.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Schoenheitsentscheid.
- Kein UI-Polish in diesem Task; die sichtbare Korrektur folgt in TASK_856.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_854_release_fire_exchange_focused_recapture_after_readability_polish.md`
- `docs/tasks/TASK_853_release_fire_exchange_engagement_readability_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFireExchangeAfterReadabilityVisualFindings.build_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_after_readability_visual_findings.v1` und `task_id = TASK_855`.
- Snapshot verlinkt TASK_854, TASK_853, TASK_851, TASK_850, TASK_847 und TASK_844.
- Snapshot akzeptiert ein `ready_for_manual_acceptance` TASK_854-Manifest mit Screenshotpfad, TASK_853-Style und 45s-Persistenz.
- Pflicht-Findings nennen `after_readability_window_still_contact_pressure`, `primary_hud_no_fire_no_los_visible`, `event_log_not_contact_fire_primary`, `fire_trace_or_impact_not_dominant` und `headless_real_window_gap`.
- Primaerer Folgepunkt ist `primary_hud_no_fire_no_los_visible`.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit, keine Shortcut-Updates.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_after_readability_visual_findings.gd`
- `scripts/tests/task_855_release_fire_exchange_after_readability_visual_findings.gd`
- `docs/tasks/TASK_855_release_fire_exchange_after_readability_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_855_release_fire_exchange_after_readability_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_854_release_fire_exchange_focused_recapture_after_readability_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_855 ist bewusst nur ein Befund. Der naechste sinnvolle Schritt ist TASK_856: den aktiven Release-Fire-Exchange im echten Fenster als primaeren CONTACT-FIRE-Moment stabilisieren, ohne Combat-Wahrheit zu verschieben.

# TASK_852 - Release Fire Exchange Focused Visual Findings

## Ziel / Problem
TASK_851 hat den echten Fensterblick nach TASK_850 neu gecaptured. Das Manifest ist technisch `review_ready`, aber der Screenshot zeigt fuer den Spieler weiterhin eher `CONTACT PRESSURE` / `NO FIRE` als einen eindeutig lesbaren ersten `CONTACT FIRE`-Feuerwechsel.

Ziel dieses Tasks ist ein read-only Findings-Schnitt, der diese Reibung klar benennt und den naechsten engen Polish-Slice vorbereitet.

## Sinnhaftigkeit / Ursache
Die bisherigen Schritte haben Export, Deep-Link, Fire-Exchange-Evidence und Visual-Focus abgesichert. Was noch stoert, ist nicht mehr der allgemeine Pfad, sondern die Spielbarkeit des ersten sichtbaren Kampf-Moments: HUD und Weltbild muessen den Spieler zum Feuerwechsel fuehren, nicht zu Debug-Sprache.

## Umfang
- `ReleaseFireExchangeFocusedVisualFindings` wertet TASK_851-Recapture und Review-Notizen aus.
- Findings nennen positive Evidence, offene Reibungen und den priorisierten Folge-Task.
- Das Ergebnis wird als `tmp/release_fire_exchange_focused_visual_findings.json` exportiert.
- Report, Status, Roadmap und Contract nennen TASK_852 und den naechsten Schritt.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen Commands, FireEvents, DamageEvents, Navigation oder Multiplayer-Wahrheit.
- Kein automatischer Pixel-/OCR-Schoenheitsentscheid.
- Kein UI-Polish in diesem Task; die sichtbare Korrektur folgt in TASK_853.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_851_release_fire_exchange_focused_visual_recapture.md`
- `docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `ReleaseFireExchangeFocusedVisualFindings.build_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_focused_visual_findings.v1` und `task_id = TASK_852`.
- Snapshot verlinkt TASK_851, TASK_850, TASK_847 und TASK_844.
- Snapshot akzeptiert ein `review_ready` TASK_851-Manifest mit Screenshotpfad und TASK_850-Focus-Style.
- Pflicht-Findings nennen `contact_pressure_instead_of_contact_fire`, `debug_no_fire_reason_visible`, `fire_trace_or_impact_still_not_readable` und `hud_exchange_confirmation_missing`.
- Primaerer Folgepunkt ist `contact_pressure_instead_of_contact_fire`.
- Snapshot bleibt read-only: keine Gameplay-Wahrheit, keine Commands, keine FireEvents, keine DamageEvents, keine Multiplayer-Wahrheit, keine Shortcut-Updates.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_focused_visual_findings.gd`
- `scripts/tests/task_852_release_fire_exchange_focused_visual_findings.gd`
- `docs/tasks/TASK_852_release_fire_exchange_focused_visual_findings.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_852_release_fire_exchange_focused_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_851_release_fire_exchange_focused_visual_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_852 ist bewusst nur ein Befund. Der naechste sinnvolle Schritt ist TASK_853: den ersten Release-Fire-Exchange fuer den Spieler sichtbar als Kampf-Moment rahmen, ohne die Simulation oder Combat-Wahrheit zu verschieben.

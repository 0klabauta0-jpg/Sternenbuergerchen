# TASK_646 - Homebase MissionPanel Density Playfeel Review

## Ziel / Problem
Nach TASK_645 ist der Homebase-Return-Block sichtbarer. Jetzt muss geprueft werden, ob das gesamte Homebase-`MissionPanel` mit Briefing, Pre-Mission-Readiness und Follow-up-Block angenehm scanbar bleibt.

## Sinnhaftigkeit / Ursache
Die einzelnen Elemente sind korrekt und read-only. Reibung kann trotzdem entstehen, wenn zu viele kleine Bloecke in einem Panel stehen oder die Reihenfolge nicht mehr sofort lesbar ist. Der naechste Schritt soll daher Dichte und Spielgefuehl messbar machen, bevor weiter visuell geschoben wird.

## Umfang
- Read-only Snapshot fuer MissionPanel-Dichte und Playfeel-Gates.
- Pruefung sichtbarer Sektionen, Reihenfolge, Bounds, Overflow, Textbudget und Follow-up-Block.
- Kleines JSON-Manifest unter `tmp/` fuer den aktuellen Reviewstand.
- Status, Roadmap, Contract und HTML-Berichte aktualisieren.

## Nicht-Ziele
- Kein neuer Homebase-Flow.
- Kein neuer Start-/Navigation-Command.
- Keine Progression-, MissionResult-, Staging- oder Gameplay-Mutation.
- Kein Rework des gesamten Homebase-Layouts.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_645_frontier_probe_homebase_summary_next_sortie_polish.md`
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Snapshot `get_homebase_missionpanel_density_playfeel_snapshot()` existiert und bleibt read-only.
- MissionPanel, Briefing, Readiness und Follow-up-Block sind sichtbar und innerhalb der Panel-Grenzen.
- Reihenfolge bleibt: Briefing -> Readiness -> Follow-up.
- MissionPanel laeuft nicht ueber; sichtbare Text-/Sektion-/Fuellungswerte werden als Gate oder Warning festgehalten.
- Verifier erzeugt ein lokales Manifest und empfiehlt nur bei belegter Reibung einen echten Runtime-Layout-Fix.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_646_homebase_missionpanel_density_playfeel_review.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_646_homebase_missionpanel_density_playfeel_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_645_frontier_probe_homebase_summary_next_sortie_polish.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task ist ein Dichte-/Review-Gate, kein finaler menschlicher Geschmackstest. Wenn das echte Fenster trotz gruenem Snapshot zu eng wirkt, muss ein separater Layout-Polish mit konkretem Befund folgen.

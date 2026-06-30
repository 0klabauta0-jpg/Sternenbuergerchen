# TASK_645 - Frontier Probe Homebase Summary Next Sortie Polish

## Ziel / Problem
Der echte TASK_644-Homebase-Fensterblick zeigt, dass Post-Debrief-Summary und Next-Sortie-Readiness technisch korrekt, aber visuell zu leise sind. Der Spieler soll nach dem Return sofort erkennen: Ergebnis ist angekommen, Homebase ist wieder aktiv, und der naechste sinnvolle Schritt ist sichtbar.

## Sinnhaftigkeit / Ursache
Die Datenkette ist bereits sauber: Debrief -> Homebase -> Summary/Readiness bleibt read-only und erzeugt keine Commands. Die Reibung liegt im Layout: zwei kleine Labels stehen am Ende des MissionPanel ohne eigenen visuellen Anker.

## Umfang
- Bestehende Summary- und Next-Sortie-Labels in einen kleinen Follow-up-Panelblock setzen.
- Fontgroesse, Mindesthoehe, Farben und Panel-Stil so anheben, dass der Block im echten Fenster lesbarer ist.
- Visible-Readiness-Snapshot um Follow-up-Panel- und Emphasis-Daten erweitern.
- Einen engen Verifier fuer TASK_645 hinzufuegen.
- Status, Roadmap, Contract und HTML-Berichte aktualisieren.

## Nicht-Ziele
- Keine neue Homebase-Navigation.
- Kein neuer Startbutton-Commit.
- Keine Progression-, MissionResult-, Staging- oder Gameplay-Mutation.
- Kein Rework des gesamten Homebase-Layouts.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_642_frontier_probe_homebase_visible_readiness_review.md`
- `docs/tasks/TASK_644_frontier_probe_homebase_real_window_review.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Post-Debrief-Summary und Next-Sortie-Zeile bleiben sichtbar und behalten ihre read-only Texte.
- Beide Labels liegen in einem sichtbaren Follow-up-Panel innerhalb des MissionPanel.
- Der Follow-up-Block hat eine pruefbare Style-ID, Emphasis-Metadaten und groessere Fonts als vorher.
- Existing TASK_642/TASK_644-Gates fuer Sichtbarkeit, Reihenfolge, Overflow und Read-only bleiben gruen.

## Betroffene Dateien
- `scripts/meta/homebase_screen.gd`
- `scripts/tests/task_645_frontier_probe_homebase_summary_next_sortie_polish.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `docs/reports/project_status_handbook_2026_06_29.html`
- `docs/reports/project_state_handbook_2026_06_30.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_645_frontier_probe_homebase_summary_next_sortie_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_644_frontier_probe_homebase_real_window_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_642_frontier_probe_homebase_visible_readiness_review.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Block verbessert Lesbarkeit, ersetzt aber keinen abschliessenden menschlichen Geschmackstest im echten Fenster. Wenn der Homebase-Blick danach immer noch zu voll wirkt, sollte der naechste Task ein breiterer Homebase-MissionPanel-Density-Pass sein.

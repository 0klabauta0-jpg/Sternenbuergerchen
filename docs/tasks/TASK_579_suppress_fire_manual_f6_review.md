# TASK_579 - Suppress Fire Manual F6 Review

## Ziel / Problem
TASK_578 macht die `SUP AREA`-Preview im Primary3D-/F6-Blick als eigene transparente Flaeche sichtbar. Ob Farbe, Alpha, Groesse, Ueberdeckung und Statussprache im echten Spielbild angenehm lesbar sind, braucht aber weiterhin einen menschlichen F6-Sichtcheck.

## Sinnhaftigkeit / Ursache
Die automatische Evidence kann zaehlen, dass `suppress_area_v1` gerendert wird. Sie kann nicht sicher bewerten, ob die Flaeche im FullHD-Spielgefuehl zu laut, zu schwach, zu gross oder mit HUD/Threat-Lines unruhig ist. Der laufende HTML-Zwischenbericht soll diesen Befund exportierbar aufnehmen, damit daraus ein kleiner belegter Folge-Polish entstehen kann.

## Umfang
- HTML-Zwischenbericht um einen `TASK_579`-Notizblock fuer den echten F6-Sichtreview erweitern.
- Exportfelder fuer Screenshotpfad, Viewport, Visual-Key, Pflichtchecks, Farbe/Alpha, Groesse/Ueberdeckung, Statussprache und naechste Prioritaet bereitstellen.
- Contract festhalten: Der Review ist read-only und erzeugt keine Gameplay-Wahrheit.
- Statischen Verifier fuer Doku-/Report-Wiring ergaenzen.

## Nicht-Ziele
- Keine Aenderung an `suppress_area_v1`-Rendering.
- Keine echte Suppression-Wirkung.
- Kein Ammo-Verbrauch.
- Kein Combat-/Movement-Commit.
- Kein automatischer Geschmacksentscheid ueber Farbe, Alpha oder Groesse.

## Relevante Contracts / Dokumente
- `docs/tasks/TASK_578_suppress_fire_visual_polish_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/dev/html_report_workbench_contract.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der HTML-Zwischenbericht nennt TASK_579 als erledigten Manual-F6-Review-Block und TASK_580 als naechsten Tuning-Folgepunkt.
- Der Bericht exportiert Screenshot-/Viewport-/Rating-/Notizfelder fuer den SUP-Area-Sichtcheck.
- Der Bericht behauptet nicht, dass der manuelle Screenshot bereits erledigt ist.
- Der JSON-Export nennt TASK_580 als naechsten sinnvollen Anschluss.
- Der Verifier prueft Task, Status, Roadmap, Contract, Reportfelder und vorhandenen TASK_578-Verifier.

## Betroffene Dateien
- `docs/tasks/TASK_579_suppress_fire_manual_f6_review.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`
- `scripts/tests/task_579_suppress_fire_manual_f6_review.gd`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_579_suppress_fire_manual_f6_review.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_578_suppress_fire_visual_polish_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Block sammelt manuelle Notizen, wendet aber noch kein visuelles Tuning an.
- Die echte Bewertung haengt weiter vom F6-Screenshot oder Playtest im sichtbaren Fenster ab.
- TASK_580 sollte nur konkrete, belegte Lesbarkeitsfindings anwenden.

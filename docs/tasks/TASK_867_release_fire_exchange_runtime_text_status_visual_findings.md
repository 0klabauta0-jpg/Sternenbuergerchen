# TASK_867 - Release Fire Exchange Runtime Text Status Visual Findings

## Ziel / Problem
TASK_866 hat nach der TASK_865-Zeitbasis-Korrektur einen frischen echten Release-Fenster-Capture erzeugt. Der Capture ist technisch `review_ready`, zeigt im Fenster aber weiter nicht die erwartete CONTACT-FIRE-Erstlesung.

Sichtbefund: #17 Selected Fireteam und #18 Mission Control beginnen weiter mit `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`; #19 Event Log zeigt `CONTACT PRESSURE: Position korrigieren`.

## Sinnhaftigkeit / Ursache
Nach mehreren HUD-/Runtime-Text-Polishes ist der wiederholte reale Befund wichtig: Wenn der Combat-Readout ehrlich `NO_LOS` meldet, darf CONTACT FIRE nicht einfach als UI-Text erzwungen werden. Der naechste sinnvolle Schritt muss klaeren, ob der Release-First-Exchange ein echtes LOS-/FireEvent-Setup braucht oder ob die korrekte Spielerlesung hier CONTACT PRESSURE ist.

## Umfang
- TASK_866-Capture als read-only Findings-Snapshot auswerten.
- Positive Befunde und Restreibungen trennen.
- Den primaeren Folgepunkt benennen: First-Exchange-LOS-/Szenario-Setup statt weiterer HUD-Textzwang.
- Doku, Roadmap, Status und Zwischenbericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Keine UI-Text-Aenderung in diesem Task.
- Kein neuer Release-Capture in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_866_release_fire_exchange_runtime_text_status_recapture.md`
- `docs/tasks/TASK_865_release_fire_exchange_runtime_text_visible_status_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- Snapshot akzeptiert TASK_866 als Quelle.
- Snapshot haelt den belegten NO_LOS-/CONTACT-PRESSURE-Fensterbefund fest.
- Snapshot empfiehlt keinen weiteren blinden HUD-Override.
- Snapshot empfiehlt TASK_868 fuer ein First-Exchange-LOS-/Scenario-Setup-Polish.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_fire_exchange_runtime_text_status_visual_findings.gd`
- `scripts/tests/task_867_release_fire_exchange_runtime_text_status_visual_findings.gd`
- `docs/tasks/TASK_867_release_fire_exchange_runtime_text_status_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_867_release_fire_exchange_runtime_text_status_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_866_release_fire_exchange_runtime_text_status_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_867 ist ein Findings-Schnitt. Die eigentliche Spielverbesserung folgt in TASK_868: Entweder muss das Release-First-Exchange-Szenario echte LOS-/FireEvent-Evidence liefern, oder die UX-Erwartung wird auf CONTACT PRESSURE als ehrlichen Zwischenzustand umgestellt.

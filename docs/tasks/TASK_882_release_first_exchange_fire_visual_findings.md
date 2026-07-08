# TASK_882 - Release First Exchange Fire Visual Findings

## Ziel / Problem
TASK_881 hat nach TASK_880 einen frischen echten Window-Handle-Capture erzeugt. Der Capture ist technisch `review_ready`, trusted und zeigt das korrekte Sternenbuergerchen-Missionsfenster. Der sichtbare Spielerblick ist aber noch nicht ueberzeugend: #17 und #18 lesen weiter zuerst `NEXT LOS/RANGE KORRIGIEREN` / `Kampf NO FIRE NO_LOS`, #19 zeigt weiter `CONTACT PRESSURE`.

## Sinnhaftigkeit / Ursache
TASK_879 beweist, dass die CONTACT-FIRE-Statusquelle im finalen Export-Trace ankommt. TASK_880 hebt FireTrace, Impact und Target-Fokus headless an. TASK_881 beweist den echten Fensterblick nach diesem Polish. Die Reibung liegt damit nicht mehr bei fehlender Trace-Evidence, sondern in der Differenz zwischen finalem Trace und sichtbarer Echtfenster-Erstlesung.

TASK_882 haelt diesen Befund read-only fest, damit der naechste Fix gezielt die real sichtbaren HUD-/Event-Log-Quellen synchronisiert, statt blind weitere VFX- oder Text-Priorisierungen aufzubauen.

## Umfang
- TASK_881-Manifest als Quelle auswerten.
- Positive Evidence festhalten: trusted Window-Handle-Capture, korrektes Missionsfenster, Runtime-Trace-Aktivierung, keine finale Trace-NO_LOS-/CONTACT-PRESSURE-Ueberschreibung, sichtbare Command-Surfaces.
- Sichtbefund festhalten: #17/#18 weiter NO_LOS-first, #19 weiter CONTACT PRESSURE, CONTACT FIRE nicht als Fenster-Erstlesung.
- Primaere Reibung benennen: TASK_880-Fire-Visual-Polish wird im echten Fenster nicht zur CONTACT-FIRE-Erstlesung.
- Naechste Richtung benennen: Real-Window-HUD-/Event-Log-Source-Sync gegen den finalen Trace-Stand.
- Doku, Roadmap, Status, Contract und HTML-Zwischenbericht synchronisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Kein weiterer FireTrace-/Impact-Tuningwert in diesem Task.
- Kein HUD-Text-Override ohne belegten Source-Sync.
- Keine neue Movement-, FireEvent-, Damage-, Contact-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Export in diesem Task.
- Keine Shortcut-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_881_release_first_exchange_fire_visual_recapture.md`
- `docs/tasks/TASK_880_release_first_exchange_fire_visual_polish.md`
- `docs/tasks/TASK_879_release_first_exchange_exported_status_source_trace.md`

## Akzeptanzkriterien
- Findings-Snapshot akzeptiert TASK_881 als Quelle.
- Snapshot unterscheidet positive technische Evidence von verbleibender CONTACT-FIRE-Lesbarkeitsreibung.
- Snapshot benennt `task_880_fire_visual_not_real_window_first_reading` als primaere Reibung.
- Snapshot benennt #17/#18/#19-spezifische Restprobleme und das nicht sichtbare CONTACT-FIRE-/FireTrace-/Impact-Lesen.
- Snapshot empfiehlt TASK_883 fuer Real-Window-HUD-/Event-Log-Source-Sync.
- Snapshot bleibt read-only und erzeugt keine Gameplay-Wahrheit.

## Betroffene Dateien
- `scripts/mission/release_first_exchange_fire_visual_findings.gd`
- `scripts/tests/task_882_release_first_exchange_fire_visual_findings.gd`
- `docs/tasks/TASK_882_release_first_exchange_fire_visual_findings.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_882_release_first_exchange_fire_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_881_release_first_exchange_fire_visual_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_882 aendert keine Runtime. Der naechste sinnvolle Fix ist TASK_883: Im echten Fenster muessen #17 Selected Fireteam, #18 Mission Control und #19 Event Log beim First-Exchange denselben finalen CONTACT-FIRE-Stand lesen, den TASK_879 im Runtime-Trace bereits belegt, ohne dabei neue Gameplay-Wahrheit im HUD zu erzeugen.

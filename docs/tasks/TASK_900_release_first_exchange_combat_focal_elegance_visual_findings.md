# TASK_900 - Release First Exchange Combat Focal Elegance Visual Findings

## Ziel / Problem
TASK_899 hat einen echten Window-Handle-Screenshot nach TASK_898 erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort weitere Visual-, Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
CONTACT FIRE ist im echten Fenster in #17 Selected Fireteam, #18 Mission Control und #19 Event Log sichtbar. Die TASK_898-Focal-Elegance macht Lane, Source-Glow und Target-Halo weicher als zuvor. Der verbleibende Engpass ist nicht fehlende Wahrheit, sondern Release-Lesbarkeit: Der Target-Halo liest noch zu markerhaft, die Welt-/Grid-Dichte konkurriert weiter, und die Source-to-target-Beziehung ist noch nicht elegant genug.

## Umfang
- TASK_899-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: trusted Window-Handle-Capture, CONTACT FIRE in #17/#18/#19, Event Log sichtbar, FIRE-/Focal-Signale im Weltbild, Command-Surfaces weiter nutzbar.
- Restreibung konkret benennen: Target-Halo noch zu gross/markerhaft, Grid-/World-Noise konkurriert, Source-to-target-Beziehung noch nicht elegant genug.
- Konkreten Folge-Task vorschlagen, ohne Combat-, Damage-, Movement-, Contact-, UI- oder Multiplayer-Wahrheit anzufassen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Visual-Polish in diesem Task.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture.
- Kein automatisches Release-Akzeptieren nur wegen sichtbarem CONTACT FIRE.
- Keine Shortcut-/Taskleisten-Aenderung.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_899_release_first_exchange_combat_focal_elegance_real_window_recapture.md`
- `docs/tasks/TASK_898_release_first_exchange_combat_focal_elegance_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeCombatFocalEleganceVisualFindings.build_snapshot()` akzeptiert das TASK_899-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und sichtbare Focal-Elegance-Signale im Weltbild.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Halo, Grid-Noise oder Source-to-target-Bezug noch zu technisch wirken.
- Der Snapshot empfiehlt einen engen Folge-Task fuer Marker-Skalierung und World-Noise-Polish, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_900_release_first_exchange_combat_focal_elegance_visual_findings.md`
- `scripts/mission/release_first_exchange_combat_focal_elegance_visual_findings.gd`
- `scripts/tests/task_900_release_first_exchange_combat_focal_elegance_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_900_release_first_exchange_combat_focal_elegance_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_899_release_first_exchange_combat_focal_elegance_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_900 bewertet nur. Der naechste Visual-Polish muss eng bleiben: Halo/Fire-Marker und Grid-/World-Noise ruhiger machen, ohne neue Combat- oder HUD-Wahrheit zu bauen.

## Naechster Schritt
TASK_901 - Release First Exchange Combat Marker Scale And World Noise Polish.

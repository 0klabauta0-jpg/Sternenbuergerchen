# TASK_903 - Release First Exchange Combat Marker Scale Visual Findings

## Ziel / Problem
TASK_902 hat nach TASK_901 einen echten Window-Handle-Capture erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort weitere Visual-, Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
Der echte TASK_902-Fensterblick bestaetigt CONTACT FIRE in #17/#18/#19 und zeigt, dass Target-Halo und World-Noise ruhiger wirken als vor TASK_901. Der verbleibende Engpass ist die erste Weltlesung der Schussbahn: FIRE/CONTACT-Marker sind sichtbar, aber die Source-to-target-Beziehung liest sich noch nicht stark genug als elegante Kampfbewegung.

## Umfang
- TASK_902-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: trusted Window-Handle-Capture, CONTACT FIRE in #17/#18/#19, Event Log sichtbar, kleinerer Halo, ruhigeres Grid/World-Noise, Command-Surfaces weiter nutzbar.
- Restreibung konkret benennen: Fire-Lane/Schussbahn noch zu subtil, CONTACT-Marker-Cluster zieht Aufmerksamkeit, Bottom-HUD bleibt dicht.
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
- `docs/tasks/TASK_902_release_first_exchange_combat_marker_scale_real_window_recapture.md`
- `docs/tasks/TASK_901_release_first_exchange_combat_marker_scale_world_noise_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeCombatMarkerScaleVisualFindings.build_snapshot()` akzeptiert das TASK_902-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und den sichtbaren TASK_901-Marker-/World-Noise-Polish.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Fire-Lane/Schussbahn, CONTACT-Marker-Cluster oder Bottom-HUD-Dichte noch sichtbar stören.
- Der Snapshot empfiehlt einen engen Folge-Task fuer Fire-Lane-/Source-to-target-Lesbarkeit, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_903_release_first_exchange_combat_marker_scale_visual_findings.md`
- `scripts/mission/release_first_exchange_combat_marker_scale_visual_findings.gd`
- `scripts/tests/task_903_release_first_exchange_combat_marker_scale_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09_aktuell.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_903_release_first_exchange_combat_marker_scale_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_902_release_first_exchange_combat_marker_scale_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_903 bewertet nur. Der naechste Polish muss eng bleiben: Schussbahn/Fire-Lane klarer machen, ohne erneut mehr CONTACT-FIRE-Text oder Combat-Logik zu bauen.

## Naechster Schritt
TASK_904 - Release First Exchange Fire Lane Readability Polish.

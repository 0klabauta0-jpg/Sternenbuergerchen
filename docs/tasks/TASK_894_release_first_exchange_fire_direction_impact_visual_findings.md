# TASK_894 - Release First Exchange Fire Direction Impact Visual Findings

## Ziel / Problem
TASK_893 hat den echten Window-Handle-Screenshot nach TASK_892 erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort wieder HUD-, Combat- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
CONTACT FIRE ist im echten Fenster in #17 Selected Fireteam, #18 Mission Control und #19 Event Log sichtbar. Der verbleibende Engpass ist visuelle Hierarchie im Weltbild: FIRE/Impact ist sichtbar, aber Quelle -> Schussrichtung -> Ziel -> Treffer muss noch schneller und schicker lesbar werden.

## Umfang
- TASK_893-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: CONTACT FIRE in #17/#18/#19, Event Log sichtbar, FIRE-/Impact-Fokus im Weltbild, Command-Surfaces weiter bedienbar.
- Restreibung konkret benennen: Source-to-target trace noch nicht stark genug, Impact/Target-Fokus konkurriert mit Raster/Weltinhalt, Bottom-HUD bleibt dicht.
- Konkreten Folge-Task vorschlagen, ohne Combat-, Damage-, Movement-, Contact-, UI- oder Multiplayer-Wahrheit anzufassen.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Movement-, Command-, UI- oder Multiplayer-Wahrheit.
- Kein neuer Capture.
- Kein automatisches Release-Akzeptieren nur wegen sichtbarem CONTACT FIRE.
- Kein Editor-/Mapbuilder-Polish.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_893_release_first_exchange_fire_direction_impact_real_window_recapture.md`
- `docs/tasks/TASK_892_release_first_exchange_fire_direction_impact_clarity_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeFireDirectionImpactVisualFindings.build_snapshot()` akzeptiert das TASK_893-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und sichtbare FIRE-/Impact-Signale im Weltbild.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Quelle-Ziel-Linie, Target-Fokus und Welt-Hierarchie nicht sofort lesbar sind.
- Der Snapshot empfiehlt einen engen Folge-Task fuer Weltkampf-Fokus/Source-to-target-Hierarchie, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_894_release_first_exchange_fire_direction_impact_visual_findings.md`
- `scripts/mission/release_first_exchange_fire_direction_impact_visual_findings.gd`
- `scripts/tests/task_894_release_first_exchange_fire_direction_impact_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_894_release_first_exchange_fire_direction_impact_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_893_release_first_exchange_fire_direction_impact_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_894 bewertet nur. Der naechste Visual-Polish muss eng bleiben: Weltkampf-Fokus, Source-to-target-Hierarchie und Raster-/HUD-Konkurrenz reduzieren, ohne neue Combat- oder HUD-Wahrheit zu bauen.

## Naechster Schritt
TASK_895 - Release First Exchange World Combat Focal Hierarchy Polish.

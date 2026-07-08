# TASK_897 - Release First Exchange World Combat Focal Visual Findings

## Ziel / Problem
TASK_896 hat einen echten Window-Handle-Screenshot nach TASK_895 erzeugt. Der Screenshot muss jetzt als Spielerblick bewertet werden, ohne sofort wieder Combat-, HUD- oder Damage-Wahrheit zu veraendern.

## Sinnhaftigkeit / Ursache
CONTACT FIRE ist im echten Fenster in #17 Selected Fireteam, #18 Mission Control und #19 Event Log sichtbar. Der TASK_895-Fokus macht den Feuerbereich praesenter. Der verbleibende Engpass ist jetzt visuelle Eleganz und Beziehungsklarheit: Source-Glow, Target-Halo und Lane sind da, lesen sich aber noch nicht sauber genug als ein schicker Feuerwechsel.

## Umfang
- TASK_896-Manifest und PNG-Befund read-only auswerten.
- Positive Befunde festhalten: CONTACT FIRE in #17/#18/#19, Event Log sichtbar, FIRE-/Focal-Signale im Weltbild, Command-Surfaces weiter nutzbar.
- Restreibung konkret benennen: Source-to-target-Lane noch nicht elegant genug, Target-Halo wirkt noch debughaft/gross, Raster und Bottom-HUD konkurrieren weiter.
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
- `docs/tasks/TASK_896_release_first_exchange_world_combat_focal_real_window_recapture.md`
- `docs/tasks/TASK_895_release_first_exchange_world_combat_focal_hierarchy_polish.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Akzeptanzkriterien
- `ReleaseFirstExchangeWorldCombatFocalVisualFindings.build_snapshot()` akzeptiert das TASK_896-Manifest als Quelle.
- Der Snapshot meldet positive Befunde fuer CONTACT FIRE in #17/#18/#19 und sichtbare Focal-Signale im Weltbild.
- Der Snapshot markiert den Befund nicht als voll akzeptiert, solange Lane/Halo/Source-Bezug noch debughaft oder nicht sofort lesbar wirken.
- Der Snapshot empfiehlt einen engen Folge-Task fuer visuelle Kampfeleganz, nicht erneute Combat-Wahrheit.
- Der Verifier prueft read-only-Grenzen: keine Commands, FireEvents, DamageEvents, Movement-, Shortcut- oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `docs/tasks/TASK_897_release_first_exchange_world_combat_focal_visual_findings.md`
- `scripts/mission/release_first_exchange_world_combat_focal_visual_findings.gd`
- `scripts/tests/task_897_release_first_exchange_world_combat_focal_visual_findings.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/spielstand_zwischenbericht_2026_07_09.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_897_release_first_exchange_world_combat_focal_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_896_release_first_exchange_world_combat_focal_real_window_recapture.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_897 bewertet nur. Der naechste Visual-Polish muss eng bleiben: Weltkampf-Fokus eleganter und weniger debughaft machen, ohne neue Combat- oder HUD-Wahrheit zu bauen.

## Naechster Schritt
TASK_898 - Release First Exchange Combat Focal Elegance Polish.

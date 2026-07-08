# TASK_856 - Release Fire Exchange Contact-Fire Primary HUD Polish

## Ziel / Problem
TASK_855 belegt, dass der echte TASK_854-Fensterblick trotz Fire-Exchange-Evidence weiter als `CONTACT PRESSURE` / `NO FIRE NO_LOS` gelesen wird. Der Spieler soll im aktiven Release-Fire-Exchange-Fenster zuerst `CONTACT FIRE` lesen, nicht einen spaeteren LOS-/Range-Korrekturgrund.

## Sinnhaftigkeit / Ursache
Die vorhandene FireEvent-/Visibility-Persistence-Evidence ist technisch vorhanden und read-only. Die sichtbaren Primaerzeilen koennen aber weiterhin aus aktuellen Contact-Decision-Diagnostics stammen. Dadurch ueberdeckt ein spaeteres `NO FIRE` den eigentlichen ersten Feuerwechsel.

## Umfang
- #17 Selected Fireteam und #18 Mission Control erhalten bei aktiver Release-Fire-Exchange-Persistenz eine gemeinsame Primaerzeile `CONTACT FIRE | ...`.
- Der alte LOS-/Range-/NO-FIRE-Grund bleibt in Detaildiagnostik und Tooltip erreichbar, aber nicht als erste Spielerlesung.
- Ein read-only TASK_856-Snapshot prueft die Primaerzeilen, die gemeinsame Fire-Evidence und die Architekturgrenzen.
- Report, Roadmap, Status und Contract nennen TASK_856 und den naechsten sinnvollen Recapture-Schritt.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neuen FireEvents, DamageEvents, Commands, Navigation oder Multiplayer-Wahrheit.
- Kein neuer Event-Log-Mechanismus.
- Kein Pixel-/OCR-Review; ein echter Recapture bleibt Folgearbeit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_855_release_fire_exchange_after_readability_visual_findings.md`
- `docs/tasks/TASK_853_release_fire_exchange_engagement_readability_polish.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Akzeptanzkriterien
- `get_release_fire_exchange_contact_fire_primary_hud_polish_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_contact_fire_primary_hud_polish.v1` und `task_id = TASK_856`.
- Bei aktiver Persistence beginnt die Primaerzeile mit `CONTACT FIRE`.
- #17 Selected Fireteam und #18 Mission Control enthalten dieselbe `CONTACT FIRE`-Primaerzeile.
- `primary_lines_contain_debug_no_fire_before_contact_fire = false`.
- Das zugrunde liegende `combat_hud_density.visibility_persistence_active` bleibt die Quelle; UI erzeugt keine FireEvents und keine Gameplay-Wahrheit.
- Der Snapshot nennt TASK_857 als naechsten Recapture-/Sichtreview-Schritt.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/mission/release_fire_exchange_contact_fire_primary_hud_polish.gd`
- `scripts/tests/task_856_release_fire_exchange_contact_fire_primary_hud_polish.gd`
- `docs/tasks/TASK_856_release_fire_exchange_contact_fire_primary_hud_polish.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`
- `docs/reports/spielstand_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_856_release_fire_exchange_contact_fire_primary_hud_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_855_release_fire_exchange_after_readability_visual_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
TASK_856 haertet die sichtbare Primaerlesung im Runtime-/HUD-Pfad. Der echte Fensterbeweis braucht danach TASK_857 als frischen Recapture, damit die Screenshot-Wirkung nicht nur aus Headless-/Snapshot-Gates abgeleitet wird.

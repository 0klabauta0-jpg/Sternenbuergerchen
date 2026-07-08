# TASK_853 - Release Fire Exchange Engagement Readability Polish

## Ziel / Problem
Der TASK_851-Fensterblick ist technisch sauber, aber der erste sichtbare Kampfkontakt liest sich fuer Spieler noch als `CONTACT PRESSURE` / `NO FIRE` statt als klarer Feuerwechsel.

## Sinnhaftigkeit / Ursache
Der echte FireEvent existiert bereits, aber die Anzeige-Persistenz des Release-Fire-Exchange ist fuer den spaeten Real-Window-Capture zu kurz und spaetere Debug-Diagnostik kann wieder in den primaeren HUD-Zeilen landen.

## Umfang
- Das vorhandene Release-Fire-Exchange-Anzeigefenster wird laenger gehalten.
- #17 Selected Fireteam, #18 Mission Control und #19 Event Log werden ueber einen separaten read-only Analyzer auf denselben `CONTACT FIRE`/`FIRE`-Status geprueft.
- Debug-`NO FIRE` darf Detaildiagnostik bleiben, aber nicht die primaere Release-Lesung waehrend aktiver Fire-Evidence.

## Nicht-Ziele
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage-, Contact-, Command- oder Multiplayer-Wahrheit.
- Keine neue Mission- oder KI-Logik.
- Kein neuer Screenshot-Capture in diesem Task.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_852_release_fire_exchange_focused_visual_findings.md`
- `docs/tasks/TASK_850_release_fire_exchange_focused_visual_polish.md`
- `docs/tasks/TASK_847_release_fire_exchange_visibility_persistence.md`

## Akzeptanzkriterien
- `ReleaseFireExchangeEngagementReadabilityPolish.build_snapshot()` meldet Schema `sternenbuergerchen.release_fire_exchange_engagement_readability_polish.v1` und `task_id = TASK_853`.
- Die Release-Fire-Exchange-Persistenz reicht fuer den bekannten echten 32s-Capture.
- #17, #18 und #19 zeigen im aktiven Exchange-Fenster dieselbe FIRE-/CONTACT-FIRE-Lesung.
- Primaere sichtbare Zeilen enthalten waehrend aktiver Fire-Evidence kein `NO FIRE`.
- Snapshot bleibt read-only und erzeugt keine Commands, FireEvents, DamageEvents oder Multiplayer-Wahrheit.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/mission/release_fire_exchange_engagement_readability_polish.gd`
- `scripts/tests/task_853_release_fire_exchange_engagement_readability_polish.gd`
- `docs/tasks/TASK_853_release_fire_exchange_engagement_readability_polish.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/release_first_exchange_zwischenbericht_2026_07_08.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_853_release_fire_exchange_engagement_readability_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_852_release_fire_exchange_focused_visual_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_850_release_fire_exchange_focused_visual_polish.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_847_release_fire_exchange_visibility_persistence.gd`
- `git diff --check`

## Risiken / offene Punkte
Der Task verbessert den automatischen HUD-/Analyzer-Beleg. Ein frischer echter Fenster-Recapture bleibt danach sinnvoll, um die menschliche Bildwirkung nach der laengeren Persistenz zu bestaetigen.

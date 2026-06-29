# TASK_548 - Combat HUD Visual Detail Tooltip Pass

## Ziel / Problem
TASK_546 und TASK_547 machen die Combat-HUD-Zeile kompakt und multi-fireteam-konsistent. Dadurch bleibt das HUD lesbar, aber die kurzen Tokens wie `COV`, `RNG`, `LOS` und `FLK` brauchen bei Bedarf eine knappe Erklaerung.

Ziel ist ein Detail-/Tooltip-Pass: Die HUD-Zeile bleibt kurz, aber #17 Selected Fireteam und #18 Mission Control bekommen denselben read-only Detailtext aus bestehenden ContactDecision-, Cover- und FireEvent-Snapshots.

## Sinnhaftigkeit / Ursache
Kompakte Kampfzeilen sind im Spielbild angenehmer, koennen aber ohne Kontext wie Debug-Kuerzel wirken. Ein Tooltip/Detail-Snapshot erklaert die Gruende, ohne das Panel wieder vollzuschreiben.

## Umfang
- Combat-HUD-Density bleibt unveraendert kurz.
- Ein Detail-Snapshot liefert Tooltip-Text und Detailzeilen.
- #17 Selected Fireteam und #18 Mission Control bekommen denselben Combat-Tooltip.
- Der Tooltip nennt Fire-State, Angreifer/Ziel, Waffe/Outcome falls vorhanden sowie Cover, Range, LOS und Flank-Kontext.
- Der Tooltip bleibt read-only und erzeugt keine Combat- oder Damage-Entscheidung.

## Nicht-Ziele
- Kein neues Popup-System.
- Kein Combat-Rewrite.
- Keine neue FireEvent-, Damage- oder Contact-Entscheidung.
- Kein manueller F6-/Screenshot-Sichttest.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_548_combat_hud_visual_detail_tooltip_pass.md`
- `docs/tasks/TASK_547_multi_fireteam_combat_hud_consistency_smoke.md`
- `docs/tasks/TASK_546_mission_combat_feedback_hud_density_polish.md`

## Akzeptanzkriterien
- `get_combat_hud_visual_detail_tooltip_snapshot()` ist read-only und setzt keine UI-Gameplay-Wahrheit.
- Die kompakte Combat-HUD-Zeile bleibt innerhalb des TASK_546-Zeichenbudgets.
- Tooltip-Text ist vorhanden, aber kurz genug fuer HUD-Nutzung.
- Tooltip-Details enthalten Fire-State, Cover, Range, LOS und Flank.
- #17 und #18 haben denselben Tooltip-Text.
- Der TASK_548-Smoke laeuft gruen.

## Betroffene Dateien
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_548_combat_hud_visual_detail_tooltip_pass.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_547_multi_fireteam_combat_hud_consistency_smoke.gd`
- `git diff --check`

## Risiken / offene Punkte
- Der Task prueft Headless-Snapshots und Control-Tooltips, keinen menschlichen Pixel-Sichttest.
- Ein spaeterer sichtbarer Popup- oder Hover-Style kann auf diesem Snapshot aufbauen, ist aber nicht Teil dieses Tasks.

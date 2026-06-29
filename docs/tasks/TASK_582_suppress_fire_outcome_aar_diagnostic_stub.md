# TASK_582 - Suppress Fire Outcome AAR Diagnostic Stub

## Ziel / Problem
TASK_581 macht `SUP` im Combat-Outcome als `suppress_pressure_intent` sichtbar. Es fehlt noch ein kleiner, zaehlbarer Debug-/AAR-Anker: Wenn ein SUP-Kontaktentscheid wirklich feuert, soll dieser Outcome messbar sein, ohne daraus bereits ein grosses After-Action-, Ammo- oder Suppression-System zu bauen.

## Sinnhaftigkeit / Ursache
Spaeter soll der Spieler im Debriefing verstehen koennen, ob Fireteams Unterdrueckungsfeuer geplant und tatsaechlich als Druckabsicht eingesetzt haben. Dafuer braucht der Missionspfad zuerst eine stabile read-only Kennzahl. Dieser Task speichert keine neue Gameplay-Wahrheit, sondern zaehlt nur deduplizierte, bereits autoritativ entstandene Contact-Decision-Diagnostics.

## Umfang
- `MissionCombatLoopDriver` erfasst deduplizierte SUP-Outcome-Diagnostics fuer echte `fired`-Kontaktentscheide.
- Die Diagnose enthaelt Count, Count pro Fireteam und den letzten SUP-Outcome.
- `MissionTacticalSandboxController` bietet einen read-only `get_suppress_fire_outcome_aar_diagnostic_snapshot()`.
- Der laufende HTML-Zwischenbericht dokumentiert TASK_582 als erledigten Arbeitsstand und benennt den naechsten Slice.
- Verifier fuer Doku, Wiring, integrierten Missionspfad und Snapshot-Leseinvarianz.

## Nicht-Ziele
- Kein vollstaendiger After-Action-Report.
- Kein Ammo-Verbrauch.
- Kein echtes Suppression-System.
- Keine Aenderung an Hit-Chance, Damage, Weapon-Ticks, Movement oder ROE-Entscheidung.
- Keine UI-seitige Combat-Wahrheit.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_581_suppress_fire_intent_outcome_smoke.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- Der Combat-Driver liefert `schema = sternenbuergerchen.suppress_fire_outcome_aar_diagnostic.v1`.
- Ein echter `fired`-SUP-Outcome erhoeht `suppress_fire_outcome_count`.
- Der Count wird nach Fireteam gebuckelt.
- Snapshot-Lesezugriffe erhoehen den Count nicht.
- `last_suppress_fire_outcome.outcome_label = suppress_pressure_intent`.
- Die Diagnose meldet weiterhin keinen Suppression-Effect, keinen Ammo-Verbrauch und keine Damage-Modifikation.
- `get_suppress_fire_outcome_aar_diagnostic_snapshot()` bleibt read-only.
- TASK_581 bleibt gruen.

## Betroffene Dateien
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`
- `docs/tasks/TASK_582_suppress_fire_outcome_aar_diagnostic_stub.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_582_suppress_fire_outcome_aar_diagnostic_stub.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Stub beweist nur, dass SUP als spaeterer AAR-Wert sauber messbar ist. Die eigentliche Debriefing-UI und echte Suppression-/Ammo-Messwerte bleiben Folgearbeit.
- Der Count ist bewusst auf `fired`-Contact-Decisions begrenzt, damit reine Preview-, Cooldown- oder Snapshot-Pfade nicht als Einsatz zaehlen.

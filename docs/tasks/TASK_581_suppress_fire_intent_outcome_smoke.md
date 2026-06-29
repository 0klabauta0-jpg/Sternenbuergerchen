# TASK_581 - Suppress Fire Intent Outcome Smoke

## Ziel / Problem
TASK_576 bis TASK_580 machen `SUP` vor `GO` als lesbare Zielbereichs-Preview sichtbar. Es fehlt noch ein kleiner Outcome-Smoke: Wenn der Combat-/Resolver-Pfad danach eine Entscheidung trifft, muss `SUP` als Druckabsicht diagnostisch sichtbar bleiben, ohne bereits ein grosses Suppression- oder Ammo-System zu behaupten.

## Sinnhaftigkeit / Ursache
Der Spieler soll verstehen, dass `SUP` mehr ist als ein Button und eine Preview-Flaeche. Gleichzeitig darf dieser Slice nicht heimlich neue Combat-Wahrheit einfuehren. `SUP` soll deshalb im Contact-Decision-Outcome als `suppress_pressure_intent` lesbar sein, aber keine Munition verbrauchen, keinen Suppression-Effect enqueuen und keinen Schaden modifizieren.

## Umfang
- `CombatFireDecisionResolver` liefert eine read-only Fire-Rule-Outcome-Diagnose.
- `MissionCombatLoopDriver` haengt diese Diagnose an bestehende Contact-Decision-Diagnostics.
- Mission-Control-/Combat-HUD-Text darf bei einem SUP-Fire kurz `SUP` nennen.
- `MissionTacticalSandboxController` bietet einen read-only `get_suppress_fire_intent_outcome_snapshot()`.
- Verifier fuer Resolver-Matrix und integrierten Missionspfad.
- Status, Roadmap, Contract und HTML-Zwischenbericht aktualisieren.

## Nicht-Ziele
- Kein echtes Suppression-System.
- Kein Ammo-Verbrauch.
- Kein neues AAR-System.
- Keine Aenderung an Hit-Chance, Damage, Weapon-Ticks oder Movement.
- Kein UI-Commit von Gameplay-State.

## Relevante Contracts / Dokumente
- `docs/dev/mission_command_feedback_contract.md`
- `docs/tasks/TASK_580_suppress_fire_visual_tuning_findings.md`
- `docs/tasks/TASK_576_suppress_fire_preview_readability_spike.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Akzeptanzkriterien
- `CombatFireDecisionResolver.build_fire_rule_outcome_diagnostic()` meldet fuer `suppress` `outcome_label = suppress_pressure_intent`.
- Contact-Decision-Diagnostics enthalten `attacker_fire_rule = suppress`, `suppress_intent_active = true` und `suppress_pressure_intent_visible = true`.
- Mission-Control- oder Combat-HUD-Text enthaelt `SUP`.
- Diagnostics melden `suppress_effect_applied = false`, `suppression_effect_payload_enqueued = false`, `ammo_consumed = false` und `suppress_damage_modifier_applied = false`.
- Der Snapshot bleibt read-only und mutiert keine Command-Queue.
- TASK_570/TASK_580 bleiben gruen.

## Betroffene Dateien
- `scripts/tactical/combat_fire_decision_resolver.gd`
- `scripts/tests/mission_combat_loop_driver.gd`
- `scripts/tests/mission_tactical_sandbox_controller.gd`
- `scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`
- `docs/tasks/TASK_581_suppress_fire_intent_outcome_smoke.md`
- `docs/dev/mission_command_feedback_contract.md`
- `docs/IMPLEMENTATION_STATUS.md`
- `docs/TASK_ROADMAP.md`
- `docs/reports/project_review_status_2026_06_28.html`

## Lokale Pruefung
- `godot_console.exe --headless --path . --script scripts/tests/task_581_suppress_fire_intent_outcome_smoke.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_580_suppress_fire_visual_tuning_findings.gd`
- `godot_console.exe --headless --path . --script scripts/tests/task_570_hold_fire_discipline_mission_bridge.gd`
- `git diff --check`

## Risiken / offene Punkte
- Dieser Smoke beweist nur die Diagnose- und Feedback-Grenze. Echte Unterdrueckungswirkung, Munitionsverbrauch, Trefferverhalten und AAR-Messwerte bleiben eigene Folgearbeit.
- Wenn `SUP` im HUD zu laut wirkt, sollte ein spaeterer Visual-/Text-Polish die knappe Anzeige kalibrieren.

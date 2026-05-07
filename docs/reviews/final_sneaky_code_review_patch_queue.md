# TASK_289 - Final Sneaky Code Review Patch Queue

## Findings

### P0

Keine P0-Blocker gefunden.

### P1 - Fixed in TASK_289

1. `scripts/command/commander_intent.gd:224` bis `scripts/command/commander_intent.gd:256` (file/line)
   - Risiko: Unbekannte `verb`, `tempo`, `fire_rule`, `contact_response` oder `risk`-Werte wurden sicher normalisiert, aber der Fallback war nicht sichtbar. Ein defekter UI-/Netzwerk-/Scenario-Payload konnte damit wie absichtlicher Spielerbefehl aussehen.
   - Repro: `CommanderIntent.from_dict({"verb": "teleport", "tempo": "warp", ...})` wurde zu einem validen Move/Normal/Return/Report/Normal-Intent.
   - Fix: `CommanderIntent` sammelt jetzt `normalization_warnings`, synchronisiert sie in `metadata` und serialisiert sie in Dict/Snapshot. `MultiplayerSnapshotContract` spiegelt diese kleinen Warning-IDs.
   - Gate: `task_289_final_sneaky_code_review_patch_queue.gd`, plus `task_285_tactical_decision_branch_integrity_review.gd` und `task_281_tactical_command_multiplayer_authority_snapshot.gd`.

2. `scripts/mission/air_asset_status.gd:53` bis `scripts/mission/air_asset_status.gd:77`, `scripts/mission/air_asset_status.gd:136` bis `scripts/mission/air_asset_status.gd:180` (file/line)
   - Risiko: Unbekannte AirAsset-State-Strings fielen sicher auf `intact` zurueck, aber ohne Diagnose. Ein fehlerhafter Snapshot oder Runtime-Patch konnte Warn-/Schadenszustand still entschaerfen.
   - Repro: `AirAssetStatus.from_dict({"state": "teleported"})` ergab `state = intact`.
   - Fix: `AirAssetStatus` sammelt `normalization_warnings`, synchronisiert sie in `metadata`, serialisiert sie im Snapshot und fuehrt Warnungen auch bei `apply_threat()` und lethal `apply_damage()` mit unbekanntem Terminal-State fort. `MultiplayerSnapshotContract` spiegelt diese Warning-IDs.
   - Gate: `task_289_final_sneaky_code_review_patch_queue.gd`, plus `task_277_dropship_freighter_anti_armor_threat_contract.gd` und `task_281_tactical_command_multiplayer_authority_snapshot.gd`.

### P2 - Patch Queue

1. `scripts/command/commander_intent.gd:178` und `scripts/tactical/fireteam_execution_plan.gd:433` bis `scripts/tactical/fireteam_execution_plan.gd:478`
   - Risiko: `CommanderIntent.to_dict()` serialisiert `cover_priority = normal` und `security_mode = facing` auch dann, wenn der Spieler nie explizit Cover/Security gewaehlt hat. Dadurch gewinnen diese Default-Strings gegen einige intent-basierte Fallbacks in `FireteamExecutionPlan`.
   - Repro: Ein `take`-Intent ohne explizite Security kommt als `security_mode = facing` an; der `take -> sector`-Fallback ist dadurch praktisch unreachable.
   - Empfehlung: In einem kleinen Folgepatch explizite Spielerwahl von Default unterscheiden, z.B. ueber `explicit_tactical_fields` oder indem `to_dict()` Default-Felder nur schreibt, wenn sie gesetzt wurden.
   - Gate: `task_285_tactical_decision_branch_integrity_review.gd`, danach TASK_282 und TASK_281.

2. `scripts/tactical/tactical_breakout_resolver.gd:123`, `scripts/tactical/tactical_breakout_resolver.gd:128`, `scripts/tactical/tactical_breakout_resolver.gd:137`
   - Risiko: Leere Breakout-Ergebnisse bleiben korrekt, aber schwer zu debuggen.
   - Repro: unbekannter Trigger oder fehlende Fireteam-ID gibt `{}` ohne `blocked_reason`.
   - Empfehlung: Optionalen Diagnosepfad fuer nicht erzeugte Breakouts einfuehren, ohne die Runtime-API fuer erfolgreiche Breakouts aufzublasen.
   - Gate: `task_276_tactical_breakout_and_exception_behavior.gd` und `task_285_tactical_decision_branch_integrity_review.gd`.

3. `scripts/tests/task_284_gameplay_truth_architecture_boundary_audit.gd` und `scripts/tests/task_286_ui_feedback_truth_regression_review.gd`
   - Risiko: Statische Boundary-Scans schuetzen nur bekannte Mutations-Token.
   - Repro: Neue Runtime-APIs koennten UI-/Meta-Code schreiben lassen, wenn die Tokenlisten nicht erweitert werden.
   - Empfehlung: Bei jeder neuen autoritativen Runtime-Methode sofort die Forbidden-token-Listen nachziehen.
   - Gate: TASK_284/TASK_286.

### P3 - Manual / Polish Queue

1. Echter Zwei-Instanzen-LAN-Smoke bleibt manuell.
2. Full-HD-Mission-Lesbarkeit, AirAsset-Fairness, Bubble-Laerm, Audio-/VFX-Gefuehl und Drag/drop-Feeling bleiben Sicht-/Spielgefuehlchecks.
3. User-Handbuch TASK_290 muss diese bekannten manuellen Restpunkte als "bekannte Einschraenkung / manueller Check" und nicht als fertig automatisierte Wahrheit formulieren.

## Abschlussentscheidung

Ready for polish.

Keine Architektur-Blocker im Review-Scope. Zwei P1-Diagnose-Fixes wurden direkt umgesetzt. Die verbleibende Queue ist klein, verhaltensbezogen und kann in separaten Folgepatches geschnitten werden.

## Abschlussstatus

- `task_289_final_sneaky_code_review_patch_queue.gd`: geplant fuer Abschlusslauf.
- Relevante Gates nach Befundlage: TASK_285, TASK_277, TASK_281, TASK_288.
- `git diff --check`: geplant fuer Abschlusslauf.

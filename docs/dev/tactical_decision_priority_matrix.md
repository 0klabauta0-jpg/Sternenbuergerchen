# Tactical Decision Priority Matrix

Status: TASK_285

## Purpose
Diese Matrix spiegelt den aktuellen Code fuer CommanderIntent, TacticalRules, FireteamExecutionPlan, MultiFireteamPlanResolver, TacticalBreakoutResolver, TacticalCommunicationResolver, EnemyTeamTacticsProfile und AirAssetThreatResolver. Sie erfindet kein neues Verhalten; sie macht die bestehenden Entscheidungszweige pruefbar.

## CommanderIntent
| Input | Normalisierung | Diagnose |
| --- | --- | --- |
| `attack`, `attack_area`, `engage_area` | `engage` | Alias ist dokumentiert |
| `move_to_area`, `move_to_position` | `move` | Alias ist dokumentiert |
| `hold_position` | `hold` | Alias ist dokumentiert |
| Legacy `unit_id` | ignoriert | Snapshot setzt `direct_unit_payload_ignored` |
| Unbekannter Verb/Tempo/FireRule/Contact/Risk | sicherer Fallback | Review-Befund: noch keine eigene Diagnose im Payload |

## TacticalRules
Konflikte werden in `TacticalCommandRules._normalize_conflicts()` in fester Reihenfolge geloest:

| Konflikt | Gewinner | Warnung |
| --- | --- | --- |
| `contact_response = avoid` plus `fire_rule = free/suppress` | `fire_rule = hold` | `conflict:avoid_contact_fire_rule:fire_rule_hold` |
| `contact_response = withdraw` plus `fire_rule = suppress` | `fire_rule = return` | `conflict:withdraw_suppress:fire_rule_return` |
| `tempo = rapid` plus `security_mode = 360` | `security_mode = facing` | `conflict:rapid_360_security:security_facing` |
| `contact_response = assault` plus `fire_rule = hold` | `contact_response = fix` | `conflict:assault_hold_fire:contact_fix` |

## FireteamExecutionPlan
| CommanderIntent | Movement | Security | UnitAction |
| --- | --- | --- | --- |
| `defend`, `hold` | `hold` | `all_round` | `hold_position` |
| `take`, `engage`, `flank`, `support` | `bounding` | `sector` fuer take/engage/support, falls nicht durch explizite Security ueberschrieben | `engage_area` bei take/engage |
| `recon`, `secure` | `probe` | `sector`/requested mode | `seek_cover` |
| `move` + `tempo = cautious` | `caterpillar` | `facing` | `move_to_position` |
| `withdraw` | `rush` oder requested movement fallback | `facing` | `retreat` |

Security und Cover werden zuerst durch explizite Intent-Felder gesetzt. Ohne explizite Security gewinnt der Verb-Fallback; ohne explizite Cover-Angabe gewinnt Risiko/Tempo: `risk = low` hebt Cover, `risk = high` senkt Cover, `tempo = cautious` hebt, `tempo = rapid` senkt. `CommanderIntent` schreibt `security_mode` und `cover_priority` nur noch bei expliziter Wahl in den Payload, damit Defaults diese FTL-Fallbacks nicht verdecken.

## MultiFireteamPlan
| Verbgruppe | Rollenfolge |
| --- | --- |
| `recon` | `recon`, `support`, `security`, `reserve` |
| `defend`, `secure` | `security`, `support`, `reserve`, `lead` |
| alles andere | `lead`, `support`, `reserve`, `security`, `recon` |

Planstatus priorisiert `blocked_path` vor `contact_stable` vor `preview`. Rollen-Swap aendert Rollen, naechste Schritte und Labels, aber keine Runtime-Positionen ausserhalb des Plan-Snapshots.

## Breakout Priority
`TacticalBreakoutResolver.detect_trigger()` gewinnt in dieser Reihenfolge:
1. `air_asset_destroyed`
2. `air_asset_threatened`
3. `leader_down`
4. `blocked_route`
5. `suppressed_pinned`
6. `casualty_medic_needed`
7. `out_of_weapon_range`
8. `low_ammo_no_weapon`
9. `rule_conflict`
10. `contact`

Die Klasse gewinnt danach ueber Trigger, FTL-Skill und `allowed_breakout_classes`:
- Air loss bevorzugt `abort_to_safe`, faellt ohne Erlaubnis auf `request_orders`.
- Blocked route wird bei hoher `breakout_judgement` zu `auto_adapt`, sonst `hold_and_report`.
- Low contact judgement fragt `request_orders`.
- Low ammo, out of range und rule conflict fragen `request_orders`.

## TacticalCommunicationEvent
Events werden nach Prioritaet sortiert, bei gleicher Prioritaet nach Event-ID oder Zeit. Channels werden begrenzt; Cooldown ist pro Event-/Fireteam-/Unit-Key. Die Schicht erzeugt Feedback, keine Gameplay-Wahrheit.

## Enemy Profile
`EnemyTeamTacticsProfile.normalize_config()` ist der zentrale Profil-Fallback. Unbekannte Profile, Security Modes, Facing-Werte, Weapon IDs und Anti-Armor-Konflikte erzeugen `diagnostics`. Das verhindert stille Editor-/Scenario-Fallbacks.

## AirAssetThreat
Gate-Reihenfolge in `AirAssetThreatResolver._evaluate_gates()`:
1. Terminaler AirAssetStatus blockiert.
2. Waffe muss Anti-Armor sein.
3. Reichweite muss passen.
4. Line of Sight muss vorhanden sein.
5. Ziel muss in Fog-of-War sichtbar sein.
6. Altitude Layer darf nicht safe/high/orbit/offmap sein.

Wenn der erste Treffer keine Warnung gesehen hat, gewinnt Warnung vor Schaden. Danach kann Treffer, Schaden oder Crash entstehen. Terminale Ergebnisse erzeugen `tactical_breakout_trigger = air_asset_destroyed`.

## Conflict Priority Summary
| Konflikt | Gewinner |
| --- | --- |
| Commander objective vs. FTL-Ausbruch | Breakout bleibt an `plan_id`/`command_id`; Zielaenderung wird `request_orders`/`abort_to_safe` |
| AirAsset destroyed vs. normal contact | AirAsset destroyed |
| Blocked route vs. contact | Blocked route |
| Suppression vs. medic needed | Suppression |
| TacticalRules avoid vs. free fire | Avoid/contact rule, FireRule wird hold |
| MultiFireteam blocked vs. contact | `blocked_path` Planstatus |

## Regression Fixtures
`scripts/tests/task_285_tactical_decision_branch_integrity_review.gd` prueft exemplarisch:
- TacticalRules-Konflikte mit Warnungen.
- CommanderIntent-Aliase und Legacy-Unit-Ignorieren.
- FireteamExecutionPlan-Bewegung, Security und UnitAction.
- MultiFireteamPlan-Rollen und Statusprioritaet.
- Breakout-Triggerprioritaet und Allowed-Class-Downgrades.
- AirAssetThreat-Gates, Warnung-vor-Schaden und Destroy-Trigger.
- EnemyProfile-Fallbacks mit Diagnostics.

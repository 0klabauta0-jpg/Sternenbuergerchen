# TASK_285 - Tactical Decision Branch Integrity Review

## Scope
Review von CommanderIntent, TacticalRules, FireteamExecutionPlan, MultiFireteamPlanResolver, TacticalBreakoutResolver, TacticalCommunicationResolver, EnemyTeamTacticsProfile und AirAssetThreatResolver. Ziel war Branch-Integritaet: keine doppelte Semantik, keine unbekannten Fallbacks ohne Sichtbarkeit, klare Konfliktprioritaeten.

## Findings

### Blocker
- Keine Blocker gefunden.

### Important
- `scripts/command/commander_intent.gd:244` bis `scripts/command/commander_intent.gd:260` normalisiert unbekannte Verb-/Tempo-/FireRule-/Contact-/Risk-Werte auf sichere Defaults, aber ohne eigenes `diagnostics`-Feld. Risiko: Ein kaputter UI-/Netzwerk-/Scenario-Payload kann spielbar aussehen, obwohl ein Spielerbefehl semantisch ersetzt wurde. Suggested fix: CommanderIntent sollte in einem kleinen Folgepatch `normalization_warnings` in Metadata/Snapshot fuehren, analog zu TacticalRules und EnemyTeamTacticsProfile.
- Behoben im aktuellen Review-Folgepatch: `CommanderIntent.to_dict()` serialisiert `security_mode` und `cover_priority` nur bei expliziter Spieler-/Scenario-Wahl. Dadurch erreicht ein `take`-Intent ohne explizite Security wieder den `take -> sector`-Fallback in `FireteamExecutionPlan`, waehrend explizite Werte wie `security_mode = facing` oder `cover_priority = high` weiter gewinnen.
- `scripts/mission/air_asset_status.gd:84` bis `scripts/mission/air_asset_status.gd:116` faellt bei unbekannten AirAsset-State-Strings auf `intact` zurueck. Risiko: Ein fehlerhafter Snapshot oder Scenario-Wert kann einen Warn-/Schadenszustand leise entschaerfen. Suggested fix: `AirAssetStatus.from_dict()` sollte unbekannte States im Metadata-Diagnosefeld merken, ohne die sichere Fallback-Semantik zu brechen.

### Cleanup
- `scripts/tactical/tactical_breakout_resolver.gd:123`, `scripts/tactical/tactical_breakout_resolver.gd:128` und `scripts/tactical/tactical_breakout_resolver.gd:137` geben bei keinem Trigger, unbekanntem Trigger oder fehlender Fireteam-ID `{}` zurueck. Das ist aktuell stabil, aber fuer Debugging duenn. Suggested fix: spaeter optional `blocked_reason`/`diagnostic` fuer nicht erzeugte Breakouts bereitstellen, damit UI/Tests leere Ergebnisse besser unterscheiden koennen.
- `scripts/tactical/multi_fireteam_plan_resolver.gd:502` bis `scripts/tactical/multi_fireteam_plan_resolver.gd:525` hat eine gute Statusprioritaet (`blocked_path` vor `contact_stable`), aber die Decision Table sollte bei Folgeaenderungen mitgepflegt werden. Der neue Verifier haelt diese Prioritaet fest.

## Positive Findings
- `scripts/tactical/tactical_command_rules.gd:218` bis `scripts/tactical/tactical_command_rules.gd:230` dokumentiert Konflikte mit stabilen Warning-IDs.
- `scripts/tactical/enemy_team_tactics_profile.gd:237` bis `scripts/tactical/enemy_team_tactics_profile.gd:303` sammelt Diagnostics fuer unbekannte Profile, Security Modes, Facing-Werte, Weapons und Anti-Armor-Konflikte.
- `scripts/combat/air_asset_threat_resolver.gd:138` bis `scripts/combat/air_asset_threat_resolver.gd:154` gibt fuer alle harten AirAsset-Gates eindeutige `blocked_reason`-Werte aus.
- `scripts/tactical/tactical_breakout_resolver.gd:96` bis `scripts/tactical/tactical_breakout_resolver.gd:115` priorisiert AirAsset-Verlust vor AirThreat, Leader down, Blocked, Suppression, Medic, Range, Ammo, Rule Conflict und Contact.

## Decision Tables
Die zentrale Matrix liegt in `docs/dev/tactical_decision_priority_matrix.md`. Sie enthaelt:
- CommanderIntent-Klassen und Legacy-Aliase.
- TacticalRules-Konfliktgewinner.
- FireteamExecutionPlan-Movement/Security/UnitAction-Mapping.
- Multi-Fireteam-Rollenfolge und Statusprioritaet.
- BreakoutState-Triggerprioritaet und Allowed-Class-Downgrades.
- TacticalCommunicationEvent-Sortierung, Channel-Limit und Cooldown.
- Enemy-Taktikprofil-Fallbacks mit Diagnostics.
- AirAssetThreat-Gates und Warnung-vor-Schaden-Regel.

## Verifier
`scripts/tests/task_285_tactical_decision_branch_integrity_review.gd` prueft die Branch-Matrix mit kleinen Fixtures. Der Test ist absichtlich schmal: Er pinnt Entscheidungsprioritaeten und Diagnosen, ohne Balancingwerte zu optimieren.

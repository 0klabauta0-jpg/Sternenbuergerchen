# Editor Save Multiplayer Contract Regression Review

TASK_287 prueft die Grenzen zwischen Editor-/Scenario-Authoring, lokalen Saves, Meta-State, Multiplayer-Commands, Replication-Snapshots und heruntergeladenen Maps nach den Tactical- und AirAsset-Erweiterungen.

## Findings

### Blocker

Keine Blocker gefunden. Die zentralen Runtime-Wahrheiten bleiben bei `SimulationRoot`, `MissionScenarioData` serialisiert nur Authoringdaten, und `MultiplayerCommandContract` blockt direkte Client-State-Mutationen fuer Tactical-/AirAsset-Felder.

### Important

1. `GameSettingsContract.normalize_settings()` uebernahm unbekannte Keys aus beliebigen Eingaben. Das konnte dazu fuehren, dass versehentlich uebergebene `roster`, `map_file_path` oder `air_asset_status`-Daten in `user://sternenbuergerchen_settings.cfg` landen. Gepatcht: Settings persistieren nur noch bekannte Display-/Audio-/Gameplay-Keys.

2. `MultiplayerMapManifest.validate_map_json_text()` validierte bisher nur wenige Top-Level-Keys. Gepatcht: heruntergeladene Map-JSON-Payloads werden rekursiv auf `script`, `resource_path` und `absolute_path` geprueft, und `enemy_team_configs` werden gegen `EnemyTeamTacticsProfile.validate_config()` validiert.

3. `MissionScenarioData` behandelt AirAsset- und Tactical-Daten korrekt als Authoring-Kontext: `to_dict()` schreibt keine Runtime-Felder wie `air_asset_status`, `runtime_state`, `tiles` oder `markers`, verbotene LZ-Runtime-Keys werden beim Laden als Validierungsfehler gemeldet, und AirAsset-Threat-Kontexte deklarieren `runtime_authority = SimulationRoot` sowie `ui_sets_gameplay_truth = false`.

4. Multiplayer-Snapshots bleiben kompakt und privatdatenarm: Unit-Snapshots behalten Ownership und berechneten Runtime-State, ignorieren aber Roster-Private-Felder wie `skill_values`, `progression`, `relationship_links` und `portrait_path`. Character-Gameplay, Feedback-Bubbles und CommunicationEvents werden auf kleine IDs/Keys reduziert.

### Cleanup

- `AirAssetRecoveryState` ist Meta-State mit `runtime_authority = MetaLayerFlow`; der Transport-Patch setzt Boardability, aber keine Scenario- oder Map-Authoringdaten.
- `PlayerRosterStore` darf lokal private Roster- und Progressionsdaten speichern. Der Multiplayer-Pfad laeuft ueber `build_public_roster_preview()` und `MultiplayerRosterContract`.
- Downloaded-Map-Consent und Manifest bleiben gueltig: Hash, Size, sichere `map_id`, sichere Scenario-Pfade und `user://`-Cache werden weiter vor Cache-Write geprueft.

## Boundaries

| Bereich | Besitzer | Lebensdauer | Darf enthalten | Darf nicht enthalten |
| --- | --- | --- | --- | --- |
| Scenario/Editor | Map Editor, `MissionScenarioData` | authoring/persistent | Objective, Enemy Groups, Tactical Authoring, Risk Tags | LZ-Runtime-Position, Dropship Request, AirAssetStatus, Unit Health |
| Map Download | Host Manifest + Client Consent | cache/persistent | Terrain JSON, Marker, Tiles, validierte EnemyTeamConfigs | Skriptreferenzen, absolute Pfade, ungepruefte Taktikprofile |
| Local Roster Save | `PlayerRosterStore` | local profile | Progression, Relationships, Personnel Events | Netzwerk-Snapshot-Wahrheit |
| Settings | `GameSettingsContract` | local config | Display, Audio, FoW, Help Mode | Roster, Map, Scenario, AirAsset Runtime |
| Meta AirAsset Recovery | `AirAssetRecoveryState` | campaign/meta | Repair/Replacement ETA, Pilot State, Transport Patch | Editor-Authoring oder Client-Commands |
| Multiplayer Command | `MultiplayerCommandContract` | transient request | whitelisted Intent/Role/Breakout/AirAsset command | direct health, objective, LZ-from-editor, AirAssetStatus |
| Multiplayer Snapshot | `MultiplayerSnapshotContract` | replicated mirror | compact runtime mirror, owner ids, public refs | raw assets, private roster fields, raw payloads |

## Verifier

`scripts/tests/task_287_editor_save_multiplayer_contract_regression_review.gd` deckt ab:

- Scenario-Roundtrip und Rejects fuer LZ-/Runtime-Bleed.
- Settings-/Roster-/AirAssetMeta-Trennung.
- Multiplayer-Command-Rejects fuer direkte State-Mutation und Host-only-Rollen.
- Snapshot-Privacy, Kompaktheit und Raw-Payload-Filter.
- Downloaded-Map-Manifest, Consent-Cache, rekursive Payload-Sicherheit und EnemyTeamConfig-Validierung.

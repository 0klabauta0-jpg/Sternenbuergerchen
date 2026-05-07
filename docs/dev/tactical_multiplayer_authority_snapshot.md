# Tactical Multiplayer Authority Snapshot

## Zweck
TASK_281 bindet die Tactical-Overhaul-Daten an den bestehenden Multiplayer-Vertrag an. Clients duerfen taktische Plaene anfragen und Server-Snapshots anzeigen, aber keine Gameplay-Wahrheit setzen.

## Authority-Regel
- `SimulationRoot` bleibt die einzige Runtime-Authority fuer Command-Annahme, Queueing, Effects und AirAssetStatus.
- Client-Payloads laufen durch `MultiplayerCommandContract`.
- Snapshot-Daten sind read-only Anzeigezustand und tragen `ui_sets_gameplay_truth = false`, wo sie eigene Tactical-Statusfelder spiegeln.

## Erlaubte neue Command-Kategorien
- `commander_intent`: validierte CommanderIntent-Payloads fuer Team-/Fireteam-Planung.
- `breakout_response`: `breakout_confirm`, `breakout_abort`, `breakout_regroup`, `breakout_override`.
- `air_asset_command`: `air_asset_guard_lz`, `air_asset_abort_approach`, `air_asset_hold`, `air_asset_request_status`.
- `role_override`: Host-only role override; normale Commander- oder Fireteam-Peers bekommen `host_required`.

## Harte Rejects
Der Command-Vertrag lehnt taktische Payloads ab, die Ergebnis-State setzen wollen:
- `fireteam_plan_status`
- `breakout_state`
- `communication_events`
- `air_asset_status`
- `air_asset_state`
- `vfx_events`
- `sfx_events`
- alle bestehenden Damage-/Vital-/Objective-/Runtime-State-Felder

## Snapshot-Felder
`MultiplayerSnapshotContract` normalisiert jetzt zusaetzlich:
- `commander_intents`
- `fireteam_plan_status`
- `communication_events`
- `tactical_rules`
- `breakout_states`
- `air_asset_status`

Alle Listen werden stabil sortiert. Events mit gleicher stabiler ID werden dedupliziert, damit Kommunikation, Weapon-Fire-SFX/VFX und AirAsset-Explosionen nicht mehrfach aus einem Snapshot abgespielt werden.

## Privacy
Fireteam-Planstatus spiegelt nur oeffentliche Faktoren wie Planqualitaet, Kommunikationsklarheit und Breakout-Urteil. Rohdaten wie `ftl_skill_factors`, Character-Sheet-Metadaten oder private UI-Notizen werden nicht in den Snapshot uebernommen.

## Apply-Regel
`SimulationRoot.apply_multiplayer_snapshot()` schreibt den normalisierten Server-Snapshot in `_last_server_state`, wendet Unit-/Objective-Spiegelung an und emittiert deduplizierte Snapshot-Audioevents. Es enqueued keine Commands und keine Effects.

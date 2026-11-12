# Active campaign mission save implementation plan

> **For agentic workers:** Coordinate air-owner interfaces with the space task; retain all existing safety gates until actual end-to-end restore passes.

**Goal:** Persist and restore actual campaign mission state, without corrupting or replacing valid home checkpoints on failure.

**Architecture:** A versioned mission checkpoint coordinates snapshots from authoritative owners and validates every required block and identity before any publication. Restore is prepared in isolated replacement owners and committed only when all owner preparations succeed. Keep legacy v1 home checkpoint read/write untouched. Mission-scope support is granted only for fully representable states.

**Tech stack:** Godot 4.6.2, GDScript, existing checkpoint store and Root owner transactions, headless verification with isolated APPDATA.

## 1. Schema and validation
- Add `scripts/mission/campaign_mission_checkpoint_contract.gd` for bounded versioned portable envelope validation; require mission identity, roster, actual mission/transport and flight/combat owner blocks; reject unknown versions, mismatched ids and unsupported transactions.
- Write `scripts/tests/campaign_mission_checkpoint_contract_verifier.gd` first: missing, malformed, inconsistent, and unsafe blocks reject without mutating inputs; valid fixture accepted, nested data deeply copied. Run red, implement, run green.

## 2. Owner snapshots and transactional preparation
- Audit real mission driver, location registry, crew, inventories, AI/health, interactions, transport, fleet travel, flight/combat, air sortie and timer/RNG; specify exact formats from owner APIs and reconcile air task schemas.
- Add owner-level capture and prepare/validate/commit APIs with gates for unrepresentable transitions. Do not serialize UI projections. Verify each owner with real state plus corrupted and identity mismatch fixtures.

## 3. Save, continue and migration
- Integrate only after all required owner APIs exist: CampaignStartConfiguration/CheckpointStore and SingleplayerRuntimeAdapter coordinate a separate versioned mission payload, preserving atomic old save and preflighting before mutating live world. MetaLayerFlow rebuilds the actual mission and commits owner preparations atomically.
- Real campaign roundtrip: actual departure, land, movement, combat/interactions, save, fresh process reload, same state and playable onward; then repeat for supported in-flight / combat phases and multiple owners. Verify old home/AP7 saves, corrupt data and failure atomicity.
- Document remaining unsupported phases; run the focused gates and existing home/save checks with isolated profiles; no EXE in this task.

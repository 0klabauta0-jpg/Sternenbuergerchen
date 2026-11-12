# AP7: bounded multiplayer authority Contract slice

## Goal / cause
Snapshot normalisation currently stamps version1 before validation, hiding explicit unknown versions. Multiplayer commands reject existing state keys only at the top level and retain the original payload; nested Hex/visibility/reservation fields therefore need an explicit boundary before category parsing/copying.

## Approved scope / non-goals
Only scripts/multiplayer/multiplayer_snapshot_contract.gd and multiplayer_command_contract.gd plus own Task/Fixture/QA. No Root/Net/Checkpoint/Runtime/shared runner edit, schema bump, new network transport or per-recipient visibility implementation. Parent permission confirmed before code. No git stage/commit.

## Version / command contract
Current wire schema is INT1, snapshot_type state, transfer_mode unreliable. Reject explicit unknown or wrongly typed schema_version BEFORE build_state_snapshot; missing version remains documented LegacyV1 compatibility (real review_20261102_p2_vital_order_verifier calls omit it). Builder remains unchanged, knownV1 tick ordering remains. No version2 is introduced.

New targeted host-state keys for actual Ground snapshot containers (units_by_id,occupant_by_grid,reservation_schema_version,committed_segments,committed_corridor_grants,admission_slots_by_grid), private _hex_lifecycle, Hex containers hex_ground/hex_state, and visibility/visibility_state/visible/detection_state/reservations are rejected at any Dictionary/Array depth. Existing top-level state rejects remain unchanged; this does NOT recursively ban all old status keys. Bounded walk before duplicate/category parsing: maximum depth16 and total4096 value nodes; exceeding either rejects clearly rather than skipping fields. Target intent geometry target_position/lz_position/world_polygon/tile_positions/facing_angle/security_mode remains valid.

## Sources / acceptance / local checks
multiplayer_snapshot_replication_contract.md, multiplayer_authority_command_contract.md, tactical_multiplayer_authority_snapshot.md, hex_tactical_runtime_contract.md and actual Contracts. Small actual-Contract fixture checks raw version rejection before builder invocation, LegacyV1, known ordering, valid intent geometry, direct/nested host-state keys and bounded traversal. Existing task168 Snapshot apply neighbour only, plus individual compiles in private isolated project/profile. No broad suite/GPU/native tests.

## Risks / open AP7 boundary
This is only an authority Contract boundary. It does not implement Ground restore, hidden-enemy per-recipient filtering, networking authenticity or a second occupancy/sight owner. Source Root work remains necessary; no complete AP7/AP8 or network safety acceptance is claimed. Max nesting/node limits are explicit command payload limits, not silent trimming or arbitrary UI metadata authorisation.

## Frozen evidence
Base8c83b1856. New actual Contract fixture10/0; existing task_168_multiplayer_snapshot_contract_verifier neighbour20/0; two isolated individual compiles Exit0. Source/read-profile/canary guards true. The bounded raw walk also rejects cyclic input before duplicate(true), while actual CommanderIntent and legitimate nested geometry/legacy non-string metadata keys remain compatible. Exact targeted key list is in the product Contract; unrelated old status fields are not recursively banned. Own evidence output/native_glut_maps/ap7_multiplayer_contracts_20261112. No Root/Net/Checkpoint/Runtime/shared runner or shared status edits; no stage/commit. full_ap7=false and per-recipient visibility/Restore remain separate work.

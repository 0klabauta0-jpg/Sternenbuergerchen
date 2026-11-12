# AP7 multiplayer Contract boundaries — frozen partial slice

Base8c83b1856. Product scope ONLY scripts/multiplayer/multiplayer_snapshot_contract.gd and multiplayer_command_contract.gd; own Task AP7_MULTIPLAYER_CONTRACT_BOUNDARIES_2026_11_12.md and this QA. No Root/Net/Checkpoint/Runtime/shared runner, schema bump, staging or commit.

Snapshot current wire schema stays INT1, state/unreliable. validate_for_apply now rejects explicit schema_version values other than INT1 BEFORE build_state_snapshot can normalise/stamp1. Missing version remains deliberate LegacyV1 compatibility for actual existing versionless local/legacy calls (review_20261102_p2_vital_order_verifier). No version2, silent downmigration or Restore introduced. Existing tick ordering and apply path stay.

Command raw walk checks only targeted new host facts recursively: actual Ground planning tables/segments/grants/admission slots/reservation schema, _hex_lifecycle, hex_ground/hex_state and selected visibility/reservation fields. The original old top-level state blacklist remains unchanged; unrelated old health metadata is NOT recursively banned. Bounds: depth16,4096 total value nodes; clear authority_payload_depth_limit / authority_payload_node_limit rejects, never silent cutoff. Runs before deep copy/category parsing, so a cyclic container also rejects boundedly. Non-string nested metadata keys remain compatible and cannot be mistaken for host-key strings. Existing target/LZ/polygon/tile/facing/security intent fields remain valid.

check.log: AP7_MULTIPLAYER_CONTRACT_RESULT checks=10 failures=0 full_ap7=false. Real two Contracts; Snapshot subclass only counts calls to the real normalisation builder. Tests INT1; malformed/unknown declarations with zero builder calls; missing LegacyV1; tick/source preservation; valid Move;14 direct+nested host-key variants in Dictionary/Array wrappers; real CommanderIntent/nested geometry/unrelated metadata; depth limit; node limit; raw cycle rejection before copy.

neighbour.log: existing task_168_multiplayer_snapshot_contract_verifier.gd,20/0. Actual Root/TestUnit/Registry fixture verifies existing V1 schema, new/old tick application, missing-unit accounting and no authoritative command/effect enqueue from snapshot apply. This is the one directly affected existing neighbour, no broad/network-play matrix. Two *_compile.log files: Godot4.6.2 individual --check-only Exit0. import.log is private dependency import only.

Reproduce this bounded case plus neighbour:

```powershell
python output/native_glut_maps/ap7_multiplayer_contracts_20261112/run.py
```

Fresh private project copies the actual preload/load closure and required existing extension, with only existing Review2Isolation autoload. No game main scene/autoload or GPU test. report.json records source_unchanged=true, real_profile_unchanged=true and private_canary=true, dependency hashes and exact exit codes. Private project: C:\dev\SternenBuergerchen-worktrees\native-glut-maps-20261110\.godot\ap7_contract_checks\02f174439c1c49ea8ecdfbcfe65c5c9c
Private user: C:\Users\bjoer\AppData\Roaming\Godot\app_userdata\SB-Codex-Review2-b51991781dea426c8c3b538425048b8c

Partial AP7 authority boundary only. Root per-recipient hidden-enemy filtering, host-only reservations, Ground save/restore and final AP7/AP8/network/native acceptance remain separate Source/Parent work; no gameplay/exploit-completeness or performance claim.

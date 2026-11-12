# AP8 twelve-field joint passage roundtrip — partial

Only fixture scripts/tests/hex_tactical_slice_verifier.gd changed, plus own Task
AP8_JOINT_PASSAGE_ROUNDTRIP_2026_11_12.md and this QA/runner. No product/shared
runner writes, stage/commit, activation, live map, scene, GPU/native or EXE.

Final15/0, individual fixture --check-only Exit0, actual Godot4.6.2 private import
and one fixture. report.json: partial_ready=true/full_ap8=false, source_unchanged,
real_profile_unchanged and private_canary all true. HomebaseScreen is NOT in the
closure; own runner explicitly refuses that WIP dependency before starting.

Same actual Root component graph,12 actual TerrainRegistry tiles and three
Known/Registry-bound CapabilityNPCs. Two real queued commands wait at closed door,
then actual Driver opens it. Exactly once, leader logical cell(3,0) is the actual
half-height ramp, a committed segment is in flight and passage grant exists:

1. Actual Groundv2 and Movementv1 export, JSON primitive roundtrip, two accepted
   original movement goals. NO command fields/tokens stripped by fixture.
2. Actual Ground.prepare_restore_state, get_prepared_restore_ground, then actual
   Movement.prepare_restore_state against that real detached target.
3. Actual Root-facing/stop/release policy gates tested via controlled authority
   refusal. They reject without Ground mutation. This is NOT a real network peer
   or a new public Root-checkpoint/restore authorization API.
4. Both actual validators finish BEFORE first publication. Ground private tail
   directly followed by Movement private tail, no getters/checks/callbacks between.
5. Same Root/Ground/Movement instances retained; JSON semantic Ground state,
   position/height projection, actual Actorpositions and original command IDs/goals
   retained. NO Actorposition assignment added to the roundtrip.
6. Continue normal Root ticks, current claims/door-close refusal, ordered passage,
   detection, actual FireDecisionResolver attackability, both command arrivals and
   post-arrival facing invalidation. Existing eight consumer checks still pass.

The private model restore APIs are trusted inprocess boundaries with owner/context
validation; they are not independently peer-authorized. Root public command/lifecycle
gates are tested separately. Root filecheckpoint admission, publication filtering,
network receiver and fresh-session Actor creation remain unproven. This is an
inplace same-Root composition, not an end-to-end save/load/network proof.

Evidence kept:
- red.log/report: prior eight-check fixture was green but lacked required joint
  marker, so own new runner rejected readiness (no product defect alleged).
- actual_root_red.log/report: real unsupported _hex_lifecycle stamped by Root,
 10/2 while old eight checks stayed green, all guards true. Parent fixed the actual
 Movement export boundary separately; fixture never removed that dictionary.
- authority_assumption_red.log/report:15/1, correct joint restore already passed;
 mistaken extra expectation for peer authority inside Movement validator removed.
 This was a fixture correction, not a hidden product fix or successful proof.

Final markers: AP7_JOINT_PASSAGE_ROUNDTRIP_READY plus existing
HEX_TACTICAL_SLICE_PARTIAL_READY. full_ap8=false/root_checkpoint=false/
host_publication=false/receiver=false/real_peer=false. Never final AP8 pass.

```powershell
python output/native_glut_maps/ap8_joint_passage_roundtrip_20261112/run.py
```

Own runner copies actual GD preloadclosure and existing isolated user guard into
a fresh minimal private project, uses the existing runner's fingerprint/error
helpers read-only, and records copied hashes. No inherited broad verifier suite.

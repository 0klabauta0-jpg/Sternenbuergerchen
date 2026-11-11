# AP8 tactical slice — partial only, frozen

Only new files: scripts/tests/hex_tactical_slice_verifier.gd, own task HEX_TACTICAL_SLICE_PARTIAL_2026_11_12.md and this QA package. Base2f47421c0. No Runtime/runner/shared-doc edits, no git add/commit or live map activation.

The new standalone composition does not inherit or run earlier full fixtures. It uses real SimulationRoot, HexGroundRuntime, TerrainRegistry, UnitRegistry, MissionCombatLoopDriver door mutation/guard, VisibilityCache, HexSightRuntimeAdapter, HexDetectionState and CombatFireDecisionResolver. The Driver subclass suppresses only automatic scene startup; lookup remains actual Registry lookup. Three real Node2D CapabilityNPCs provide actual command/position/skill methods; none implements movement, sight, restore or a second simulation. Two movers and one stationary opposing target occupy distinct admitted cells.

Exactly12 registered hexes: ten-column corridor, H0→explicit H+0.5 ramp→H1, real blocked door, two side exits. The first10-cell authoring attempt correctly retained the passage grant because its leader goal was still in the corridor; two actual exit cells fixed the fixture geometry, not runtime rules. Initial command state was corrected to unassigned, allowing Root to accept the first real command rather than a synthetic uncommitted Hold.

Final output: HEX_TACTICAL_SLICE_PARTIAL checks=8 failures=0 full_ap8=false; marker HEX_TACTICAL_SLICE_PARTIAL_READY. Checks cover actual admission/size, waiting before a closed route and blocked shot, real door opening with rear-facing target still hidden, exclusive ordered ramp/door passage, closure refusal during a live passage, actual detection after logical field/facing change plus current sight in shot check, both Root command arrivals, and post-arrival rear turn invalidating detection/shot. Evidence: passage_order=[leader,follower], half-height=true, observed detection at logical(7,0).

This is an actual attackability query, not a damage effect, live battle or native shot animation. Normal Driver timing methods are called explicitly at the actual Root tick; rendering does not drive detection. No performance, native visual/GPU, broad matrix or AP9 acceptance.

AP7 is explicitly missing: actual HexGroundRuntime has neither export_state() nor restore_state(); no checkpoint/peer restore owner is exercised. AP6c transport/producer lifecycle is also not part of this narrow setup. No DummyRestore exists. Even an Exit0 here is deliberately NOT HEX_TACTICAL_SLICE_PASS and never full AP8 readiness. Final owner integration and AP8 lifecycle/restore acceptance remain Tabletop/Parent work.

Run only this partial case from worktree root:

```powershell
python output/native_glut_maps/hex_tactical_slice_20261112/run_partial.py
```

The own launcher reads the existing runner's profile fingerprint/error helpers without editing that runner. It copies only the actual GDScript preload/load closure plus required terrain catalog/LimboAI extension into a fresh private project, imports it, runs individual --check-only and the one fixture. report.json records exact commands, source hashes, project/profile paths, source_unchanged=true, real_profile_unchanged=true, private_canary=true. The existing Review2Isolation autoload verifies actual user:// and writes the canary before any test. No game autoload/main scene, real profile write or fake profile-guard claim.

Current private project: C:\dev\SternenBuergerchen-worktrees\native-glut-maps-20261110\.godot\hex_tactical_checks\ap8-partial-6c658ea0b14b44f79f3c98af720c677a\project
Current private user: C:\Users\bjoer\AppData\Roaming\Godot\app_userdata\SB-Codex-Review2-76c342f6c5ae4708a2e059e644790ad8

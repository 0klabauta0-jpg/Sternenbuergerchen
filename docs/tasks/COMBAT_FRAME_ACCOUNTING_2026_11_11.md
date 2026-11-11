# Native B combat: frame accounting before optimization

## Goal and cause
The real 1x B encounter still contains long visible frames. The existing
profile retains only the last SimulationRoot physics tick and reads the
previous view `_process` receipt at the next `process_frame` boundary.
Catch-up frames can contain several ticks. Establish complete, frame-keyed
evidence before choosing a further optimization.

## Scope and non-goals
Add opt-in bounded debug accounting for physics count/sum/max and existing
scopes, frame IDs for view/meta work, and an end-of-draw native collector.
After a fresh native baseline, remove only measured redundant projections
with an unchanged synchronous owner/command lifecycle. Keep all 512x256 maps,
details, actual actors, balance, movement and simulation tempo unchanged.
No armor-proxy changes, release/EXE or integration work in this task.

## Sources
AGENTS.md; docs/ARCHITECTURE.md; docs/CODEX_RULES.md;
docs/dev/mission_hud_projection_authority_contract.md;
docs/tasks/REGIONAL_FIRST_GO_NAVIGATION_2026_11_11.md;
docs/qa/navigation_first_go_20261111/README.md.

## Acceptance
- Every native row joins only receipts stamped with the same process-frame ID.
- All physics ticks in that frame contribute count, sum and maximum; frames
  without ticks contain zero physics work rather than a stale last tick.
- Existing named simulation scopes survive as per-frame sums/maxima.
- View scopes cover pending FoW/chunks/publication; meta scopes distinguish
  services, campaign progress, checkpoint and tutorial work.
- Debug disabled is behavior-preserving; getters do not consume or mutate data.
- Private-profile headless checks cover accounting and owner regressions.
- Native baseline and any after run use the same private post-A checkpoint,
  regular Continue/GO, actual B guard at 1x and unchanged map SHA-256 values.
- Request and receive the coordinating agent's CPU/GPU window before every
  native measurement. No concurrent render/import/benchmark workloads.

## Files and local verification
scripts/core/simulation_root.gd; optional core debug-only helper;
scripts/meta/meta_layer_flow.gd; campaign_tutorial_presenter.gd;
scripts/terrain/terrain_map_3d_view.gd (instrumentation only);
scripts/tests/native_glut_battle_profile.gd; focused verifier;
docs/qa/combat_frame_accounting_20261111/.
Use private APPDATA/LOCALAPPDATA directories beneath output/native_glut_maps.
Do not touch the user's campaign/roster. Record commands, source hashes,
engine/context, raw samples, failures and scope limits in the QA report.

## Risks and open points
Debug instrumentation adds overhead and must report its own work separately.
GPU times describe the last measured viewport render, not whole-game CPU.
Short combat samples are diagnostic and cannot certify general FPS/stutter.
If the baseline does not support a safe narrow fix, finish with diagnosis.

## Result
Implemented opt-in bounded frame accounting and same-frame CPU collection.
The measured redundant tutorial guard projection now reuses the same fresh
owner snapshot. Focused RED/GREEN and owner regressions, plus two private
native 1x B sorties, are recorded in
docs/qa/combat_frame_accounting_20261111/README.md. Both native runs pass37/0
with eight real shots and zero frame-binding errors. Tutorial reads fall2→1.
Whole-frame timings vary beyond this small fix; no broad FPS improvement is
attributed to it. Regional publication and campaign-observation costs remain.
No commit, push, main integration or EXE export in this delegated step.

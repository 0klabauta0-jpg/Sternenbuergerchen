# Polisa Dock-UI — frozen command seam

Product scope only scripts/ui/star_map_screen.gd (+28/-2), own Task
POLISA_DOCK_UI_2026_11_12.md and this QA. No staging/commit, flags/liveJSON,
Root/Adapter/Flow/Canvas edits or owner mutations. Existing _begin_approach unchanged.

Actual full Screen/OrbitCanvas with controlled snapshot/area/command providers.
Actual named Button signal passes through Screen._send to the command recorder;
the recorder deliberately returns a backend rejection, proving existing error
feedback and no UI-side gameplay success. No Root/Visit/Fuel outcome is forged.
Runtime fixture omits strategic 3D ship routes; no model/native proof is claimed.

10/0 checks and individual Screen compile Exit0. red.log has the clean original
missing-button failure1/1, before product edits. Earlier private runner setup
needed its shader and real star_system JSON closure; those setup errors are
not used as product RED. check.log/report.json record final true source/profile
guards and actual private Isolationcanary. Fresh minimal project, copied actual
preload closure, no game main scene, no broad test suite/native/GPU/EXE.

Checks: no autopick; explicit local ship and visible orbit; exact five payload
fields and unique request IDs; fresh Area DTO read on click; stale revision;
system view; removed Actor closes local view; hidden Screen; missing provider.
New controls reuse existing _button/_style_buttons. Current ownship identity is
the explicitly selected matching Actor from the authoritative ownship Area DTO;
UI does not decide ownership, Gate/Claim, Fuel, Crew or Visit eligibility.

Visible existing orbit polls retain their0.1s cadence. Each provider update and
click immediately synchronizes affordance; a hidden Screen cannot send. Static
strategic destination selection/approach logic stays unchanged. Backend/RootDTO
and reviewed callback fix are required for paired integration. No actual dock,
R08 arrival, native aesthetics or full gameplay acceptance.

Run only this small probe from the worktree root:

```powershell
python output/native_glut_maps/polisa_dock_ui_20261112/run_check.py
```

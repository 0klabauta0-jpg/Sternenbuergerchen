# Polisa station dock layout — frozen pure technical geometry

Existing task SPACE_POLISA_LOCAL_DOCK_2026_11_12.md, Parent base8905d56b9. Only new product helper scripts/mission/polisa_station_dock_layout.gd, own docs/dev/polisa_station_dock_layout_contract.md and this QA package. No existing file, UI/Runtime/GFX/Root/Travel/Pad data changed; no git stage/commit.

build() returns exactly the agreed detached offset value descriptor: schema space_station_dock_layout.v1, revision polisa_glut2_dock_v1, body glut_2, area orbit_approach:glut_2, station polisa, target polisa_station_dock, map bounds512x256, anchor(256,124), blockRect2i(244,116,24,12), gate(256,133). No surface_location_id, fake SC metre or R08 pad measurement. It rejects inconsistent existing OrbitApproachLayout identity/bounds and tests block/gate separation from the real bounded body mask/entryband. No whole-map scan or scene/owner access; caller caches by area/revision, not per frame.

check.log: POLISA_DOCK_LAYOUT_RESULT checks=6 failures=0 runtime_wired=false visual_approved=false. Six scenarios: exact identity/revision; exact offset geometry; anchor/block/bounds/gate; body/entryband separation; no surface/extra body; detached repeat builds/upstream unchanged. compile.log: individual Godot4.6.2 --check-only Exit0.

Run only this small check from worktree root:

```powershell
python output/native_glut_maps/polisa_station_dock_layout_20261112/run_check.py
```

Fresh private minimal project with only helper, existing OrbitApproachLayout, fixture and existing Review2Isolation autoload. report.json includes exact commands, dependency hashes and true source_unchanged/real_profile_unchanged/private_canary guards. No game main scene or game autoload. Private project: C:\dev\SternenBuergerchen-worktrees\native-glut-maps-20261110\.godot\polisa_dock_layout_checks\7a673597d1d14dc88d98e7c520a15d93
Private user: C:\Users\bjoer\AppData\Roaming\Godot\app_userdata\SB-Codex-Review2-1de8df20947e4f11a0609a1f4b667e9a

Technical starting geometry only. No native screenshot, aesthetic approval, Runtime docking/undocking, navigation, claims, pilot/crew, visit/pad/fuel transaction or live route activation is claimed. Existing station R08 and strategic Polisa path remain unchanged. No broad tests/GPU or commit.

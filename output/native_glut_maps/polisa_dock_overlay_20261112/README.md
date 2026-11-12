# Polisa dock overlay â€” read-only readiness, frozen

Product scope ONLY scripts/ui/orbit_area_canvas.gd. Own Task POLISA_DOCK_OVERLAY_2026_11_12.md and this package. Basea64788a7d; shared descriptor from31551cc64. No Flow/Screen/Adapter/Root/helper/model/roomdesign/route edits, no stage/commit.

Overlay appears only for ok=true Root-shaped Area DTO, canonical Glut2 area and exactly one two-field dock_targets record with target_id polisa_station_dock and revision polisa_glut2_dock_v1. Missing/wrong/ambiguous record hides it immediately. No target is inferred from Area or body alone. Station block silhouette/Polisa caption and separate gold Dockgate marker read the same shared descriptor. Explicit offset->axial->plane conversion; no camera-derived coordinates or SC-metre/pad assumptions.

Descriptor and plane polygons are cached per area/revision (including failed descriptor result); Ship pose updates retain this cache and do not invalidate static drawing. Camera, area/layout and overlay-visibility changes redraw static commands. Existing ship/static split remains. Valid visible station block suppresses inside-block Move intents; existing global Area bounds/static mask also remain in force. A free Dockgate marker is only a display and existing Move intent, never a dock action or permit. No new button/command/job or automatic craft selection.

check.log: POLISA_DOCK_OVERLAY_RESULT checks=9 failures=0 docking_commands=false visual_approved=false. Actual Control/Canvas and real shared descriptor/Hex helpers; controlled Root-shaped DTO, not real gameplay activation. The original eight checks cover missing/wrong target, exact descriptor selection, coordinate conversion/picking, blocked station vs existing ID/cell Move at gate, static-cache retention/source immutability after Ship motion, camera-cache retention, wrong revision/area hiding, and restored cached overlay without selected craft or DTO alias.

compile.log: Godot4.6.2 individual Canvas --check-only Exit0. Reproduce only this small probe:

```powershell
python output/native_glut_maps/polisa_dock_overlay_20261112/run_check.py
```

Fresh private minimal project copies only actual Canvas/geometry preload closure, fixture and existing Review2Isolation guard; no game main scene/autoload, GPU or imported R08 model. report.json records commands/dependency hashes, source_unchanged=true, real_profile_unchanged=true and private_canary=true. Private project: C:/dev/SternenBuergerchen-worktrees/native-glut-maps-20261110/.godot/polisa_dock_overlay_checks/d6918e004f4b4ae281d0b24546abb535
Private user: C:/Users/bjoer/AppData/Roaming/Godot/app_userdata/SB-Codex-Review2-8a0dae7dcf2f4466b360e0debb45da37

Graphics status: technical native 2D overlay candidate using existing StarMapCanvas palette/caption style, no new imagery/model/room design. No screenshot/native rendering review and no aesthetic approval claimed. Runtime DTO delivery, Dock/Undock public APIs and actual gameplay/native acceptance remain separate Source/Parent work. No broad suite/EXE/commit.

Parity review: one additional side-boundary regression reproduced RED9/1 (parity_red.log). Current GREEN is9/0. The hull now reads the actual68 perimeter hexes of the24x12 station block, covering odd/even row shifts before computing its cached plane hull. No interior/fullmap loop, per-pose rebuild, new owner or renderer. Individual compile and all three isolation guards remain true.

# Orbit approach authoring candidate

Current source: scripts/mission/orbit_approach_layout.gd. Base ec5bf93c0. Task docs/tasks/ORBIT_APPROACH_LAYOUT_2026_11_11.md; separate unwired contract docs/dev/orbit_approach_layout_contract.md.

geometry_check.gd / geometry_check.log: ORBIT_LAYOUT_RESULT checks=8 failures=0 runtime_wired=false.
compile.log: Godot4.6.2 --check-only exit0, engine banner only.

Pure data only: local512x256 bounds, lower32-row arrival band, centered nominal256-wide circular limb with4-row visible sagitta and radius2050; gate candidates derive from the same limb. No ship placement, travel, squadron, blockade, admission, access permission, strategic256-grid mutation, current3-marker replacement or new simulation. Each build is fresh data. No GPU/native/battle/performance acceptance or commit.

# Polisa dock overlay: read-only projection readiness

## Goal / cause
The existing local OrbitAreaCanvas may display the shared technical station target only when an authoritative Area DTO explicitly exposes the agreed target/revision. No docking command, button, navigation job or second gameplay owner is added.

## Scope / sources
Only scripts/ui/orbit_area_canvas.gd plus this task and own QA. Read PROJECT_BRIEF/ARCHITECTURE/CODEX_RULES/IMPLEMENTATION_STATUS, graphics_reference_revision_contract.md, polisa_station_dock_layout_contract.md and shared descriptor from31551cc64. No Flow/Screen/Adapter/Root/helper/live data edits or git stage/commit.

## Contract / acceptance
Show station geometry exclusively for ok=true, canonical orbit_approach:glut_2 and a single exact dock_targets record {target_id:polisa_station_dock,revision:polisa_glut2_dock_v1}. Missing/wrong/ambiguous records immediately hide the overlay. This is a projection filter, not authority. The shared descriptor supplies station block, anchor and distinct gate; explicit offset->axial->plane conversion uses the existing shared Hex helpers. Render a technical station silhouette/Polisa label and separate dockgate marker in the existing StarMapCanvas palette; no new R08 rooms/model/asset or aesthetic claim.

Cache detached descriptor/plane draw geometry by area/revision. Ship pose updates neither rebuild it nor invalidate the static layer; camera/layout/target-visibility changes do. Existing static/ship drawing split remains. A visible valid station block rejects inside-block Move intents locally, while Root independently validates every request. Gate display grants no permit or dock action.

## Local checks / boundaries
A few focused headless projection/picking/cache/source-copy checks plus individual compile in a fresh minimal private project/profile. No GPU/screenshot/broad suite. Own evidence output/native_glut_maps/polisa_dock_overlay_20261112. Root target DTO and real docking owner are separate activation prerequisites; no public docking API is assumed. Technical readiness only, native aesthetics and docking acceptance remain open.

## Result / frozen evidence
Basea64788a7d. Eight focused checks passed, 0 failures; isolated individual Canvas compile Exit0. True source/profile/canary guards in report.json. Plane hull/gate and detached descriptor cache survive pose/camera updates; invalid target removes projection immediately. Failed descriptor builds are also cached to avoid repeat build attempts. No rendered screenshot or aesthetic approval. No Dock command/authority or public Source API assumed. Only Canvas product delta, own Task/QA; Parent owns staging/integration.

## Parity review correction / renewed freeze
One added regression covers all six corners of side-boundary cells(244,126) and(267,117), with polygon edges included as contained. RED9/1 in parity_red.log; GREEN9/0 after building the hull from actual perimeter hexes of both row parities. The24x12 block visits only68 perimeter cells once per area/revision cache; no whole-block/map scan or new renderer. Existing eight checks remain, individual compile Exit0 and source/profile/canary guards true. Only Canvas and own QA/task changed. Native/GPU/visual approval remain absent.

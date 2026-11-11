# Polisa R03 integrated visual and authored map

Root opened both final native candidate images: six pads at front/rear, rings and solar arrays on the long-axis ends, six real rooms and three existing R07 armor displays. Actual view hexes are clear in the close view; fine at whole-station scale.

Production uses the existing scene/script/map/location IDs. The candidate script is copied without executable changes (LF normalization only); the only candidate-map change is the production props scene path. All six landing pad IDs are registered in locations.json. tools/build_polisa_station.py now rebuilds R03 from the same layout rather than restoring the old compact station.

5565 deck tiles /4899 walkable in one connected component. Native candidate art: Godot4.6.2 D3D12, exit0, no errors/warnings.14124 static triangles/9 groups plus22472 display triangles/6 meshes. No new actor owners, collisions, dynamic lights or frame loops. source art/polisa_r03_20261111 retains reference provenance, layout target and original frozen hashes. The earlier shader-cache-path failure remains in the art output; the final private absolute profile succeeded.

Large pads28x34 contain clear24x30 design envelopes; this is future freighter space, not a verified Caterpillar model or landing. Source fixture updated for the new pad binding and batched visuals; no repeated old full economy fixture. Native travel/shop/boarding/save/battle/FPS acceptance remains deferred by user. Station-specific hex material lifts lines above the deck and keeps enough far contrast; other map defaults remain unchanged.

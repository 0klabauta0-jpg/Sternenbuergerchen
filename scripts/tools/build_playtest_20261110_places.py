"""Expand authored places around unchanged anchors; no runtime generation.

Signed axial coordinates are already supported by TerrainRegistry and the hex
view's bounds derived from actual tiles. Stable seed/hash, no global RNG stream.
Run once on the pre-expansion maps; repeated invocation is an explicit no-op.
"""
from pathlib import Path
import hashlib
import json
import math

ROOT = Path(__file__).resolve().parents[2]
NAMES = ["campaign_intro_base", "homebase_frontier_exploration", "satellite_crash_site", "trade_outpost"]
MIN_Q, MIN_R, WIDTH, HEIGHT = -30, -30, 96, 98


def noise(name, q, r):
    return int.from_bytes(hashlib.sha256(f"place-v1:{name}:{q}:{r}".encode()).digest()[:4], "big") / 2**32


def ground(q, r):
    return dict(grid_position=dict(x=q, y=r), type_id="ground_flat", walkable=True,
                blocks_los=False, cover_value=0, height_level=0, object_height=0,
                surface_type="sand", edge_type="none")


def expand(name):
    path = ROOT / "maps" / (name + ".json")
    data = json.loads(path.read_text(encoding="utf-8-sig"))
    if data.get("place_world", {}).get("version") == 1:
        return data
    old_width, old_height = data["grid_size"]["x"], data["grid_size"]["y"]
    old = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in data["tiles"]}
    cells = []
    for q in range(MIN_Q, MIN_Q + WIDTH):
        for r in range(MIN_R, MIN_R + HEIGHT):
            inside = 0 < q < old_width - 1 and 0 < r < old_height - 1
            tile = old[q, r] if inside and (q, r) in old else ground(q, r)
            if not inside:
                # Wide clear valley around the original place, with connected
                # geological groups farther out; never a repeated border fence.
                distance = math.hypot(q - old_width / 2, r - old_height / 2)
                ridge = math.sin(q * .13) + math.cos(r * .17) + math.sin((q+r)*.09)
                if distance > 22 and ridge > 1.55 and noise(name,q,r) < .20:
                    tile.update(walkable=False, blocks_los=True, object_type_id="spacekit_rock_large_a",
                                object_scale=1.1 + noise(name,r,q)*.8,
                                object_rotation_degrees=int(noise(name,q+1,r)*360), surface_type="rock")
                elif abs(q-10) <= 1 or abs(r-10) <= 1:
                    tile["surface_type"] = "ground"
            cells.append(tile)
    data["grid_size"] = dict(x=WIDTH, y=HEIGHT)
    data["tiles"] = cells
    data["place_world"] = dict(version=1, seed="place-v1:"+name,
                               axial_min=[MIN_Q, MIN_R], core_bounds=[0,0,old_width,old_height],
                               source="Authored September reference; unchanged original place anchors and furnished models")
    path.write_text(json.dumps(data, ensure_ascii=False, separators=(",", ":"))+"\n", encoding="utf-8")
    return data


def extend_base_navigation(coarse):
    path = ROOT / "maps/base_interior_navigation.json"
    nav = json.loads(path.read_text(encoding="utf-8-sig"))
    if nav.get("place_world", {}).get("version") == 1:
        return
    old_width, old_height = nav["grid_size"]["x"], nav["grid_size"]["y"]
    old = {(t["grid_position"]["x"], t["grid_position"]["y"]): t for t in nav["tiles"]}
    coarse_cells = {(t["grid_position"]["x"],t["grid_position"]["y"]):t for t in coarse["tiles"]}
    cells = []
    for q in range(MIN_Q*4, (MIN_Q+WIDTH)*4):
        for r in range(MIN_R*4, (MIN_R+HEIGHT)*4):
            # Preserve the tested room/capsule-clearance interior exactly.
            inside = 4 <= q < old_width-4 and 4 <= r < old_height-4
            if inside and (q,r) in old:
                tile = old[q,r]
            else:
                tile = ground(q,r)
                coarse_tile = coarse_cells.get((q//4,r//4))
                tile["walkable"] = bool(coarse_tile and coarse_tile["walkable"])
                tile["blocks_los"] = not tile["walkable"]
            cells.append(tile)
    nav["tiles"] = cells
    nav["grid_size"] = dict(x=WIDTH*4,y=HEIGHT*4)
    nav["place_world"] = dict(version=1, axial_min=[MIN_Q*4,MIN_R*4], core_clearance_preserved=True)
    path.write_text(json.dumps(nav,ensure_ascii=False,separators=(",", ":"))+"\n",encoding="utf-8")


if __name__ == "__main__":
    places = {name: expand(name) for name in NAMES}
    extend_base_navigation(places["campaign_intro_base"])
    print("Authored 4 places with 9408 hexes each; original room clearance retained in extended navigation.")

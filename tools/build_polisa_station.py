"""Authored compact orbital deck; no external model imports or game-state owner."""
from pathlib import Path
import json,math
ROOT=Path(__file__).resolve().parents[1]
def inside(x,z):
    return (-9<=x<=9 and -8<=z<=8) or (-28<=x<=-15 and -5<=z<=5) or (15<=x<=28 and -5<=z<=5) or (-5<=x<=5 and 15<=z<=28) or (-17<=x<=17 and -1.6<=z<=1.6) or (-1.6<=x<=1.6 and 6<=z<=17)
def world(q,r):
    x,z=q+r*.5,math.sqrt(3)*.5*r
    return {"x":64*(x-z),"y":32*(x+z)}
def main():
    tiles=[]
    for r in range(-48,48):
        for q in range(-48,48):
            x,z=q+r*.5,math.sqrt(3)*.5*r
            if not inside(x,z):continue
            # Low kiosks and outer hub walls are real blockers; four entrances stay open.
            wall=(-9<x<9 and 7.0<abs(z)<8 and abs(x)>2) or (8.5<abs(x)<9.1 and abs(z)<7 and abs(z)>2) or any(abs(x-cx)<1.5 and abs(z-cz)<.6 for cx,cz in [(-5,-4.7),(5,-4.7),(-5,4.6),(5,4.6)])
            tiles.append({"grid_position":{"x":q,"y":r},"type_id":"ground_flat","height_level":0,"surface_type":"road","edge_type":"none","walkable":not wall,"blocks_los":wall,"object_height":1 if wall else 0,"cover_value":35 if wall else 0})
    markers={"spawn_alpha":world(-21,0),"spawn_bravo":world(21,0),"ship_return":world(-21,0),"objective_point":world(0,0),"trade_service":world(0,0),"polisa_pad_01":world(-21,0),"polisa_pad_02":world(21,0),"polisa_pad_03":world(-12,24)}
    for key,value in markers.items():value.update(marker_type_id="spawn_alpha" if key.startswith("polisa_pad") else key,name=key,placement_context="editor_only",symbol="circle")
    data={"map_name":"Polisa / Freie Raumstation","grid_topology":"hex_axial_v1","grid_size":{"x":96,"y":96},"grid_origin":{"x":0,"y":0},"tile_size":{"half_width":64,"half_height":32},"terrain_visual_theme_id":"frontier_illustrated_v1","mission_slot_count":4,"markers":markers,"tiles":tiles,"patrol_paths":{},"enemy_team_configs":{},"place_presentation":{"orbital_station":True,"initial_camera_size":38.0,"props":[{"path":"res://scenes/terrain/polisa_station_visual.tscn","center":[0,0],"scale":1.0}],"structures":[],"pads":[]},"place_world":{"id":"polisa","kind":"orbital_station","version":1}}
    (ROOT/"maps/polisa_station.json").write_text(json.dumps(data,ensure_ascii=False,separators=(",",":"))+"\n",encoding="utf-8")
    print("POLISA deck cells",len(tiles))
if __name__=="__main__":main()

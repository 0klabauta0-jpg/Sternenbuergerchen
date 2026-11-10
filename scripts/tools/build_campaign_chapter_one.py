"""Offline, deterministic chapter content authoring. No runtime state mutation."""
from pathlib import Path
import copy
import json
import math

ROOT = Path(__file__).resolve().parents[2]

def load(path):
    return json.loads((ROOT / path).read_text(encoding="utf-8"))

def save(path, value, compact=False):
    (ROOT / path).write_text(json.dumps(value, ensure_ascii=False, indent=None if compact else 2,
                                     separators=(",", ":") if compact else None) + "\n", encoding="utf-8")

def plane(grid):
    q, r = grid
    return q + r * .5, r * math.sqrt(3) * .5

def marker(d, name, grid, label, kind="interaction_computer"):
    x, z = plane(grid)
    d["markers"][name] = {"x": d["grid_origin"]["x"] + (x-z)*64,
                          "y": d["grid_origin"]["y"] + (x+z)*32,
                          "marker_type_id": kind, "name": label,
                          "placement_context": "editor_only", "symbol": "circle"}

def tile_index(d):
    return {(int(t["grid_position"]["x"]), int(t["grid_position"]["y"])): t for t in d["tiles"]}

def clear_disc(d, grid, radius=2):
    for (q, r), tile in tile_index(d).items():
        dq, dr = q-grid[0], r-grid[1]
        if max(abs(dq), abs(dr), abs(dq+dr)) <= radius:
            for key in ["object_type_id", "object_scale", "object_rotation_degrees"]:
                tile.pop(key, None)
            tile.update(walkable=True, blocks_los=False, height_level=0, object_height=0, cover_value=0)

def structure(d, ident, grid, hall=False):
    x, z = plane(grid)
    size = [6.0, 2.4, 4.0] if hall else [3.7, 1.6, 3.0]
    presentation = d.setdefault("place_presentation", {})
    presentation["structures"] = [s for s in presentation.get("structures", []) if s.get("id") != ident]
    presentation["structures"].append(
        {"center": [x,z], "hall":hall, "id":ident, "name":ident, "size":size})
    # Same footprint as the current exterior presentation, with half-cell margin.
    for (q,r), t in tile_index(d).items():
        tx,tz = plane((q,r))
        if abs(tx-x) <= size[0]/2+.6 and abs(tz-z) <= size[2]/2+.6:
            t.update(object_type_id="frontier_scene_solid", walkable=False, blocks_los=True,
                     cover_value=80, object_height=3, height_level=0)

def landscape(d, variant):
    # Keep the original settlement core and all original objects/anchors intact.
    # Distant bands form traversable rocky valley floors with isolated ridges.
    for (q,r), t in tile_index(d).items():
        if 0 <= q < 24 and 0 <= r < 20 or t.get("object_type_id"):
            continue
        x,z = plane((q,r))
        center = 12 + 8*math.sin((x+variant*13)/12)
        delta = abs(z-center)
        if delta < 2.4:
            t.update(surface_type="rock", height_level=0, cover_value=0)
        elif 3.5 < delta < 7 and (q+r+variant) % 5 != 0:
            t.update(surface_type="rock", height_level=1, cover_value=20)
        elif (q*17+r*31+variant*7) % 29 == 0:
            t.update(surface_type="rock", height_level=1, cover_value=30)
    d.setdefault("place_world", {})["campaign_landscape"] = {
        "version":1, "variant":variant, "features":["dry_river", "rocky_valley", "low_ridges"],
        "authoring":"offline; original settlement core retained"}

def bind(step, marker_id, label, previous="", duration=3.0):
    binding = {"gate_id":step,"step_id":step,"duration_seconds":duration,
               "required_state":step+"_done","interaction_type":"computer",
               "required_order":"take","radius_world":96.0,"required_team":"team_alpha",
               "display_name":label,"interaction_id":marker_id,"marker_id":marker_id}
    flow = {"step_id":step,"min_hold_seconds":duration,"objective_type":"interaction_use",
            "required_state":step+"_done","target_marker_id":marker_id}
    if previous:
        binding["requires_step_id"] = previous
        flow["requires_step_id"] = previous
    return binding, flow

def scenario(ident, title, map_name, interactions, enemy_count=0):
    bindings, steps = [], []
    if enemy_count:
        steps.append({"step_id":"clear_outpost", "objective_type":"air_defense_shutdown",
                      "enemy_group_id":"outpost_guards", "required_state":"outpost_cleared",
                      "target_marker_id":"spawn_enemy_defense", "min_hold_seconds":0.0})
    previous = "clear_outpost" if enemy_count else ""
    for step, marker_id, label in interactions:
        binding, flow = bind(step, marker_id, label, previous)
        bindings.append(binding)
        steps.append(flow)
        previous = step
    groups = []
    if enemy_count:
        # Existing data-based tactics profile; one sidearm-only guard is the first fight.
        tactics = {"profile_id":"defensive_cover","stance":"defend","cover_behavior":"hold_best_cover",
                   "security_mode":"cover_arc","facing":"east","advance_style":"hold",
                   "allowed_weapon_roles":["sidearm"] if enemy_count == 1 else ["sidearm","smg"],
                   "sight_behavior":"cover_arc","contact_behavior":"suppress_from_cover",
                   "weapon_profile":"standard_close","weapon_id":"pistol" if enemy_count == 1 else "smg","visual_archetype":"enemy_space_suit_orange",
                   "movement_posture_policy":"hold_ready","ready_distance_world":320.0,
                   "travel_speed_factor":.3,"ready_speed_factor":.2,"aim_move_speed_factor":.15,
                   "heavy_weapon_role":"none","anti_armor_threat":False,"air_asset_risk_profile":"none",
                   "communication_intensity":"low"}
        groups.append({"group_id":"outpost_guards","display_name":"Außenpostenwache",
                       "team_id":"team_bravo","spawn_marker_id":"spawn_enemy_defense",
                       "enemy_ids":[ident+"_guard_%02d" % (i+1) for i in range(enemy_count)],"tactics":tactics})
    return {"version":1,"scenario_id":ident,"display_name":title,"map_file_path":"res://maps/"+map_name+".json",
            "time_limit_seconds":2400.0,"mission_slot_count_override":4,"win_condition":"objective_capture",
            "objective":{"marker_id":"objective_point","capture_radius":80.0},"enemy_groups":groups,
            "wave_config":{"wave_delay_seconds":0.0,"wave_count":1 if enemy_count else 0,
                           "first_wave_delay_seconds":0.0,"units_per_wave":max(1,enemy_count)},
            "patrol_bindings":[],"briefing":{"summary":title+"; Fracht und Personen sicher zurückbringen.",
                "minimap_mode":"terrain_only","objectives":[{"target_id":m,"text":l} for _,m,l in interactions],"title":title},
            "vertical_slice":{"scenario_kind":"singleplayer_job","finite_enemy_roster":bool(enemy_count),"team_slots":[{"role":"recovery",
                "player_assignable_modes":["singleplayer"],"spawn_marker_id":"spawn_alpha","team_id":"team_alpha","npc_owned":False}],
                "play_modes":["singleplayer"],"contract_version":1,"interaction_points":bindings,"flow_steps":steps},
            "notes":["Authored chapter-one content. Runtime gates, not UI clicks, determine completion."]}

def main():
    a = load("maps/satellite_crash_site.json")
    b = load("maps/trade_outpost.json")
    landscape(a,1)
    landscape(b,2)
    # Satellite site is now a genuine expedition beyond the landing area.
    sat=(18,38)
    for t in a["tiles"]:
        if str(t.get("object_type_id","")).startswith("spacekit_satellite_dish"):
            t.pop("object_type_id",None)
            t.update(walkable=True,blocks_los=False,cover_value=0)
    for ident,label in [("satellite_data","Satellitendaten bergen"),("objective_point","Satelliten-Absturzstelle")]:
        marker(a,ident,sat,label,"objective_point" if ident == "objective_point" else "interaction_computer")
    clear_disc(a,sat)
    tile_index(a)[(20,38)].update(object_type_id="spacekit_satellite_dish_detailed",walkable=False,blocks_los=True,object_height=2)
    trader=(38,-8)
    marker(a,"trade_service",trader,"Händler / Lieferung")
    structure(a,"Satellitenregion · Handel",(38,-12),True)
    clear_disc(a,trader)
    # Existing B trade hall stays put; the hostile outpost is far to its southeast.
    outpost=(40,34)
    marker(b,"objective_point",outpost,"Außenposten sichern","objective_point")
    marker(b,"recover_crate",outpost,"Transportkiste übernehmen")
    marker(b,"spawn_enemy_defense",(39,36),"Außenpostenwache","spawn_enemy_defense")
    marker(b,"recruit_contact",(11,9),"Gespräch: Besatzungsmitglied aufnehmen")
    structure(b,"Außenposten · Lager",(39,40),True)
    for grid in [outpost,(39,36),(11,9)]: clear_disc(b,grid)
    c=copy.deepcopy(b)
    c.update(map_name="fortified_outpost",patrol_paths={})
    c["singleplayer_site"]={"location_id":"fortified_outpost","landing_pads":[{"id":"fortified_pad_01","marker_id":"ship_return","grid":[7,11]}],
                              "visual_status":"authored current frontier exteriors; native style acceptance pending"}
    c["place_world"]["seed"]="campaign:fortified-outpost"
    landscape(c,3)
    c["markers"].pop("trade_service",None)
    c["markers"].pop("recruit_contact",None)
    c["markers"].pop("recover_crate",None)
    marker(c,"outpost_chip",(40,34),"Außenposten-Chip bergen")
    c["markers"]["objective_point"]["name"]="Gesicherter Außenposten"
    for d,name in [(a,"satellite_crash_site"),(b,"trade_outpost"),(c,"fortified_outpost")]:
        d["place_world"]["campaign_chapter"]="chapter_one_v1"
        save("maps/"+name+".json",d,True)
    # Orbit scene data is consumed by the dedicated encounter runtime, never a fake ground fight.
    space={"map_name":"distress_orbit","grid_topology":"hex_axial_v1","grid_size":{"x":24,"y":24},
           "grid_origin":{"x":0,"y":0},"tile_size":{"half_width":64,"half_height":32},
           "mission_slot_count":4,"tiles":[],"markers":{},"patrol_paths":{},"enemy_team_configs":{},
           "space_encounter":{"id":"buccaneer_rescue","hostile":{"craft_id":"hostile_cutlass","model_id":"cutlass","faction":"hostile"},
                              "neutral":{"craft_id":"neutral_buccaneer","model_id":"buccaneer","faction":"neutral"}}}
    for q in range(24):
        for r in range(24):
            space["tiles"].append({"grid_position":{"x":q,"y":r},"type_id":"ground_flat","walkable":True,"blocks_los":False,
                                   "cover_value":0,"height_level":0,"object_height":0,"surface_type":"ground","edge_type":"none"})
    for ident,grid in [("spawn_alpha",(3,12)),("spawn_bravo",(20,12)),("objective_point",(15,12)),("cutlass_contact",(20,12)),("buccaneer_contact",(15,12))]:
        marker(space,ident,grid,ident,"spawn_alpha" if ident=="spawn_alpha" else "interaction_computer")
    save("maps/distress_orbit.json",space,True)

    definitions=[
        ("satellite_recovery","Satellitendaten bergen","satellite_crash_site",[("secure_satellite","satellite_data","Satellitendaten sichern"),("return_to_ship","ship_return","Mit dem Chip zum Schiff zurückkehren")],0),
        ("outpost_recovery","Ersten Außenposten sichern","trade_outpost",[("recover_crate","recover_crate","C-Benit-Transportkiste sichern"),("return_to_ship","ship_return","Fracht zum Schiff zurückbringen")],1),
        ("benit_delivery","C-Benit zum Satelliten-Handelsposten liefern","satellite_crash_site",[("deliver_benit","trade_service","Transportkiste am Handelsposten abgeben"),("return_to_ship","ship_return","Nach der Lieferung zum Schiff zurückkehren")],0),
        ("outpost_chip_recovery","Chip aus gesichertem Außenposten bergen","fortified_outpost",[("secure_outpost_chip","outpost_chip","Außenposten-Chip sichern"),("return_to_ship","ship_return","Mit dem Chip zum Schiff zurückkehren")],2),
        ("buccaneer_rescue","Buccaneer im Weltraum retten","distress_orbit",[("enemy_cutlass_destroyed","cutlass_contact","Feindliche Cutlass besiegen"),("rescue_buccaneer","buccaneer_contact","Neutrale Buccaneer retten")],0)]
    locations_by_job=["satellite_crash","trade_outpost","satellite_crash","fortified_outpost","distress_orbit"]
    credits=[150,100,100,250,300]
    blueprint=["light_armor","","mining_tool","assault_rifle",""]
    jobs={}
    previous=""
    for i,(ident,title,map_name,interactions,enemies) in enumerate(definitions):
        scen=scenario(ident,title,map_name,interactions,enemies)
        if ident in ["satellite_recovery", "outpost_recovery"]:
            service, _ = bind("trade_service", "trade_service", "Händler / Tankservice", duration=2.0)
            scen["vertical_slice"]["interaction_points"].append(service)
        if ident=="buccaneer_rescue":
            scen["space_encounter"]=space["space_encounter"]
            scen["notes"].append("Dedicated ship-combat runtime owns combat and verified completion; ground Use cannot resolve this encounter.")
        save("data/mission_scenarios/"+ident+".json",scen)
        reward={"credits":credits[i]}
        if blueprint[i]: reward["blueprint_id"]=blueprint[i]
        jobs[ident]={"id":ident,"title":title,"description":title+". Bestätigten Fortschritt im Auftrag verfolgen.",
                     "location_id":locations_by_job[i],"scenario_id":ident,"prerequisite_job_id":previous,
                     "home_upload":i in [0,3],"required_step_ids":(["clear_outpost"] if enemies else [])+[x[0] for x in interactions],"reward":reward}
        previous=ident
    save("data/singleplayer/jobs.json",jobs)
    locations=load("data/singleplayer/locations.json")
    locations["satellite_crash"]["services"]=["trade","refuel"]
    locations["trade_outpost"]["scenario_file_path"]="res://data/mission_scenarios/outpost_recovery.json"
    for ident,title,pos,map_name,scen in [("fortified_outpost","Gesicherter Außenposten",[.5,.83],"fortified_outpost","outpost_chip_recovery"),
                                        ("distress_orbit","Notruf im Planetenorbit",[.91,.38],"distress_orbit","buccaneer_rescue")]:
        locations[ident]={"id":ident,"name":title,"region_position":pos,"map_file_path":"res://maps/"+map_name+".json",
                          "scenario_file_path":"res://data/mission_scenarios/"+scen+".json",
                          "landing_pad_ids":["fortified_pad_01" if ident=="fortified_outpost" else "distress_rendezvous_01"],"services":[]}
    save("data/singleplayer/locations.json",locations)
    resources=load("data/singleplayer/location_resources.json")
    resources.setdefault("fortified_outpost", {})
    resources.setdefault("distress_orbit", {})
    # Keep existing salvage opportunities, convert the old ore source into Benit.
    resources["satellite_crash"]["iron_ridge_01"].update(name="A-Benit abbauen",item_id="a_benit",quantity=8)
    for loc,ident,item,grid in [("satellite_crash","b_benit_01","b_benit",[31,25]),
                               ("trade_outpost","a_benit_01","a_benit",[18,29]),
                               ("trade_outpost","c_benit_01","c_benit",[29,10])]:
        resources.setdefault(loc,{})[ident]={"name":item.replace("_","-").title()+" abbauen","item_id":item,"quantity":8,
            "required_tool":"mining_tool","duration_seconds":4.0,"radius_world":96.0,"discovery_radius_world":384.0,"grid":grid,"kind":"ore"}
    for loc,map_name in [("satellite_crash","satellite_crash_site"),("trade_outpost","trade_outpost")]:
        d=load("maps/"+map_name+".json")
        for site in resources[loc].values(): clear_disc(d,site["grid"],1)
        save("maps/"+map_name+".json",d,True)
    save("data/singleplayer/location_resources.json",resources)
    trade=load("data/singleplayer/trade_offers.json")
    trade["service_locations"]["satellite_crash"]=["trade","refuel"]
    trade["service_locations"]["fortified_outpost"]=[]
    trade["service_locations"]["distress_orbit"]=[]
    # Prices/quantities are initial balancing values, not user-approved final values.
    trade["benit_buy_orders"]={"satellite_crash":{"c_benit":12},"trade_outpost":{"b_benit":12}}
    for dest in ["fortified_outpost","distress_orbit"]:
        trade["route_fuel_costs"]["homebase>"+dest]=10.0
        trade["route_fuel_costs"][dest+">homebase"]=10.0
    save("data/singleplayer/trade_offers.json",trade)

if __name__ == "__main__":
    main()

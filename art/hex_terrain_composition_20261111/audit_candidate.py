"""Bounded offline authoring audit; does not launch Godot or touch live maps."""
import importlib.util
import json
from collections import Counter, deque
from hashlib import sha256
from pathlib import Path
import subprocess
import sys

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"output/native_glut_maps/explicit_ramps_candidate"
ART=Path(__file__).resolve().parent
COMPILER=ROOT/"scripts/tools/build_native_glut_ground.py"
spec=importlib.util.spec_from_file_location("glut_compiler",COMPILER)
compiler=importlib.util.module_from_spec(spec)
spec.loader.exec_module(compiler)
hashes={z:sha256((OUT/(name+".json")).read_bytes()).hexdigest() for z,name in compiler.MAPS.items()}
if "--repeat" in sys.argv:
    subprocess.run([sys.executable,str(COMPILER),"A","B","C"],cwd=ROOT,check=True)


def connected(index, goals, excluded=frozenset()):
    start=(7,11);reached={start};queue=deque([start])
    while queue:
        current=queue.popleft()
        if current in goals:return True
        for dq,dr in compiler.DIRECTIONS:
            target=(current[0]+dq,current[1]+dr)
            if target not in reached and target not in excluded and compiler.can_cross(index,current,target):
                reached.add(target);queue.append(target)
    return False


results=[]
for z,name in compiler.MAPS.items():
    path=OUT/(name+".json")
    data=json.loads(path.read_text(encoding="utf8"))
    baseline=json.loads((ROOT/"maps"/(name+".json")).read_text(encoding="utf8"))
    index={(t["grid_position"]["x"],t["grid_position"]["y"]):t for t in data["tiles"]}
    report=json.loads((OUT/f"{z}_authoring_check.json").read_text())
    failures=list(report["failures"])
    stable_keys=["markers","patrol_paths","enemy_team_configs","singleplayer_site",
                 "place_presentation","map_name","grid_origin","tile_size","grid_topology"]
    changed=[key for key in stable_keys if baseline[key]!=data[key]]
    if changed:failures.append(["metadata_changed",changed])
    checksum=sha256(path.read_bytes()).hexdigest()
    reproducible=checksum==hashes[z]
    if not reproducible:failures.append(["not_reproducible"])
    offsets={(q+r//2,r) for q,r in index}
    expected={(x,r) for x in range(-170,342) for r in range(-108,148)}
    if offsets!=expected:failures.append(["extent_mismatch"])
    peaks=[p for p,t in index.items() if t["height_level"]>0 and t["ramp_direction"]<0
           and not t.get("object_type_id") and all(index.get((p[0]+a,p[1]+b),t)["height_level"]<t["height_level"]
                                                   for a,b in compiler.DIRECTIONS)]
    if peaks:failures.append(["isolated_raised_peak",peaks])
    rocks=lambda d:{(t["grid_position"]["x"],t["grid_position"]["y"]) for t in d["tiles"]
                    if t.get("object_type_id")=="spacekit_rock_large_a"}
    if rocks(data)!=rocks(baseline):failures.append(["legacy_rock_footprint_changed"])
    high={p for p,t in index.items() if t["height_level"]==8 and t["ramp_direction"]<0}
    components=[]
    while high:
        start=high.pop();queue=deque([start]);size=1
        while queue:
            q,r=queue.popleft()
            for dq,dr in compiler.DIRECTIONS:
                p=q+dq,r+dr
                if p in high:high.remove(p);queue.append(p);size+=1
        components.append(size)
    bridges={p for p,t in index.items() if t.get("object_type_id")=="glut_bridge_deck"}
    alternative_checks={}
    if z=="C":
        target=next(a for a in report["marker_checks"] if a["id"]=="objective_point")["axial"]
        goals=set(compiler.hex_disk(*target,2))
        groups={"north":{p for p in bridges if p[1]<0},
                "main":{p for p in bridges if p[1]>0 and p[0]+p[1]*.5<170}}
        for group,blocked in groups.items():
            alternative_checks["objective_reachable_without_"+group+"_bridge"]=connected(index,goals,blocked)
        if not all(alternative_checks.values()):failures.append(["alternate_crossing_failed"])
    results.append({"zone":z,"map":str(path.relative_to(ROOT)),"sha256":checksum,
                    "repeated_build_byte_identical":reproducible,"repeated_build_executed":"--repeat" in sys.argv,
                    "status":"PASS" if not failures else "FAIL","failures":failures,
                    "metadata_differences":changed,"tile_count":len(index),
                    "isolated_objectless_raised_peaks":len(peaks),
                    "height8_components_largest_first":sorted(components,reverse=True),
                    "existing_rock_footprints_preserved":len(rocks(data)),
                    "objects_by_type":dict(Counter(t.get("object_type_id","") for t in data["tiles"] if t.get("object_type_id"))),
                    "alternative_crossings":alternative_checks,"authoring":report})
manifest={"schema":"sternenbuergerchen.hex_terrain_composition.v1",
          "status":"PASS" if all(r["status"]=="PASS" for r in results) else "FAIL",
          "source_baseline":compiler.BASE,"compiler_sha256":sha256(COMPILER.read_bytes()).hexdigest(),
          "terrain_height_rules":"explicit_hex_ramps_v1","regional_terrain_version":3,
          "scope":"offline candidate authoring only; no native gameplay, save, multiplayer or performance acceptance",
          "results":results}
(ART/"manifest.json").write_text(json.dumps(manifest,indent=2),encoding="utf8")
print(json.dumps({"status":manifest["status"],"maps":[{"zone":r["zone"],"status":r["status"],"failures":r["failures"],"sha256":r["sha256"]} for r in results]}))
if manifest["status"]!="PASS":raise SystemExit(1)

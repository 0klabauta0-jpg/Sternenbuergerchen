"""Independent saved-data checks; does not mutate product files."""
from pathlib import Path
import collections
import hashlib
import json
import math
import subprocess

ROOT = Path(__file__).resolve().parents[3]
OUT = Path(__file__).resolve().parent
catalog = json.loads((ROOT/'data/frontier_building_visual_catalog.json').read_text(encoding='utf-8'))
results = []
for name in ['station_outpost_64x64', 'station_outpost_192x192']:
    path = 'maps/' + name + '.json'
    before = json.loads(subprocess.check_output(['git','show','HEAD:'+path], cwd=ROOT, text=True, encoding='utf-8'))
    after = json.loads((ROOT/path).read_text(encoding='utf-8'))
    assert before['markers'] == after['markers']
    assert before['patrol_paths'] == after['patrol_paths']
    lookup = {(t['grid_position']['x'],t['grid_position']['y']):t for t in after['tiles']}
    props = after['place_presentation']['props']
    assert len(props) == (2 if name.endswith('64x64') else 18)
    reserved = set()
    for prop in props:
        entry = catalog[prop['asset_id']]
        assert prop['path'] == entry['model_path']
        yaw = math.radians(prop['rotation_degrees'])
        points = [(prop['center'][0]+prop['scale']*(math.cos(yaw)*x+math.sin(yaw)*z), prop['center'][1]+prop['scale']*(-math.sin(yaw)*x+math.cos(yaw)*z)) for x in [entry['min'][0],entry['max'][0]] for z in [entry['min'][2],entry['max'][2]]]
        xmin,xmax = min(p[0] for p in points),max(p[0] for p in points)
        zmin,zmax = min(p[1] for p in points),max(p[1] for p in points)
        cells = {(x,z) for x in range(math.floor(xmin-.5),math.ceil(xmax+.5)+1) for z in range(math.floor(zmin-.5),math.ceil(zmax+.5)+1) if x+.5 > xmin and x-.5 < xmax and z+.5 > zmin and z-.5 < zmax}
        assert cells == {tuple(g) for g in prop['reserved_grids']}
        for cell in cells:
            tile = lookup[cell]
            assert not tile['walkable'] and tile['blocks_los'] and tile['object_type_id']=='frontier_scene_solid'
        reserved |= cells
    for old in before['tiles']:
        key = (old['grid_position']['x'],old['grid_position']['y'])
        new = lookup[key]
        if key not in reserved:
            assert old == new, key
        else:
            for field, value in old.items():
                if field not in {'object_type_id','walkable','blocks_los','cover_value','object_height'}:
                    assert new.get(field) == value, (key,field)
    origin = after['grid_origin']; sizes = after['tile_size']
    def grid_at(point):
        dx=(point['x']-origin['x'])/sizes['half_width'];dy=(point['y']-origin['y'])/sizes['half_height']
        return round((dx+dy)*.5),round((dy-dx)*.5)
    patrol_cells = [grid_at(p) for route in after['patrol_paths'].values() for p in route]
    assert all(lookup[g]['walkable'] for g in patrol_cells)
    # Stronger than checking points: their cardinal movement graph remains connected.
    seen={patrol_cells[0]}; queue=collections.deque(seen)
    while queue:
        x,y=queue.popleft()
        for g in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]:
            if g not in seen and g in lookup and lookup[g]['walkable'] and abs(lookup[g]['height_level']-lookup[(x,y)]['height_level']) <= 1:
                seen.add(g);queue.append(g)
    assert all(g in seen for g in patrol_cells)
    results.append({'map':path,'buildings':len(props),'unique_reserved_cells':len(reserved),'patrol_waypoints_walkable_and_connected':len(patrol_cells),'markers_exactly_preserved':True,'patrols_exactly_preserved':True,'non_footprint_tiles_exactly_preserved':True,'sha256':hashlib.sha256((ROOT/path).read_bytes()).hexdigest()})

audit = json.loads((ROOT/'docs/qa/building_asset_audit_20261110/inventory.json').read_text(encoding='utf-8'))
unchanged = sum(hashlib.sha256((ROOT/m['path']).read_bytes()).hexdigest()==m['sha256'] for m in audit['models'])
assert unchanged == len(audit['models'])
manifest = json.loads((ROOT/'data/map_builder_workbench_manifest.json').read_text(encoding='utf-8'))
assert not any(p['type_id'] in catalog for p in manifest['demo_layout']['props'])
new_files = [ROOT/e['model_path'][6:] for e in catalog.values()] + list((ROOT/'Assets/curated/frontier_illustrated_20261101/building_previews').glob('*.png'))
receipt = {'maps':results,'original_model_hashes_unchanged':unchanged,'new_assets':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in new_files},'unsafe_workbench_demo_building_absent':True,'navigation_check_scope':'stored cardinal graph, walkable and height delta<=1; not a combat/playability acceptance'}
(OUT/'saved_map_verification.json').write_text(json.dumps(receipt,indent=2)+'\n',encoding='utf-8')
print(json.dumps(receipt))

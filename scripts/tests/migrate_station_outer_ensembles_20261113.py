"""Complete the eight outer authored ensembles, preserving every tile payload."""
import copy
from collections import Counter
import hashlib
import importlib.util
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('initial_station_revision', Path(__file__).with_name('migrate_station_warehouse_layout_20261113.py'))
initial = importlib.util.module_from_spec(spec)
spec.loader.exec_module(initial)
REVISION = 'all_station_ensembles_v1'


def cell(tile):
    return tile['grid_position']['x'], tile['grid_position']['y']


def boundary(tiles, anchor, already_projected):
    corners = [cell(t) for t in tiles if t.get('object_type_id') == 'station_set_wall_corner']
    assert len(corners) == 3, ('unexpected corner family', corners)
    if already_projected:
        corners = [(q + (r-anchor)//2, r) for q, r in corners]
    return [min(q for q, r in corners), min(r for q, r in corners),
            max(q for q, r in corners), max(r for q, r in corners)]


def payloads(tiles):
    return Counter(json.dumps({k:v for k,v in t.items() if k != 'grid_position'}, sort_keys=True) for t in tiles)


def migrate(data):
    result = copy.deepcopy(data)
    layout = result['place_presentation']['station_module_layout']
    assert layout.get('schema') == 'warehouse_axes_v1'
    if layout.get('ensembles_revision') == REVISION:
        return result, {'already_current':True}
    width = int(data['grid_size']['x'])
    assert width in (64, 192) and data['grid_size']['y'] == width
    blocks = width // 64
    central = (blocks//2, blocks//2)
    before = {cell(t):t for t in data['tiles']}
    updated = dict(before)
    permutation = {}
    regions = []
    for by in range(blocks):
        for bx in range(blocks):
            modules = [t for t in data['tiles'] if cell(t)[0]//64 == bx and cell(t)[1]//64 == by
                       and t.get('object_type_id','').startswith(('station_set_wall','station_set_door'))]
            assert len(modules) == 76, ('unexpected ensemble', bx, by, len(modules))
            anchor = 31 + by*64
            limits = boundary(modules, anchor, (bx,by) == central)
            q0, r0 = limits[0]-2, limits[1]-2
            w, h = limits[2]-limits[0]+5, limits[3]-limits[1]+5
            region = {'id':f'station_{bx}_{by}', 'row_anchor':anchor,
                      'source_region':[q0,r0,w,h], 'floor_boundary':limits,
                      'module_count':len(modules)}
            regions.append(region)
            if (bx,by) == central:
                assert region['source_region'] == layout['source_region']
                layout['floor_boundary'] = limits
                continue
            source = {(q,r) for r in range(r0,r0+h) for q in range(q0,q0+w)}
            mapping = {(q,r):(q-(r-anchor)//2,r) for q,r in source}
            assert len(set(mapping.values())) == len(mapping)
            inverse = {target:origin for origin,target in mapping.items()}
            for end in set(mapping.values()) - source:
                start = end
                while start in inverse: start = inverse[start]
                mapping[end] = start
            assert set(mapping) == set(mapping.values())
            assert not set(mapping).intersection(permutation)
            assert all(q//64 == bx and r//64 == by for q,r in mapping)
            permutation.update(mapping)
            for origin,target in mapping.items():
                tile = copy.deepcopy(before[origin])
                tile['grid_position'] = {'x':target[0], 'y':target[1]}
                updated[target] = tile
    result['tiles'] = [updated[cell(t)] for t in data['tiles']]
    moved_points = []
    def move_point(point, label):
        origin = initial.grid_of(point, data)
        target = permutation.get(origin, origin)
        if target == origin: return
        assert target[1] == origin[1]
        delta = target[0]-origin[0]
        point['x'] += delta*data['tile_size']['half_width']
        point['y'] += delta*data['tile_size']['half_height']
        assert initial.grid_of(point, result) == target
        moved_points.append({'point':label, 'from':list(origin), 'to':list(target)})
    for name,point in result.get('markers',{}).items(): move_point(point,'marker:'+name)
    for name,points in result.get('patrol_paths',{}).items():
        for index,point in enumerate(points): move_point(point,f'patrol:{name}:{index}')
    layout['regions'] = regions
    layout['ensembles_revision'] = REVISION
    assert payloads(result['tiles']) == payloads(data['tiles'])
    assert result['place_presentation']['props'] == data['place_presentation']['props']
    assert result['place_presentation']['building_authoring'] == data['place_presentation']['building_authoring']
    for prop in data['place_presentation']['props']:
        for grid in prop.get('reserved_grids',[]):
            key = tuple(int(v) for v in grid)
            assert updated[key] == before[key], ('reserved building changed', key)
    assert all(updated[key] == tile for key,tile in before.items() if key not in permutation)
    assert all(updated[key] == tile for key,tile in before.items() if (key[0]//64,key[1]//64) == central)
    assert not any(t.get('object_type_id','').startswith('spacekit_pipe') for t in result['tiles'])
    moved = [{'from':list(origin),'to':list(target)} for origin,target in sorted(permutation.items()) if origin != target]
    return result, {'regions':regions,'moved_cells':moved,'moved_points':moved_points,
                    'module_count':sum(r['module_count'] for r in regions),
                    'tile_payload_multiset_preserved':True, 'central_ensemble_unchanged':True,
                    'buildings_and_reserved_tiles_unchanged':True, 'outside_regions_unchanged':True}


def main():
    audit = []
    for name in ['station_outpost_64x64','station_outpost_192x192']:
        path = ROOT/'maps'/(name+'.json')
        raw = path.read_bytes()
        result, record = migrate(json.loads(raw))
        if record.get('already_current'): continue
        assert migrate(result)[0] == result
        encoded = (json.dumps(result,ensure_ascii=False,indent='\t')+'\n').encode('utf-8')
        path.write_bytes(encoded)
        audit.append({'map':'res://maps/'+path.name,'before_sha256':hashlib.sha256(raw).hexdigest(),
                      'after_sha256':hashlib.sha256(encoded).hexdigest(), **record})
    if audit:
        (ROOT/'docs/qa/review_completion_20261113/station_outer_layout_migration.json').write_text(
            json.dumps({'schema':REVISION,'maps':audit},ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(json.dumps([{'map':r['map'],'regions':len(r['regions']),'modules':r['module_count'],
                       'moved_cells':len(r['moved_cells']),'moved_points':r['moved_points']} for r in audit]))


if __name__ == '__main__': main()

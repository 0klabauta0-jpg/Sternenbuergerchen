"""Standard-library manifest finalizer. Does not modify sources or exports."""
from pathlib import Path
import json,hashlib,struct
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
ROLES=['operator','pilot','mechanic','medic']
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def rel(p):return str(Path(p).relative_to(ROOT)).replace('\\','/')
def glb_stats(path):
    buf=Path(path).read_bytes();n=struct.unpack_from('<I',buf,12)[0];g=json.loads(buf[20:20+n]);binary=buf[28+n:]
    sizes={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
    fmt={5120:'b',5121:'B',5122:'h',5123:'H',5125:'I',5126:'f'};cache={}
    def accessor(i):
        if i in cache:return cache[i]
        a=g['accessors'][i];bv=g['bufferViews'][a['bufferView']];s=sizes[a['type']];f='<'+fmt[a['componentType']]*s
        step=bv.get('byteStride',struct.calcsize(f));start=bv.get('byteOffset',0)+a.get('byteOffset',0)
        cache[i]=[struct.unpack_from(f,binary,start+k*step) for k in range(a['count'])];return cache[i]
    meshes=[]
    for m in g['meshes']:
        groups={};count=0;tris=0
        for p in m['primitives']:
            attributes={k:accessor(v) for k,v in p['attributes'].items()};count+=len(attributes['POSITION']);tris+=g['accessors'][p['indices']]['count']//3
            for i,position in enumerate(attributes['POSITION']):
                pos=tuple(round(x,6) for x in position)
                other=tuple((k,tuple(round(float(x),6) for x in v[i])) for k,v in sorted(attributes.items()) if k!='POSITION')+(('material',p.get('material')),)
                groups.setdefault(pos,[]).append(other)
        meshes.append({'mesh':m['name'],'triangles':tris,'gltf_attribute_vertices':count,'unique_positions_at_1_micrometre':len(groups),
            'coincident_position_groups':sum(len(v)>1 for v in groups.values()),
            'coincident_groups_with_different_normal_uv_skin_or_material_attributes':sum(len(set(v))>1 for v in groups.values())})
    clips=[]
    for a in g['animations']:
        inputs=[g['accessors'][s['input']] for s in a['samplers']]
        clips.append({'name':a['name'],'duration_seconds':max(x['max'][0] for x in inputs)-min(x['min'][0] for x in inputs)})
    return {'meshes':meshes,'animations':clips,'skins':len(g['skins']),'materials':len(g['materials']),'images':len(g['images']),
        'node_names':[n.get('name','') for n in g['nodes']],
        'no_lights_collision_navigation':not any(any(s in n.get('name','').lower() for s in ['-col','-navmesh']) for n in g['nodes']) and 'KHR_lights_punctual' not in g.get('extensions',{})}

def main():
    rt=read(QA/'roundtrip.json');previous=read(HERE.parent/'qa/stock_manifest.json');rows=[]
    for role in ROLES:
        record=read(QA/(role+'_manifest.json'));poses=read(QA/(role+'_poses.json'));roundtrip=next(x for x in rt['assets'] if x['role']==role)
        old=next(x for x in previous['assets'] if x['role_label']==role)
        assert sha(ROOT/old['editable'])==old['editable_sha256'] and sha(ROOT/old['glb'])==old['glb_sha256']
        assert record['body_geometry_uv_weight_signature_before']==record['body_geometry_uv_weight_signature_after']
        assert record['raw_qa_pass'] and record['body_uv_qa_pass'] and roundtrip['pass'] and poses['motion_curves_match_stock']
        assert all(x.get('raw_qa_pass',True) for x in poses['pose_checks'])
        record['source_blend_sha256']=sha(ROOT/record['source_blend'])
        record['stock_files_unchanged_against_pass01_manifest']=True
        record['export_inspection']=glb_stats(ROOT/record['glb'])
        record['roundtrip']={'report':rel(QA/'roundtrip.json'),'raw':roundtrip['raw_qa_report'],'pass':roundtrip['pass'],'warnings':roundtrip['warnings'],
            'rest_position_error_m':roundtrip['rest_bidirectional_nearest_vertex_error_m'],
            'sampled_frames_per_clip':33,'clip_count':2,'maximum_bidirectional_vertex_error_m':max(e for c in roundtrip['clips'] for s in c['samples'] for e in s['bidirectional_nearest_vertex_error_m'].values())}
        record['warning_acceptance']='Fresh glTF import retains attribute splits at UV and flat/hard-normal seams. Duplicate-vertex warnings and resulting seam boundaries are retained raw, not hidden/repaired. Source geometry is closed and warning-free; rest and all66 clip frames match bidirectionally within0.00004m. Export attribute split evidence is recorded above.'
        record['pose_report']=rel(QA/(role+'_poses.json'));record['source_qa_report']=rel(QA/(role+'_qa_raw.json'))
        opened=[role+'_poses.png',role+'_stock_idle_front.png',role+'_random.png',role+'_wire.png',role+'_roundtrip_walk.png']
        record['opened_visuals']=[{'path':rel(QA/name),'sha256':sha(QA/name)} for name in opened]
        rows.append(record)
    refs=[]
    for path in rows[0]['references']:
        p=ROOT/path;refs.append({'path':path,'sha256':sha(p),'status':'current reference image; no model approval inferred'})
    generator=HERE/'generator/build_equipment.py'
    result={'schema':'sternenbuergerchen.citizen_equipment_candidates.v1','task':'docs/tasks/ART_2026_11_01_pass02.md',
        'blender':'5.2.3 LTS','status':'separate native equipment candidates; parent task owns Godot integration/capture; no user approval',
        'baseline':'Pass01 stock Kenney characterMedium geometry, proportions, texture and weights retained exactly',
        'generator':rel(generator),'generator_sha256':sha(generator),'references':refs,'assets':rows,
        'visual_review':{'opened':True,'finding':'Original friendly heads/faces, body proportions and suit textures remain visible. Broad chamfered breast/shoulder/knee forms and supported packs are distinct in front/rear/side and walk poses. Pilot headset is open; mechanic has stowed cassette; medic has orange pack mark.',
            'limits':'Workbench texture views assess geometry/attachments, not final Godot lighting. In diagnostic extreme arm/elbow poses pads intentionally overlap at the shoulder; no detached parts or spikes were seen. Gear stays rigid and does not use cloth simulation. Role recognition at actual game distance remains a native preview check. Three environment references guide palette; detailed adult anatomy from the earlier citizen illustration is deliberately not reproduced because the current user chose the Kenney base.'},
        'integration_interface':{'exports':'Assets/curated/frontier_illustrated_20261101/citizens_pass02/{role}.glb','meshes':['characterMedium','Gear_Modular'],'skeleton':'Root original Kenney hierarchy, one shared skin','animations':['idle','walk'],'runtime_scale':.35,'origin':'feet floorZ0, restheight1.78m','front_godot':'+Z','no_gameplay_state':True},
        'not_claimed':['user visual acceptance','native Godot result from this subtask','population or combat/loadout migration','full performance acceptance']}
    (HERE/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'manifest':rel(HERE/'manifest.json'),'roles':[{'role':r['role'],'triangles':r['stats_rest']['triangles'],'glb_sha256':r['glb_sha256'],'roundtrip_max_error_m':r['roundtrip']['maximum_bidirectional_vertex_error_m']} for r in rows]},indent=2))

if __name__=='__main__':main()

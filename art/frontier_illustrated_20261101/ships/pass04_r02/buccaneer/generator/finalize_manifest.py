"""Stage selected iteration explicitly, or validate/collect frozen Buccaneer evidence."""
from pathlib import Path
import hashlib,json,struct,sys,shutil
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[4]
QA=HERE/'qa';OLD=ROOT/'art/frontier_illustrated_20261101/ships/pass04'
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/buccaneer_01.glb'
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def rel(p):return Path(p).relative_to(ROOT).as_posix()
def record(p):return {'path':rel(p),'sha256':sha(p)}
def main():
    if '--stage' in sys.argv:
        folder=HERE/'iterations/i02';row=read(folder/'qa/buccaneer_01_manifest.json')
        assert row['qa_pass'] and not row['qa_errors']
        (HERE/'source').mkdir(exist_ok=True);QA.mkdir(exist_ok=True);EXPORT.parent.mkdir(exist_ok=True)
        shutil.copy2(folder/'source/buccaneer_01.blend',HERE/'source/buccaneer_01.blend')
        shutil.copy2(folder/'buccaneer_01.glb',EXPORT)
        row['source']=rel(HERE/'source/buccaneer_01.blend');row['export']['path']=rel(EXPORT)
        (QA/'buccaneer_01_manifest.json').write_text(json.dumps(row,indent=2),encoding='utf-8')
        print('Staged iteration2; run fresh verify_roundtrip.py before finalizing.');return
    row=read(QA/'buccaneer_01_manifest.json');rt=read(QA/'roundtrip.json')['assets'][0]
    assert row['qa_pass'] and not row['qa_errors'] and not row['qa_warnings']
    assert rt['pass'] and not rt['errors'] and rt['material_assignments_match']
    assert rt['maximum_bidirectional_nearest_vertex_error_m']<.00003 and rt['maximum_corner_normal_error']<.0001
    assert rt['finite_positions_and_normals']
    assert sha(ROOT/row['source'])==row['source_sha256']
    assert sha(EXPORT)==row['export']['sha256']==rt['glb_sha256']
    assert row['triangles']==row['export']['triangles']==rt['triangles']<20000
    data=EXPORT.read_bytes();length=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+length])
    assert len(g['meshes'])==len(g['nodes'])==1 and len(g['materials'])<=10
    assert not any(g.get(key) for key in ['images','animations','skins','cameras'])
    assert 'KHR_lights_punctual' not in g.get('extensions',{})
    prior=read(OLD/'qa/buccaneer_01_manifest.json')
    assert sha(OLD/'source/buccaneer_01.blend')==row['retained_r01']['source_sha256']==prior['source_sha256']
    assert sha(OLD/'generator/build_ships.py')==row['retained_r01']['generator_sha256']
    assert sha(ROOT/prior['export']['path'])==prior['export']['sha256']
    iterations=[]
    for name in ['i01','i02']:
        folder=HERE/'iterations'/name;item=read(folder/'qa/buccaneer_01_manifest.json')
        assert item['qa_pass'] and not item['qa_errors'] and sha(ROOT/item['source'])==item['source_sha256']
        assert sha(ROOT/item['export']['path'])==item['export']['sha256']
        item['views']=read(folder/'qa/buccaneer_01_views.json')
        item['opened_images']=[record(folder/'qa'/('buccaneer_01_'+view+'.png')) for view in ['front','rear','game','top','random','wire']]
        item['selected_for_native']=name=='i02';iterations.append(item)
    row['geometry']={'triangles':row['triangles'],'vertices':row['vertices'],'editable_parts':row['editable_parts'],'materials':row['export']['materials']}
    row['qa']={'pass':True,'raw':record(HERE/'iterations/i02/qa/buccaneer_01_raw.json'),'errors':[],'warnings':[]}
    row['roundtrip']=rt;row['views']=iterations[1]['views'];row['opened_images']=iterations[1]['opened_images']+[record(ROOT/p) for p in rt['images']]
    row['warning_acceptance']={'roundtrip_duplicate_positions':'The sole fresh-import warning is duplicate positions at intentional normal/material attribute seams (14088; no loose vertices). Exact positions/material triangle counts and corner normals were verified; source has zero errors/warnings. No imported mesh repair.',
        'uv':'Untextured constant palette intentionally omits UVs.'}
    row['construction']='New original procedural low-poly shape revision using R01 helpers; no stock Kenney/SC mesh, old OBJ or material-study mesh imported.'
    row['remaining_visual_differences']=['Cowls still more regular and cylindrical than the interlocked angular illustration.',
        'Workbench glass/light surfaces darker than painted target; native light/material review belongs to parent.',
        'Small static display gear is an original simplified support, not canonical SC landing gear.',
        'No illustrated scratch/paint texture field or emissive engine effect; usage is represented by a few broad material zones.']
    dependencies=[HERE/'generator'/f for f in ['build_buccaneer.py','review_buccaneer.py','verify_roundtrip.py','finalize_manifest.py']]+[OLD/'generator'/f for f in ['build_ships.py','review_ships.py']]
    result={'schema':'sternenbuergerchen.pass04_r02_buccaneer.v1','task':'docs/tasks/ART_2026_11_01_pass04.md',
        'status':'frozen revised visual candidate; native integration and visual acceptance owned by parent task',
        'blender':'5.2.3 LTS','generator':rel(HERE/'generator/build_buccaneer.py'),'dependencies':[record(p) for p in dependencies],
        'qa_skill_script':{'path':'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts/qa_check.py','sha256':sha(Path('C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts/qa_check.py')),'unmodified':True},
        'assets':[row],'iterations':iterations,'reference_images':row['reference_images'],
        'retained_r01_originals':{'source':record(OLD/'source/buccaneer_01.blend'),'export':record(ROOT/prior['export']['path']),'generator':record(OLD/'generator/build_ships.py'),'unchanged':True},
        'native_interface':{'runtime_scale':.22,'front_godot':'+Z','pivot':'full BBox XY center / static feet minZ0','normalization_length_m':11,'canonical_sc_dimensions':False,'collision_navigation_lights':False},
        'normal_route':'Smooth-by-angle on shaped pod surfaces; source per-corner normals carried explicitly into assembled GLB; fresh import checked against source.',
        'visual_review':{'opened_source_images':12,'opened_fresh_glb_images':3,'directions':'R01 reference-facing front38/32deg, rear-142/32deg; game24/50deg with native world camera size12 at scale.22',
            'iteration1':'New broad canopy/cannon, hollow inlets, curved open cowls, swept thick wings. Mounting gap fixed. Long cowl / overlaid wing panel / obscured rear warm ring prompted iteration2.',
            'iteration2':'Shorter shoulder/neck cowl zones, recessed framed glazing, integrated shaped wing polygons with ivory outer field/ochre root zone, exposed warm deep rear throat, broad bevels and only eight structural fastener heads.',
            'independent_review':'current_visuals opened source front/rear vs13/11: no gross visible hole/floating assembly or front/rear mix-up; remaining illustration differences stated; no visual user approval.'},
        'qa_runs':{'source_final':record(HERE/'build_i02_final.log'),'views_final':record(HERE/'review_i02_final.log'),'roundtrip_final':record(HERE/'roundtrip_normals_final.log'),
            'failed_iterations_retained':['iterations/i01/qa/buccaneer_01_raw_failed_mount_r01.json','iterations/i02/qa/buccaneer_01_raw_failed_fastener_mount.json'],
            'note':'Failed mounting studies are historical and are not final QA evidence.'},
        'not_claimed':['user visual approval','canonical SC geometry/size','flight/weapon/landing mechanics','Godot import performed by this generator','performance/release acceptance']}
    (HERE/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'pass':True,'manifest':rel(HERE/'manifest.json'),'export':row['export'],'source':record(ROOT/row['source']),'normal_error':rt['maximum_corner_normal_error']},indent=2))
if __name__=='__main__':main()

"""Fresh Blender GLB roundtrip, numbers and geometry only; never engine import."""
import bpy, sys, json, hashlib
from pathlib import Path
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[4]
ART=ROOT/'art/frontier_illustrated_20261101/structures'
manifest=json.loads((ART/'manifest.json').read_text())
sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
records={}
for name,source in manifest['assets'].items():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    path=ROOT/source['export_glb']
    assert hashlib.sha256(path.read_bytes()).hexdigest()==source['glb']['sha256']
    assert bpy.ops.import_scene.gltf(filepath=str(path))=={'FINISHED'}
    bpy.context.view_layer.update()
    objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    points=[o.matrix_world@Vector(c) for o in objects for c in o.bound_box]
    lo=[min(v[i] for v in points) for i in range(3)]
    hi=[max(v[i] for v in points) for i in range(3)]
    size=[hi[i]-lo[i] for i in range(3)]
    assert len(objects)==1
    assert max(abs(size[i]-source['dimensions_blender_xyz'][i]) for i in range(3))<0.0001
    assert abs(lo[2])<0.0001 and abs(lo[0]+hi[0])<0.0001 and abs(lo[1]+hi[1])<0.0001
    qa=qa_check.run(objects=[o.name for o in objects],profile='game',uv=False,eps=.0003,tol=.006)
    (ART/'qa'/(name+'_glb_roundtrip_qa_raw.json')).write_text(json.dumps(qa,indent=2))
    assert qa['pass'],name+': '+str(qa['errors'])
    # Imported meshes contain polygon faces; explicit loop-triangle calculation.
    for o in objects:o.data.calc_loop_triangles()
    tris=sum(len(o.data.loop_triangles) for o in objects)
    assert tris==source['glb']['triangles']
    records[name]={'pass':True,'glb_sha256':source['glb']['sha256'],'objects':len(objects),
        'triangles':tris,'dimensions_blender_xyz':size,'bounds_min':lo,'bounds_max':hi,
        'materials':len(objects[0].data.materials),'geometry_qa_pass':qa['pass'],
        'warnings':qa['warnings'],'source_bounds_match_tolerance_m':0.0001}
result={'pass':True,'blender':bpy.app.version_string,'native_engine_import':False,'assets':records}
(ART/'qa/pass02_glb_roundtrip.json').write_text(json.dumps(result,indent=2))
print('FRONTIER_STRUCTURE_ROUNDTRIP '+json.dumps(result))

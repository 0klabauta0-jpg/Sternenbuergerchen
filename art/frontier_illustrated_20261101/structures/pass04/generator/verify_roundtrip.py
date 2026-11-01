"""Fresh GLB import verification; deliberately does not launch Godot."""
from pathlib import Path
import bpy,json,sys,hashlib
from mathutils import Vector
from mathutils.kdtree import KDTree
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
sys.path.insert(0,str(HERE/'generator'))
from review_pass04 import review
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
ASSETS=['habitat_cutaway_01','freihafen_hall_01','utility_fuel_01']
def get_points(obs):return [o.matrix_world@v.co for o in obs for v in o.data.vertices]
def point_error(a,b):
    kd=KDTree(len(a))
    for i,p in enumerate(a):kd.insert(p,i)
    kd.balance();return max(kd.find(p)[2] for p in b)
def material_tris(obs):
    out={}
    for ob in obs:
        for p in ob.data.polygons:
            name=ob.data.materials[p.material_index].name
            out[name]=out.get(name,0)+len(p.vertices)-2
    return out
def verify(asset):
    source=HERE/'source'/(asset+'.blend');glb=ROOT/'Assets/curated/frontier_illustrated_20261101/structures_pass04'/(asset+'.glb')
    bpy.ops.wm.open_mainfile(filepath=str(source));obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert all(not o.animation_data and not o.constraints for o in obs),'Static modules must not retain source door/lift object animation'
    original=get_points(obs);original_materials=material_tris(obs);owners=[o.name for o in obs for v in o.data.vertices]
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(glb),merge_vertices=True)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert len(imported)==1
    actual=get_points(imported);materials=material_tris(imported)
    error=max(point_error(original,actual),point_error(actual,original));print('GEOMETRY_COMPARE',asset,error,len(original),len(actual),flush=True)
    if error>=.00003:
        kd=KDTree(len(actual))
        for i,p in enumerate(actual):kd.insert(p,i)
        kd.balance();bad=sorted([(kd.find(p)[2],owners[i],list(p),list(kd.find(p)[0])) for i,p in enumerate(original)],reverse=True)[:8]
        print('GEOMETRY_MISMATCH',json.dumps(bad),original_materials,materials,flush=True)
    assert error<.00003,(asset,error)
    assert materials==original_materials,(asset,materials,original_materials)
    lo=[min(p[i] for p in actual) for i in range(3)];hi=[max(p[i] for p in actual) for i in range(3)]
    assert abs(lo[2])<.0001 and abs(lo[0]+hi[0])<.0001 and abs(lo[1]+hi[1])<.0001
    assert sum(materials.values())<25000
    raw=qa_check.run(objects=[o.name for o in imported],profile='game',eps=.0003,tol=.006,uv=False)
    (QA/(asset+'_roundtrip_raw.json')).write_text(json.dumps(raw,indent=2),encoding='utf-8')
    assert raw['pass'],raw['errors']
    sc,cam=review.setup();aspect=sc.render.resolution_x/sc.render.resolution_y;images=[]
    for label,pitch in [('front',42),('game',50)]:
        direction=review.camera_direction(24,pitch);target,ortho=review.fitted_camera(imported,direction,aspect)
        if label=='game':ortho=12/.35*aspect
        p=QA/(asset+'_roundtrip_'+label+'.png');review.render(p,sc,cam,direction,ortho,target);images.append(str(p.relative_to(ROOT)))
    rec={'asset':asset,'pass':True,'glb_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'import_method':'fresh Blender5.2.3 factory-empty; merge_vertices=True requested; attribute seams preserved; no source repair',
        'mesh_count':len(imported),'triangles':sum(materials.values()),'triangles_by_material':materials,'material_assignment_matches_source':True,
        'bounds_blender_m':{'min':lo,'max':hi},'dimensions_blender_m':[hi[i]-lo[i] for i in range(3)],'ground_z':lo[2],
        'maximum_bidirectional_nearest_vertex_error_m':error,'raw_qa':str((QA/(asset+'_roundtrip_raw.json')).relative_to(ROOT)),
        'raw_warnings':raw['warnings'],'raw_errors':raw['errors'],'images':images}
    print('FRESH_ROUNDTRIP '+json.dumps(rec));return rec
if __name__=='__main__':
    rows=[verify(a) for a in ASSETS]
    (QA/'roundtrip.json').write_text(json.dumps({'blender':bpy.app.version_string,'pass':all(r['pass'] for r in rows),'assets':rows},indent=2),encoding='utf-8')

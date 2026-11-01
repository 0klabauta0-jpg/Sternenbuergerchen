"""Fresh static GLB verification. No Godot import/runtime process is launched."""
from pathlib import Path
import bpy,json,sys,hashlib,math
from mathutils.kdtree import KDTree
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[4];QA=HERE/'qa'
sys.path.insert(0,str(ROOT/'art/frontier_illustrated_20261101/ships/pass04/generator'))
import review_ships as review
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
ASSETS=['buccaneer_01']
def points(obs):return [o.matrix_world@v.co for o in obs for v in o.data.vertices]
def material_tris(obs):
    out={}
    for ob in obs:
        for p in ob.data.polygons:
            key=ob.data.materials[p.material_index].name;out[key]=out.get(key,0)+len(p.vertices)-2
    return out
def nearest_error(a,b):
    kd=KDTree(len(a))
    for i,p in enumerate(a):kd.insert(p,i)
    kd.balance();return max(kd.find(p)[2] for p in b)
def corner_normals(obs):
    out={}
    for ob in obs:
        normal_matrix=ob.matrix_world.to_3x3().inverted().transposed()
        for loop in ob.data.loops:
            position=ob.matrix_world@ob.data.vertices[loop.vertex_index].co
            normal=(normal_matrix@ob.data.corner_normals[loop.index].vector).normalized()
            assert all(math.isfinite(v) for v in [*position,*normal]) and normal.length>.999
            out.setdefault(tuple(round(float(v),5) for v in position),[]).append(normal.copy())
    return out
def verify(asset):
    glb=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04_r02'/(asset+'.glb')
    bpy.ops.wm.open_mainfile(filepath=str(HERE/'source'/(asset+'.blend')))
    source=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert all(not o.animation_data and not o.constraints for o in source)
    before=points(source);mats=material_tris(source);source_normals=corner_normals(source)
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(glb),merge_vertices=True)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert len(imported)==1
    after=points(imported);err=max(nearest_error(before,after),nearest_error(after,before));assert err<.00003
    imported_normals=corner_normals(imported);normal_error=0
    for position,normals in imported_normals.items():
        assert position in source_normals
        normal_error=max(normal_error,max(min((normal-original).length for original in source_normals[position]) for normal in normals))
    assert normal_error<.0001,normal_error
    assert material_tris(imported)==mats
    lo=[min(p[i] for p in after) for i in range(3)];hi=[max(p[i] for p in after) for i in range(3)]
    assert abs(lo[2])<.0001 and abs(lo[0]+hi[0])<.0001 and abs(lo[1]+hi[1])<.0001
    target=16 if asset=='cutlass_01' else 11;assert abs(hi[1]-lo[1]-target)<.0001
    raw=qa_check.run(objects=[o.name for o in imported],profile='game',uv=False,eps=.0003,tol=.008)
    (QA/(asset+'_roundtrip_raw.json')).write_text(json.dumps(raw,indent=2),encoding='utf-8');assert raw['pass'],raw['errors']
    sc,cam=review.setup();aspect=sc.render.resolution_x/sc.render.resolution_y;images=[]
    for name,d in [('front',review.direction(38,32)),('rear',review.direction(-142,32)),('game',review.direction(24,50))]:
        target,ortho=review.fitted_camera(imported,d,aspect)
        if name=='game':ortho=12/.22*aspect
        p=QA/(asset+'_roundtrip_'+name+'.png');review.render(p,sc,cam,d,ortho,target);images.append(str(p.relative_to(ROOT)).replace('\\','/'))
    rec={'asset':asset,'pass':True,'glb_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'import':'fresh empty Blender5.2.3; merge_vertices=True requested; no source/import geometry repair',
         'mesh_count':len(imported),'triangles':sum(mats.values()),'triangles_by_material':mats,'material_assignments_match':True,
         'bounds_blender_m':{'min':lo,'max':hi},'dimensions_blender_m':[hi[i]-lo[i] for i in range(3)],'ground_z':lo[2],
         'maximum_bidirectional_nearest_vertex_error_m':err,'maximum_corner_normal_error':normal_error,'finite_positions_and_normals':True,'raw_qa':str((QA/(asset+'_roundtrip_raw.json')).relative_to(ROOT)).replace('\\','/'),'errors':raw['errors'],'warnings':raw['warnings'],'images':images}
    print('SHIP_ROUNDTRIP '+json.dumps(rec));return rec
if __name__=='__main__':
    rows=[verify(a) for a in ASSETS]
    (QA/'roundtrip.json').write_text(json.dumps({'pass':all(r['pass'] for r in rows),'blender':bpy.app.version_string,'assets':rows},indent=2),encoding='utf-8')

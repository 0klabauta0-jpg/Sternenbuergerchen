"""Fresh Cutlass GLB import: positions, material triangles, corner normals and raw QA."""
from pathlib import Path
import bpy,json,sys,hashlib,math
from mathutils.kdtree import KDTree
ART=Path(__file__).resolve().parents[1];ROOT=ART.parents[4];QA=ART/'qa/iteration02'
sys.path.insert(0,str(ART/'generator'));import review_cutlass as review
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check
def points(obs):
    bpy.context.view_layer.update();return [o.matrix_world@v.co for o in obs for v in o.data.vertices]
def material_tris(obs):
    out={}
    for o in obs:
        for p in o.data.polygons:
            k=o.data.materials[p.material_index].name;out[k]=out.get(k,0)+len(p.vertices)-2
    return out
def nearest(a,b):
    kd=KDTree(len(a))
    for i,p in enumerate(a):kd.insert(p,i)
    kd.balance();return max(kd.find(p)[2] for p in b)
def normal_map(obs):
    out={}
    for o in obs:
        nmat=o.matrix_world.to_3x3().inverted().transposed()
        for p in o.data.polygons:
            mat=o.data.materials[p.material_index].name
            for li in p.loop_indices:
                v=o.matrix_world@o.data.vertices[o.data.loops[li].vertex_index].co
                key=(tuple(round(x,4) for x in v),mat)
                out.setdefault(key,[]).append((nmat@o.data.corner_normals[li].vector).normalized())
    return out
def normal_error(a,b):
    assert set(a)==set(b)
    return max((math.degrees(math.acos(max(-1,min(1,max(n.dot(m) for m in b[k]))))) for k,ns in a.items() for n in ns),default=0)
def main():
    source=ART/'source/iteration02/cutlass_01.blend';glb=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/cutlass_01.glb'
    bpy.ops.wm.open_mainfile(filepath=str(source));obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert all(not o.animation_data and not o.constraints for o in obs)
    before=points(obs);mats=material_tris(obs);normals=normal_map(obs)
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(glb),merge_vertices=True)
    imported=[o for o in bpy.context.scene.objects if o.type=='MESH'];assert len(imported)==1
    after=points(imported);err=max(nearest(before,after),nearest(after,before));assert err<.00003
    assert material_tris(imported)==mats
    n_after=normal_map(imported);normal_degrees=max(normal_error(normals,n_after),normal_error(n_after,normals));assert normal_degrees<.5,normal_degrees
    lo=[min(p[i] for p in after) for i in range(3)];hi=[max(p[i] for p in after) for i in range(3)]
    assert abs(lo[2])<.0001 and abs(lo[0]+hi[0])<.0001 and abs(lo[1]+hi[1])<.0001 and abs(hi[1]-lo[1]-16)<.0001
    raw=qa_check.run(objects=[o.name for o in imported],profile='game',uv=False,eps=.0003,tol=.008)
    (QA/'roundtrip_raw.json').write_text(json.dumps(raw,indent=2),encoding='utf-8');assert raw['pass'],raw['errors']
    sc,cam=review.setup();asp=sc.render.resolution_x/sc.render.resolution_y;images=[]
    for name,d in [('front',review.direction(-38,30)),('rear',review.direction(142,30)),('game',review.direction(24,50))]:
        target,ortho=review.fit(imported,d,asp)
        if name=='game':ortho=12/.22*asp
        p=QA/('roundtrip_'+name+'.png');review.render(p,sc,cam,d,ortho,target);images.append(str(p.relative_to(ROOT)).replace('\\','/'))
    rec={'pass':True,'asset':'cutlass_01','blender':bpy.app.version_string,'glb_sha256':hashlib.sha256(glb.read_bytes()).hexdigest(),'import':'fresh factory-empty scene, merge_vertices=True; no post-import repair','mesh_count':len(imported),'materials':len(mats),'triangles':sum(mats.values()),'material_triangles_match':True,'triangles_by_material':mats,'bounds_blender_m':{'min':lo,'max':hi},'dimensions_blender_m':[hi[i]-lo[i] for i in range(3)],'maximum_bidirectional_nearest_vertex_error_m':err,'maximum_bidirectional_corner_normal_error_degrees':normal_degrees,'normal_comparison_tolerance_degrees':.5,'normal_note':'Normals are not claimed bit-exact: corner normals are encoded/reconstructed when combining and importing the GLB. Maximum measured angular difference is retained and must be below0.5degree, followed by opened imported renders.','raw_qa':'art/frontier_illustrated_20261101/ships/pass04_r02/cutlass/qa/iteration02/roundtrip_raw.json','errors':raw['errors'],'warnings':raw['warnings'],'images':images}
    (QA/'roundtrip.json').write_text(json.dumps(rec,indent=2),encoding='utf-8');print('CUTLASS_ROUNDTRIP '+json.dumps(rec))
if __name__=='__main__':main()

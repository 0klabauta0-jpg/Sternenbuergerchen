"""Fresh GLB import: all 33 frames of both original clips and raw mesh QA.

No Godot import is launched here; the parent task owns the native import/capture.
"""
from pathlib import Path
import bpy,json,sys,struct,hashlib
from mathutils import Matrix
from mathutils.kdtree import KDTree
HERE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(HERE/'generator'))
import build_equipment as build
import review_equipment as review
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
QA=HERE/'qa'

def points(meshes):
    dg=bpy.context.evaluated_depsgraph_get();data={}
    for ob in meshes:
        ev=ob.evaluated_get(dg);me=ev.to_mesh()
        name='body' if ob.name.startswith('characterMedium') else 'gear'
        data.setdefault(name,[]).extend(ob.matrix_world@v.co for v in me.vertices);ev.to_mesh_clear()
    return data
def nearest_error(a,b):
    kd=KDTree(len(a))
    for i,p in enumerate(a):kd.insert(p,i)
    kd.balance();return max(kd.find(p)[2] for p in b)
def choose_clip(rig,clip):
    acts=[a for a in bpy.data.actions if a.name.lower()==clip or a.name.lower().endswith('|'+clip) or a.name.lower().endswith('_'+clip)]
    if len(acts)!=1:raise RuntimeError('Ambiguous imported clip '+clip+': '+str([a.name for a in bpy.data.actions]))
    rig.animation_data_create();rig.animation_data.action=acts[0];rig.animation_data.action_slot=next(iter(acts[0].slots))
    return acts[0]
def body_triangle_count(gl):
    return {m['name']:sum(gl['accessors'][p['indices']]['count']//3 for p in m['primitives']) for m in gl['meshes']}
def verify(role):
    blend=HERE/'source'/(role+'_equipment.blend');path=build.EXPORT/(role+'.glb')
    bpy.ops.wm.open_mainfile(filepath=str(blend));rig=bpy.data.objects['Root'];meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
    source={}
    for clip in ['idle','walk']:
        build.set_pose(rig,clip,0);source[clip]=[]
        for f in range(33):
            bpy.context.scene.frame_set(f);bpy.context.view_layer.update();source[clip].append(points(meshes))
    build.set_pose(rig);source_rest=points(meshes)
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.context.scene.render.fps=30
    # Request the importer's attribute-aware merge. UV and hard-normal seams
    # that require different attributes remain split, and are reported raw.
    bpy.ops.import_scene.gltf(filepath=str(path),merge_vertices=True)
    rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE'];assert len(rigs)==1
    rig=rigs[0];meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
    rig.animation_data.action=None
    for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
    bpy.context.view_layer.update()
    assert len(meshes)==2
    rest=points(meshes);resterr=max(max(nearest_error(source_rest[k],rest[k]),nearest_error(rest[k],source_rest[k])) for k in rest)
    raw=qa_check.run(objects=[o.name for o in meshes],profile='game',eps=.0003,tol=.004,uv=False)
    build.dump(QA/(role+'_roundtrip_raw.json'),raw)
    stats=build.mesh_stats(meshes);bounds=stats['bounds_blender_m']
    assert abs(bounds['min'][2])<.0001 and abs(bounds['max'][2]-1.78)<.0001
    assert resterr<.00003
    b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];gl=json.loads(b[20:20+n])
    tri=body_triangle_count(gl);expected=json.loads((QA/(role+'_manifest.json')).read_text())['stats_rest']['triangles']
    assert sum(tri.values())==expected and stats['triangles']==expected
    assert len(gl['skins'])==1 and len(gl['materials'])==4 and len(gl['images'])==1
    clips=[]
    for clip in ['idle','walk']:
        action=choose_clip(rig,clip);rows=[]
        for f in range(33):
            bpy.context.scene.frame_set(f);bpy.context.view_layer.update();actual=points(meshes)
            err={k:max(nearest_error(source[clip][f][k],actual[k]),nearest_error(actual[k],source[clip][f][k])) for k in actual}
            assert max(err.values())<.00004,(role,clip,f,err)
            rows.append({'frame':f,'bidirectional_nearest_vertex_error_m':err})
        clips.append({'name':clip,'imported_action':action.name,'frames':list(action.frame_range),'duration_seconds':(action.frame_range[1]-action.frame_range[0])/30,'sampled_frame_count':33,'samples':rows})
    choose_clip(rig,'walk');bpy.context.scene.frame_set(8);bpy.context.view_layer.update()
    render=QA/(role+'_roundtrip_walk.png');review.render(render,meshes,(.85,-1,.28))
    result={'role':role,'pass':bool(raw['pass']),'glb_sha256':hashlib.sha256(b).hexdigest(),
        'import_method':'fresh Blender5.2.3 factory-empty; merge_vertices=True requested; required UV/hard-normal attribute seam copies remain; no source repair',
        'rig_count':1,'skinned_mesh_count':2,'skin_count':len(gl['skins']),'material_count':len(gl['materials']),'embedded_images':len(gl['images']),
        'triangles_by_gltf_mesh':tri,'stats_rest':stats,'rest_bidirectional_nearest_vertex_error_m':resterr,
        'clips':clips,'raw_qa_report':str((QA/(role+'_roundtrip_raw.json')).relative_to(build.ROOT)),
        'errors':raw['errors'],'warnings':raw['warnings'],'image':str(render.relative_to(build.ROOT))}
    print('ROUNDTRIP_RESULT '+json.dumps({k:v for k,v in result.items() if k!='clips'}));return result

if __name__=='__main__':
    roles=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else build.ROLES
    rows=[verify(r) for r in roles or build.ROLES]
    build.dump(QA/'roundtrip.json',{'blender':bpy.app.version_string,'pass':all(r['pass'] for r in rows),'assets':rows})

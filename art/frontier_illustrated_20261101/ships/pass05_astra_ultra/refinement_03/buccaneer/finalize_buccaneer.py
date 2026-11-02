"""Prepare editable source with references and one-mesh GLB, no runtime import.
Blender -b --factory-startup -P finalize_buccaneer.py
"""
import bpy, sys, json, math, hashlib
from pathlib import Path
from mathutils import Vector
HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').exists())
SRC=HERE/'iterations/i01/buccaneer_master.blend'
OUT=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/buccaneer_01.glb'
OUT.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=str(SRC))
low=bpy.data.collections['LOW'];obs=[o for o in low.all_objects if o.type=='MESH'];dg=bpy.context.evaluated_depsgraph_get()
verts=[];faces=[];norms=[];uvs=[];mi=[];mats=[]
for ob in obs:
    eo=ob.evaluated_get(dg);me=eo.to_mesh(preserve_all_data_layers=True,depsgraph=dg);me.calc_loop_triangles()
    start=len(verts);verts.extend(tuple(ob.matrix_world@v.co) for v in me.vertices)
    nm=ob.matrix_world.to_3x3().inverted().transposed()
    for tri in me.loop_triangles:
        faces.append(tuple(start+v for v in tri.vertices));mat=me.materials[tri.material_index]
        if mat not in mats:mats.append(mat)
        mi.append(mats.index(mat))
        for li in tri.loops:
            norms.append(tuple((nm@me.corner_normals[li].vector).normalized()));uvs.append(tuple(me.uv_layers.active.data[li].uv))
    eo.to_mesh_clear()
# Export Blender's actual evaluated normals once, then merge raw GLB attribute
# arrays. Re-encoding corner normals into a new Blender mesh measurably drifts.
raw=HERE/'exports/buccaneer_source_parts.glb';raw.parent.mkdir(exist_ok=True)
bpy.ops.object.select_all(action='DESELECT')
for ob in obs:ob.select_set(True)
bpy.context.view_layer.objects.active=obs[0]
bpy.ops.export_scene.gltf(filepath=str(raw),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_extras=True,export_animations=False)
sys.path.insert(0,str(HERE.parent.parent/'qa_tools'))
from consolidate_glb import consolidate
merge=consolidate(raw,OUT)
(HERE/'exports/consolidation.json').write_text(json.dumps(merge,indent=2),encoding='utf8')
# Source assemblies remain independently editable and retain their bevel stacks.
groups={}
for ob in obs:
    name=ob.name
    group='Landing_Gear' if 'gear' in name.lower() else 'Cannon' if any(x in name.lower() for x in ('gun','barrel','cannon')) else 'Port_Engine' if '_L' in name else 'Starboard_Engine' if '_R' in name else 'Fuselage'
    if group not in groups:
        groups[group]=bpy.data.collections.new(group);low.children.link(groups[group])
    low.objects.unlink(ob);groups[group].objects.link(ob)
refs=bpy.data.collections.new('REF');bpy.context.scene.collection.children.link(refs)
for i,f in enumerate(['13_buccaneer_vorne_wimmel_vereinfacht.png','11_buccaneer_hinten_wimmel.png']):
    path=ROOT/'docs/reports/assets/grafik-2026-11-01'/f;im=bpy.data.images.load(str(path),check_existing=True);im.pack()
    ob=bpy.data.objects.new('REF_'+f[:-4],None);ob.empty_display_type='IMAGE';ob.data=im;ob.empty_display_size=11;ob.location=(-14,0,7+i*8);ob.rotation_euler=(math.pi/2,0,0);refs.objects.link(ob);ob.hide_render=True
refs.hide_viewport=True;refs.hide_render=True
scene=bpy.context.scene;cam=scene.camera;cam.location=(-22,-17,21);cam.rotation_euler=(Vector((0,0,2))-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=16.2
for screen in bpy.data.screens:
    for area in screen.areas:
        if area.type=='VIEW_3D':
            area.spaces.active.region_3d.view_location=(0,0,2)
            area.spaces.active.region_3d.view_distance=20
            area.spaces.active.region_3d.view_rotation=cam.rotation_euler.to_quaternion()
            area.spaces.active.shading.type='MATERIAL'
scene['candidate_notice']='Source parts editable; final GLB consolidated losslessly outside Blender. Reference dimensions and underside inferred. Native Godot check pending main chat.'
bpy.ops.object.select_all(action='DESELECT');obs[0].select_set(True);bpy.context.view_layer.objects.active=obs[0]
final=HERE/'buccaneer_master.blend';bpy.ops.wm.save_as_mainfile(filepath=str(final))
points=[Vector(v) for v in verts];lo=[min(v[i] for v in points) for i in range(3)];hi=[max(v[i] for v in points) for i in range(3)]
result={'source':str(final),'glb':str(OUT),'triangles':len(faces),'source_meshes':len(obs),'export_meshes':1,'materials':[m.name for m in mats],'bbox_blender':{'min':lo,'max':hi,'size':[hi[i]-lo[i] for i in range(3)]},'sha256':{'blend':hashlib.sha256(final.read_bytes()).hexdigest(),'glb':hashlib.sha256(OUT.read_bytes()).hexdigest()}}
(HERE/'delivery_stats.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps(result))


import bpy,bmesh,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[1]/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'caterpillar.blend'))
removed={}
for ob in list(bpy.context.scene.objects):
    if ob.type!='MESH':continue
    if ob.name.startswith('CargoDoor') and not ob.get('mechanical_clearance_applied'):
        # Separate the exterior door skins from the thickened stationary rim.
        ob.location.x += .006 if '_R_' in ob.name else -.006
        ob['mechanical_clearance_applied']=.006
    old=ob.data;matlist=list(old.materials);verts=[tuple(v.co) for v in old.vertices];faces=[];mis=[];seen=set()
    for f in old.polygons:
        ids=tuple(f.vertices);key=tuple(sorted(ids))
        if f.area<1e-10 or len(set(ids))<3 or key in seen:continue
        seen.add(key);faces.append(ids);mis.append(f.material_index)
    mesh=bpy.data.meshes.new(ob.name+'_CleanMesh');mesh.from_pydata(verts,[],faces);mesh.update()
    for m in matlist:mesh.materials.append(m)
    for f,idx in zip(mesh.polygons,mis):f.material_index=idx
    ob.data=mesh;bpy.data.meshes.remove(old)
    bm=bmesh.new();bm.from_mesh(mesh);unseen=set(bm.verts);islands=[]
    while unseen:
        first=next(iter(unseen));stack=[first];unseen.remove(first);vs=[]
        while stack:
            v=stack.pop();vs.append(v)
            for e in v.link_edges:
                w=e.other_vert(v)
                if w in unseen:unseen.remove(w);stack.append(w)
        islands.append(vs)
    debris=[v for group in islands if len(group)<12 for v in group] if ob.name in ['Hull','NoseCargoDoor'] or ob.name.startswith('CargoDoor') else []
    removed[ob.name]=len(debris)
    if debris:bmesh.ops.delete(bm,geom=debris,context='VERTS')
    bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    for group in islands:
        group=[v for v in group if v.is_valid]
        if not group:continue
        fs={f for v in group for f in v.link_faces};es={e for v in group for e in v.link_edges}
        if all(len(e.link_faces)==2 for e in es):
            vol=sum(f.verts[0].co.dot(f.verts[1].co.cross(f.verts[2].co))/6 for f in fs)
            if vol<0:bmesh.ops.reverse_faces(bm,faces=list(fs))
    bm.to_mesh(mesh);bm.free();mesh.update()
bpy.context.view_layer.update()
points=[o.matrix_world@v.co for o in bpy.context.scene.objects if o.type=='MESH' for v in o.data.vertices]
ground=min(p.z for p in points);bpy.data.objects['Caterpillar'].location.z-=ground
bpy.context.view_layer.update()
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check,review_shots
names=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
report=qa_check.run(objects=names,profile='game',uv=False)
(OUT/'qa_raw.json').write_text(json.dumps(report,indent=2))
print('QA',report['pass'],report['errors'],report['warnings'],flush=True)
metrics=json.loads((OUT/'metrics.json').read_text());metrics['removed_debris_vertices']=removed;metrics['ground_offset']=ground
for o in bpy.context.scene.objects:
    if o.type=='MESH':o.data.calc_loop_triangles()
metrics['output_triangles']=sum(len(o.data.loop_triangles) for o in bpy.context.scene.objects if o.type=='MESH')
metrics['final_parts']={o.name:len(o.data.loop_triangles) for o in bpy.context.scene.objects if o.type=='MESH'}
metrics['qa_pass']=report['pass'];(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'caterpillar.blend'))
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'caterpillar.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_materials='EXPORT',export_yup=True,export_animations=True,export_animation_mode='SCENE',export_anim_scene_split_object=False,export_force_sampling=True)
for mode in ['solid','material','random','wire']:
    review_shots.run(objects=names,out=str(OUT/f'candidate_{mode}.png'),views=['front','back','left','right','top','three_quarter'],mode=mode,res=700)
bpy.context.scene.frame_set(60)
review_shots.run(objects=names,out=str(OUT/'mechanisms_open.png'),views=['front','right','top','three_quarter'],mode='material',res=850)

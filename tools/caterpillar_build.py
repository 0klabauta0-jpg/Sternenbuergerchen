"""Isolated local Caterpillar derivative; never connects to live Blender.
Source mesh retained in normalized_source.blend; moving panels extracted before reduction.
"""
import bpy,bmesh,json,math,sys,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'normalized_source.blend'))
source=bpy.data.objects['CaterpillarSource'];source.data.calc_loop_triangles()
source_tris=len(source.data.loop_triangles)
bm=bmesh.new();bm.from_mesh(source.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00015)
bm.verts.ensure_lookup_table();bm.verts.index_update();bm.faces.ensure_lookup_table();bm.faces.index_update()
unseen=set(bm.verts);components=[]
while unseen:
    start=next(iter(unseen));stack=[start];unseen.remove(start);vs=[]
    while stack:
        v=stack.pop();vs.append(v)
        for e in v.link_edges:
            w=e.other_vert(v)
            if w in unseen: unseen.remove(w);stack.append(w)
    faces=set(f for v in vs for f in v.link_faces)
    if faces:components.append((vs,faces))
groups={'Hull':[]};bay_ranges=[(-2.718,-2.085),(-2.001,-1.368),(-1.284,-.651),(-.567,.066)]
for vs,fs in components:
    mn=[min(v.co[i] for v in vs) for i in range(3)];mx=[max(v.co[i] for v in vs) for i in range(3)]
    name='Hull'
    if mn[2]>=.23 and mx[2]<=.685:
        for j,(a,b) in enumerate(bay_ranges,1):
            if mn[1]>=a-.005 and mx[1]<=b+.005:
                if mn[0]>.515 and mx[0]<.64:name=f'CargoDoor_R_{j:02d}'
                elif mx[0]<-.132 and mn[0]>-.26:name=f'CargoDoor_L_{j:02d}'
    if mn[1]>-3.51 and mx[1]<-3.48 and mn[0]>-.17 and mx[0]<.55 and mn[2]>.25 and mx[2]<.56:
        name='NoseCargoDoor'
    groups.setdefault(name,[]).extend(fs)
def make_object(name,faces):
    vs=sorted({v for f in faces for v in f.verts},key=lambda v:v.index);ix={v:i for i,v in enumerate(vs)}
    mesh=bpy.data.meshes.new(name+'_Mesh');mesh.from_pydata([tuple(v.co) for v in vs],[],[[ix[v] for v in f.verts] for f in faces]);mesh.update()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);return ob
obs=[make_object(k,v) for k,v in groups.items()]
bm.free();bpy.data.objects.remove(source,do_unlink=True)
root=bpy.data.objects.new('Caterpillar',None);bpy.context.collection.objects.link(root)
def active(o):
    bpy.ops.object.select_all(action='DESELECT');o.select_set(True);bpy.context.view_layer.objects.active=o
def clean(o):
    bm=bmesh.new();bm.from_mesh(o.data)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00015)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.00002)
    seen=set();duplicates=[]
    bm.verts.ensure_lookup_table();bm.verts.index_update()
    for f in bm.faces:
        key=tuple(sorted(v.index for v in f.verts))
        if key in seen or f.calc_area()<1e-10: duplicates.append(f)
        seen.add(key)
    if duplicates:bmesh.ops.delete(bm,geom=duplicates,context='FACES_ONLY')
    loose=[v for v in bm.verts if not v.link_faces]
    if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(o.data);bm.free();o.data.update()
def tris(o):o.data.calc_loop_triangles();return len(o.data.loop_triangles)
stats=[]
for o in obs:
    active(o);before=tris(o);clean(o)
    print('PROCESS',o.name,before,flush=True)
    # Voxel cleanup is per component, AFTER mechanical separation; it removes
    # stacked source skin duplicates without fusing the doors to the hull.
    # The supplied exterior contains zero-thickness sheet surfaces. Give those
    # sheets a small thickness before voxel union so roofs/panel skins survive.
    solid=o.modifiers.new('PreserveThinSourcePanels','SOLIDIFY');solid.thickness=.014 if o.name=='Hull' else .008;solid.offset=0
    bpy.ops.object.modifier_apply(modifier=solid.name)
    o.data.remesh_voxel_size=.007 if o.name=='Hull' else .004
    o.data.use_remesh_preserve_volume=False
    o.data.use_remesh_preserve_attributes=False
    bpy.ops.object.voxel_remesh()
    print('REMESH',o.name,tris(o),flush=True)
    smooth=o.modifiers.new('SmoothVoxelStairs','SMOOTH');smooth.factor=.5;smooth.iterations=2
    bpy.ops.object.modifier_apply(modifier=smooth.name)
    budget=27000 if o.name=='Hull' else 650
    current=tris(o)
    if current>budget:
        mod=o.modifiers.new('SilhouetteReduction','DECIMATE');mod.ratio=budget/current;mod.use_collapse_triangulate=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    clean(o);stats.append({'name':o.name,'source_triangles':before,'triangles':tris(o)})
    print('REDUCED',o.name,tris(o),flush=True)
    o.parent=root
def mat(name,col,metal=.1):
    m=bpy.data.materials.new(name);m.diffuse_color=(*col,1);m.use_nodes=True
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED');p.inputs['Base Color'].default_value=(*col,1);p.inputs['Roughness'].default_value=.67;p.inputs['Metallic'].default_value=metal
    return m
mats=[mat('Hull_MutedRed',(.28,.075,.055)),mat('Structure_Dark',(.065,.085,.10)),mat('Panels_Bone',(.55,.52,.42)),mat('Access_Ochre',(.65,.34,.06))]
for o in obs:
    o.data.materials.clear()
    for m in mats:o.data.materials.append(m)
    for f in o.data.polygons:
        x,y,z=f.center;f.material_index=0
        if z<.25 or y>1.9:f.material_index=1
        elif z>.67 or (.1<y<1.7 and x>.75):f.material_index=2
        if o.name.startswith('CargoDoor'):f.material_index=0 if z>.39 else 1
        f.use_smooth=False
controls=[]
for o in obs:
    if not (o.name.startswith('CargoDoor') or o.name=='NoseCargoDoor'):continue
    is_nose=o.name=='NoseCargoDoor'
    if is_nose:hinge=Vector((.191,-3.49,.259));axis=0;angle=math.pi/2
    else:
        side=o.name.split('_')[1];j=int(o.name.rsplit('_',1)[1]);a,b=bay_ranges[j-1]
        hinge=Vector((.555 if side=='R' else -.172,(a+b)/2,.239));axis=1;angle=math.pi/2 if side=='R' else -math.pi/2
    # Origin is the hinge itself: the animated nodes directly own real panel geometry.
    for v in o.data.vertices:v.co-=hinge
    o.location=hinge;o['role']='cargo_side_door';o['source_geometry']='Extracted whole source surface components before decimation'
    for frame,value in [(1,0),(30,angle),(60,angle),(90,0)]:
        o.rotation_euler[axis]=value;o.keyframe_insert(data_path='rotation_euler',frame=frame)
    o['hinge_axis_local']='X' if is_nose else 'Y';o['open_degrees']=math.degrees(angle)
    controls.append({'node':o.name,'pivot':list(hinge),'axis':o['hinge_axis_local'],'open_degrees':math.degrees(angle),'source_faces':next(s['source_triangles'] for s in stats if s['name']==o.name)})
def box(name,center,size,material,parent):
    sx,sy,sz=(x/2 for x in size)
    vs=[(x*sx,y*sy,z*sz) for x,y,z in [(-1,-1,-1),(-1,-1,1),(-1,1,-1),(-1,1,1),(1,-1,-1),(1,-1,1),(1,1,-1),(1,1,1)]]
    fs=[(0,4,6,2),(1,3,7,5),(0,1,5,4),(2,6,7,3),(0,2,3,1),(4,5,7,6)]
    mesh=bpy.data.meshes.new(name+'_Mesh');mesh.from_pydata(vs,[],fs);mesh.materials.append(material);mesh.update()
    ob=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(ob);ob.location=center;ob.parent=parent;clean(ob);return ob
# Source is an exterior shell without a verifiable service-lift assembly. This is a
# clearly declared new detachable replacement mounted outside the command pod.
lift=box('ServiceLiftDeck',(1.37,.35,.37),(.38,.46,.035),mats[3],root);lift['role']='service_lift';lift['provenance']='New authored replacement access platform, not extracted original lift'
for f,z in [(1,.37),(30,.37),(60,.07),(90,.37)]:lift.location.z=z;lift.keyframe_insert(data_path='location',frame=f)
box('LiftGuide_A',(1.18,.15,.255),(.025,.035,.43),mats[1],root)
box('LiftGuide_B',(1.18,.55,.255),(.025,.035,.43),mats[1],root)
box('LiftMount',(1.10,.35,.39),(.18,.40,.04),mats[1],root)
controls.append({'node':lift.name,'translation_axis':'Z','raised_z':.37,'lowered_z':.07,'new_authored_geometry':True})
scene=bpy.context.scene;scene.render.fps=30;scene.frame_start=1;scene.frame_end=90;scene.frame_set(1)
root['candidate_only']=True;root['scale_note']='Normalized 8m source length; original unit not certified';root['forward_blender']='-Y';root['forward_gltf']='+Z';root['mechanism_status']='8 extracted side doors; authored replacement service lift; prototype animation, no runtime'
for o in bpy.context.scene.objects:
    if o.animation_data and o.animation_data.action:o.animation_data.action.name=o.name+'_Demonstration'
export_objects=[o for o in bpy.context.scene.objects if o==root or o.parent==root]
active(root)
for o in export_objects:o.select_set(True)
source_info=json.loads((OUT/'fbx_inspection.json').read_text())
metrics={'source':source_info,'source_triangles':source_tris,'parts':stats,'controls':controls,'blender_version':bpy.app.version_string,'output_triangles':sum(tris(o) for o in export_objects if o.type=='MESH'),'source_normalized_length':8.0,'units':'stylized meters, not canonical ship size','forward_blender':'-Y','forward_gltf':'+Z','limitations':['Source lacks named door/lift rig and verified interior','Lift is newly authored replacement geometry; placement is candidate','No cargo collisions, navmesh, personnel transport or gameplay authority','No source textures; new four-color candidate palette']}
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2))
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'caterpillar.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'caterpillar.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_materials='EXPORT',export_yup=True,export_animations=True,export_animation_mode='SCENE',export_anim_scene_split_object=False,export_force_sampling=True)
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import review_shots
names=[o.name for o in export_objects if o.type=='MESH']
for mode in ['solid','material','random','wire']:
    review_shots.run(objects=names,out=str(OUT/f'candidate_{mode}.png'),views=['front','back','left','right','top','three_quarter'],mode=mode,res=700)
scene.frame_set(60)
review_shots.run(objects=names,out=str(OUT/'mechanisms_open.png'),views=['front','right','top','three_quarter'],mode='material',res=850)
print('METRICS',json.dumps(metrics))

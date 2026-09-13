"""Reproducible local-only derivative of user-supplied DRAKE-BUCCANEER OBJ.
Run with Blender --background --factory-startup --python tools/prepare_freibeuter.py.
The source file remains unchanged. No license or original-design claim is made.
"""
import bpy, json, hashlib, math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:\Users\bjoer\3D Objects\drive-download-20250521T120706Z-1-001\DRAKE\DRAKE-BUCCANEER.obj')
OUT = ROOT / 'assets' / 'local' / 'freibeuter'
OUT.mkdir(parents=True, exist_ok=True)
(OUT/'source').mkdir(exist_ok=True)
(OUT/'source'/'.gdignore').write_text('')
bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete(use_global=False)
bpy.ops.wm.obj_import(filepath=str(SOURCE))
meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
for o in meshes:
    o.data.calc_loop_triangles()
info = {'source':str(SOURCE),'source_sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'objects':len(meshes),'vertices':sum(len(o.data.vertices) for o in meshes),'triangles':sum(len(o.data.loop_triangles) for o in meshes),'parts':[]}
for o in meshes:
    coords = [o.matrix_world @ Vector(p) for p in o.bound_box]
    info['parts'].append({'name':o.name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'min':[min(p[k] for p in coords) for k in range(3)],'max':[max(p[k] for p in coords) for k in range(3)],'materials':[m.name for m in o.data.materials if m]})
(OUT / 'source-inspection.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
print('SOURCE_INSPECTION',json.dumps(info))
# Import alone is first inspection; final processing is appended after evidence review.
# Normalize length to eight meters and place the underside on z=0.
bpy.ops.object.select_all(action='DESELECT')
for part in meshes: part.select_set(True)
bpy.context.view_layer.objects.active=meshes[0]
if len(meshes)>1: bpy.ops.object.join()
ship = bpy.context.view_layer.objects.active
bpy.context.view_layer.objects.active = ship
bpy.ops.object.select_all(action='DESELECT')
ship.select_set(True)
bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
coords = [v.co.copy() for v in ship.data.vertices]
mins = Vector([min(v[k] for v in coords) for k in range(3)])
maxs = Vector([max(v[k] for v in coords) for k in range(3)])
center = (mins + maxs) / 2
scale = 8.0 / (maxs.y-mins.y)
for v in ship.data.vertices:
    v.co = (v.co - Vector((center.x,center.y,mins.z))) * scale
ship.data.update()
# Source orientation was visually inspected: rear engines are -Y, cockpit +Y;
# Blender Z-up / forward +Y becomes glTF Y-up / forward -Z.
import bmesh
bm=bmesh.new(); bm.from_mesh(ship.data)
bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=0.0008)
bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=0.0001)
bm.to_mesh(ship.data); bm.free()
ship.data.remesh_voxel_size=0.035
bpy.ops.object.voxel_remesh()
smooth=ship.modifiers.new('Simplify sub-pixel greebles','SMOOTH')
smooth.factor=0.65; smooth.iterations=3
bpy.ops.object.modifier_apply(modifier=smooth.name)
ship.data.calc_loop_triangles()
planar=ship.modifiers.new('Remove coplanar source detail','DECIMATE')
planar.decimate_type='DISSOLVE';planar.angle_limit=math.radians(7.0)
planar.use_dissolve_boundaries=False
bpy.ops.object.modifier_apply(modifier=planar.name)
ship.data.validate(verbose=False,clean_customdata=True)
ship.data.update();ship.data.calc_loop_triangles()
clean_triangles=len(ship.data.loop_triangles)
modifier=ship.modifiers.new('Freibeuter readable silhouette','DECIMATE')
modifier.decimate_type='COLLAPSE'; modifier.ratio=min(1.0,14000/clean_triangles)
modifier.use_collapse_triangulate=True
modifier.use_symmetry=True; modifier.symmetry_axis='X'
bpy.context.view_layer.objects.active=ship
bpy.ops.object.modifier_apply(modifier=modifier.name)
ship.data.validate(verbose=False,clean_customdata=True)
ship.data.update()
# Collapse can move the lowest point slightly; align final output, not source alone.
lowest=min(v.co.z for v in ship.data.vertices)
for v in ship.data.vertices:v.co.z-=lowest
ship.data.update()
for polygon in ship.data.polygons: polygon.use_smooth=False
# Rebuild a clean mesh datablock so stale OBJ/decimator corner data cannot leak
# into glTF. Keep unique non-degenerate faces and no unused vertices.
old_mesh=ship.data
vertices=[tuple(v.co) for v in old_mesh.vertices]
faces=[];seen=set()
for face in old_mesh.polygons:
    ids=tuple(face.vertices);key=tuple(sorted(ids))
    if face.area<=1e-10 or len(set(ids))<3 or key in seen:continue
    seen.add(key);faces.append(ids)
used=sorted({i for face in faces for i in face})
remap={old:new for new,old in enumerate(used)}
clean_mesh=bpy.data.meshes.new('Freibeuter_Lowpoly')
clean_mesh.from_pydata([vertices[i] for i in used],[],[[remap[i] for i in face] for face in faces])
clean_mesh.validate(clean_customdata=True);clean_mesh.update()
ship.data=clean_mesh
bpy.data.meshes.remove(old_mesh)
ship.name='Freibeuter'; ship.data.name='Freibeuter_Lowpoly'
ship.data.materials.clear()
def material(name,color,metallic=0.0,roughness=0.75):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metallic;shader.inputs['Roughness'].default_value=roughness
    return mat
colors=[('Hull warm ivory',(0.45,0.49,0.46),0.1),('Structure graphite',(0.105,0.135,0.15),0.2),('Service orange',(0.66,0.13,0.065),0.05),('Cockpit smoked blue',(0.035,0.10,0.135),0.3)]
for name,color,metallic in colors: ship.data.materials.append(material(name,color,metallic))
for face in ship.data.polygons:
    center=face.center;x,y,z=center
    slot=0
    if z<0.60 or (abs(x)>1.75 and y<-0.60):slot=1
    if (abs(x)>1.8 and -2.55<y<-1.90 and z>0.7) or (abs(x)>2.25 and 0.10<y<1.90 and z>0.8):slot=2
    if y>2.45 and abs(x)<0.7 and z>1.12:slot=3
    face.material_index=slot
ship['source_file']=SOURCE.name
ship['source_sha256']=info['source_sha256']
ship['provenance']='User-provided DRAKE-BUCCANEER OBJ; local authorized derivative. Source rights not established; no redistribution license claimed.'
ship['forward_blender']='+Y';ship['forward_gltf']='-Z';ship['up_gltf']='+Y'
# Export only the gameplay mesh. Source underside is on ground, without a renderer offset.
bpy.ops.object.select_all(action='DESELECT');ship.select_set(True);bpy.context.view_layer.objects.active=ship
assert not ship.data.validate(), 'Final mesh must already be valid'
bpy.ops.export_scene.gltf(filepath=str(OUT/'freibeuter.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_materials='EXPORT',export_yup=True)
ship.data.calc_loop_triangles()
processed={'vertices':len(ship.data.vertices),'faces':len(ship.data.polygons),'triangles':len(ship.data.loop_triangles),'materials':len(ship.data.materials),'blender_dimensions_xyz':list(ship.dimensions),'gltf_dimensions_xyz':[ship.dimensions.x,ship.dimensions.z,ship.dimensions.y],'forward':'-Z','up':'+Y','bottom_y':0.0}
# Actual Blender studio preview, showing front (+Y in Blender) and port-side silhouette.
world=bpy.context.scene.world;world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(0.065,0.085,0.10,1)
world.node_tree.nodes['Background'].inputs[1].default_value=0.4
def aim(obj,point):obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()
def area(name,loc,power,size):
    bpy.ops.object.light_add(type='AREA',location=loc)
    ob=bpy.context.object;ob.name=name;ob.data.energy=power;ob.data.shape='DISK';ob.data.size=size;aim(ob,(0,0,0))
area('Key',(3,5,10),1400,7);area('Fill',(-6,1,6),900,6);area('Rim',(2,-7,8),1800,5)
bpy.ops.mesh.primitive_plane_add(size=200,location=(0,0,-0.035))
floor=bpy.context.object;floor.name='Preview floor';floor.data.materials.append(material('Preview floor',(0.075,0.10,0.115)))
bpy.ops.object.camera_add(location=(10,13,10))
camera=bpy.context.object;aim(camera,(0,0,0.9));camera.data.type='ORTHO';camera.data.ortho_scale=10.7
scene=bpy.context.scene;scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.samples=32
scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'preview.png')
scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source'/'freibeuter.blend'))
bpy.ops.render.render(write_still=True)
# Validate the written GLB, not merely the pre-export mesh.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(OUT/'freibeuter.glb'))
exported=[o for o in bpy.context.scene.objects if o.type=='MESH']
for ob in exported:ob.data.calc_loop_triangles()
world_points=[ob.matrix_world@v.co for ob in exported for v in ob.data.vertices]
verified={'objects':len(exported),'vertices':sum(len(ob.data.vertices) for ob in exported),'faces':sum(len(ob.data.polygons) for ob in exported),'triangles':sum(len(ob.data.loop_triangles) for ob in exported),'materials':len({mat.name for ob in exported for mat in ob.data.materials if mat}),'reimport_blender_min':[min(v[k] for v in world_points) for k in range(3)],'reimport_blender_max':[max(v[k] for v in world_points) for k in range(3)]}
metrics={'source':info,'clean_triangles':clean_triangles,'processed':processed,'verified_glb':verified,'blender_version':bpy.app.version_string,'provenance':'User-provided DRAKE-BUCCANEER OBJ, local authorized derivative; no redistribution license claimed.'}
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2),encoding='utf-8')
assert 8000<=verified['triangles']<=20000,verified
assert abs(verified['reimport_blender_min'][2])<0.001,verified
assert verified['materials']==4,verified
bpy.ops.wm.open_mainfile(filepath=str(OUT/'source'/'freibeuter.blend'))
reopened=bpy.data.objects.get('Freibeuter')
assert reopened is not None and reopened.type=='MESH'
reopened.data.calc_loop_triangles()
assert len(reopened.data.loop_triangles)==processed['triangles']
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==info['source_sha256']
metrics['blend_reopened_verified']=True
metrics['source_unchanged_verified']=True
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2),encoding='utf-8')
print('EXPORT_VERIFIED',json.dumps(verified))

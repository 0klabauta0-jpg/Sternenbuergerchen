"""Reproducible local-only derivative of user-supplied DRAKE-CUTLASS OBJ.
Run with Blender --background --factory-startup --python tools/prepare_shuttle_n4.py.
The source file remains unchanged. No license or original-design claim is made.
"""
import bpy, json, hashlib, math
from pathlib import Path
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r'C:\Users\bjoer\3D Objects\drive-download-20250521T120706Z-1-001\DRAKE\DRAKE-CUTLASS.obj')
OUT = ROOT / 'assets' / 'local' / 'entersaebel_n5'
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
ship = meshes[0]
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
ship.data.calc_loop_triangles()
planar=ship.modifiers.new('Remove coplanar source detail','DECIMATE')
planar.decimate_type='DISSOLVE';planar.angle_limit=math.radians(7.0)
planar.use_dissolve_boundaries=False
bpy.ops.object.modifier_apply(modifier=planar.name)
ship.data.validate(verbose=False,clean_customdata=True)
ship.data.update();ship.data.calc_loop_triangles()
clean_triangles=len(ship.data.loop_triangles)
modifier=ship.modifiers.new('N1 readable silhouette','DECIMATE')
modifier.decimate_type='COLLAPSE'; modifier.ratio=min(1.0,11500/clean_triangles)
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
clean_mesh=bpy.data.meshes.new('Entersaebel_Lowpoly')
clean_mesh.from_pydata([vertices[i] for i in used],[],[[remap[i] for i in face] for face in faces])
clean_mesh.validate(clean_customdata=True);clean_mesh.update()
ship.data=clean_mesh
bpy.data.meshes.remove(old_mesh)
# N4: remove the complete forward wing/gun attachments, fixed dorsal turret
# and stray low undercarriage remnants. The source asset itself is untouched.
bm=bmesh.new();bm.from_mesh(ship.data)
removed=[v for v in bm.verts if (v.co.y>1.35 and abs(v.co.x)>0.82) or (v.co.y>2.9 and v.co.z<0.54) or (0.6<v.co.y<2.35 and abs(v.co.x)<0.60 and v.co.z>1.72)]
bmesh.ops.delete(bm,geom=removed,context='VERTS')
# Remove detached slivers left after trimming the original wing assemblies.
visited=set();slivers=[]
for start in bm.verts:
 if start in visited:continue
 component=[];todo=[start];visited.add(start)
 while todo:
  vertex=todo.pop();component.append(vertex)
  for edge in vertex.link_edges:
   other=edge.other_vert(vertex)
   if other not in visited:visited.add(other);todo.append(other)
 center=sum((v.co for v in component),Vector())/len(component)
 if len(component)<24 and abs(center.x)>1.5 and center.y>0.0:slivers.extend(component)
if slivers:bmesh.ops.delete(bm,geom=slivers,context='VERTS')
edges=[e for e in bm.edges if e.is_boundary]
if edges: bmesh.ops.holes_fill(bm,edges=edges,sides=0)
bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
bm.to_mesh(ship.data);bm.free()
# Author an explicit profile consumed by the core: hull within7.5x11m,
# feet on ground, aft boarding access outside hull at z+6.8 in Godot.
verts=[v.co.copy() for v in ship.data.vertices]
lo=Vector([min(v[k] for v in verts) for k in range(3)])
hi=Vector([max(v[k] for v in verts) for k in range(3)])
for v in ship.data.vertices:
 v.co.x=(v.co.x-(lo.x+hi.x)/2)*7.5/(hi.x-lo.x)
 v.co.y=(v.co.y-(lo.y+hi.y)/2)*11.0/(hi.y-lo.y)
 v.co.z=(v.co.z-lo.z)*2.6/(hi.z-lo.z)+0.65
ship.data.update()

ship.name='Entersaebel'; ship.data.name='Entersaebel_Lowpoly'
ship.data.materials.clear()
def material(name,color,metallic=0.0,roughness=0.75):
    mat=bpy.data.materials.new(name);mat.diffuse_color=(*color,1);mat.use_nodes=True
    shader=mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value=(*color,1)
    shader.inputs['Metallic'].default_value=metallic;shader.inputs['Roughness'].default_value=roughness
    return mat
colors=[('Hull warm ivory',(0.66,0.69,0.64),0.1),('Structure graphite',(0.105,0.135,0.15),0.2),('Service orange',(0.88,0.265,0.055),0.05),('Cockpit smoked blue',(0.035,0.10,0.135),0.3)]
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
ship['provenance']='User-provided DRAKE-CUTLASS OBJ; local authorized derivative. Source rights not established; no redistribution license claimed.'
ship['forward_blender']='+Y';ship['forward_gltf']='-Z';ship['up_gltf']='+Y'
# Export only the gameplay mesh. Source underside is on ground, without a renderer offset.
# Separate named gameplay nodes: no fixed weapons remain on the hull.
def cube(name,at,size,mat,parent=None):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at)
 ob=bpy.context.object;ob.name=name;ob.dimensions=size;bpy.ops.object.transform_apply(location=False,rotation=False,scale=True);ob.data.materials.append(mat)
 if parent is not None:
  world=ob.matrix_world.copy();ob.parent=parent;ob.matrix_world=world
 return ob
root=bpy.data.objects.new('Entersaebel_Root',None);bpy.context.collection.objects.link(root);ship.parent=root
parts=[ship]
for x,y in [(-1.65,-3.0),(1.65,-3.0),(0.0,3.55)]:
 parts.append(cube('LandingStrut', (x,y,0.50),(0.24,0.30,0.95),ship.data.materials[1],root))
 foot=cube('LandingFoot',(x,y,0.12),(0.68,1.0,0.24),ship.data.materials[1],root)
 bevel=foot.modifiers.new('Chamfered shoe','BEVEL');bevel.width=0.09;bevel.segments=1
 bpy.context.view_layer.objects.active=foot;bpy.ops.object.modifier_apply(modifier=bevel.name);parts.append(foot)
# A short stern step stops before the shared boarding point (+Z6.8).
parts.append(cube('AftAccessStep',(0,-5.1,0.18),(1.1,0.8,0.36),ship.data.materials[1],root))
turret=bpy.data.objects.new('TurretPivot',None);bpy.context.collection.objects.link(turret);turret.parent=root;turret.location=(0,0.3,3.0)
# Low octagonal bearing and chamfered armor align with the original hull facets.
def collar(name,radius,depth,z,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=radius,depth=depth,location=(0,0.3,z))
 ob=bpy.context.object;ob.name=name;ob.data.materials.append(mat)
 world=ob.matrix_world.copy();ob.parent=turret;ob.matrix_world=world
 parts.append(ob)
collar('TurretBearing',0.72,0.16,3.02,ship.data.materials[1])
collar('TurretArmor',0.65,0.38,3.26,ship.data.materials[0])
cap=cube('TurretSlopedCap',(0,0.3,3.46),(1.03,1.12,0.22),ship.data.materials[0],turret)
bevel=cap.modifiers.new('Broad armor chamfers','BEVEL');bevel.width=0.14;bevel.segments=1
bpy.context.view_layer.objects.active=cap;bpy.ops.object.modifier_apply(modifier=bevel.name);parts.append(cap)
for x in (-0.42,0.42):
 parts.append(cube('TurretBarrel',(x,1.30,3.28),(0.16,1.5,0.18),ship.data.materials[1],turret))
parts.append(cube('TurretSight',(0,0.87,3.37),(0.3,0.22,0.20),ship.data.materials[3],turret))
bpy.ops.object.select_all(action='DESELECT')
for ob in [root,turret]+parts:ob.select_set(True)
bpy.context.view_layer.objects.active=ship
assert not ship.data.validate(), 'Final mesh must already be valid'
bpy.ops.export_scene.gltf(filepath=str(OUT/'entersaebel.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_materials='EXPORT',export_yup=True)
ship.data.calc_loop_triangles()
processed={'vertices':len(ship.data.vertices),'faces':len(ship.data.polygons),'triangles':len(ship.data.loop_triangles),'materials':len(ship.data.materials),'blender_dimensions_xyz':list(ship.dimensions),'gltf_dimensions_xyz':[ship.dimensions.x,ship.dimensions.z,ship.dimensions.y],'forward':'-Z','up':'+Y','bottom_y':min(v.co.z for v in ship.data.vertices),'n5_hull_profile':[7.5,11.0],'n5_aft_access_godot':[0,6.8],'n5_turret_node':'TurretPivot'}
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
camera=bpy.context.object;aim(camera,(0,0,0.9));camera.data.type='ORTHO';camera.data.ortho_scale=15.2
scene=bpy.context.scene;scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.samples=64
scene.render.resolution_x=1200;scene.render.resolution_y=900;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.filepath=str(OUT/'preview.png')
scene.view_settings.view_transform='AgX'
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source'/'entersaebel.blend'))
bpy.ops.render.render(write_still=True)
# Validate the written GLB, not merely the pre-export mesh.
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(OUT/'entersaebel.glb'))
exported=[o for o in bpy.context.scene.objects if o.type=='MESH']
for ob in exported:ob.data.calc_loop_triangles()
world_points=[ob.matrix_world@v.co for ob in exported for v in ob.data.vertices]
verified={'objects':len(exported),'vertices':sum(len(ob.data.vertices) for ob in exported),'faces':sum(len(ob.data.polygons) for ob in exported),'triangles':sum(len(ob.data.loop_triangles) for ob in exported),'materials':len({mat.name for ob in exported for mat in ob.data.materials if mat}),'reimport_blender_min':[min(v[k] for v in world_points) for k in range(3)],'reimport_blender_max':[max(v[k] for v in world_points) for k in range(3)]}
metrics={'source':info,'clean_triangles':clean_triangles,'processed':processed,'verified_glb':verified,'blender_version':bpy.app.version_string,'provenance':'User-provided DRAKE-CUTLASS OBJ, local authorized derivative; no redistribution license claimed.'}
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2),encoding='utf-8')
assert 8000<=verified['triangles']<=22000,verified
assert any(ob.name=='TurretPivot' for ob in bpy.context.scene.objects),'Independent turret pivot missing'
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==info['source_sha256']
bpy.ops.wm.open_mainfile(filepath=str(OUT/'source'/'entersaebel.blend'))
assert bpy.data.objects.get('TurretPivot') is not None
metrics['blend_reopened_verified']=True;metrics['source_unchanged_verified']=True
(OUT/'metrics.json').write_text(json.dumps(metrics,indent=2),encoding='utf-8')
assert abs(verified['reimport_blender_min'][2])<0.001,verified
assert verified['materials']==4,verified
assert abs(verified['reimport_blender_max'][0]-verified['reimport_blender_min'][0]-7.5)<0.001,verified
assert abs(verified['reimport_blender_max'][1]-verified['reimport_blender_min'][1]-11.0)<0.001,verified
print('EXPORT_VERIFIED',json.dumps(verified))

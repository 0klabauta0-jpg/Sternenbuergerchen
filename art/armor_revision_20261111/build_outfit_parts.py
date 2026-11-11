"""Authored rigid armor volumes for the existing game skeletons.

Blender 5.1.1; later assembled into one skinned mesh per class in Godot.
The user's eight-view heavy suit is the shape target. No green overlay plate.
"""
import bpy
import bmesh
import json
import math
import sys
from pathlib import Path

OUT = Path(sys.argv[sys.argv.index('--') + 1]).resolve()
OUT.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
sys.path.insert(0, str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import qa_check

MATERIALS = []
for name, color, metallic, roughness in [
 ('M_Armor_Ceramic', (.52, .50, .45, 1), .16, .57),
 ('M_Armor_Graphite', (.035, .045, .061, 1), .08, .86),
 ('M_Armor_Titanium', (.14, .17, .21, 1), .55, .40),
 ('M_Armor_Amber', (.85, .39, .065, 1), .25, .46),
 ('M_Armor_Visor', (.009, .021, .036, 1), .65, .20),
]:
 m = bpy.data.materials.new(name)
 m.diffuse_color = color
 p = next(n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED')
 p.inputs['Base Color'].default_value = color
 p.inputs['Metallic'].default_value = metallic
 p.inputs['Roughness'].default_value = roughness
 MATERIALS.append(m)


def loft(name, rings, segments=12, surface='armor'):
 """Closed chamfered cross sections, with structural bands instead of decals.

 Each ring is z, width, depth, optional fore/aft center. Front is Blender -Y.
 """
 vertices = []
 for ring in rings:
  z, w, d = ring[:3]
  cy = ring[3] if len(ring) > 3 else 0
  for j in range(segments):
   angle = 2*math.pi*j/segments
   x, y = math.cos(angle)*w*.5, math.sin(angle)*d*.5
   if name.startswith('helmet'):
    # Squared cheek planes, a shaped breathing mask and brow ridge.
    x = math.copysign(abs(math.cos(angle))**.70, math.cos(angle))*w*.5
    y = math.copysign(abs(math.sin(angle))**.70, math.sin(angle))*d*.5
    if y < 0 and -.31 <= z <= .06:
     y -= .095*(1-abs(math.cos(angle)))
    if y < 0 and z >= .30:
     y -= .035*(1-abs(math.cos(angle)))
   # A central breast ridge makes the front a shaped armor volume.
   if 'torso' in name and y < 0 and z > -.1:
    y -= .025*(1-abs(math.cos(angle)))
   vertices.append((x, y+cy, z))
 faces, materials = [], []
 faces.append(tuple(reversed(range(segments)))); materials.append(2)
 for i in range(len(rings)-1):
  z = (rings[i][0]+rings[i+1][0])*.5
  for j in range(segments):
   faces.append((i*segments+j, i*segments+(j+1)%segments,
                 (i+1)*segments+(j+1)%segments, (i+1)*segments+j))
   angle = 2*math.pi*(j+.5)/segments
   front = math.sin(angle) < -.65
   back = math.sin(angle) > .65
   material = 0
   if surface == 'cloth': material = 1
   if 'torso' in name:
    if -.22 < z < -.10: material = 2
    if back and .08 < z < .30: material = 1
    if front and .28 < z < .37 and abs(math.cos(angle)) < .55: material = 3
    if front and z < -.31: material = 2
   if name.startswith('helmet'):
    if front and -.12 < z < .19: material = 4
    elif front and -.31 < z < -.12: material = 2
    elif front and .31 < z < .42 and abs(math.cos(angle)) < .4: material = 3
    elif back and -.12 < z < .19: material = 2
   elif name in ['forearm','shin','boot','pelvis_heavy','pelvis_medium']:
    if abs(math.cos(angle)) > .85: material = 2
    if -.12 < z < -.04: material = 1
   if name == 'boot' and z < -.32: material = 1
   materials.append(material)
 faces.append(tuple(range((len(rings)-1)*segments,len(rings)*segments))); materials.append(0 if name.startswith('helmet') else 2)
 mesh = bpy.data.meshes.new(name+'_Mesh')
 mesh.from_pydata(vertices, [], faces); mesh.update()
 obj = bpy.data.objects.new(name, mesh)
 bpy.context.collection.objects.link(obj)
 for material in MATERIALS: mesh.materials.append(material)
 for face, material in zip(mesh.polygons, materials): face.material_index = material
 return obj


def shaped_helmet(name):
 # Own construction, only informed by the user image and accessory proportions.
 # Swept crown, inset visor, projecting breathing mask and bevelled cheek planes.
 profile=[(0,-.55),(.30,-.50),(.48,-.28),(.50,.17),(.32,.48),(0,.52),(-.32,.48),(-.50,.17),(-.48,-.28),(-.30,-.50)]
 # Rounded crown with a swept brow; taper the jaw instead of a vertical bucket.
 # Medium retains a narrower optical strip and less projecting cheek volume.
 medium=name.endswith('medium')
 rings=[(-.50,.54,.55,.065),(-.35,.72,.81,-.035),(-.19,.91,.96,-.045),(-.05,.96,.98,-.025),(-.02,.96,.93,-.005),(.14,1,.93,0),(.18,1,1,0),(.28,.96,.98,.025),(.39,.84,.86,.060),(.47,.56,.60,.085),(.50,.18,.19,.10)]
 vertices=[]
 for z,w,d,cy in rings:
  for x,y in profile:
   # Recess the optical surface inside its protective rim.
   front_relief=.020 if -.02 <= z <= .14 and y<-.3 else 0
   # Optical band slopes down at the cheek, like a protective brow above an eye.
   brow_slope=-.035*abs(x)*2 if -.05 <= z <= .28 and y<-.3 else 0
   vertices.append((x*w,y*d+cy+front_relief,z+brow_slope))
 faces=[tuple(reversed(range(10)))];materials=[1]
 for ring in range(len(rings)-1):
  mid=(rings[ring][0]+rings[ring+1][0])*.5
  for j in range(10):
   faces.append((ring*10+j,ring*10+(j+1)%10,(ring+1)*10+(j+1)%10,(ring+1)*10+j))
   front=j in [0,1,8,9]
   material=0
   if front and -.02 < mid < .14:material=4
   elif front and -.35 < mid < -.05 and j in [0,9]:material=2
   elif front and (-.05 < mid < -.02 or .14 < mid < .18):material=1
   elif front and .18 < mid < .28 and j in [1,8]:material=3
   elif not front and -.05 < mid < .14:material=2
   materials.append(material)
 faces.append(tuple(range((len(rings)-1)*10,len(rings)*10)));materials.append(0)
 mesh=bpy.data.meshes.new(name+'_Mesh');mesh.from_pydata(vertices,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 for m in MATERIALS:mesh.materials.append(m)
 for face,material in zip(mesh.polygons,materials):face.material_index=material
 # Own compact temple couplers, not geometry copied from a package helmet.
 extras=[]
 for side in [-1,1]:
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.105,depth=.055,
    location=(side*.49,.10,-.005),rotation=(0,math.pi/2,0))
  ear=bpy.context.object;ear.data.materials.append(MATERIALS[2]);extras.append(ear)
  bpy.ops.mesh.primitive_cylinder_add(vertices=12,radius=.067,depth=.059,
    location=(side*.49,.10,-.005),rotation=(0,math.pi/2,0))
  inset=bpy.context.object;inset.data.materials.append(MATERIALS[1]);extras.append(inset)
 bpy.ops.object.select_all(action='DESELECT')
 for part in [obj]+extras:part.select_set(True)
 bpy.context.view_layer.objects.active=obj;bpy.ops.object.join()
 return obj


objects = []
torso_heavy=[(-.5,.65,.66),(-.32,.74,.72),(-.22,.89,.80),(-.10,.84,.78),(.06,.98,.88),(.28,1,1),(.37,.93,.96),(.44,.81,.83),(.5,.48,.60)]
torso_medium=[(-.5,.65,.65),(-.31,.73,.70),(-.22,.85,.75),(-.10,.83,.77),(.06,.96,.90),(.28,1,1),(.37,.92,.96),(.44,.79,.82),(.5,.49,.61)]
torso_light=[(-.5,.7,.7),(-.25,.77,.79),(.06,.98,.92),(.30,1,1),(.43,.86,.87),(.5,.54,.66)]
for name, rings in [('torso_heavy',torso_heavy),('torso_medium',torso_medium),('torso_light',torso_light)]:
 objects.append(loft(name,rings,16,'cloth' if name.endswith('light') else 'armor'))
for name in ['pelvis_heavy','pelvis_medium','pelvis_light']:
 objects.append(loft(name,[(-.5,.55,.75),(-.30,.82,.92),(-.10,1,1),(.17,.97,.94),(.5,.83,.87)],12,'cloth' if name.endswith('light') else 'armor'))
objects.append(loft('pauldron',[(-.5,.65,.65),(-.28,.98,.90),(.10,1,1),(.35,.87,.88),(.5,.56,.58)],12))
objects.append(loft('upper_arm',[(-.5,.77,.75),(-.32,.89,.86),(.08,1,1),(.36,.93,.93),(.5,.73,.77)],12))
objects.append(loft('forearm',[(-.5,.72,.73),(-.30,.90,.83),(-.12,.94,.92),(-.04,.94,.94),(.14,1,1),(.40,.91,.86),(.5,.70,.72)],12))
objects.append(loft('hand_guard',[(-.5,.72,.69),(-.29,.96,.85),(.15,1,1),(.44,.84,.81),(.5,.69,.68)],12))
objects.append(loft('thigh',[(-.5,.71,.67),(-.28,.83,.84),(.06,.96,.96),(.33,1,1),(.5,.82,.83)],12))
objects.append(loft('knee',[(-.5,.64,.68),(-.27,.93,.92),(.12,1,1),(.38,.86,.84),(.5,.54,.61)],12))
objects.append(loft('shin',[(-.5,.70,.72),(-.31,.83,.85),(-.12,.86,.86),(-.04,.86,.87),(.17,1,1),(.38,.96,.93),(.5,.75,.71)],12))
objects.append(loft('boot',[(-.5,.95,.98,-.10),(-.32,1,1,-.10),(-.12,.96,.94,-.09),(.02,.77,.72,.05),(.26,.68,.60,.14),(.5,.62,.55,.17)],12))
for name in ['helmet_medium','helmet_heavy']:
 objects.append(shaped_helmet(name))
bpy.ops.mesh.primitive_torus_add(major_segments=20,minor_segments=6,major_radius=.38,minor_radius=.10)
collar=bpy.context.object;collar.name='collar'
collar.data.materials.append(MATERIALS[2]);objects.append(collar)

reports=[]
for index,obj in enumerate(objects):
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 if obj.name!='collar':
  bevel=obj.modifiers.new('Consistent armor edge chamfer','BEVEL')
  bevel.width=.008;bevel.segments=1;bevel.use_clamp_overlap=True
  bpy.ops.object.modifier_apply(modifier=bevel.name)
 bm=bmesh.new();bm.from_mesh(obj.data)
 bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
 bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.000001)
 bmesh.ops.triangulate(bm,faces=list(bm.faces))
 bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
 bm.to_mesh(obj.data);bm.free();obj.data.validate(clean_customdata=True)
 bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT')
 bpy.ops.uv.smart_project(angle_limit=math.radians(66),island_margin=.025)
 bpy.ops.object.mode_set(mode='OBJECT')
 # Weighted normals keep broad panels clean and avoid diagonal visor highlights.
 for polygon in obj.data.polygons:polygon.use_smooth=True
 edge_flags=obj.data.attributes.get('sharp_edge') or obj.data.attributes.new('sharp_edge','BOOLEAN','EDGE')
 bm=bmesh.new();bm.from_mesh(obj.data);bm.edges.ensure_lookup_table()
 for edge in bm.edges:
  edge_flags.data[edge.index].value=(not edge.is_manifold) or edge.calc_face_angle(0)>math.radians(38) or (len(edge.link_faces)==2 and edge.link_faces[0].material_index!=edge.link_faces[1].material_index)
 bm.free()
 normals=obj.modifiers.new('Armor panel weighted normals','WEIGHTED_NORMAL');normals.keep_sharp=True;normals.weight=50
 bpy.ops.object.modifier_apply(modifier=normals.name)
 obj['asset_role']='rigid_armor_segment'
 obj['front_axis']='Blender -Y / Godot +Z'
 obj['pivot_contract']='centered segment; fit and rigid skin binding supplied by owner rig'
 report=qa_check.run(objects=[obj.name],profile='game')
 report['asset']=obj.name
 report['accepted_warning_reason']='Centered wearable segment: no independent ground plane; joints are assembled against actual bone rests.'
 reports.append(report)
 if not report['pass']:
  (OUT/'qa_failed.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
  raise RuntimeError(json.dumps(report))
 bpy.ops.export_scene.gltf(filepath=str(OUT/(obj.name+'.glb')),export_format='GLB',use_selection=True,export_animations=False,export_extras=True)
 obj.location.x=(index%6)*1.6
 obj.location.y=(index//6)*1.8
 obj.location.z=.55
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'armor_outfit_parts.blend'))
(OUT/'qa.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('ARMOR_OUTFIT_PARTS_PASS',len(reports),'segments',flush=True)

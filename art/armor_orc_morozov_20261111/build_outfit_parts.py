"""Own light/medium ORC-inspired and heavy Morozov-inspired armor families.

Blender 5.1.1; later assembled into one skinned mesh per class in Godot.
The image-generated Kenney turnarounds and the user's revisions define the
three-class target. No welding goggles, protruding mouth block or green overlay.
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
 ('M_Armor_Ceramic', (.48, .46, .40, 1), .20, .58),
 ('M_Armor_Graphite', (.035, .045, .061, 1), .08, .86),
 ('M_Armor_Titanium', (.18, .21, .25, 1), .38, .53),
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


def panel(name, points, front, depth, material=0):
 """Solid shaped plate in X/Z, attached to the suit by its rear face."""
 vertices=[(x,front,z) for x,z in points]+[(x,front+depth,z) for x,z in points]
 n=len(points);faces=[tuple(reversed(range(n))),tuple(range(n,n*2))]
 for i in range(n):faces.append((i,(i+1)%n,(i+1)%n+n,i+n))
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vertices,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 mesh.materials.append(MATERIALS[material]);return obj


def box(name, center, size, material):
 bpy.ops.mesh.primitive_cube_add(size=1,location=center)
 obj=bpy.context.object;obj.name=name;obj.scale=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 obj.data.materials.append(MATERIALS[material]);return obj


def combine(name, parts):
 bpy.ops.object.select_all(action='DESELECT')
 for obj in parts:obj.select_set(True)
 bpy.context.view_layer.objects.active=parts[0];bpy.ops.object.join()
 obj=parts[0];obj.name=name
 # Joining leaves the active object's origin in place; normalize to world zero.
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 return obj


def flexible(name,rings,segments=12):
 obj=loft(name,rings,segments,'cloth')
 for face in obj.data.polygons:face.material_index=1
 return obj


def torso(medium):
 name='torso_medium' if medium else 'torso_heavy'
 core=flexible(name,[(-.5,.64,.62),(-.18,.82,.80),(.16,1,.90),(.37,.98,.91),(.5,.62,.65)],12)
 pieces=[core]
 if medium:
  # Two angular pectoral plates, separate flexible center and articulated belly.
  for side in [-1,1]:
   pieces.append(panel('ORC shaped pectoral',[(side*x,z) for x,z in [(.055,.38),(.32,.45),(.49,.26),(.41,.04),(.08,-.01)]],-.48,.13,0))
   pieces.append(panel('Dark inset',[(side*x,z) for x,z in [(.10,.30),(.32,.35),(.40,.24),(.34,.15),(.10,.12)]],-.49,.025,2))
  for z,w in [(-.10,.60),(-.25,.53),(-.40,.44)]:
   pieces.append(panel('Articulated belly',[(-w/2,z+.065),(w/2,z+.065),(w/2+.025,z-.025),(0,z-.075),(-w/2-.025,z-.025)],-.43,.09,0))
  pieces.append(panel('Spine plate',[(-.28,.30),(.28,.30),(.32,-.05),(0,-.40),(-.32,-.05)],.36,.10,2))
 else:
  # Broad reinforced vest, shoulder harness, visible edge padding and rear spine.
  shield=[(-.34,.40),(.34,.40),(.45,.20),(.39,-.23),(.22,-.40),(-.22,-.40),(-.39,-.23),(-.45,.20)]
  pieces.append(panel('Morozov broad shield',shield,-.53,.18,2))
  pieces.append(panel('Strike panel',[(-.26,.26),(.26,.26),(.31,.13),(.26,-.22),(0,-.31),(-.26,-.22),(-.31,.13)],-.55,.035,0))
  for side in [-1,1]:
   pieces.append(box('Harness',(side*.34,-.47,.14),(.055,.15,.57),1))
   pieces.append(box('Harness buckle',(side*.34,-.55,.31),(.085,.055,.055),0))
   pieces.append(box('Lower vest pad',(side*.33,-.43,-.37),(.22,.15,.15),2))
   for z in [-.20,-.02,.16,.34]:
    pieces.append(box('Padded seam',(side*.40,-.17,z),(.075,.35,.025),2))
  pieces.append(panel('Raised back armor',[(-.27,.42),(.27,.42),(.37,.25),(.32,-.31),(0,-.46),(-.32,-.31),(-.37,.25)],.35,.15,2))
  pieces.append(box('Back spine',(0,.52,.02),(.085,.055,.61),0))
 pieces.append(box('Small status tab',(.18,-.50 if medium else -.55,.32),(.08,.05,.025),3))
 return combine(name,pieces)


def limb(name,heavy,kind,light=False):
 rings=[(-.5,.66,.65),(-.30,.87,.84),(.10,1,1),(.34,.93,.91),(.5,.69,.70)]
 core=flexible(name,rings,10)
 mat=0 if not heavy or kind in ['pauldron','forearm','thigh','knee','hand_guard'] else 2
 if kind=='pauldron':
  points=[(-.49,.20),(-.31,.47),(.30,.47),(.50,.20),(.40,-.20),(0,-.45),(-.39,-.20)]
 elif kind=='knee':
  points=[(-.34,.45),(.34,.45),(.48,.19),(.35,-.30),(0,-.47),(-.35,-.30),(-.48,.19)]
 else:
  points=[(-.35,.44),(.35,.44),(.45,.15),(.30,-.43),(-.30,-.43),(-.45,.15)]
 pieces=[core,panel('Shaped outer guard',points,-.45 if light else -.49,.08 if light else .17,mat)]
 if heavy:
  for z in [-.24,.22]:
   pieces.append(box('Reinforcement band',(0,-.54,z),(.65,.10,.075),1))
  pieces.append(box('Side fastening',(.35,-.19,-.08),(.08,.43,.07),1))
 elif not light:
  pieces.append(panel('Inset relief',[(-.19,.25),(.19,.25),(.23,.12),(.13,-.17),(-.13,-.17),(-.23,.12)],-.51,.035,2))
 return combine(name,pieces)


def open_orc_helmet(name='helmet_medium',light=False):
 # A thick shell with a real open face: no copied accessory or hidden character.
 n=16;rings=[(-.50,.56,.64),(-.34,.73,.94),(.19,1,1),(.32,.94,.94),(.46,.68,.69),(.50,.25,.26)]
 vertices=[]
 for inner in [False,True]:
  for z,w,d in rings:
   for j in range(n):
    a=2*math.pi*j/n;inset=(.030 if light else .045) if inner else 0
    rear_width=max(w,.90) if z==-.34 and math.sin(a)>-.2 else w
    vertices.append((math.cos(a)*(rear_width/2-inset),math.sin(a)*(d/2-inset),z-(.04 if inner and z==.50 else 0)))
 faces=[];materials=[];offset=len(rings)*n
 for i in range(len(rings)-1):
  for j in range(n):
   front=math.sin(2*math.pi*(j+.5)/n)<-.38
   if i==1 and front:continue
   quad=(i*n+j,i*n+(j+1)%n,(i+1)*n+(j+1)%n,(i+1)*n+j)
   # The crown stripe is part of the shell, avoiding a nearly coplanar overlay.
   faces.append(quad);materials.append(2 if (i<2 and not front) or (i>=2 and j in [3,4,11,12]) else 0)
   faces.append(tuple(v+offset for v in reversed(quad)));materials.append(1)
 # Close the crown with distinct outer/inner caps; leave only the real face
 # opening and the neck aperture, each edged with a solid thickness wall.
 top=(len(rings)-1)*n
 faces.append(tuple(range(top,top+n)));materials.append(2)
 faces.append(tuple(reversed(range(top+offset,top+offset+n))));materials.append(1)
 # Close every exposed shell boundary, including the face opening.
 counts={}
 for f in faces[:]:
  if min(f)>=offset:continue
  for a,b in zip(f,f[1:]+f[:1]):
   k=tuple(sorted((a,b)));counts[k]=counts.get(k,0)+1
 for (a,b),count in counts.items():
  if count==1:faces.append((a,b,b+offset,a+offset));materials.append(2)
 mesh=bpy.data.meshes.new('ORC open helmet');mesh.from_pydata(vertices,[],faces);mesh.update()
 obj=bpy.data.objects.new(name,mesh);bpy.context.collection.objects.link(obj)
 for m in MATERIALS:mesh.materials.append(m)
 for f,m in zip(mesh.polygons,materials):f.material_index=m
 pieces=[obj,box('Chin armor',(0,-.32,-.43),(.20 if light else .24,.15,.10),0)]
 # The image-generated turnaround resolves the bucket silhouette into an open
 # frame with separate temple couplers and a dark lower rear shell.
 for side in [-1,1]:
  for radius,depth,material in [(.12,.085,0),(.077,.090,2)]:
   bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=radius,depth=depth,
      location=(side*.49,0,-.02),rotation=(0,math.pi/2,0))
   ear=bpy.context.object;ear.data.materials.append(MATERIALS[material]);pieces.append(ear)
 return combine(name,pieces)


def morozov_helmet():
 obj=shaped_helmet('helmet_heavy')
 # User correction: no protruding welding goggles, hexagonal mouthpiece or
 # external filters. A recessed visor and the shell's integrated chin remain.
 for p in obj.data.polygons:
  if p.material_index in [0,3]:p.material_index=2
 return obj


def light_torso():
 core=flexible('torso_light',[(-.5,.63,.64),(-.10,.79,.75),(.23,1,.90),(.42,.83,.83),(.5,.60,.66)],12)
 pieces=[core]
 for side in [-1,1]:
  pieces.append(panel('Light pectoral',[(side*x,z) for x,z in [(.06,.37),(.29,.39),(.40,.21),(.30,.06),(.07,.08)]],-.45,.08,0))
 for z in [-.12,-.31]:
  pieces.append(panel('Light belly guard',[(-.20,z+.04),(.20,z+.04),(.17,z-.04),(0,z-.07),(-.17,z-.04)],-.39,.07,0))
 pieces.append(panel('Light back plate',[(-.19,.31),(.19,.31),(.23,.05),(0,-.20),(-.23,.05)],.32,.10,0))
 return combine('torso_light',pieces)


def pelvis(heavy):
 name='pelvis_heavy' if heavy else 'pelvis_medium'
 base=flexible(name,[(-.5,.40,.65),(-.1,.84,.87),(.32,1,1),(.5,.94,.95)],12)
 pieces=[base,panel('Central groin guard',[(-.20,.25),(.20,.25),(.24,.03),(.12,-.45),(-.12,-.45),(-.24,.03)],-.45,.12,2 if heavy else 0)]
 for side in [-1,1]:
  pieces.append(box('Hip fastening',(side*.36,-.27,.25),(.20,.22,.29),2 if heavy else 0))
 return combine(name,pieces)


objects=[torso(True),torso(False),open_orc_helmet(),morozov_helmet(),light_torso(),open_orc_helmet('helmet_light',True)]
light_belt=flexible('pelvis_light',[(-.5,.55,.70),(-.15,.90,.91),(.30,1,1),(.5,.90,.92)],12)
objects.append(combine('pelvis_light',[light_belt,box('Belt buckle',(0,-.44,.26),(.17,.09,.13),2)]))
for kind in ['pauldron','forearm','knee']:objects.append(limb(kind+'_light',False,kind,True))
for heavy in [False,True]:
 family='heavy' if heavy else 'medium'
 for kind in ['pauldron','forearm','thigh','knee','shin','boot']+(['upper_arm','hand_guard'] if heavy else []):
  objects.append(limb(kind+'_'+family,heavy,kind))
 objects.append(pelvis(heavy))
# A genuinely high U-shaped padded collar, front cut down for the mask.
collar=flexible('collar',[(-.5,1,1),(-.25,1,1),(.5,.85,.85)],16)
# Hollow it as a ring rather than filling the neck with a solid volume.
bpy.data.objects.remove(collar,do_unlink=True)
bpy.ops.mesh.primitive_torus_add(major_segments=16,minor_segments=8,major_radius=.36,minor_radius=.13)
collar=bpy.context.object;collar.name='collar'
for v in collar.data.vertices:
 v.co.z*=2.0
 if v.co.y<-.10:v.co.z-=.22*min(1,(-v.co.y-.10)/.3)
collar.data.materials.append(MATERIALS[1]);objects.append(collar)

reports=[]
for index,obj in enumerate(objects):
 bpy.ops.object.select_all(action='DESELECT');obj.select_set(True);bpy.context.view_layer.objects.active=obj
 if obj.name not in ['collar','helmet_medium','helmet_light']:
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
  edge_flags.data[edge.index].value=(not edge.is_manifold) or edge.calc_face_angle(0)>math.radians(18 if obj.name in ['helmet_medium','helmet_light'] else 38) or (len(edge.link_faces)==2 and edge.link_faces[0].material_index!=edge.link_faces[1].material_index)
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
 obj.location.x=(index%6)*1.8
 obj.location.y=(index//6)*1.8
 obj.location.z=.55
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'armor_outfit_parts.blend'))
(OUT/'qa.json').write_text(json.dumps(reports,indent=2),encoding='utf-8')
print('ARMOR_OUTFIT_PARTS_PASS',len(reports),'segments',flush=True)

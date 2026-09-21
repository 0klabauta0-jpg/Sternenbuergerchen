"""Original modular habitat props. Run with Blender --background --python.
No third-party source asset is modified. Blender coordinates are Z-up.
"""
import bpy, json, math
from pathlib import Path

OUT=Path(__file__).resolve().parents[1]/'assets'/'original'/'habitat'
OUT.mkdir(parents=True,exist_ok=True)
SOURCE=OUT.parents[2]/'tools'/'source'/'habitat'
SOURCE.mkdir(parents=True,exist_ok=True)
(SOURCE/'.gdignore').touch()
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
palette={'ivory':(.63,.59,.49,1),'frame':(.12,.17,.18,1),'orange':(.72,.25,.055,1),'fabric':(.84,.40,.12,1),'white':(.83,.79,.67,1),'blue':(.09,.27,.31,1),'screen':(.08,.66,.62,1),'leaf':(.16,.31,.12,1)}
mats={}
for name,color in palette.items():
 m=bpy.data.materials.new(name);m.diffuse_color=color;m.use_nodes=True
 m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=color
 m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.74
 mats[name]=m

def box(at,size,mat,bevel=.035):
 bpy.ops.mesh.primitive_cube_add(size=1,location=at);o=bpy.context.object;o.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 o.data.materials.append(mats[mat])
 if bevel:
  m=o.modifiers.new('Soft manufactured edges','BEVEL');m.width=min(bevel,min(size)*.25);m.segments=1
  bpy.context.view_layer.objects.active=o;bpy.ops.object.modifier_apply(modifier=m.name)
 return o
def cylinder(at,radius,height,mat):
 bpy.ops.mesh.primitive_cylinder_add(vertices=10,radius=radius,depth=height,location=at)
 bpy.context.object.data.materials.append(mats[mat]);return bpy.context.object
def crate(x,y,z,w=.7):
 box((x,y,z+.28),(w,.52,.56),'ivory')
 box((x,y-.27,z+.28),(w*.72,.025,.08),'orange',.004)
 box((x,y-.29,z+.39),(.18,.025,.055),'frame',.004)
def plant(x,y,z):
 cylinder((x,y,z+.12),.15,.24,'ivory')
 for i in range(5):
  leaf=box((x+math.sin(i*1.3)*.10,y+math.cos(i*1.3)*.1,z+.37),(.10,.07,.35),'leaf',.015)
  leaf.rotation_euler=(math.sin(i)*.4,math.cos(i)*.4,i)
def build(name):
 if name=='shelf':
  for x in [-1.4,1.4]:
   for y in [-.4,.4]:box((x,y,1.4),(.10,.10,2.8),'frame')
  for z in [.12,1.02,1.92,2.8]:box((0,0,z),(3,.95,.10),'ivory')
  for row in range(3):
   for i in range(3):
    crate(-.94+i*.94,-.06,.18+row*.9)
    if i==1:box((0,.1,.87+row*.9),(.65,.48,.14),'blue')
 elif name=='workwall':
  box((0,.25,1.85),(3,.18,1.9),'frame')
  box((0,-.18,1.04),(3,.95,.16),'ivory')
  for x in [-1.15,1.15]:box((x,0,.5),(.45,.65,1),'frame')
  for i in range(8):
   x=-1.2+i*.34
   box((x,.11,1.9),(.07,.09,.60 if i%2 else .43),'white')
   box((x,.10,2.14),(.19,.10,.10),'orange')
  for x in [-1,0,1]:crate(x,.04,1.18,.48)
  box((0,.08,2.73),(2.75,.11,.07),'white')
 elif name=='cabinet':
  box((0,0,1.2),(1,.7,2.4),'frame')
  box((0,-.365,1.25),(.89,.08,2.17),'ivory')
  box((.29,-.42,1.32),(.055,.05,.33),'orange')
  for i in range(3):box((0,-.415,1.95+i*.08),(.52,.04,.022),'frame',.002)
 elif name=='bed':
  box((0,0,.22),(1.4,2.5,.4),'frame')
  box((0,0,.50),(1.31,2.39,.3),'white',.07)
  box((0,-.28,.68),(1.34,1.78,.16),'fabric',.06)
  box((0,.84,.72),(.9,.49,.23),'white',.08)
  box((0,-.49,.775),(1.35,.24,.05),'ivory',.015)
  box((0,1.23,.56),(1.47,.13,.96),'ivory')
 elif name=='table':
  box((0,0,.92),(3.4,1.55,.15),'ivory')
  for x in [-1.3,1.3]:box((x,0,.45),(.13,1.15,.9),'frame')
  for x in [-.9,.9]:
   cylinder((x,-.28,1.04),.13,.14,'white')
   box((x,.28,1.02),(.42,.3,.025),'orange',.004)
  plant(0,0,1.0)
 elif name=='cargo':
  box((0,0,1.3),(6,2.5,2.6),'frame',.10)
  box((0,0,1.35),(5.8,2.53,2.3),'ivory',.07)
  for x in [-2.85,2.85]:box((x,0,1.3),(.3,2.68,2.75),'orange',.06)
  for x in [-2.3,-1.5,-.7,.1,.9,1.7,2.3]:
   for y in [-1.29,1.29]:box((x,y,1.4),(.10,.09,2.16),'frame',.01)
  for y in [-.65,.65]:box((3.02,y,1.3),(.09,.08,2.13),'ivory',.015)
 elif name=='planter':
  box((0,0,.32),(1.8,.7,.6),'ivory')
  for x in [-.6,0,.6]:plant(x,0,.62)

evidence=[]
for name in ['shelf','workwall','cabinet','bed','table','planter','cargo']:
 bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
 build(name)
 bpy.ops.object.select_all(action='SELECT')
 bpy.context.view_layer.objects.active=bpy.context.selected_objects[0]
 bpy.ops.object.join();o=bpy.context.object;o.name=name
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 bpy.context.scene.cursor.location=(0,0,0);bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
 o.data.calc_loop_triangles()
 evidence.append({'name':name,'vertices':len(o.data.vertices),'triangles':len(o.data.loop_triangles),'materials':len(o.data.materials)})
 bpy.ops.export_scene.gltf(filepath=str(OUT/(name+'.glb')),export_format='GLB',use_selection=True)
 bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE/(name+'.blend')))
(OUT/'manifest.json').write_text(json.dumps(evidence,indent=2),encoding='utf-8')
print('HABITAT_ASSETS',json.dumps(evidence))

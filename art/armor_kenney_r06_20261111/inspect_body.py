import bpy,json
from pathlib import Path
from mathutils import Vector
root=Path(__file__).resolve().parents[2]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb'))
rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('character'))
hips=rig.matrix_world@rig.data.bones['Hips'].head_local
head=rig.matrix_world@rig.data.bones['Head'].head_local
left=rig.matrix_world@rig.data.bones['LeftArm'].head_local
right=rig.matrix_world@rig.data.bones['RightArm'].head_local
up=(head-hips).normalized();x=(left-right).normalized();front=x.cross(up).normalized()
height=(left-hips).dot(up);width=(left-right).length
rows={}
for v in body.data.vertices:
 p=body.matrix_world@v.co;h=(p-hips).dot(up)/height
 if -.25<h<1.20 and abs(p.dot(x))<width*.7:
  key=round(h,3);rows.setdefault(key,[]).append({'x':round(p.dot(x),4),'d':round(p.dot(front),4),'g':[(body.vertex_groups[g.group].name,round(g.weight,3)) for g in v.groups]})
print('BODY',len(body.data.vertices),'tris',len(body.data.polygons),'width',width,'height',height,'hips',hips[:], 'left',left[:])
print(json.dumps(rows))

"""Small known-good and deliberately damaged fixtures for verify_ship.py."""
from pathlib import Path
import json
import struct
import bpy

OUT=Path(__file__).resolve().parent/'selftest'
OUT.mkdir(exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
col=bpy.data.collections.new('LOW');bpy.context.scene.collection.children.link(col)
bpy.ops.mesh.primitive_cube_add(size=2,location=(0,0,.5))
ob=bpy.context.object;ob.name='VH_QATest_Hull';ob.scale=(.6,2,.5)
for c in list(ob.users_collection):c.objects.unlink(ob)
col.objects.link(ob)
bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
mat=bpy.data.materials.new('M_TestPaint');mat.use_nodes=True
p=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
p.inputs['Base Color'].default_value=(.12,.19,.21,1)
p.inputs['Metallic'].default_value=.1;p.inputs['Roughness'].default_value=.7
ob.data.materials.append(mat)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'good.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
data=bytearray((OUT/'good.glb').read_bytes());jlen=struct.unpack_from('<I',data,12)[0]
doc=json.loads(data[20:20+jlen]);bin_start=20+jlen+8
normal=doc['meshes'][0]['primitives'][0]['attributes']['NORMAL']
access=doc['accessors'][normal];view=doc['bufferViews'][access['bufferView']]
offset=bin_start+view.get('byteOffset',0)+access.get('byteOffset',0)
values=struct.unpack_from('<fff',data,offset)
struct.pack_into('<fff',data,offset,*(-v for v in values))
(OUT/'bad_normal.glb').write_bytes(data)

data=bytearray((OUT/'good.glb').read_bytes())
position=doc['meshes'][0]['primitives'][0]['attributes']['POSITION']
access=doc['accessors'][position];view=doc['bufferViews'][access['bufferView']]
offset=bin_start+view.get('byteOffset',0)+access.get('byteOffset',0)
x=struct.unpack_from('<f',data,offset)[0]
struct.pack_into('<f',data,offset,x+.1)
(OUT/'bad_position.glb').write_bytes(data)

original=(OUT/'good.glb').read_bytes()
doc['materials'][0]['pbrMetallicRoughness']['baseColorFactor'][0]=.8
encoded=json.dumps(doc,separators=(',',':')).encode('utf-8')
encoded+=b' '*((-len(encoded))%4)
binary_chunk=original[20+jlen:]
(OUT/'bad_material.glb').write_bytes(struct.pack('<III',0x46546c67,2,20+len(encoded)+len(binary_chunk))+
                                    struct.pack('<II',len(encoded),0x4e4f534a)+encoded+binary_chunk)

# A detached two-part subassembly: local touching alone must not pass global connectivity.
for label,pos,scale in [('DetachedFoot',(2,0,.15),(.3,.3,.15)),('DetachedStrut',(2,0,.5),(.12,.12,.4))]:
    bpy.ops.mesh.primitive_cube_add(size=2,location=pos)
    part=bpy.context.object;part.name=label;part.scale=scale
    for c in list(part.users_collection):c.objects.unlink(part)
    col.objects.link(part);bpy.ops.object.transform_apply(location=False,rotation=True,scale=True)
    part.data.materials.append(mat)
for part in col.objects:part.location.x-=.85
bpy.ops.object.select_all(action='DESELECT')
for part in col.objects:part.select_set(True)
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'source_detached.blend'))
bpy.ops.export_scene.gltf(filepath=str(OUT/'detached.glb'),export_format='GLB',use_selection=True,export_animations=False,export_yup=True)
print('FIXTURES',str(OUT))

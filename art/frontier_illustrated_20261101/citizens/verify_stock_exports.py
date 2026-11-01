"""Fresh Blender GLB roundtrip of the final stock Kenney exports; no renders."""
from pathlib import Path
import json,sys,hashlib,struct
import bpy
from mathutils import Matrix
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
OUT=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
records=[]
for role in ['operator','pilot','mechanic','medic']:
 path=OUT/(role+'.glb')
 bpy.ops.wm.read_factory_settings(use_empty=True)
 bpy.ops.import_scene.gltf(filepath=str(path))
 rigs=[o for o in bpy.context.scene.objects if o.type=='ARMATURE']
 # Blender glTF importer may add an 80-triangle hidden bone-display widget.
 # Inspect the actual skinned runtime mesh, not that importer UI helper.
 meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
 for rig in rigs:
  if rig.animation_data:rig.animation_data.action=None
  for pb in rig.pose.bones:pb.matrix_basis=Matrix.Identity(4)
 bpy.context.view_layer.update()
 pts=[o.matrix_world@v.co for o in meshes for v in o.data.vertices]
 bounds={'min':[min(v[i] for v in pts) for i in range(3)],'max':[max(v[i] for v in pts) for i in range(3)]}
 raw=qa_check.run(objects=[o.name for o in meshes],profile='game',uv=True)
 data=path.read_bytes();n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n])
 clips=[]
 for a in g['animations']:
  times=[g['accessors'][s['input']] for s in a['samplers']]
  clips.append({'name':a['name'],'duration_seconds':max(t['max'][0] for t in times)-min(t['min'][0] for t in times)})
 rec={'role':role,'glb_sha256':hashlib.sha256(data).hexdigest(),'mesh_count':len(meshes),'rig_count':len(rigs),
  'triangles':sum(len(p.vertices)-2 for o in meshes for p in o.data.polygons),'bounds_blender_m':bounds,
  'bones':[b.name for r in rigs for b in r.data.bones],'clips':clips,'raw_qa':raw}
 print('ROUNDTRIP_MEASUREMENT',role,len(meshes),len(rigs),rec['triangles'],bounds,raw['errors'])
 assert len(meshes)==1 and len(rigs)==1 and rec['triangles']==1604
 assert abs(bounds['min'][2])<.0001 and abs(bounds['max'][2]-1.78)<.0001
 assert {a['name'] for a in clips}=={'idle','walk'} and raw['pass']
 records.append(rec)
 print('ROUNDTRIP_OK',role,rec['triangles'],bounds,clips)
(HERE/'qa/stock_roundtrip.json').write_text(json.dumps({'pass':True,'blender':bpy.app.version_string,'assets':records},indent=2),encoding='utf-8')

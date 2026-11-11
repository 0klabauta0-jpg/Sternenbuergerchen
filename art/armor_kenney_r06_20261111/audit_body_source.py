"""Read-only Blender provenance audit. Does not save/edit either model."""
import bpy,json,sys,hashlib
from pathlib import Path
ART=Path(__file__).resolve().parent;ROOT=ART.parents[1]
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import qa_check
def snapshot():
 body=next(o for o in bpy.data.objects if o.type=='MESH' and o.name.startswith('character'))
 rig=next(o for o in bpy.data.objects if o.type=='ARMATURE')
 faces=[]
 for face in body.data.polygons:
  corners=[(body.data.loops[i].vertex_index,tuple(tuple(layer.data[i].uv) for layer in body.data.uv_layers)) for i in face.loop_indices]
  faces.append(min(tuple(corners[n:]+corners[:n]) for n in range(len(corners))))
 return {
  'vertices':len(body.data.vertices),'triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
  'indices':[tuple(p.vertices) for p in body.data.polygons],
  'uv':[[tuple(d.uv) for d in layer.data] for layer in body.data.uv_layers],
  'oriented_faces_with_corner_uv':sorted(faces),
  'weights':[[tuple((g.group,round(g.weight,8))) for g in v.groups] for v in body.data.vertices],
  'vertex_groups':[g.name for g in body.vertex_groups],
  'bones':[(b.name,b.parent.name if b.parent else '',tuple(round(c,8) for row in b.matrix_local for c in row)) for b in rig.data.bones],
  'actions':sorted((a.name,tuple(a.frame_range)) for a in bpy.data.actions),
  'positions':[tuple(v.co) for v in body.data.vertices],
  'qa':qa_check.run(objects=[body.name],profile='game')}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02/operator.glb'))
original=snapshot()
bpy.ops.wm.open_mainfile(filepath=str(ART/'body_r06_editable.blend'))
derived=snapshot()
oa=set(original['oriented_faces_with_corner_uv']);da=set(derived['oriented_faces_with_corner_uv'])
print('FACE_DIFFERENCES',len(oa-da),len(da-oa),list(oa-da)[:3],list(da-oa)[:3])
print('UNORIENTED_EQUAL',set(tuple(sorted(face)) for face in oa)==set(tuple(sorted(face)) for face in da))
same={key:original[key]==derived[key] for key in ['vertices','triangles','oriented_faces_with_corner_uv','weights','vertex_groups','bones','actions']}
metrics={label:next(iter(data['qa']['objects'].values())) for label,data in [('original',original),('derived',derived)]}
result={'pass':all(same.values()),'unchanged':same,'action_count':len(original['actions']),'bone_count':len(original['bones']),
 'raw_loop_serialization_identical':{key:original[key]==derived[key] for key in ['indices','uv']},
 'original_qa_warnings':original['qa']['warnings'],'derived_qa_warnings':derived['qa']['warnings'],'metrics':metrics,
 'note':'Position changes are intentional. Oriented faces including each vertex-index/UV-corner pair are compared independent of cyclic start and face ordering. Raw index and UV loop arrays are also identical in the final source. No reversed face orientation is permitted by this comparison.'}
(ART/'body_source_audit.json').write_text(json.dumps(result,indent=2),encoding='utf8')
print('BODY_SOURCE_AUDIT',json.dumps(result))
if not result['pass']:raise RuntimeError('Unexpected body provenance change')

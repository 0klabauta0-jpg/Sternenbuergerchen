import bpy,json,sys,hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'caterpillar.blend'))
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check
names=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
report=qa_check.run(objects=names,profile='game',uv=False)
(OUT/'qa_raw.json').write_text(json.dumps(report,indent=2))
def stats():
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];points=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    for o in obs:o.data.calc_loop_triangles()
    return {'objects':len(obs),'triangles':sum(len(o.data.loop_triangles) for o in obs),'min':[min(v[i] for v in points) for i in range(3)],'max':[max(v[i] for v in points) for i in range(3)],'parts':{o.name:len(o.data.loop_triangles) for o in obs}}
source=stats()
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(OUT/'caterpillar.glb'))
bpy.context.view_layer.update();imported=stats()
assert imported['triangles']==source['triangles'],(source,imported)
assert imported['objects']==source['objects'],(source,imported)
for c in ['min','max']:
    assert max(abs(a-b) for a,b in zip(source[c],imported[c]))<.0001
actions=[a.name for a in bpy.data.actions]
assert actions,'No animation imported'
sc=bpy.context.scene;sc.frame_set(1);bpy.context.view_layer.update()
closed={o.name:[list(row) for row in o.matrix_world] for o in bpy.context.scene.objects if o.type=='MESH'}
sc.frame_set(48);bpy.context.view_layer.update()
opened={o.name:[list(row) for row in o.matrix_world] for o in bpy.context.scene.objects if o.type=='MESH'}
moving=[n for n in closed if closed[n]!=opened[n]]
assert 'ServiceLiftDeck' in moving,moving
assert all(f'CargoDoor_{s}_{i:02d}' in moving for s in ['L','R'] for i in range(1,5)),moving
assert 'Hull' not in moving,moving
metrics=json.loads((OUT/'metrics.json').read_text());path=Path(metrics['source']['file'])
assert hashlib.sha256(path.read_bytes()).hexdigest()==metrics['source']['sha256']
result={'source_blend':source,'fresh_glb':imported,'animations':actions,'moving_nodes':moving,'source_unchanged':True,'glb_sha256':hashlib.sha256((OUT/'caterpillar.glb').read_bytes()).hexdigest(),'blend_sha256':hashlib.sha256((OUT/'caterpillar.blend').read_bytes()).hexdigest(),'qa_pass':report['pass'],'qa_errors':report['errors'],'qa_warnings':report['warnings']}
(OUT/'verification.json').write_text(json.dumps(result,indent=2));print(json.dumps(result))

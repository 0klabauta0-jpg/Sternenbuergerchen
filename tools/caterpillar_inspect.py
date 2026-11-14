import bpy, json, sys, hashlib
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'art/ship_models_20261114/caterpillar'
OUT.mkdir(parents=True,exist_ok=True)
SOURCE=Path('C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE/DRAKE-CATERPILLAR.FBX')
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-core/scripts')
import env_report
print('ENV',env_report.run())
bpy.ops.object.select_all(action='SELECT');bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(SOURCE))
info={'file':str(SOURCE),'sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'objects':[]}
for o in bpy.context.scene.objects:
    row={'name':o.name,'type':o.type,'parent':o.parent.name if o.parent else None,'location':list(o.location),'scale':list(o.scale)}
    if o.type=='MESH':
        o.data.calc_loop_triangles()
        p=[o.matrix_world@Vector(v) for v in o.bound_box]
        row.update(vertices=len(o.data.vertices),triangles=len(o.data.loop_triangles),min=[min(v[i] for v in p) for i in range(3)],max=[max(v[i] for v in p) for i in range(3)],materials=[m.name for m in o.data.materials if m])
    info['objects'].append(row)
(OUT/'fbx_inspection.json').write_text(json.dumps(info,indent=2),encoding='utf8')
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'inspection.blend'))
print(json.dumps(info))

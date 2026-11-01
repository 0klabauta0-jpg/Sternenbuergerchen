from pathlib import Path
import bpy,json,sys
from mathutils import Matrix
HERE=Path(__file__).resolve().parents[1]
bpy.ops.wm.open_mainfile(filepath=str(HERE.parent/'operator_stock.blend'))
rig=bpy.data.objects['Root']; body=bpy.data.objects['characterMedium']
rig.animation_data.action=None
for b in rig.pose.bones:b.matrix_basis=Matrix.Identity(4)
bpy.context.view_layer.update()
record={'objects':[{'name':o.name,'type':o.type,'matrix':[list(x) for x in o.matrix_world]} for o in bpy.context.scene.objects], 'bones':[]}
for b in rig.data.bones:
    vg=body.vertex_groups.get(b.name)
    vs=[v.co for v in body.data.vertices if vg and any(g.group==vg.index and g.weight>.5 for g in v.groups)]
    record['bones'].append({'name':b.name,'head':list(b.head_local),'tail':list(b.tail_local),'parent':b.parent.name if b.parent else None,'count':len(vs),'bounds':{'min':[min(v[i] for v in vs) for i in range(3)],'max':[max(v[i] for v in vs) for i in range(3)]} if vs else None})
(HERE/'qa/stock_inspection.json').write_text(json.dumps(record,indent=2),encoding='utf-8')
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import review_shots
review_shots.run(objects=[body.name],out=str(HERE/'qa/stock_solid.png'),views=['front','right','back','three_quarter'],mode='solid',res=400)
print(json.dumps(record))

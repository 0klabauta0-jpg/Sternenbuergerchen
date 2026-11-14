import bpy,bmesh,json,sys
from pathlib import Path
from mathutils import Vector
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'inspection.blend'))
o=next(x for x in bpy.context.scene.objects if x.type=='MESH')
bpy.context.view_layer.objects.active=o;o.select_set(True)
bpy.ops.object.transform_apply(location=True,rotation=True,scale=True)
coords=[v.co for v in o.data.vertices];mn=Vector([min(p[i] for p in coords) for i in range(3)]);mx=Vector([max(p[i] for p in coords) for i in range(3)])
s=8/(mx.y-mn.y);center=Vector(((mn.x+mx.x)/2,(mn.y+mx.y)/2,mn.z))
for v in o.data.vertices:
    v.co=(v.co-center)*s;v.co.x=-v.co.x;v.co.y=-v.co.y
o.name='CaterpillarSource'
bm=bmesh.new();bm.from_mesh(o.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=0.00001)
bm.verts.ensure_lookup_table();bm.verts.index_update()
unseen=set(bm.verts);islands=[]
while unseen:
    first=next(iter(unseen));stack=[first];unseen.remove(first);vs=[]
    while stack:
        v=stack.pop();vs.append(v)
        for e in v.link_edges:
            w=e.other_vert(v)
            if w in unseen:unseen.remove(w);stack.append(w)
    faces=set(f for v in vs for f in v.link_faces)
    islands.append({'verts':len(vs),'faces':len(faces),'min':[min(v.co[i] for v in vs) for i in range(3)],'max':[max(v.co[i] for v in vs) for i in range(3)],'first_index':min(v.index for v in vs)})
islands.sort(key=lambda x:x['faces'],reverse=True)
(OUT/'islands.json').write_text(json.dumps(islands,indent=2))
bm.to_mesh(o.data);bm.free()
bpy.ops.wm.save_as_mainfile(filepath=str(OUT/'normalized_source.blend'))
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import review_shots
review_shots.run(objects=[o.name],out=str(OUT/'source_views.png'),views=['front','back','left','right','top','three_quarter'],mode='solid',res=900)
print('ISLANDS',len(islands),json.dumps(islands[:30]))

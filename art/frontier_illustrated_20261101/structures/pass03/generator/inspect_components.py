from pathlib import Path
import bpy,bmesh,json,sys,colorsys
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3]
rows=[]
for pack,name in [('factory','door'),('factory','crane'),('factory','crane-lift'),('space_station','wall'),('space_station','bed-single')]:
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(ROOT/'Assets/curated/kenney'/pack/'models'/(name+'.glb')),merge_vertices=True)
    for ob in [o for o in bpy.context.scene.objects if o.type=='MESH']:
        bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001);bm.verts.ensure_lookup_table();bm.faces.ensure_lookup_table()
        seen=set();islands=[]
        for v in bm.verts:
            if v in seen:continue
            work=[v];group=[]
            while work:
                a=work.pop()
                if a in seen:continue
                seen.add(a);group.append(a);work.extend(e.other_vert(a) for e in a.link_edges)
            faces={f for v in group for f in v.link_faces}
            lo=[min(v.co[i] for v in group) for i in range(3)];hi=[max(v.co[i] for v in group) for i in range(3)]
            islands.append({'verts':len(group),'faces':len(faces),'tris':sum(len(f.verts)-2 for f in faces),'local_bounds':[lo,hi],'closed':all(len(e.link_faces)==2 for v in group for e in v.link_edges)})
        bm.free()
        m=ob.data.materials[0];im=next(n.image for n in m.node_tree.nodes if n.type=='TEX_IMAGE');w,h=im.size;pixels=list(im.pixels);cols={}
        uv=ob.data.uv_layers.active
        for p in ob.data.polygons:
            u=sum(uv.data[i].uv.x for i in p.loop_indices)/len(p.loop_indices);v=sum(uv.data[i].uv.y for i in p.loop_indices)/len(p.loop_indices)
            x=min(w-1,max(0,int(u*w)));y=min(h-1,max(0,int(v*h)));rgb=tuple(round(c,4) for c in pixels[(y*w+x)*4:(y*w+x)*4+3]);cols[str(rgb)]=cols.get(str(rgb),0)+1
        rows.append({'pack':pack,'asset':name,'object':ob.name,'islands':islands,'face_colors':cols})
(HERE/'qa/kenney_sources/components.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
print(json.dumps(rows))

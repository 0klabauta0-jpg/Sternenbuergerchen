"""Read-only curated Kenney geometry/texture audit and viewed module previews."""
from pathlib import Path
import bpy,sys,json,hashlib
from mathutils import Vector
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa/kenney_sources'
sys.path.insert(0,str(HERE/'generator'))
import review_cutaways as review
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
SOURCES={'space_station':['wall','wall-window','wall-door','bed-single','table-display','computer','computer-wide','container-wide'],
         'factory':['door','door-wide-closed','detail-tank','crane','crane-lift']}
def audit(pack,name):
    p=ROOT/'Assets/curated/kenney'/pack/'models'/(name+'.glb')
    bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(p),merge_vertices=True)
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    lo=[min(v[i] for v in pts) for i in range(3)];hi=[max(v[i] for v in pts) for i in range(3)]
    data={'pack':pack,'asset':name,'path':str(p.relative_to(ROOT)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),
          'bounds_blender':{'min':lo,'max':hi},'dimensions':[hi[i]-lo[i] for i in range(3)],
          'objects':[{'name':o.name,'verts':len(o.data.vertices),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'matrix':[list(v) for v in o.matrix_world]} for o in obs],
          'materials':[]}
    for m in bpy.data.materials:
        data['materials'].append({'name':m.name,'images':[{'name':n.image.name,'path':n.image.filepath,'size':list(n.image.size)} for n in m.node_tree.nodes if n.type=='TEX_IMAGE' and n.image]})
    raw=qa_check.run(objects=[o.name for o in obs],profile='game',eps=.0003,tol=.006,uv=False);data['raw_qa']=raw
    sc,cam=review.setup();sc.display.shading.color_type='TEXTURE'
    for label,d in [('front',Vector((1,-1.5,1.1))),('top',Vector((0,-.001,1)))]:
        target,ortho=review.fitted_camera(obs,d,sc.render.resolution_x/sc.render.resolution_y)
        review.render(QA/(pack+'_'+name+'_'+label+'.png'),sc,cam,d,ortho,target)
    return data
if __name__=='__main__':
    rows=[audit(pack,n) for pack,names in SOURCES.items() for n in names]
    (QA/'inspection.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
    print('MODULE_INSPECTION '+json.dumps([{k:r[k] for k in ['pack','asset','dimensions','objects']} for r in rows]))

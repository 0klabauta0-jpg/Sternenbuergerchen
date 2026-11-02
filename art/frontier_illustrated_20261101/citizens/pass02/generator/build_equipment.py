"""Pass02 equipment candidates on the unchanged, normalized Kenney stock rig.

Blender 5.2.3 CLI: --python build_equipment.py -- [operator pilot mechanic medic]
No source Kenney files or Pass01 sources/exports are overwritten.
"""
from pathlib import Path
import bpy,bmesh,json,hashlib,struct,sys,math
from mathutils import Matrix,Vector

HERE=Path(__file__).resolve().parents[1]
ROOT=HERE.parents[3]
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens_pass02'
QA=HERE/'qa'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
ROLES=['operator','pilot','mechanic','medic']
PARTS=[];MATS={};RIG=None

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,data):Path(p).write_text(json.dumps(data,indent=2),encoding='utf-8')
def srgb(h):
    c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in c)+(1,)
def mat(name,color):
    m=bpy.data.materials.new('M_FrontierGear_'+name);m.diffuse_color=srgb(color)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=srgb(color);bs.inputs['Roughness'].default_value=.83
    return m
def signature(body):
    data={'vertices':[list(v.co) for v in body.data.vertices],
          'polygons':[list(p.vertices) for p in body.data.polygons],
          'weights':[[[body.vertex_groups[g.group].name,g.weight] for g in v.groups] for v in body.data.vertices],
          'uv':[[list(l.uv) for l in layer.data] for layer in body.data.uv_layers]}
    return hashlib.sha256(json.dumps(data,separators=(',',':')).encode()).hexdigest()
def mesh(name,vs,fs,material,bone,bevel=.01):
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(vs,[],fs);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);bpy.context.scene.collection.objects.link(ob)
    me.materials.append(MATS[material])
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    if bevel:
        md=ob.modifiers.new('Soft_illustrated_edges','BEVEL');md.width=bevel;md.segments=2;md.limit_method='ANGLE';md.harden_normals=True
        bpy.ops.object.modifier_apply(modifier=md.name)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    vg=ob.vertex_groups.new(name=bone);vg.add(list(range(len(me.vertices))),1,'REPLACE')
    md=ob.modifiers.new('Original_Kenney_skeleton','ARMATURE');md.object=RIG
    ob.parent=RIG;ob['equipment_module']=name;ob['rigid_bind_bone']=bone;ob['candidate']='ART pass02; not user-approved final art'
    PARTS.append(ob);return ob
def box(name,c,size,material,bone,bevel=.01):
    a,b,d=(v/2 for v in size);x,y,z=c
    vs=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],material,bone,min(bevel,min(size)*.2))
def profile(name,pts,y0,y1,material,bone,bevel=.009):
    n=len(pts);vs=[(x,y,z) for y in (y0,y1) for x,z in pts]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,material,bone,bevel)
def octagon(cx,z,w,h,c):
    x0,x1=cx-w/2,cx+w/2;z0,z1=z-h/2,z+h/2
    return [(x0+c,z0),(x1-c,z0),(x1,z0+c),(x1,z1-c),(x1-c,z1),(x0+c,z1),(x0,z1-c),(x0,z0+c)]
def equipment(role):
    chest='Orange' if role=='mechanic' else 'Ivory'
    shoulder='Orange' if role=='pilot' else 'Ivory'
    knee='Slate' if role=='mechanic' else 'Ivory'
    # One chamfered breastplate: broad silhouette, no tiny seams or bolts.
    profile('Gear_Breastplate',[(-.105,.915),(.105,.915),(.16,.975),(.16,1.135),(.112,1.185),(-.112,1.185),(-.16,1.135),(-.16,.975)],-.173,-.101,chest,'UpperChest',.009)
    box('Gear_ChestIdentifier',(0,-.182,1.112),(.105,.028,.038),'Ivory' if role=='mechanic' else 'Orange','UpperChest',.006)
    for side,sign in [('Left',1),('Right',-1)]:
        box('Gear_'+side+'Shoulder',(sign*.245,-.005,1.172),(.17,.19,.12),shoulder,side+'Arm',.017)
        profile('Gear_'+side+'Knee',octagon(sign*.13,.327,.132,.145,.028),-.103,-.036,knee,side+'Leg',.008)
    # Pack front embeds the stock back; separate rear lid is visibly supported.
    box('Gear_Backpack',(0,.157,1.002),(.264,.178,.31),'Slate','Chest',.026)
    box('Gear_BackpackLid',(0,.247,1.01),(.225,.045,.245),'Ivory' if role in ['operator','medic'] else 'Orange','Chest',.018)
    if role=='medic':
        box('Gear_MedicalKitMarkVertical',(0,.277,1.01),(.036,.025,.132),'Orange','Chest',.004)
        box('Gear_MedicalKitMarkHorizontal',(0,.281,1.01),(.118,.025,.034),'Orange','Chest',.004)
    elif role=='mechanic':
        # Stowed large tool cassette, no loose hand tool or arm-swing obstruction.
        box('Gear_ToolCassette',(0,.289,.948),(.184,.065,.085),'Slate','Chest',.012)
    elif role=='pilot':
        # Open headset: original face, hair and height remain visible.
        for side,sign in [('Left',1),('Right',-1)]:
            box('Gear_'+side+'HeadsetCup',(sign*.211,.026,1.51),(.06,.17,.196),'Slate','Head',.018)
            box('Gear_'+side+'HeadsetCover',(sign*.244,.026,1.51),(.028,.128,.143),'Ivory','Head',.008)
        box('Gear_HeadsetRearBridge',(0,.226,1.555),(.372,.075,.073),'Slate','Head',.015)

def set_pose(rig,clip=None,frame=0):
    rig.animation_data.action=None
    for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
    if clip:
        a=bpy.data.actions[clip];rig.animation_data.action=a;rig.animation_data.action_slot=next(iter(a.slots))
    bpy.context.scene.frame_set(frame);bpy.context.view_layer.update()
def mesh_stats(obs):
    pts=[];tris=0;verts=0
    dg=bpy.context.evaluated_depsgraph_get()
    for ob in obs:
        ev=ob.evaluated_get(dg);me=ev.to_mesh()
        pts.extend(ob.matrix_world@v.co for v in me.vertices);verts+=len(me.vertices);tris+=sum(len(p.vertices)-2 for p in me.polygons);ev.to_mesh_clear()
    lo=[min(v[i] for v in pts) for i in range(3)];hi=[max(v[i] for v in pts) for i in range(3)]
    return {'vertices':verts,'triangles':tris,'bounds_blender_m':{'min':lo,'max':hi},'dimensions_blender_m':[hi[i]-lo[i] for i in range(3)]}
def check_binding(parts,rig):
    errors=[]
    for ob in parts:
        bone=ob['rigid_bind_bone']
        if not rig.data.bones[bone].use_deform:errors.append(ob.name+': non-deform target')
        for v in ob.data.vertices:
            ws=[(ob.vertex_groups[g.group].name,g.weight) for g in v.groups if g.weight>1e-8]
            if ws!=[(bone,1.0)]:errors.append(ob.name+': vertex not rigidly weighted')
    return {'pass':not errors,'errors':errors,'modules':[{'name':o.name,'bone':o['rigid_bind_bone'],'vertices':len(o.data.vertices),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons)} for o in parts]}

def build(role):
    global RIG,PARTS,MATS
    stock=HERE.parent/(role+'_stock.blend');old_export=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens'/(role+'.glb')
    bpy.ops.wm.open_mainfile(filepath=str(stock));RIG=bpy.data.objects['Root'];body=bpy.data.objects['characterMedium'];PARTS=[]
    set_pose(RIG);body_sig=signature(body)
    MATS={key:mat(key,color) for key,color in [('Ivory','e4dfd1'),('Slate','3e5358'),('Orange','cf7c34')]}
    equipment(role);obs=[body]+PARTS
    assert signature(body)==body_sig
    binding=check_binding(PARTS,RIG);assert binding['pass']
    raw=qa_check.run(objects=[o.name for o in obs],profile='game',eps=.0003,tol=.004,uv=False)
    body_uv=qa_check.run(objects=[body.name],profile='game',eps=.0003,tol=.004,uv=True)
    dump(QA/(role+'_qa_raw.json'),raw);dump(QA/(role+'_body_uv_raw.json'),body_uv)
    dump(QA/(role+'_binding.json'),binding)
    stats=mesh_stats(obs)
    bpy.context.scene.render.fps=30;bpy.context.scene.frame_start=0;bpy.context.scene.frame_end=32
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    # Self-contained editable sources; embedded PNG bytes remain the Kenney skin.
    for m in body.data.materials:
        for node in m.node_tree.nodes:
            if node.type=='TEX_IMAGE' and node.image and not node.image.packed_file:node.image.pack()
    blend=HERE/'source'/(role+'_equipment.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
    # Collapse only the new equipment on an export copy; the original body stays
    # separate with its untouched UVs, weights and topology. All share Root.
    bpy.ops.object.select_all(action='DESELECT')
    for ob in PARTS:ob.select_set(True)
    bpy.context.view_layer.objects.active=PARTS[0];bpy.ops.object.join();gear=bpy.context.object;gear.name='Gear_Modular'
    bpy.ops.object.select_all(action='DESELECT')
    for ob in [RIG,body,gear]:ob.select_set(True)
    bpy.context.view_layer.objects.active=RIG
    target=EXPORT/(role+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,
        export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True,
        export_def_bones=True,export_all_influences=False,export_materials='EXPORT')
    buf=target.read_bytes();n=struct.unpack_from('<I',buf,12)[0];g=json.loads(buf[20:20+n])
    record={'role':role,'status':'separate equipment candidate; no user visual approval inferred',
        'source_bundle':'Kenney Animated Characters Bundle 4.0','license':'CC0; new equipment original procedural work',
        'stock_blend':str(stock.relative_to(ROOT)),'stock_blend_sha256':sha(stock),'stock_glb':str(old_export.relative_to(ROOT)),'stock_glb_sha256':sha(old_export),
        'body_geometry_uv_weight_signature_before':body_sig,'body_geometry_uv_weight_signature_after':signature(body),
        'body_vertices':len(body.data.vertices),'body_triangles':sum(len(p.vertices)-2 for p in body.data.polygons),
        'source_blend':str(blend.relative_to(ROOT)),'source_blend_sha256':sha(blend),'glb':str(target.relative_to(ROOT)),'glb_sha256':sha(target),
        'rig':'original Root; no new bones; rigid equipment groups on existing deform bones','bone_count_source':len(RIG.data.bones),
        'equipment_binding':binding,'stats_rest':stats,'mesh_count_glb':len(g.get('meshes',[])),'skin_count_glb':len(g.get('skins',[])),
        'material_count_glb':len(g.get('materials',[])),'embedded_images':len(g.get('images',[])),
        'animations':[a['name'] for a in g.get('animations',[])],
        'coordinates':'metres; rest height 1.78; feet Z0; Blender -Y front / Z up -> Godot +Z front / Y up; existing runtime scale 0.35',
        'raw_qa_pass':raw['pass'],'body_uv_qa_pass':body_uv['pass'],'errors':raw['errors'],'warnings':raw['warnings'],
        'qa_scope':'Full new assembled geometry at rest; original body UV separately. New constant-color gear intentionally has no UVs. No expensive-check skips.',
        'references':['docs/reports/assets/grafik-2026-11-01/02_menschen_stilstudie.png','docs/reports/assets/grafik-2026-11-01/references/current/01_rostgrenze_cutaway.png','docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png','docs/reports/assets/grafik-2026-11-01/references/current/03_taktische_rostwelt_gesamtkarte.png']}
    dump(QA/(role+'_manifest.json'),record)
    print('EQUIPMENT_RESULT '+json.dumps(record));return record

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ROLES
    chosen=args or ROLES
    for r in chosen:
        if r not in ROLES:raise ValueError(r)
        build(r)

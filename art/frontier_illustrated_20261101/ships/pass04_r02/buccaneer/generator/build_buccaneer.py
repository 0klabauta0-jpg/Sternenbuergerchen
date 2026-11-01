"""Two separate Buccaneer shape/look iterations; original Pass04 source untouched."""
from pathlib import Path
import sys, json, math, hashlib, struct
import bpy, bmesh
from mathutils import Vector, Matrix

HERE=Path(__file__).resolve().parents[1]
ROOT=HERE.parents[4]
OLD=ROOT/'art/frontier_illustrated_20261101/ships/pass04'
sys.path.insert(0,str(OLD/'generator'))
import build_ships as b
ORIGINAL_MESH=b.mesh
ITERATION=1
PALETTE={'Ivory':'ddd0af','Petrol':'53696b','Frame':'27383c','Steel':'8a8d80',
         'Ochre':'d39843','Glass':'2c4651','WarmCore':'a56e38','GlassWarm':'554b3e',
         'UsedIvory':'bcb69e','UsedPetrol':'667776'}

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return Path(p).relative_to(ROOT).as_posix()
def dump(p,d):Path(p).write_text(json.dumps(d,indent=2),encoding='utf-8')

def mesh(name,vs,fs,material='Petrol',face_materials=None,bevel=0):
    ob=ORIGINAL_MESH(name,vs,fs,material,face_materials,0)
    if bevel:
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        md=ob.modifiers.new('Broad_two_step_bevel','BEVEL');md.width=bevel;md.segments=2 if ITERATION==1 else 3
        md.limit_method='ANGLE';md.use_clamp_overlap=True
        bpy.ops.object.modifier_apply(modifier=md.name)
        bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
    return ob
b.mesh=mesh

def lathe(name,cx,cz,profile,materials,segments=40,angle_paint=None):
    """Closed section in y/r revolved around Y; genuine hollow lips/throats."""
    vs=[(cx+r*math.cos(i*math.tau/segments),y,cz+r*math.sin(i*math.tau/segments)) for y,r in profile for i in range(segments)]
    fs=[];mats=[]
    for j in range(len(profile)):
        nj=(j+1)%len(profile)
        for i in range(segments):
            fs.append((j*segments+i,j*segments+(i+1)%segments,nj*segments+(i+1)%segments,nj*segments+i))
            mats.append(angle_paint(j,i,segments) if angle_paint else materials[j])
    ob=mesh(name,vs,fs,face_materials=mats)
    return ob

def cowl(name,cx,cz,side):
    # Top/side armor is a partial curved shell; lower engine remains exposed.
    segments=24;angles=[math.radians(-25+i*230/segments) for i in range(segments+1)]
    sections=[(-1.33,1.13),(-1.08,1.25),(-.68,1.30),(1.78,1.25),(2.15,1.16)]
    if ITERATION==2:
        sections=[(-1.33,1.13),(-1.05,1.27),(-.58,1.34),(.25,1.30),(.48,1.17),(.68,1.17),(.92,1.31),(1.58,1.28),(2.15,1.16)]
    vs=[]
    for inner in [False,True]:
        for j,(y,r) in enumerate(sections):
            for i,a in enumerate(angles):
                # Broad broken rear shoulders rather than identical ring bands.
                yy=y
                if j==len(sections)-1:yy-=.34 if i in range(8,16) else .04
                if j==0:yy+=.20 if i in range(7,16) else 0
                rr=r-(.115 if inner else 0)
                vs.append((cx+rr*math.cos(a),yy,cz+rr*math.sin(a)))
    n=segments+1;layer=len(sections)*n;fs=[];mats=[]
    for inner in [0,1]:
        for j in range(len(sections)-1):
            for i in range(segments):
                a=inner*layer+j*n+i
                fs.append((a,a+1,a+1+n,a+n))
                mat='Frame' if inner else 'Ivory'
                if not inner and ITERATION==2 and j in [3,4]:mat='Frame'
                if not inner and ITERATION==2 and ((side=='L' and j==2 and i in range(3,7)) or (side=='R' and j==1 and i in range(16,20))):mat='UsedIvory'
                mats.append(mat)
    for j in [0,len(sections)-1]:
        for i in range(segments):
            a=j*n+i;fs.append((a,a+1,a+1+layer,a+layer));mats.append('Frame' if j==len(sections)-1 else 'Ivory')
    for i in [0,segments]:
        for j in range(len(sections)-1):
            a=j*n+i;fs.append((a,a+n,a+n+layer,a+layer));mats.append('Frame')
    return mesh(name,vs,fs,face_materials=mats)

def recessed_canopy(sections):
    rings=[b.ring8(w,z0,z1) for y,w,z0,z1 in sections];n=8
    vs=[(x,sections[j][0],z) for j,r in enumerate(rings) for x,z in r]
    fs=[tuple(range(n-1,-1,-1))];mats=['Frame']
    for j in range(len(sections)-1):
        for i in range(n):
            quad=[j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i]
            if j not in [1,3] or i not in [2,3,4,5,6,7]:
                fs.append(tuple(quad));mats.append('Ivory');continue
            corners=[Vector(vs[k]) for k in quad];center=sum(corners,Vector())/4
            normal=(corners[1]-corners[0]).cross(corners[2]-corners[0]).normalized()
            # Determine outward radial direction for actual 5cm recessed glazing.
            if normal.dot(Vector((center.x,0,center.z-2.2)))<0:normal=-normal
            inset=[center+(v-center)*.94 for v in corners];ring=len(vs)
            vs.extend(tuple(v) for v in inset);inside=len(vs);vs.extend(tuple(v-normal*.052) for v in inset)
            for k in range(4):
                nk=(k+1)%4;fs.append((quad[k],quad[nk],ring+nk,ring+k));mats.append('Ivory')
                fs.append((ring+k,ring+nk,inside+nk,inside+k));mats.append('Frame')
            fs.append(tuple(inside+k for k in range(4)));mats.append('Glass' if i in [4,5] else 'GlassWarm')
    fs.append(tuple(range((len(sections)-1)*n,len(sections)*n)));mats.append('Ivory')
    return mesh('Canopy_Armored_Frame',vs,fs,face_materials=mats)

def wing_position(s,u,v):
    x=s*(3.61+2.75*u-.23*v*u)
    front=-.42+1.98*u;rear=2.68+1.15*u
    return x,front+(rear-front)*v,2.31+.16*math.sin(math.pi*v)-.08*u

def integrated_wing(side,s):
    # A thick shaped airfoil surface: color belongs to its own polygons.
    us=[0,.18,.36,.68,1];vs_grid=[0,.16,.80,1];points=[]
    for bottom in [False,True]:
        for u in us:
            for v in vs_grid:
                x,y,z=wing_position(s,u,v);points.append((x,y,2.02-.03*u if bottom else z))
    rows=len(us);cols=len(vs_grid);layer=rows*cols;faces=[];colors=[]
    for j in range(rows-1):
        for k in range(cols-1):
            q=(j*cols+k,(j+1)*cols+k,(j+1)*cols+k+1,j*cols+k+1)
            faces.append(q)
            color='Ivory' if j>=2 and k==1 else 'Ochre' if j==1 else 'Petrol'
            if side=='R' and j==3 and k==1:color='UsedIvory'
            colors.append(color);faces.append(tuple(layer+a for a in reversed(q)));colors.append('Frame')
    border=[j*cols for j in range(rows)]+[(rows-1)*cols+k for k in range(1,cols)]+[j*cols+cols-1 for j in range(rows-2,-1,-1)]+[k for k in range(cols-2,0,-1)]
    for a,c in zip(border,border[1:]+border[:1]):faces.append((a,c,c+layer,a+layer));colors.append('Petrol')
    return mesh('Swept_Integrated_Airfoil_'+side,points,faces,face_materials=colors,bevel=.035)

def pod(side,s):
    b.group('Buccaneer_stepped_engine_'+side);cx=s*2.75;cz=2.73
    # Dark continuous engine core with visibly different axial volumes.
    rear_core=(3.52,.75) if ITERATION==2 else (4.18,.86)
    b.barrel('Pod_Core_'+side,cx,cz,[(-2.02,1.18),(-1.52,1.10),(-.86,1.12),(.82,1.11),(2.12,1.08),(2.42,.95),(3.42,.94),rear_core],40,
        lambda j,i:'Frame' if j in [1,4] else 'Petrol')
    # Thick rounded intake housing and deep stepped inner bore (not a painted disk).
    profile=[(-3.13,1.08),(-3.09,1.22),(-2.94,1.38),(-2.68,1.46),(-2.34,1.45),(-2.08,1.31),(-1.89,1.16),
             (-1.89,.86),(-2.02,.86),(-2.80,.93),(-3.04,.98)]
    def intake_paint(j,i,n):
        if j in [3,4]:return 'Ochre'
        if j in [0,8,9,10]:return 'Frame'
        if ITERATION==2 and j==2 and i in range(23,28):return 'UsedPetrol'
        return 'Petrol'
    lathe('Shaped_Intake_'+side,cx,cz,profile,[],48,intake_paint)
    lathe('Deep_Inlet_Bore_'+side,cx,cz,[(-2.78,.76),(-2.67,.80),(-2.03,.78),(-1.96,.64),(-2.68,.63)],['Steel','Frame','Frame','Frame','Frame'],40)
    cowl('Broken_Ivory_Cowl_'+side,cx,cz,side)
    # Armor strap leaves a broad black technical neck visible behind the cowl.
    lathe('Aft_Collar_'+side,cx,cz,[(2.25,1.03),(2.31,1.17),(2.50,1.17),(2.60,1.05),(2.60,.94),(2.25,.94)],['Frame','Ochre','Frame','Frame','Frame','Frame'],40)
    for ss in [-1,1]:
        shoulder=[(-.70,.17,3.78,4.01),(1.64,.19,3.72,3.98),(2.14,.12,3.70,3.88)]
        if ITERATION==2:shoulder=[(-.84,.18,3.80,4.05),(-.04,.20,3.79,4.04),(.24,.12,3.75,3.92)]
        ob=b.loft('Cowl_Shoulder_'+side+str(ss),shoulder,'Petrol')
        ob.data.transform(Matrix.Translation((cx+ss*.69,0,0)))
    # Rear cowl tapers into a deep warm throat; large few thick petals frame it.
    lathe('Rear_Bell_'+side,cx,cz,[(3.05,.95),(3.38,1.04),(3.98,1.03),(4.42,.97),(4.69,.94),
          (4.74,.79),(4.60,.74),(3.72,.68),(3.53,.75)],['Petrol','Petrol','Frame','Ochre','Steel','Steel','Frame','WarmCore','Frame'],40)
    b.disc('Rear_Core_Dark_'+side,cx,cz,3.61,3.69,.69,'Frame')
    lathe('Recess_Warm_Ring_'+side,cx,cz,[(3.76,.68),(3.85,.68),(3.85,.41),(3.76,.41)],['WarmCore']*4,32)
    for j in range(6):
        a=j*math.tau/6;vs=[]
        for y,rin,rout,w in [(3.92,1.00,1.22,.28),(4.98,.92,1.10,.23)]:
            for theta,r in [(a-w,rin),(a+w,rin),(a+w,rout),(a-w,rout)]:vs.append((cx+r*math.cos(theta),y,cz+r*math.sin(theta)))
        mesh('Rear_Thick_Petal_'+side+str(j),vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'Petrol',bevel=.045)
    # One lower service block and one top broad clamp; no greeble spray.
    b.box('Lower_Service_'+side,(cx,-.1,1.63),(.84,2.04,.38),'Frame',.07)
    b.box('Top_Cowl_Clamp_'+side,(cx,.35,4.03),(.36,.34,.16),'Ochre',.05)

def build():
    b.group('Buccaneer_compact_spine')
    b.loft('Compact_Fuselage',[(-5.05,.36,1.35,1.89),(-4.20,.72,1.22,2.35),(-2.80,1.00,1.19,3.03),(-1.50,1.02,1.14,3.18),
        (.75,.86,1.18,3.11),(3.65,1.00,1.34,2.87),(4.47,.82,1.43,2.65)],'Petrol',paint=lambda j,i:'Ivory' if i in [4] and j>2 else 'Petrol')
    b.group('Buccaneer_short_broad_canopy')
    # Cream armored rim with large uninterrupted glazing; shortened blunt wedge.
    cs=[(-5.12,.37,1.43,1.94),(-4.94,.49,1.41,2.16),(-4.12,.79,1.36,2.69),(-3.94,.83,1.37,2.79),
        (-2.61,.96,1.52,3.29),(-2.43,.96,1.56,3.34),(-1.97,.89,1.78,3.30)]
    if ITERATION==2:recessed_canopy(cs)
    else:b.loft('Canopy_Armored_Frame',cs,'Ivory',paint=lambda j,i:('GlassWarm' if i in [2,3,6,7] and j in [1,3] else 'Glass' if i in [4,5] and j in [1,3] else 'Ivory'))
    b.box('Canopy_Chin',(0,-4.04,1.40),(1.10,1.55,.27),'Frame',.08)
    for side,s in [('L',-1),('R',1)]:
        b.group('Buccaneer_pylon_'+side)
        b.slab_xy('Wide_Swept_InnerPylon_'+side,[(s*.63,-2.15),(s*2.97,-1.23),(s*3.14,2.93),(s*.65,3.92)],1.93,2.37,'Petrol',.065)
        ob=b.loft('Pylon_Arched_Shoulder_'+side,[(-2.25,.23,2.22,2.60),(-.95,.60,2.15,3.03),(1.82,.55,2.17,3.10),(3.68,.34,2.22,2.83)],'Petrol')
        ob.data.transform(Matrix.Translation((s*1.47,0,0)))
        b.slab_xy('Pylon_Ivory_Inset_'+side,[(s*.94,-.68),(s*1.68,-.35),(s*1.74,2.73),(s*.97,3.14)],2.89,3.06,'Ivory',.06)
        pod(side,s)
        b.group('Buccaneer_swept_wing_'+side)
        outline=[(s*3.65,-.42),(s*4.20,-.16),(s*6.36,1.56),(s*6.13,3.83),(s*4.48,3.17),(s*3.61,2.68)]
        if ITERATION==2:integrated_wing(side,s)
        else:
            b.slab_xy('Swept_Thick_Wing_'+side,outline,2.02,2.29,'Petrol',.07)
            b.slab_xy('Swept_Ivory_Wing_Panel_'+side,[(s*4.39,.36),(s*6.16,1.73),(s*5.98,3.55),(s*4.34,2.95)],2.265,2.35,'Ivory',.045)
            b.slab_xy('Wing_Swept_Leading_Spar_'+side,[(s*3.78,-.34),(s*4.08,-.29),(s*6.28,1.47),(s*6.25,1.68)],2.31,2.41,'Petrol',.03)
            b.slab_xy('Wing_Root_Amber_'+side,[(s*4.05,.09),(s*4.34,.31),(s*4.31,2.93),(s*4.04,2.80)],2.27,2.36,'Ochre',.025)
    b.group('Buccaneer_large_dorsal_cannon')
    b.box('Cannon_Carriage',(0,.85,3.12),(1.18,2.34,.37),'Frame',.08)
    b.loft('Large_Cannon_Receiver',[(-.67,.43,3.23,3.89),(-.25,.57,3.22,4.02),(1.93,.52,3.20,3.95),(2.38,.35,3.18,3.74)],'Petrol',paint=lambda j,i:'Ochre' if i==4 and j==1 else 'Petrol')
    b.bar('Cannon_Barrel',(0,-3.03,3.68),(0,-.22,3.68),.19,'Steel',16)
    lathe('Cannon_Muzzle',0,3.68,[(-3.16,.24),(-2.81,.24),(-2.81,.13),(-3.16,.13)],['Frame']*4,16)
    b.box('Cannon_Receiver_Side',(0,1.52,3.51),(1.16,.57,.33),'UsedPetrol' if ITERATION==2 else 'Petrol',.07)
    b.group('Buccaneer_aft_blocks')
    for s in [-1,1]:
        b.slab_yz('Aft_Keel_'+str(s),[(2.94,1.35),(4.91,1.24),(4.78,2.02),(3.10,2.60)],s*.70-.11,s*.70+.11,'Frame',.04)
        b.box('Aft_Armor_'+str(s),(s*.66,3.71,2.80),(.38,1.28,.20),'Ivory',.05)
    if ITERATION==2:
        b.group('Buccaneer_selected_panel_connections')
        for s in [-1,1]:
            # Only eight large fastener heads total, attached to visible structural panels.
            for x,y,z in [wing_position(s,.52,.35),wing_position(s,.80,.77),(s*.71,2.99,2.91),(s*.72,-1.42,3.20)]:
                location=Vector((x,y,z));normal=Vector((0,0,1))
                if abs(x)>4:
                    wing=next(ob for ob in b.PARTS if ob.name=='Swept_Integrated_Airfoil_'+('L' if s<0 else 'R'))
                    hit,location,normal,index=wing.ray_cast(Vector((x,y,6)),Vector((0,0,-1)))
                    assert hit
                b.bar('Flush_Panel_Fastener_'+str(s)+'_'+str(y),location-normal*.026,location+normal*.028,.058,'Steel',8)
    b.group('Buccaneer_static_display_feet')
    b.gear('Nose_Foot',0,-3.33,1.44,.68)
    for s in [-1,1]:b.gear('Pod_Foot_'+str(s),s*2.67,1.77,1.58,.78)

def export(path):
    vs=[];fs=[];mids=[];smooth=[];normals=[];keys=list(b.MATS)
    for ob in b.PARTS:
        offset=len(vs);vs.extend(tuple(ob.matrix_world@v.co) for v in ob.data.vertices)
        normal_matrix=ob.matrix_world.to_3x3().inverted().transposed()
        for p in ob.data.polygons:
            fs.append(tuple(offset+i for i in p.vertices));mids.append(keys.index(next(k for k,m in b.MATS.items() if m==ob.data.materials[p.material_index])))
            smooth.append(p.use_smooth)
            normals.extend(tuple((normal_matrix@ob.data.corner_normals[i].vector).normalized()) for i in p.loop_indices)
    me=bpy.data.meshes.new('buccaneer_01_Mesh');me.from_pydata(vs,[],fs);me.update()
    for m in b.MATS.values():me.materials.append(m)
    for p,mi,sm in zip(me.polygons,mids,smooth):p.material_index=mi;p.use_smooth=sm
    me.normals_split_custom_set(normals)
    ob=bpy.data.objects.new('buccaneer_01',me);bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_lights=False,export_cameras=False)
    data=path.read_bytes();n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n])
    rec={'path':rel(path),'sha256':sha(path),'bytes':len(data),'meshes':len(g['meshes']),'materials':len(g['materials']),
         'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),
         'nodes':len(g['nodes']),'animations':len(g.get('animations',[])),'skins':len(g.get('skins',[]))}
    bpy.data.objects.remove(ob,do_unlink=True);return rec

def main():
    global ITERATION
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['1'];ITERATION=int(args[0])
    out=HERE/'iterations'/('i0'+str(ITERATION));qa=out/'qa';source=out/'source'
    for p in [qa,source]:p.mkdir(parents=True,exist_ok=True)
    b.PALETTE=PALETTE;b.reset();build();lo,hi=b.bounds(b.PARTS);factor=11/(hi.y-lo.y);offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for ob in b.PARTS:
        ob.data.transform(Matrix.Scale(factor,4)@Matrix.Translation(-offset))
        if any(key in ob.name for key in ['Pod_Core','Shaped_Intake','Deep_Inlet','Broken_Ivory','Aft_Collar','Rear_Bell','Recess_Warm']):
            bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
            bpy.ops.object.shade_smooth_by_angle(angle=math.radians(28))
    lo,hi=b.bounds(b.PARTS);tris=sum(len(p.vertices)-2 for ob in b.PARTS for p in ob.data.polygons);assert tris<20000
    raw=b.qa_check.run(objects=[o.name for o in b.PARTS],profile='game',uv=False,eps=.0003,tol=.008);dump(qa/'buccaneer_01_raw.json',raw)
    path=source/'buccaneer_01.blend';bpy.ops.wm.save_as_mainfile(filepath=str(path));glb=export(out/'buccaneer_01.glb');assert glb['materials']<=10
    rec={'asset':'buccaneer_01','iteration':ITERATION,'status':'unapproved revised visual candidate','source':rel(path),'source_sha256':sha(path),'export':glb,
         'triangles':tris,'editable_parts':len(b.PARTS),'vertices':sum(len(ob.data.vertices) for ob in b.PARTS),'dimensions_blender_m':list(hi-lo),
         'bounds_blender_m':{'min':list(lo),'max':list(hi)},'normalization_length_m':11,'normalization_uniform_factor':factor,
         'scale_status':'stylized display normalization, not canonical SC size','front_blender':'-Y','front_godot':'+Z','runtime_scale_suggested':.22,
         'pivot':'full BBox XY center / static feet minZ0','palette':PALETTE,'no_emission':True,'qa_pass':raw['pass'],'qa_errors':raw['errors'],'qa_warnings':raw['warnings'],
         'reference_images':[{'path':'docs/reports/assets/grafik-2026-11-01/'+f,'sha256':sha(ROOT/'docs/reports/assets/grafik-2026-11-01'/f)} for f in b.REFS['buccaneer_01']],
         'retained_r01':{'generator':rel(OLD/'generator/build_ships.py'),'generator_sha256':sha(OLD/'generator/build_ships.py'),'source':rel(OLD/'source/buccaneer_01.blend'),'source_sha256':sha(OLD/'source/buccaneer_01.blend')},
         'scope':'original new geometry using prior procedural helpers; no imported Kenney/SC mesh; source QA covers entire assembly without expensive-check skips; UV excluded for solid palette',
         'changes':'segmented tapered pods/partial curved cowl, dark hollow intakes, deep large exhausts and six thick petals, shorter broad framed canopy, thick swept wings, large dorsal receiver/cannon; iteration2 adds broad bevels/panel fields/eight fastener heads'}
    dump(qa/'buccaneer_01_manifest.json',rec);print('BUCC_BUILD '+json.dumps(rec))

if __name__=='__main__':main()

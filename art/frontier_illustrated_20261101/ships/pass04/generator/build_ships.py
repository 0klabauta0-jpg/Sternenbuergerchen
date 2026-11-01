"""New simplified Drake silhouettes from the assigned two-view illustrations.

No OBJ/old material-study mesh is imported, decimated, recolored or relabeled.
Source lengths16/11m are display normalization, not canonical Star Citizen size.
Blender5.2.3 CLI -b --factory-startup --python-exit-code1 -P build_ships.py
"""
from pathlib import Path
import bpy,bmesh,math,sys,json,hashlib,struct
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[5]
ART=ROOT/'art/frontier_illustrated_20261101/ships/pass04'
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04'
QA=ART/'qa'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
MATS={};PARTS=[];GROUP='Hull'
PALETTE={'Ivory':'e4dccb','Petrol':'4c6870','Frame':'2d3e43','Steel':'8b9693','Ochre':'d99b45','Glass':'2d4a59','WarmCore':'a66a36','GlassWarm':'674f3c'}
REFS={'cutlass_01':['08_cutlass_vorne_wimmel.png','09_cutlass_hinten_wimmel.png'],
      'buccaneer_01':['13_buccaneer_vorne_wimmel_vereinfacht.png','11_buccaneer_hinten_wimmel.png']}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,d):Path(p).write_text(json.dumps(d,indent=2),encoding='utf-8')
def srgb(h):
    c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in c)+(1,)
def reset():
    global MATS,PARTS,GROUP
    bpy.ops.wm.read_factory_settings(use_empty=True);PARTS=[];MATS={};GROUP='Hull'
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    for key,col in PALETTE.items():
        m=bpy.data.materials.new('M_Drake04_'+key);m.diffuse_color=srgb(col)
        bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value=srgb(col);bs.inputs['Roughness'].default_value=.82 if key not in ['Glass','GlassWarm'] else .32
        bs.inputs['Metallic'].default_value=.08 if key=='Steel' else 0
        MATS[key]=m
def group(name):
    global GROUP
    GROUP=name
def mesh(name,vs,fs,material='Petrol',face_materials=None,bevel=0):
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(vs,[],fs);me.update();keys=list(MATS)
    for m in MATS.values():me.materials.append(m)
    for i,p in enumerate(me.polygons):p.material_index=keys.index(face_materials[i] if face_materials else material)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);co=bpy.data.collections.get(GROUP)
    if not co:co=bpy.data.collections.new(GROUP);bpy.context.scene.collection.children.link(co)
    co.objects.link(ob);ob['ship_assembly']=GROUP
    if bevel:
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        md=ob.modifiers.new('Quiet_beveled_edges','BEVEL');md.width=bevel;md.segments=1;md.limit_method='ANGLE';md.harden_normals=True
        bpy.ops.object.modifier_apply(modifier=md.name)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    PARTS.append(ob);return ob
def box(name,c,size,mat='Petrol',bevel=.03):
    x,y,z=c;a,b,d=(v/2 for v in size)
    vs=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,bevel=min(bevel,min(size)*.18))
def slab_xy(name,xy,z0,z1,mat='Petrol',bevel=.025):
    n=len(xy);vs=[(x,y,z) for z in (z0,z1) for x,y in xy]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel=bevel)
def slab_yz(name,yz,x0,x1,mat='Petrol',bevel=.025):
    n=len(yz);vs=[(x,y,z) for x in (x0,x1) for y,z in yz]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel=bevel)
def slab_xz(name,xz,y0,y1,mat='Petrol',bevel=.025):
    n=len(xz);vs=[(x,y,z) for y in (y0,y1) for x,z in xz]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel=bevel)
def ring8(hw,zb,zt):
    h=zt-zb
    return [(-hw*.78,zb),(hw*.78,zb),(hw,zb+h*.18),(hw,zt-h*.20),(hw*.70,zt),(-hw*.70,zt),(-hw,zt-h*.20),(-hw,zb+h*.18)]
def ring10(hw,zb,zt):
    h=zt-zb;spine=.78
    return [(-hw*.78,zb),(hw*.78,zb),(hw,zb+h*.18),(hw,zt-h*.20),(hw*.72,zt),(spine,zt),(-spine,zt),(-hw*.72,zt),(-hw,zt-h*.20),(-hw,zb+h*.18)]
def loft(name,sections,mat='Petrol',spine=False,paint=None):
    rings=[ring10(w,a,b) if spine else ring8(w,a,b) for y,w,a,b in sections];n=len(rings[0])
    vs=[(x,sections[j][0],z) for j,ring in enumerate(rings) for x,z in ring];fs=[];mats=[]
    fs.append(tuple(range(n-1,-1,-1)));mats.append('Frame' if 'Canopy' in name else mat)
    for j in range(len(rings)-1):
        for i in range(n):
            fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
            mats.append(paint(j,i) if paint else ('Ivory' if spine and i==5 else mat))
    fs.append(tuple(range((len(rings)-1)*n,len(rings)*n)));mats.append(mat)
    return mesh(name,vs,fs,mat,mats)
def bar(name,a,b,r,mat='Frame',segments=10):
    a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized()
    vs=[tuple(p+r*(u*math.cos(i*math.tau/segments)+v*math.sin(i*math.tau/segments))) for p in (a,b) for i in range(segments)]
    fs=[tuple(range(segments-1,-1,-1)),tuple(range(segments,segments*2))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,vs,fs,mat)
def barrel(name,cx,cz,profile,segments=16,paint=None):
    vs=[(cx+r*math.cos(i*math.tau/segments),y,cz+r*math.sin(i*math.tau/segments)) for y,r in profile for i in range(segments)]
    fs=[tuple(range(segments-1,-1,-1))];mats=['Frame']
    for j in range(len(profile)-1):
        for i in range(segments):
            fs.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i))
            mats.append(paint(j,i) if paint else 'Petrol')
    fs.append(tuple(range((len(profile)-1)*segments,len(profile)*segments)));mats.append('Frame')
    return mesh(name,vs,fs,'Petrol',mats)
def annulus(name,cx,cz,y0,y1,ro,ri,mat='Steel',segments=16):
    vs=[]
    for y,r in [(y0,ro),(y0,ri),(y1,ro),(y1,ri)]:
        vs.extend((cx+r*math.cos(i*math.tau/segments),y,cz+r*math.sin(i*math.tau/segments)) for i in range(segments))
    fs=[];mats=[]
    for i in range(segments):
        j=(i+1)%segments
        fs.extend([(i,j,segments+j,segments+i),(2*segments+i,3*segments+i,3*segments+j,2*segments+j),(i,2*segments+i,2*segments+j,j),(segments+i,segments+j,3*segments+j,3*segments+i)])
        mats.extend([mat,mat,mat,'Frame'])
    return mesh(name,vs,fs,mat,mats)
def disc(name,cx,cz,y0,y1,r,mat='Frame'):
    return bar(name,(cx,y0,cz),(cx,y1,cz),r,mat,16)
def gear(name,x,y,attach_z,wide=.75):
    # A grounded static display support, not a canonical animation/mechanism.
    box(name+'_Foot',(x,y,.09),(wide,1.02,.18),'Frame',.035)
    bar(name+'_Strut',(x,y,.17),(x*.88,y+.20,attach_z),.11,'Steel',10)
    box(name+'_Knee',(x*.91,y+.15,attach_z*.70),(.29,.33,.24),'Petrol',.025)
    bar(name+'_Brace',(x,y-.25,.19),(x*.88,y+.26,attach_z-.04),.065,'Frame',8)

def cutlass():
    group('Cutlass_transport_hull')
    loft('Cutlass_CargoHull',[(-4.25,1.55,1.60,3.70),(-2.8,2.20,1.35,3.95),(1.5,2.55,1.30,4.0),(5.7,2.30,1.35,3.82),(6.5,1.95,1.50,3.48)],spine=True)
    # Raised broad dorsal shoulders, not a field of small surface greebles.
    for side,s in [('L',-1),('R',1)]:
        slab_xy('Cutlass_DorsalShoulder_'+side,[(s*.85,1.30),(s*2.24,1.70),(s*2.05,5.60),(s*.85,5.90)],3.80,4.04,'Petrol',.035)
        box('Cutlass_DorsalMark_'+side,(s*1.48,3.74,4.055),(.82,.30,.055),'Ochre',.008)
        for i,y in enumerate((-.80,1.32,3.40)):
            box('Cutlass_CargoSideInset_'+side+str(i),(s*2.43,y,2.51),(.22,1.24,.78),'Frame',.055)
    group('Cutlass_canopy')
    sections=[(-7.60,.40,1.88,2.66),(-7.48,.43,1.90,2.73),(-6.65,.77,1.98,3.28),(-6.53,.80,2.00,3.34),(-5.30,1.00,2.14,4.05),(-5.18,1.01,2.16,4.08),(-3.80,1.08,2.30,4.17),(-3.42,1.01,2.38,4.12)]
    def cockpit(j,i):
        return 'Glass' if j in [1,3,5] and i in [2,4,6] else 'Ivory'
    loft('Cutlass_Canopy',sections,'Ivory',paint=cockpit)
    box('Cutlass_ChinMount',(0,-6.96,1.88),(.76,.68,.34),'Frame',.045)
    for s in [-1,1]:bar('Cutlass_ChinGun_'+str(s),(s*.22,-7.83,1.91),(s*.22,-6.70,1.91),.10,'Frame',10)
    group('Cutlass_forward_forks')
    for side,s in [('L',-1),('R',1)]:
        xy=[(s*1.40,-3.45),(s*2.50,-2.62),(s*5.95,-3.38),(s*5.95,-5.35),(s*3.65,-4.98),(s*2.05,-4.10)]
        slab_xy('Cutlass_ForeWing_'+side,xy,2.65,3.05,'Petrol',.045)
        slab_yz('Cutlass_EndPlate_'+side,[(-5.58,1.40),(-3.48,1.40),(-3.32,3.96),(-5.55,3.96)],s*5.90-.12,s*5.90+.12,'Petrol',.035)
        box('Cutlass_EndPlateMark_'+side,(s*6.025,-4.42,2.18),(.045,.92,.57),'Ochre',.012)
        box('Cutlass_WingRootBand_'+side,(s*4.25,-4.31,3.07),(.65,.28,.075),'Ochre',.01)
        bar('Cutlass_ForkBarrel_'+side,(s*5.90,-6.67,2.72),(s*5.90,-4.70,2.72),.115,'Frame',12)
        slab_yz('Cutlass_ForkKeel_'+side,[(-6.16,1.49),(-5.17,1.54),(-5.02,2.10),(-5.78,2.11)],s*5.90-.18,s*5.90+.18,'Frame',.025)
    group('Cutlass_aft_engine_mounts')
    for side,s in [('L',-1),('R',1)]:
        slab_xy('Cutlass_EnginePylon_'+side,[(s*1.90,2.25),(s*4.40,2.64),(s*4.40,5.42),(s*2.10,5.78)],2.61,3.10,'Petrol',.045)
        box('Cutlass_EnginePylonCap_'+side,(s*3.22,4.22,3.12),(1.38,1.42,.22),'Petrol',.045)
        cx=s*4.15;cz=3.20
        profile=[(3.35,1.12),(3.65,1.16),(4.65,1.25),(5.30,1.20),(5.52,1.20),(6.70,.94),(7.20,.94)]
        def podpaint(j,i):
            if j==3:return 'Ochre'
            if j in [1,2] and math.sin((i+.5)*math.tau/16)>.20:return 'Ivory'
            return 'Petrol' if j<4 else 'Steel'
        barrel('Cutlass_EngineBody_'+side,cx,cz,profile,16,podpaint)
        cowl=loft('Cutlass_ArmoredEngineCowl_'+side,[(1.30,.65,2.30,3.40),(2.05,1.06,2.12,4.20),(3.42,1.22,2.15,4.60),(4.50,1.18,2.17,4.58),(5.02,.96,2.22,4.28)],'Ivory',paint=lambda j,i:'Ivory' if i in [3,4,5] else 'Petrol')
        cowl.data.transform(Matrix.Translation((cx,0,0)))
        box('Cutlass_EngineFrontVent_'+side,(cx,1.28,2.89),(.63,.09,.20),'Frame',.025)
        annulus('Cutlass_ExhaustHousing_'+side,cx,cz,7.10,7.77,1.03,.76,'Frame')
        annulus('Cutlass_ExhaustLip_'+side,cx,cz,7.69,7.91,1.075,.78,'Steel')
        disc('Cutlass_ExhaustRecess_'+side,cx,cz,7.17,7.28,.78,'WarmCore')
        disc('Cutlass_ExhaustDarkCore_'+side,cx,cz,7.285,7.31,.45,'Frame')
        # Two substantial pod skirts echo the armored cowling in both views.
        for ss in [-1,1]:
            slab_yz('Cutlass_EngineSkirt_'+side+str(ss),[(2.30,2.30),(5.60,2.10),(6.18,2.64),(3.0,2.78)],cx+ss*.86-.14,cx+ss*.86+.14,'Petrol',.025)
    group('Cutlass_cargo_ramp')
    slab_xz('Cutlass_ClosedRearRamp',[(-1.40,1.48),(1.40,1.48),(1.65,3.30),(-1.65,3.30)],6.38,6.67,'Frame',.045)
    for i,z in enumerate([1.82,2.45,3.08]):box('Cutlass_RampCrossbar_'+str(i),(0,6.70,z),(2.55,.10,.13),'Petrol',.015)
    for s in [-1,1]:box('Cutlass_RampSideMark_'+str(s),(s*1.53,6.72,2.43),(.13,.11,1.08),'Ochre',.015)
    group('Cutlass_dorsal_turret')
    bar('Cutlass_TurretTurntable',(0,-1.0,3.88),(0,-1.0,4.20),.63,'Frame',16)
    loft('Cutlass_TurretHousing',[(-1.61,.52,4.12,4.58),(-1.15,.69,4.08,4.86),(-.42,.60,4.07,4.78)],'Petrol',paint=lambda j,i:'Ivory' if i in [3,4,5] else 'Petrol')
    for s in [-1,1]:bar('Cutlass_TurretBarrel_'+str(s),(s*.60,-3.72,4.49),(s*.60,-.94,4.49),.115,'Frame',12)
    group('Cutlass_static_landing_gear')
    for i,(x,y) in enumerate([(-1.65,-2.75),(1.65,-2.75),(-1.85,4.65),(1.85,4.65)]):gear('Cutlass_Gear_'+str(i),x,y,1.55,.88)
    return {'identity':['faceted transport cargo body','lowered segmented cockpit','two forward stubwings/endplates and fork guns','two separate outboard aft engines on pylons','central closed loading ramp','small dorsal twin turret'],
        'limits':['closed graphic cargo ramp, no interior','four-pad original simplified static display undercarriage, not canonical source gear','no textures, flight or weapon mechanics']}

def buccaneer():
    group('Buccaneer_narrow_fuselage')
    loft('Buccaneer_SlimSpine',[(-5.40,.32,1.25,1.8),(-4.7,.56,1.15,2.25),(-3.3,.80,1.10,3.0),(-2.0,.74,1.05,3.2),(0,.68,1.15,2.95),(3.5,.78,1.25,2.80),(4.7,.72,1.40,2.55)],'Petrol')
    group('Buccaneer_canopy')
    cs=[(-5.31,.35,1.40,1.82),(-5.18,.40,1.37,1.95),(-4.60,.65,1.30,2.40),(-4.48,.67,1.31,2.45),(-2.70,.82,1.40,3.10),(-2.58,.82,1.43,3.12),(-1.85,.76,1.65,3.18),(-1.66,.73,1.70,3.14)]
    cs=[(y,w+.035,zb+.057,zt+.057) for y,w,zb,zt in cs]
    loft('Buccaneer_Canopy',cs,'Ivory',paint=lambda j,i:'GlassWarm' if j in [1,3,5] and i in [2,4,6] else 'Ivory')
    group('Buccaneer_pod_pylons')
    for side,s in [('L',-1),('R',1)]:
        slab_xy('Buccaneer_InnerPylon_'+side,[(s*.55,-1.40),(s*2.8,-.95),(s*3.0,2.90),(s*.62,3.64)],1.80,2.24,'Petrol',.035)
        box('Buccaneer_InnerFairing_'+side,(s*1.33,.60,2.40),(.95,2.64,.47),'Petrol',.055)
    group('Buccaneer_twin_engine_pods')
    for side,s in [('L',-1),('R',1)]:
        cx=s*2.70;cz=2.65
        profile=[(-2.25,1.24),(-1.90,1.30),(-1.68,1.30),(-.45,1.18),(2.40,1.20),(2.66,1.20),(3.38,1.15),(4.35,.95)]
        def podpaint(j,i):
            if j in [1,4]:return 'Ochre'
            if j in [2,3,5] and math.sin((i+.5)*math.tau/16)>.15:return 'Ivory'
            return 'Petrol'
        barrel('Buccaneer_EnginePod_'+side,cx,cz,profile,16,podpaint)
        annulus('Buccaneer_FrontIntake_'+side,cx,cz,-2.66,-2.10,1.28,.97,'Petrol')
        annulus('Buccaneer_IntakeLip_'+side,cx,cz,-2.70,-2.56,1.31,1.04,'Frame')
        disc('Buccaneer_IntakeDepth_'+side,cx,cz,-2.40,-2.20,.99,'Frame')
        annulus('Buccaneer_IntakeInnerRing_'+side,cx,cz,-2.43,-2.34,.69,.57,'Frame')
        annulus('Buccaneer_RearNozzle_'+side,cx,cz,4.24,4.88,.96,.66,'Frame')
        annulus('Buccaneer_RearLip_'+side,cx,cz,4.72,4.95,1.00,.68,'Steel')
        disc('Buccaneer_RecessWarm_'+side,cx,cz,4.30,4.39,.68,'WarmCore')
        disc('Buccaneer_RecessDark_'+side,cx,cz,4.395,4.42,.38,'Frame')
        # Six large rear petals are geometry, not a spray of tiny engine parts.
        for j in range(6):
            a=j*math.tau/6;half=.18;vs=[]
            for y,rin,rout,w in [(4.38,.89,1.08,half),(5.44,.91,1.04,half*.72)]:
                for theta,r in [(a-w,rin),(a+w,rin),(a+w,rout),(a-w,rout)]:vs.append((cx+r*math.cos(theta),y,cz+r*math.sin(theta)))
            mesh('Buccaneer_ExhaustPetal_'+side+str(j),vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],'Petrol')
    group('Buccaneer_short_outer_wings')
    for side,s in [('L',-1),('R',1)]:
        slab_xy('Buccaneer_OuterWing_'+side,[(s*3.45,-.25),(s*4.20,-.10),(s*5.95,1.0),(s*5.85,3.70),(s*4.30,3.20),(s*3.45,2.70)],2.04,2.30,'Petrol',.035)
        slab_xy('Buccaneer_WingIvory_'+side,[(s*4.55,.63),(s*5.76,1.38),(s*5.69,3.41),(s*4.52,3.05)],2.275,2.35,'Ivory',.015)
        slab_xy('Buccaneer_WingOchre_'+side,[(s*4.37,.54),(s*4.62,.68),(s*4.58,3.06),(s*4.34,2.99)],2.29,2.37,'Ochre',.008)
    group('Buccaneer_dorsal_gun_and_keels')
    box('Buccaneer_CannonMount',(0,1.04,2.94),(.87,1.69,.36),'Frame',.05)
    loft('Buccaneer_CannonReceiver',[(-.05,.32,3.02,3.49),(.35,.42,3.02,3.66),(1.74,.38,3.02,3.61)],'Petrol')
    bar('Buccaneer_DorsalBarrel',(0,-2.94,3.43),(0,.71,3.43),.135,'Steel',12)
    bar('Buccaneer_DorsalMuzzle',(0,-3.07,3.43),(0,-2.75,3.43),.18,'Frame',12)
    for s in [-1,1]:
        slab_yz('Buccaneer_AftKeel_'+str(s),[(3.50,1.43),(5.34,1.25),(5.45,2.02),(3.65,2.64)],s*.62-.12,s*.62+.12,'Frame',.02)
        box('Buccaneer_SpineIvory_'+str(s),(s*.56,2.18,2.80),(.32,2.02,.12),'Ivory',.02)
    group('Buccaneer_static_landing_gear')
    gear('Buccaneer_NoseGear',0,-3.44,1.37,.60)
    for i,s in enumerate([-1,1]):gear('Buccaneer_PodGear_'+str(i),s*2.30,1.58,1.56,.70)
    return {'identity':['very narrow central fuselage and pointed glazed nose','two large parallel cylindrical pods, dark front inlets and smaller petalled rear nozzles','short swept outer wings','central dorsal cannon','open negative space between fuselage and pods at front'],
        'limits':['tripod original simplified static undercarriage, not a canonical animated landing system','intake/exhaust internals reduced to broad concentric shapes and six rear petals per pod','no textures or flight/weapon mechanics']}

def bounds(obs):
    bpy.context.view_layer.update();points=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    return Vector([min(p[i] for p in points) for i in range(3)]),Vector([max(p[i] for p in points) for i in range(3)])
def export(asset):
    vs=[];fs=[];mids=[];keys=list(MATS)
    for ob in PARTS:
        offset=len(vs);vs.extend(tuple(ob.matrix_world@v.co) for v in ob.data.vertices)
        for p in ob.data.polygons:
            key=next(k for k,m in MATS.items() if m==ob.data.materials[p.material_index]);fs.append(tuple(offset+i for i in p.vertices));mids.append(keys.index(key))
    me=bpy.data.meshes.new(asset+'_Mesh');me.from_pydata(vs,[],fs);me.update()
    for m in MATS.values():me.materials.append(m)
    for p,i in zip(me.polygons,mids):p.material_index=i
    ob=bpy.data.objects.new(asset,me);bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    path=EXPORT/(asset+'.glb');bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_lights=False,export_cameras=False)
    b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n])
    result={'path':str(path.relative_to(ROOT)).replace('\\','/'),'sha256':sha(path),'bytes':len(b),'meshes':len(g['meshes']),'materials':len(g['materials']),
            'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),'nodes':len(g['nodes']),'skins':len(g.get('skins',[])),'animations':len(g.get('animations',[]))}
    bpy.data.objects.remove(ob,do_unlink=True);return result
def main():
    funcs={'cutlass_01':(cutlass,16.0),'buccaneer_01':(buccaneer,11.0)}
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else funcs
    for asset in args or funcs:
        reset();fn,target=funcs[asset];meta=fn();lo,hi=bounds(PARTS);factor=target/(hi.y-lo.y);offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
        for ob in PARTS:ob.data.transform(Matrix.Scale(factor,4)@Matrix.Translation(-offset))
        lo,hi=bounds(PARTS);tris=sum(len(p.vertices)-2 for o in PARTS for p in o.data.polygons);assert tris<15000
        raw=qa_check.run(objects=[o.name for o in PARTS],profile='game',uv=False,eps=.0003,tol=.008)
        dump(QA/(asset+'_raw.json'),raw)
        path=ART/'source'/(asset+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(path));glb=export(asset)
        rec={'asset':asset,'status':'new simplified illustration-led model candidate; not a stock SC model or accepted final art','construction':'new original low-poly mesh reconstruction; no old OBJ/material-study/Kenney ship geometry imported',
             'source':str(path.relative_to(ROOT)).replace('\\','/'),'source_sha256':sha(path),'export':glb,'triangles':tris,'vertices':sum(len(o.data.vertices) for o in PARTS),'editable_parts':len(PARTS),
             'dimensions_blender_m':list(hi-lo),'bounds_blender_m':{'min':list(lo),'max':list(hi)},'normalization_length_m':target,'normalization_uniform_factor':factor,
             'scale_status':'explicitly stylized display normalization, NOT canonical Star Citizen measurements','pivot':'full BBox XY center / groundZ0 on static feet','front_blender':'-Y','front_godot':'+Z','runtime_scale_suggested':.22,
             'palette':PALETTE,'no_emission':True,'reference_images':[{'path':'docs/reports/assets/grafik-2026-11-01/'+p,'sha256':sha(ROOT/'docs/reports/assets/grafik-2026-11-01'/p)} for p in REFS[asset]],
             'qa_pass':raw['pass'],'qa_errors':raw['errors'],'qa_warnings':raw['warnings'],'qa_scope':'entire static assembly, no expensive-check skips; UV excluded for solid-color materials','identity':meta,
             'groups':{name:[o.name for o in PARTS if o['ship_assembly']==name] for name in sorted({o['ship_assembly'] for o in PARTS})}}
        dump(QA/(asset+'_manifest.json'),rec);print('SHIP_BUILD '+json.dumps({k:v for k,v in rec.items() if k not in ['groups','reference_images']}))
if __name__=='__main__':main()

"""Cutlass form revision, two retained iterations. New geometry; R01 stays readonly.
Blender5.2.3 --background --factory-startup --python-exit-code1 --python this.py -- 1|2
"""
from pathlib import Path
import bpy,bmesh,math,sys,json,hashlib,struct
from mathutils import Vector,Matrix
ART=Path(__file__).resolve().parents[1]
ROOT=ART.parents[4]
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04_r02'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
MATS={};PARTS=[];GROUP='Hull';ITERATION=1
PALETTE={'Ivory':'e2d5b9','Petrol':'4f6569','Slate':'657a7d','Frame':'293a40','Steel':'8a9694','Ochre':'d49b48','Glass':'274d60','WarmCore':'ba773d','Inset':'3a5058'}
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,d):Path(p).parent.mkdir(parents=True,exist_ok=True);Path(p).write_text(json.dumps(d,indent=2),encoding='utf-8')
def srgb(h):
    c=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in c)+(1,)
def reset():
    global PARTS,MATS,GROUP
    bpy.ops.wm.read_factory_settings(use_empty=True);PARTS=[];MATS={};GROUP='Hull'
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    for k,c in PALETTE.items():
        m=bpy.data.materials.new('M_CutlassR02_'+k);m.diffuse_color=srgb(c)
        bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value=srgb(c);bs.inputs['Roughness'].default_value=.76 if k!='Glass' else .28
        bs.inputs['Metallic'].default_value=.25 if k=='Steel' else 0
        MATS[k]=m
def group(name):
    global GROUP
    GROUP=name
def recessed(vs,fs,mats,items):
    # Replace actual exterior faces with inset rims, sloped walls and deeper floors.
    # Each requested normal points OUT; positive depth is into the component.
    newf=[];newm=[]
    for i,(f,mat) in enumerate(zip(fs,mats)):
        if i not in items:newf.append(f);newm.append(mat);continue
        scale,depth,normal,inner=items[i];n=Vector(normal).normalized();c=sum((Vector(vs[j]) for j in f),Vector())/len(f)
        rim=[];floor=[]
        for j in f:
            p=c+(Vector(vs[j])-c)*scale;rim.append(len(vs));vs.append(tuple(p))
            floor.append(len(vs));vs.append(tuple(p-n*depth))
        for j in range(len(f)):
            k=(j+1)%len(f)
            newf.extend([(f[j],f[k],rim[k],rim[j]),(rim[j],rim[k],floor[k],floor[j])]);newm.extend([mat,'Frame'])
        newf.append(tuple(floor));newm.append(inner)
    return vs,newf,newm
def mesh(name,vs,fs,mat='Petrol',fm=None,bevel=.035,recess=None):
    vs=list(vs);fs=list(fs);fm=list(fm) if fm else [mat]*len(fs)
    if recess:vs,fs,fm=recessed(vs,fs,fm,recess)
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(vs,[],fs);me.update();keys=list(MATS)
    for m in MATS.values():me.materials.append(m)
    for p,m in zip(me.polygons,fm):p.material_index=keys.index(m)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);co=bpy.data.collections.get(GROUP)
    if not co:co=bpy.data.collections.new(GROUP);bpy.context.scene.collection.children.link(co)
    co.objects.link(ob);ob['ship_assembly']=GROUP
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    if bevel:
        md=ob.modifiers.new('Structural_chamfers','BEVEL');md.width=bevel;md.segments=2 if bevel>=.045 else 1;md.limit_method='ANGLE';md.angle_limit=math.radians(27);md.harden_normals=True
        bpy.ops.object.modifier_apply(modifier=md.name)
    # Bevel can collapse tiny inset corners; weld only coincident generated
    # vertices inside this component, retaining every intended exterior plane.
    bm=bmesh.new();bm.from_mesh(me)
    bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.00001)
    bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.00001)
    bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    # Keep broad planes flat while softening only their physical chamfers.
    for p in me.polygons:p.use_smooth=True
    md=ob.modifiers.new('Area_weighted_normals','WEIGHTED_NORMAL');md.keep_sharp=True;md.weight=50
    bpy.ops.object.modifier_apply(modifier=md.name)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    PARTS.append(ob);return ob
def box(name,c,size,mat='Petrol',bevel=.04,recess=None):
    x,y,z=c;a,b,d=[v/2 for v in size]
    vs=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,bevel=min(bevel,min(size)*.16),recess=recess)
def slab(name,poly,axis,a,b,mat='Petrol',bevel=.04,recess=None):
    def point(p,k):return (k,p[0],p[1]) if axis==0 else ((p[0],k,p[1]) if axis==1 else (p[0],p[1],k))
    n=len(poly);vs=[point(p,k) for k in (a,b) for p in poly]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    return mesh(name,vs,fs,mat,bevel=bevel,recess=recess)
def ring(w,zb,zt,spine=False):
    h=zt-zb
    if spine:return [(-w*.77,zb),(w*.77,zb),(w,zb+h*.24),(w,zt-h*.28),(w*.72,zt),(.83,zt+.16),(-.83,zt+.16),(-w*.72,zt),(-w,zt-h*.28),(-w,zb+h*.24)]
    return [(-w*.75,zb),(w*.75,zb),(w,zb+h*.22),(w,zt-h*.25),(w*.66,zt),(-w*.66,zt),(-w,zt-h*.25),(-w,zb+h*.22)]
def loft(name,sections,mat='Petrol',paint=None,spine=False,indent=None,bevel=.04):
    rings=[ring(w,zb,zt,spine) for y,w,zb,zt in sections];n=len(rings[0]);vs=[(x,sections[j][0],z) for j,r in enumerate(rings) for x,z in r]
    fs=[tuple(range(n-1,-1,-1))];fm=[mat];rec={}
    for j in range(len(rings)-1):
        for i in range(n):
            fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i));fm.append(paint(j,i) if paint else mat)
            if indent:
                spec=indent(j,i)
                if spec:rec[len(fs)-1]=spec
    fs.append(tuple(range((len(rings)-1)*n,len(rings)*n)));fm.append(mat)
    return mesh(name,vs,fs,mat,fm,bevel,recess=rec)
def wing(name,poly,bottom,top,mat='Petrol',inset=False):
    n=len(poly);vs=[(x,y,z) for zs in (bottom,top) for (x,y),z in zip(poly,zs)]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,2*n))]+[(j,(j+1)%n,(j+1)%n+n,j+n) for j in range(n)]
    rec={1:(.80,.07,(0,0,1),'Slate')} if inset else None
    return mesh(name,vs,fs,mat,bevel=.06,recess=rec)
def bar(name,a,b,r,mat='Frame',segments=16):
    a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized()
    vs=[tuple(p+r*(u*math.cos(i*math.tau/segments)+v*math.sin(i*math.tau/segments))) for p in (a,b) for i in range(segments)]
    fs=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,vs,fs,mat,bevel=0)
def barrel(name,cx,cz,profile,mat='Petrol',paint=None,segments=24):
    vs=[(cx+r*math.cos(i*math.tau/segments),y,cz+r*math.sin(i*math.tau/segments)) for y,r in profile for i in range(segments)]
    fs=[tuple(range(segments-1,-1,-1))];fm=['Frame']
    for j in range(len(profile)-1):
        for i in range(segments):
            fs.append((j*segments+i,j*segments+(i+1)%segments,(j+1)*segments+(i+1)%segments,(j+1)*segments+i));fm.append(paint(j,i) if paint else mat)
    fs.append(tuple(range((len(profile)-1)*segments,len(profile)*segments)));fm.append('Frame')
    return mesh(name,vs,fs,mat,fm,bevel=0)
def annulus(name,cx,cz,y0,y1,ro,ri,mat='Steel',segments=24):
    vs=[]
    for y,r in [(y0,ro),(y0,ri),(y1,ro),(y1,ri)]:vs.extend((cx+r*math.cos(i*math.tau/segments),y,cz+r*math.sin(i*math.tau/segments)) for i in range(segments))
    fs=[];fm=[]
    for i in range(segments):
        j=(i+1)%segments;fs.extend([(i,j,segments+j,segments+i),(2*segments+i,3*segments+i,3*segments+j,2*segments+j),(i,2*segments+i,2*segments+j,j),(segments+i,segments+j,3*segments+j,3*segments+i)]);fm.extend([mat,mat,mat,'Frame'])
    return mesh(name,vs,fs,mat,fm,bevel=0)
def gear(name,x,y):
    box(name+'_Foot',(x,y,.12),(.88,1.1,.24),'Frame',.055)
    bar(name+'_Leg',(x,y,.21),(x*.92,y+.20,1.64),.15,'Steel',12)
    bar(name+'_Brace',(x,y-.32,.20),(x*.92,y+.27,1.55),.085,'Frame',12)
    box(name+'_Mount',(x*.92,y+.18,1.53),(.46,.55,.42),'Petrol',.055)
def construct():
    group('01_Stepped_transport_hull')
    sections=[(-3.65,1.65,1.55,3.90),(-2.65,2.42,1.35,4.28),(-.40,2.94,1.22,4.40),(2.7,3.02,1.20,4.42),(5.25,2.79,1.30,4.14),(6.45,2.28,1.52,3.54)]
    def hull_inset(j,i):
        if j in [1,2,3] and i in [2,8]:return (.77,.14,(1 if i==2 else -1,0,0),'Inset')
        if ITERATION>=2 and j in [1,3] and i==5:return (.83,.07,(0,0,1),'Ivory')
    loft('Cargo_stepped_hull',sections,spine=True,paint=lambda j,i:'Ivory' if i==5 else ('Slate' if i in [3,7] else 'Petrol'),indent=hull_inset,bevel=.07)
    # Two substantial shoulder shells taper towards the rear, with real recessed planes.
    for side,s in [('L',-1),('R',1)]:
        if ITERATION==1:
            ob=loft('Cargo_shoulder_'+side,[(-2.6,.51,3.28,4.20),(-.8,.78,3.34,4.63),(2.3,.84,3.36,4.66),(4.95,.68,3.26,4.34),(5.9,.40,3.10,3.85)],'Petrol',paint=lambda j,i:'Slate' if i in [3,4,5] else 'Petrol',bevel=.06)
            ob.data.transform(Matrix.Translation((s*1.98,0,0)))
        else:
            for name,sects in [('Forward',[(-2.64,.51,3.28,4.20),(-.86,.79,3.34,4.73),(.94,.86,3.36,4.73),(1.52,.79,3.34,4.54)]),('Aft',[(1.68,.80,3.34,4.48),(2.04,.85,3.36,4.68),(4.67,.70,3.26,4.39),(5.88,.40,3.10,3.84)])]:
                ob=loft('Cargo_shoulder_'+name+'_'+side,sects,'Petrol',paint=lambda j,i:'Slate' if i in [3,4,5] else 'Petrol',indent=lambda j,i:(.81,.065,(0,0,1),'Petrol') if j==1 and i==4 else None,bevel=.05)
                ob.data.transform(Matrix.Translation((s*1.98,0,0)))
                if name=='Forward':
                    # Paint is assigned to existing upper rim triangles, not a glued box.
                    for p in ob.data.polygons:
                        c=p.center
                        if c.z>4.62 and -.50<c.y<-.20:p.material_index=list(MATS).index('Ochre')
    group('02_Broad_glazed_cockpit')
    cs=[(-7.52,.68,2.00,2.94),(-7.18,1.02,1.94,3.40),(-6.70,1.25,1.96,3.86),(-5.30,1.48,2.10,4.48),(-5.13,1.48,2.12,4.53),(-3.63,1.42,2.40,4.56),(-3.30,1.26,2.48,4.41)]
    def windows(j,i):
        if j in [2,4] and i in [2,3,4,5,6]:
            normal=(1,0,0) if i==2 else ((-1,0,0) if i==6 else (0,-.25,1))
            return (.79,.055,normal,'Glass')
    loft('Cockpit_rounded_angular_shell',cs,'Ivory',indent=windows,bevel=.055)
    box('Cockpit_lower_chin',(0,-6.91,1.97),(1.23,.91,.40),'Frame',.075)
    for s in [-1,1]:bar('Chin_cannon_'+str(s),(s*.34,-7.82,2.02),(s*.34,-6.55,2.02),.13,'Frame',12)
    group('03_Profiled_forward_forks')
    for side,s in [('L',-1),('R',1)]:
        poly=[(s*1.82,-2.80),(s*2.65,-2.12),(s*4.94,-3.17),(s*5.46,-3.81),(s*5.48,-5.26),(s*4.65,-5.48),(s*3.08,-4.76),(s*2.06,-4.18)]
        bottom=[2.32,2.32,2.36,2.25,2.10,2.13,2.32,2.39];top=[3.77,3.95,3.54,3.35,3.05,3.02,3.46,3.64]
        wing('Fork_structural_shoulder_'+side,poly,bottom,top,inset=ITERATION>=2)
        yz=[(-5.84,1.32),(-4.85,1.44),(-3.37,1.52),(-3.15,3.51),(-3.44,4.12),(-5.56,4.12),(-5.78,3.74)]
        recess={1 if s>0 else 0:(.74,.065,(s,0,0),'Petrol')} if ITERATION>=2 else None
        slab('Fork_armor_endplate_'+side,yz,0,s*5.40-.19,s*5.40+.19,'Petrol',.065,recess)
        # Deep lower claw and a gun with an actual receiver rather than a floating rod.
        slab('Fork_lower_claw_'+side,[(-6.28,1.39),(-5.14,1.47),(-4.69,2.09),(-5.68,2.23)],0,s*5.40-.23,s*5.40+.23,'Frame',.05)
        box('Fork_gun_receiver_'+side,(s*5.40,-5.01,2.69),(.48,1.15,.49),'Inset',.05)
        bar('Fork_gun_barrel_'+side,(s*5.40,-6.64,2.70),(s*5.40,-4.81,2.70),.14,'Frame',16)
        box('Fork_ochre_panel_'+side,(s*5.603,-4.43,2.33),(.055,1.16,.79),'Ochre',.015)
        if ITERATION>=2:
            # The forward upper chamfer itself carries a broad ochre stripe.
            fork=bpy.data.objects['Fork_structural_shoulder_'+side]
            for p in fork.data.polygons:
                c=p.center
                if c.z>2.70 and c.y<-4.72:p.material_index=list(MATS).index('Ochre')
    group('04_Articulated_separate_engine_pods')
    for side,s in [('L',-1),('R',1)]:
        cx=s*4.34;cz=3.48
        wing('Engine_structural_pylon_'+side,[(s*2.24,1.77),(s*3.88,2.03),(s*4.21,4.78),(s*2.40,5.22)],[2.62,2.55,2.45,2.55],[3.58,3.61,3.31,3.65],inset=False)
        # A visible thick circular mounting joint on each inboard face.
        bar('Engine_pivot_'+side,(s*2.66,3.40,3.40),(s*4.24,3.40,3.40),.70,'Frame',24)
        bar('Engine_pivot_hub_'+side,(s*2.60,3.40,3.40),(s*3.12,3.40,3.40),.48,'Steel',24)
        barrel('Engine_core_'+side,cx,cz,[(1.9,.90),(2.40,1.15),(3.18,1.28),(4.20,1.28),(5.20,1.18),(5.63,1.10),(6.42,1.00),(7.00,.94)],'Frame',paint=lambda j,i:'Steel' if j in [4,5] else 'Frame')
        # Forward sloped armor, interrupted by open dark machinery at its rear.
        cowl_end=4.31 if ITERATION>=2 else 3.83
        cowl=loft('Engine_forward_cowl_'+side,[(1.10,.63,2.55,3.70),(1.64,.98,2.32,4.35),(2.45,1.21,2.23,4.91),(3.42,1.25,2.24,4.94),(cowl_end,1.16,2.30,4.77)],'Petrol',paint=lambda j,i:'Ivory' if i in [3,4,5] else ('Slate' if i in [2,6] else 'Petrol'),indent=lambda j,i:(.69,.07,(1 if i==2 else -1,0,.2),'Frame') if j==1 and i in [2,6] else None,bevel=.075)
        cowl.data.transform(Matrix.Translation((cx,0,0)))
        # Rear upper shell is visibly a different structural section.
        rear=loft('Engine_aft_cowl_'+side,[(4.56,1.12,2.52,4.52),(4.78,1.21,2.46,4.72),(5.55,1.15,2.51,4.62),(5.84,1.03,2.58,4.38)],'Petrol',paint=lambda j,i:'Ivory' if i in [3,4,5] else 'Petrol',bevel=.055)
        rear.data.transform(Matrix.Translation((cx,0,0)))
        annulus('Engine_ochre_collar_'+side,cx,cz,5.63,5.87,1.20,1.04,'Ochre')
        # A broad front inlet below the armor nose, framed and actually inset.
        face=[(cx-.50,2.78),(cx+.50,2.78),(cx+.54,3.22),(cx-.54,3.22)]
        slab('Engine_inlet_'+side,face,1,1.055,1.18,'Petrol',.025,{0:(.77,.08,(0,-1,0),'Frame')})
        # Heavy lower side rails create the segmented silhouette, not tiny greebles.
        for ss in [-1,1]:
            slab('Engine_lower_rail_'+side+str(ss),[(1.84,2.35),(2.55,1.96),(4.9,2.02),(5.48,2.43),(4.8,2.74),(2.35,2.74)],0,cx+ss*.95-.16,cx+ss*.95+.16,'Petrol',.055)
        annulus('Engine_nozzle_housing_'+side,cx,cz,6.15,7.45,1.10,.77,'Steel')
        annulus('Engine_nozzle_lip_'+side,cx,cz,7.28,7.58,1.17,.79,'Frame')
        annulus('Engine_nozzle_trim_'+side,cx,cz,7.56,7.68,1.13,.80,'Steel')
        depth=7.02 if ITERATION>=2 else 6.52
        bar('Engine_warm_recess_'+side,(cx,depth,cz),(cx,depth+.13,cz),.78,'WarmCore',24)
        bar('Engine_dark_core_'+side,(cx,depth+.12,cz),(cx,depth+.19,cz),.31,'Frame',24)
        if ITERATION>=2:
            # Two broad exposed coolant rails bridge the dark interrupted cowl.
            for ss in [-1,1]:bar('Engine_exposed_link_'+side+str(ss),(cx+ss*1.05,3.4,3.70),(cx+ss*1.05,4.94,3.70),.18,'Steel',16)
            # A pair of angular links ties both armor sections to the main core.
            for ss in [-1,1]:
                slab('Engine_ochre_joint_'+side+str(ss),[(3.61,3.05),(4.65,3.05),(4.67,3.50),(3.60,3.68)],0,cx+ss*1.10-.11,cx+ss*1.10+.11,'Ochre',.045)
    group('05_Closed_loading_ramp')
    poly=[(-1.64,1.52),(1.64,1.52),(1.96,3.50),(1.28,3.72),(-1.28,3.72),(-1.96,3.50)]
    slab('Rear_ramp_frame',poly,1,6.34,6.64,'Petrol',.06,{1:(.82,.16,(0,1,0),'Frame')})
    # Rear steps are structural ledges below the dark ramp, not an imitation grid.
    box('Ramp_lower_sill',(0,6.57,1.55),(2.78,.36,.27),'Steel',.04)
    if ITERATION>=2:
        for j,(z0,z1,w) in enumerate([(1.80,2.25,1.36),(2.30,2.76,1.43),(2.81,3.28,1.48)]):
            slab('Ramp_door_panel_'+str(j),[(-w,z0),(w,z0),(w*.97,z1),(-w*.97,z1)],1,6.42,6.53,'Slate' if j!=1 else 'Petrol',.035)
        for s in [-1,1]:
            box('Ramp_hinge_mount_'+str(s),(s*1.69,6.57,2.46),(.36,.37,1.03),'Petrol',.045)
            bar('Ramp_hinge_pin_'+str(s),(s*1.69,6.78,2.02),(s*1.69,6.78,2.94),.13,'Steel',16)
    for s in [-1,1]:
        ob=loft('Rear_haunch_'+str(s),[(4.4,.52,1.64,3.60),(5.50,.58,1.55,3.45),(6.65,.44,1.79,2.92)],'Petrol',paint=lambda j,i:'Ivory' if i==4 and j==1 else 'Petrol',bevel=.055)
        ob.data.transform(Matrix.Translation((s*1.98,0,0)))
    group('06_Dorsal_twin_turret')
    bar('Turret_turntable',(0,-1.38,4.25),(0,-1.38,4.59),.76,'Frame',24)
    loft('Turret_armored_housing',[(-2.13,.59,4.47,4.98),(-1.76,.82,4.43,5.28),(-.76,.75,4.44,5.19),(-.48,.59,4.48,4.96)],'Petrol',paint=lambda j,i:'Ivory' if i in [3,4,5] else 'Petrol',bevel=.065)
    for s in [-1,1]:
        box('Turret_receiver_'+str(s),(s*.77,-1.43,4.94),(.29,.92,.32),'Steel',.035)
        bar('Turret_barrel_'+str(s),(s*.77,-4.12,4.97),(s*.77,-1.41,4.97),.14,'Frame',16)
    group('07_Supported_static_gear')
    for i,(x,y) in enumerate([(-1.95,-2.20),(1.95,-2.20),(-2.08,4.66),(2.08,4.66)]):gear('Gear_'+str(i),x,y)
    if ITERATION>=2:
        group('08_Sparse_panel_connections')
        # Twelve readable structural fasteners, deliberately not an all-over rivet field.
        for s in [-1,1]:
            for j,(y,z) in enumerate([(-.35,4.61),(2.50,4.51)]):
                bar('Shoulder_fastener_'+str(s)+'_'+str(j),(s*2.06,y,z),(s*2.06,y,z+.13),.09,'Steel',8)
            for j,y in enumerate([-4.87,-3.75]):
                bar('Fork_fastener_'+str(s)+'_'+str(j),(s*5.50,y,3.52),(s*5.65,y,3.52),.085,'Steel',8)
            for j,(y,z) in enumerate([(2.45,4.89),(3.42,4.92)]):
                bar('Cowl_fastener_'+str(s)+'_'+str(j),(s*4.34,y,z),(s*4.34,y,z+.13),.085,'Steel',8)
def bounds(obs):
    bpy.context.view_layer.update();ps=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    return Vector([min(p[i] for p in ps) for i in range(3)]),Vector([max(p[i] for p in ps) for i in range(3)])
def export_glb(path):
    vs=[];fs=[];mis=[];keys=list(MATS)
    for o in PARTS:
        off=len(vs);vs.extend(tuple(o.matrix_world@v.co) for v in o.data.vertices)
        for p in o.data.polygons:fs.append(tuple(off+j for j in p.vertices));mis.append(p.material_index)
    me=bpy.data.meshes.new('cutlass_01_Mesh');me.from_pydata(vs,[],fs);me.update()
    for m in MATS.values():me.materials.append(m)
    for p,mi in zip(me.polygons,mis):p.material_index=mi
    ob=bpy.data.objects.new('cutlass_01',me);bpy.context.scene.collection.objects.link(ob)
    # Preserve imported normals as local custom normals from the editable assembly.
    normals=[]
    for o in PARTS:
        normals.extend(tuple(c.vector) for c in o.data.corner_normals)
    for p in me.polygons:p.use_smooth=True
    me.normals_split_custom_set(normals)
    me.update()
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    path.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=str(path),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_lights=False,export_cameras=False)
    bpy.data.objects.remove(ob,do_unlink=True)
    b=path.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n])
    return {'path':str(path.relative_to(ROOT)).replace('\\','/'),'sha256':sha(path),'bytes':len(b),'meshes':len(g['meshes']),'materials':len(g['materials']),'nodes':len(g['nodes']),'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),'animations':len(g.get('animations',[])),'skins':len(g.get('skins',[]))}
def main():
    global ITERATION
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ['1'];ITERATION=int(args[0]);assert ITERATION in [1,2]
    reset();construct();lo,hi=bounds(PARTS);factor=16/(hi.y-lo.y);off=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for o in PARTS:o.data.transform(Matrix.Scale(factor,4)@Matrix.Translation(-off))
    lo,hi=bounds(PARTS);tris=sum(len(p.vertices)-2 for o in PARTS for p in o.data.polygons);print('TRIANGLE_COUNT',tris);assert tris<20000
    qa=ART/'qa'/('iteration%02d'%ITERATION);source=ART/'source'/('iteration%02d'%ITERATION)/'cutlass_01.blend';source.parent.mkdir(parents=True,exist_ok=True)
    raw=qa_check.run(objects=[o.name for o in PARTS],profile='game',uv=False,eps=.0003,tol=.008);dump(qa/'source_raw.json',raw)
    bpy.ops.wm.save_as_mainfile(filepath=str(source))
    target=EXPORT/'cutlass_01.glb' if ITERATION==2 else ART/'iterations/iteration01/cutlass_01.glb'
    exp=export_glb(target)
    rec={'asset':'cutlass_01','iteration':ITERATION,'source':str(source.relative_to(ROOT)).replace('\\','/'),'source_sha256':sha(source),'export':exp,'triangles':tris,'vertices':sum(len(o.data.vertices) for o in PARTS),'editable_parts':len(PARTS),'dimensions_blender_m':list(hi-lo),'bounds_blender_m':{'min':list(lo),'max':list(hi)},'normalization_length_m':16,'runtime_scale':.22,'front_blender':'-Y','front_godot':'+Z','pivot':'full BBox XY center, groundZ0','palette':PALETTE,'qa_pass':raw['pass'],'qa_errors':raw['errors'],'qa_warnings':raw['warnings'],'raw_source_qa':str((qa/'source_raw.json').relative_to(ROOT)).replace('\\','/'),'groups':{n:[o.name for o in PARTS if o['ship_assembly']==n] for n in sorted({o['ship_assembly'] for o in PARTS})}}
    dump(qa/'build_manifest.json',rec);print('CUTLASS_BUILD '+json.dumps({k:v for k,v in rec.items() if k!='groups'}))
if __name__=='__main__':main()

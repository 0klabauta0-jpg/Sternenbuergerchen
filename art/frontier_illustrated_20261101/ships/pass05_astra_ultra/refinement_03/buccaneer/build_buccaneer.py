"""Original reference-led lofted Buccaneer. Blender 5.2 headless, rerunnable.
All dimensions inferred from perspective concepts; normalized length 11 m.
Run blender -b --factory-startup -P build_buccaneer.py -- --iteration i01
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, argparse, hashlib, shutil
from mathutils import Vector

HERE=Path(__file__).resolve().parent
PACKAGE=HERE.parent.parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').exists())
OUT=HERE/'exports'
P=argparse.ArgumentParser(); P.add_argument('--iteration',default='i01'); P.add_argument('--views',default='front,rear,side,top,game'); P.add_argument('--qa',action='store_true')
args=P.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
ITER=HERE/'iterations'/args.iteration; ITER.mkdir(parents=True,exist_ok=True); OUT.mkdir(parents=True,exist_ok=True)
shutil.copy2(__file__,ITER/'build_buccaneer.py')
bpy.ops.wm.read_factory_settings(use_empty=True)
SC=bpy.context.scene; SC.unit_settings.system='METRIC'; SC.unit_settings.scale_length=1
LOW=bpy.data.collections.new('LOW'); SC.collection.children.link(LOW)
STAGE=bpy.data.collections.new('REVIEW'); SC.collection.children.link(STAGE)
MATS={}; OBJECTS=[]
COLORS={'Petrol':(.070,.105,.115,1),'Ivory':(.76,.60,.37,1),'Ochre':(.70,.31,.025,1),'Graphite':(.012,.018,.024,1),'Glass':(.025,.030,.035,1),'Steel':(.29,.30,.28,1),'PetrolShade':(.038,.056,.064,1),'WarmCore':(.65,.18,.025,1)}
for name,col in COLORS.items():
    m=bpy.data.materials.new('M_'+name); m.diffuse_color=col
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=col; p.inputs['Roughness'].default_value=.66
    p.inputs['Metallic'].default_value=1 if name=='Steel' else 0
    if name=='Glass': p.inputs['Roughness'].default_value=.26
    if name=='WarmCore':
        p.inputs['Emission Strength'].default_value=0
        p.inputs['Metallic'].default_value=.65
        p.inputs['Roughness'].default_value=.48
    tex=PACKAGE/'buccaneer/textures'/(name+'_basecolor.png')
    if tex.exists():
        im=bpy.data.images.load(str(tex),check_existing=True);im.colorspace_settings.name='sRGB';im.pack()
        nt=m.node_tree.nodes.new('ShaderNodeTexImage');nt.image=im;m.node_tree.links.new(nt.outputs['Color'],p.inputs['Base Color'])
        if name not in ('Glass','WarmCore','Steel'):
            rough=bpy.data.images.load(str(PACKAGE/'buccaneer/textures/paint_roughness.png'),check_existing=True);rough.colorspace_settings.name='Non-Color';rough.pack()
            rt=m.node_tree.nodes.new('ShaderNodeTexImage');rt.image=rough;m.node_tree.links.new(rt.outputs['Color'],p.inputs['Roughness'])
    MATS[name]=m

def mesh(name,verts,faces,mat='Petrol',face_mats=None,bevel=0,smooth=False):
    me=bpy.data.meshes.new('VH_Buccaneer_'+name); me.from_pydata(verts,[],faces);me.update()
    ob=bpy.data.objects.new('VH_Buccaneer_'+name,me); LOW.objects.link(ob);OBJECTS.append(ob)
    for m in MATS.values():me.materials.append(m)
    keys=list(MATS)
    for i,p in enumerate(me.polygons):p.material_index=keys.index(face_mats[i] if face_mats else mat);p.use_smooth=smooth
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=[f for f in bm.faces if len(f.verts)>4]);bm.to_mesh(me);bm.free()
    if bevel:
        md=ob.modifiers.new('Machined_edge_radii','BEVEL');md.width=bevel;md.segments=2;md.limit_method='ANGLE';md.angle_limit=.55;md.use_clamp_overlap=True
        md.harden_normals=True
        wn=ob.modifiers.new('Face_area_normals','WEIGHTED_NORMAL');wn.keep_sharp=True;wn.weight=50
        for p in me.polygons:p.use_smooth=True
        tri=ob.modifiers.new('Stable_bevel_corner_triangulation','TRIANGULATE');tri.min_vertices=5
    return ob

def ring(w,b,t):
    h=t-b
    return [(-.70*w,b),(.70*w,b),(w,b+.22*h),(.85*w,t-.17*h),(.44*w,t),(-.44*w,t),(-.85*w,t-.17*h),(-w,b+.22*h)]

def loft(name,sections,mat='Petrol',bevel=.025,paint=None):
    vs=[(x,y,z) for y,w,b,t in sections for x,z in ring(w,b,t)];fs=[tuple(range(7,-1,-1))];ms=[mat]
    for j in range(len(sections)-1):
        for i in range(8):
            fs.append((j*8+i,j*8+(i+1)%8,(j+1)*8+(i+1)%8,(j+1)*8+i));ms.append(paint(j,i) if paint else mat)
    fs.append(tuple(range((len(sections)-1)*8,len(sections)*8)));ms.append(mat)
    return mesh(name,vs,fs,face_mats=ms,bevel=bevel)

def prism(name,xy,z0,z1,mat='Petrol',bevel=.02):
    n=len(xy);vs=[(x,y,z0 if not isinstance(z0,list) else z0[i]) for i,(x,y) in enumerate(xy)]+[(x,y,z1 if not isinstance(z1,list) else z1[i]) for i,(x,y) in enumerate(xy)]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel=bevel)

def beam(name,a,b,r,mat='Steel',segments=12):
    a,b=Vector(a),Vector(b);d=b-a;up=d.normalized();u=up.cross(Vector((0,0,1)))
    if u.length<.01:u=up.cross(Vector((1,0,0)))
    u.normalize();v=up.cross(u)
    pts=[tuple(c+r*(u*math.cos(i*math.tau/segments)+v*math.sin(i*math.tau/segments))) for c in (a,b) for i in range(segments)]
    faces=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,pts,faces,mat,bevel=.012)

def radial(name,cx,cz,profile,mats,segments=40,flatten=1,phase=0):
    # closed axial radial profile, true inner walls; no overlapping stacked cylinders
    vs=[]
    for y,r in profile:
        for i in range(segments):
            a=i*math.tau/segments+phase
            x=math.cos(a)*r;z=math.sin(a)*r
            # subtly squared/octagonal casing; round throat kept by caller
            z=max(-r*flatten,min(r*flatten,z))
            vs.append((cx+x,y,cz+z))
    fs=[];ms=[]
    for j in range(len(profile)):
        nj=(j+1)%len(profile)
        for i in range(segments):fs.append((j*segments+i,j*segments+(i+1)%segments,nj*segments+(i+1)%segments,nj*segments+i));ms.append(mats[j])
    return mesh(name,vs,fs,face_mats=ms)

def canopy():
    # User's refinement03: structural lower tub, glazing in the upper half.
    # Original RSI images inspire the continuous keel and sill; exact
    # half-height glazing is the user's stronger stylization.
    sections=[(-5.55,.30,1.02,1.54),(-5.25,.47,1.02,1.83),(-3.62,.91,1.08,2.83),(-2.10,1.02,1.20,2.93),(-1.72,.90,1.28,2.80)]
    def cabin_ring(w,b,t):
        h=t-b
        return [(-.62*w,b),(.62*w,b),(.93*w,b+.18*h),(w,b+.46*h),(.94*w,b+.50*h),(.53*w,t-.015*h),(.48*w,t),(-.48*w,t),(-.53*w,t-.015*h),(-.94*w,b+.50*h),(-w,b+.46*h),(-.93*w,b+.18*h)]
    N=12
    vs=[(x,y,z) for y,w,b,t in sections for x,z in cabin_ring(w,b,t)];fs=[tuple(range(N-1,-1,-1))];ms=['PetrolShade']
    for j in range(4):
        for i in range(N):
            ids=[j*N+i,j*N+(i+1)%N,(j+1)*N+(i+1)%N,(j+1)*N+i]
            if (j in (1,2) and i in (4,8)) or (j==1 and i==6):
                p=[Vector(vs[k]) for k in ids];c=sum(p,Vector())/4
                inset=[c+(v-c)*.94 for v in p]
                n=(p[1]-p[0]).cross(p[2]-p[0]).normalized()
                if n.dot(Vector((c.x,0,c.z-1.6)))<0:n=-n
                k=len(vs);vs.extend(tuple(v) for v in inset);q=len(vs);vs.extend(tuple(v-n*.025) for v in inset)
                for h in range(4):
                    h2=(h+1)%4;fs.append((ids[h],ids[h2],k+h2,k+h));ms.append('Ivory')
                    fs.append((k+h,k+h2,q+h2,q+h));ms.append('Ochre' if i in (4,8) else 'Graphite')
                fs.append(tuple(q+h for h in range(4)));ms.append('Glass')
            else:
                fs.append(tuple(ids));ms.append('Graphite' if i==0 else 'PetrolShade' if i in (1,3,9,11) else 'Petrol' if i in (2,10) or (j==3 and i in (4,8)) else 'Ivory')
    fs.append(tuple(range(4*N,5*N)));ms.append('Ivory')
    mesh('Armored_tub_and_upper_canopy',vs,fs,face_mats=ms)

def cowl(side,cx,cz):
    # Continuous cream service jacket BETWEEN the collars, not a barrel with
    # a dark strap through its centre. The broad top and oblique shoulder planes
    # are explicit facets; staggered front/rear edges key into dark mechanics.
    ang=[math.radians(a) for a in (5,18,35,54,69,90,111,126,145,162,175)]
    seg=len(ang)-1
    rows=[(.18,1.14),(.41,1.23),(.94,1.245),(1.83,1.205),(2.30,1.13),(2.62,1.02)]
    n=seg+1;layer=n*len(rows);vs=[]
    for inner in (0,1):
        for j,(y,r) in enumerate(rows):
            for i,a in enumerate(ang):
                rr=r-(.105 if inner else 0);yy=y
                if j==0:yy+=.04 if 3<=i<=7 else .37
                if j==len(rows)-1:yy-=.29 if 3<=i<=7 else .01
                xx=max(-.955*rr,min(.955*rr,rr*math.cos(a)))
                zz=min(.93*rr,rr*math.sin(a))
                vs.append((cx+xx,yy,cz+zz))
    fs=[];ms=[]
    for k in (0,1):
        for j in range(len(rows)-1):
            for i in range(seg):
                a=k*layer+j*n+i;fs.append((a,a+1,a+n+1,a+n));ms.append('Ivory' if k==0 and i not in (0,seg-1) else 'PetrolShade')
    for j in (0,len(rows)-1):
        for i in range(seg):a=j*n+i;fs.append((a,a+1,a+1+layer,a+layer));ms.append('Ivory')
    for i in (0,seg):
        for j in range(len(rows)-1):a=j*n+i;fs.append((a,a+n,a+n+layer,a+layer));ms.append('PetrolShade')
    mesh('Faceted_unbroken_service_cowl_'+side,vs,fs,face_mats=ms)

def wing(side,s):
    # Four span stations, differing airfoil thickness, swept leading and trailing edges.
    us=[0,.20,.40,1];ts=[0,.13,.82,1];vs=[]
    for layer in (0,1):
        for u in us:
            for t in ts:
                # Preserve the old outer wing outline; the inner root grows
                # inward to meet the smaller engine saddle.
                x=s*(2.69+2.49*u);lead=.18+1.65*u;trail=3.80-.20*u;y=lead+(trail-lead)*t
                if u==1 and t in (0,1):x-=s*.18;y+=.14 if t==0 else -.14
                z=1.52-.10*u-.035*(1-u)+(0 if layer==0 else .33-.21*u+.06*math.sin(math.pi*t))
                vs.append((x,y,z))
    fs=[];ms=[];N=len(us)*len(ts)
    for j in range(3):
        for k in range(3):
            a=j*4+k;q=(a,a+4,a+5,a+1);fs.extend([tuple(reversed(q)),tuple(N+x for x in q)]);ms.extend(['PetrolShade','Ivory' if j>=1 and k==1 else 'Ochre' if j==1 and k==0 else 'Petrol'])
    border=[0,4,8,12,13,14,15,11,7,3,2,1]
    for a,b in zip(border,border[1:]+border[:1]):fs.append((a,b,N+b,N+a));ms.append('Petrol')
    mesh('Swept_thick_airfoil_'+side,vs,fs,face_mats=ms,bevel=.028)

def engine(side,s):
    assembly_start=len(OBJECTS)
    x=s*2.47;z=2.22
    # Open front bell and single continuous dark inner casing through aft collar.
    radial('Continuous_pressure_shell_'+side,x,z,[(-1.78,.975),(-1.52,1.15),(-.98,1.29),(-.35,1.20),(.16,1.02),(2.5,.94),(3.38,.86),(3.40,.62),(-.25,.65),(-1.50,.69),(-1.78,.73)],['Petrol','Petrol','Petrol','Petrol','PetrolShade','PetrolShade','Graphite','Graphite','Graphite','Graphite','Graphite'],32,.96)
    radial('Sculpted_intake_bevel_and_recessed_lip_'+side,x,z,[(-1.84,.74),(-1.84,.86),(-1.76,.988),(-1.65,1.075),(-1.60,1.04),(-1.70,.93),(-1.71,.745)],['PetrolShade','PetrolShade','Petrol','Petrol','Graphite','Graphite','Steel'],40)
    radial('Intake_inner_secondary_step_'+side,x,z,[(-1.78,.735),(-1.63,.748),(-1.51,.69),(-1.54,.647),(-1.72,.68)],['Graphite','Steel','Graphite','Graphite','Graphite'],40)
    for label,y,r0,r1 in [('Fore',-1.48,1.174,1.224),('Aft',-.27,1.223,1.165)]:
        thickness=.025 if label=='Fore' else .035
        radial('Ochre_'+label+'_maintenance_band_'+side,x,z,[(y-.075,r0),(y+.095,r1),(y+.12,r1-thickness),(y-.09,r0-thickness)],['Ochre']*4,32,.96)
    # Throat tapers to a recessed backplate rather than a flat painted opening.
    radial('Intake_inner_throat_'+side,x,z,[(-1.69,.70),(-1.37,.69),(-.52,.47),(-.44,.03),(-.49,.03),(-.61,.42),(-1.40,.61),(-1.69,.64)],['Steel']+['Graphite']*7,32)
    radial('Forward_cowl_structural_clamp_'+side,x,z,[(-.12,1.135),(.04,1.17),(.27,1.17),(.34,1.09),(.30,.955),(-.12,.985)],['PetrolShade','PetrolShade','Steel','Graphite','Graphite','Graphite'],32,.95)
    cowl(side,x,z)
    radial('Aft_structural_collar_'+side,x,z,[(2.42,.94),(2.56,1.04),(2.81,1.06),(2.96,.96),(2.91,.87),(2.5,.85)],['Graphite','Graphite','Ochre','Steel','Graphite','Graphite'],40)
    radial('Hot_nozzle_'+side,x,z,[(2.85,.86),(3.20,.85),(3.57,.77),(3.65,.65),(3.55,.57),(3.18,.47),(3.10,.06),(3.06,.06),(3.06,.74)],['Steel','PetrolShade','Steel','Steel','WarmCore','Graphite','Graphite','Graphite','Graphite'],32)
    # Six deliberately unequal lobes: broad short upper shingles and projecting
    # lower petals expose the warm recessed throat, like the rear concept.
    for i,deg in enumerate((30,90,150,210,270,330)):
        a=math.radians(deg); lower=math.sin(a)<-.1
        end=4.10 if deg==270 else 3.96 if lower else 3.62 if deg==90 else 3.76
        width=.38 if lower else .40; vs=[]
        for y,r,hw in [(2.94,.91,width),(end-.22,1.015 if lower else .96,width),(end,.99 if lower else .91,width*.84)]:
            for angle in (a-hw,a+hw):vs.append((x+r*math.cos(angle),y,z+r*math.sin(angle)))
        vs += [(x+(xx-x)*.86,y,z+(zz-z)*.86) for xx,y,zz in vs[:]]
        fs=[(0,1,3,2),(2,3,5,4),(6,8,9,7),(8,10,11,9),(0,6,7,1),(4,5,11,10),(0,2,4,10,8,6),(1,7,9,11,5,3)]
        mesh('Staggered_nozzle_petal_'+side+'_'+str(i),vs,fs,'PetrolShade',bevel=.018)
    # Structural bridge smoothly joins intake pod and fuselage with a vent at its bow.
    xy=[(s*.72,-1.62),(s*1.62,-1.44),(s*2.20,-.95),(s*2.16,2.50),(s*1.25,3.26),(s*.86,2.62)]
    prism('Shoulder_bridge_'+side,xy,[1.45,1.65,1.75,1.82,1.50,1.50],[3.02,3.18,3.05,2.91,2.55,2.58],'Petrol',.045)
    fair=loft('Raised_intake_fairing_'+side,[(-1.36,.54,2.54,3.34),(-1.04,.62,2.50,3.58),(.42,.64,2.49,3.43),(1.66,.46,2.45,3.10)],'Petrol',.038,lambda j,i:'Ochre' if j==0 and i==4 else 'Petrol')
    for vert in fair.data.vertices:vert.co.x+=s*1.39
    # Integrated forward vent is built into the bridging armor, backed and rimmed.
    v=[(s*1.01,-1.385,2.85),(s*1.77,-1.385,2.85),(s*1.76,-1.385,3.23),(s*1.02,-1.385,3.23)]
    vs=v+[(xx,yy+.09,zz) for xx,yy,zz in v]
    mesh('Vent_recess_'+side,vs,[(0,1,2,3),(4,7,6,5),(0,4,5,1),(1,5,6,2),(2,6,7,3),(3,7,4,0)],'Graphite')
    for i in range(4):
        u=(i+1)/5;px=s*(1.01+.76*u);py=-1.38
        beam('Vent_louver_'+side+str(i),(px,py,2.87),(px+s*.03,py+.005,3.21),.027,'Steel',6)
    # Long upper strake overlaps the cowl/bridge seam instead of decorative blocks.
    prism('Dorsal_engine_strake_'+side,[(s*1.50,.25),(s*1.79,.55),(s*1.78,2.99),(s*1.46,3.50),(s*1.25,3.32)],[2.69,2.69,2.52,2.42,2.46],[3.09,3.14,2.89,2.71,2.75],'Ivory',.025)
    # Cowl lock tangs bridge the interrupted circumferential dark collar.
    prism('Cowl_lock_tang_'+side,[(x-.17,-.18),(x+.17,-.18),(x+.23,.47),(x-.23,.47)],3.15,[3.40,3.40,3.36,3.36],'Petrol',.025)
    prism('Cowl_lock_marker_'+side,[(x-.18,-.13),(x+.18,-.13),(x+.18,.06),(x-.18,.06)],3.32,3.44,'Ochre',.02)
    # A loadbearing faceted side beam keys cowl, wing root and aft nozzle together.
    prism('Outer_pod_longitudinal_spine_'+side,[(s*3.10,-1.46),(s*3.53,-1.01),(s*3.70,.12),(s*3.64,1.72),(s*3.38,2.92),(s*3.01,3.33),(s*2.96,2.35),(s*3.13,.85)],
          [1.22,1.28,1.31,1.29,1.25,1.37,1.40,1.28],[1.70,2.26,2.45,2.32,2.09,1.76,2.02,2.20],'Petrol',.035)
    # Angular shoe under the round intake gives the housing a constructed lower contour.
    prism('Inlet_lower_skid_casing_'+side,[(x-.50,-1.94),(x+.50,-1.94),(x+.88,-1.51),(x+.93,-.48),(x-.93,-.48),(x-.88,-1.51)],
          [1.09,1.09,1.02,1.04,1.04,1.02],[1.20,1.20,1.45,1.48,1.48,1.45],'PetrolShade',.027)
    # Pale wingroot saddle overlaps, rather than merely touching, the dark side beam.
    prism('Wing_root_saddle_'+side,[(s*3.35,.55),(s*3.77,.77),(s*3.84,1.66),(s*3.66,2.12),(s*3.29,1.95)],
          [1.66,1.66,1.63,1.64,1.68],[1.99,2.09,2.03,1.88,1.97],'Ivory',.03)
    # User-requested primary proportion correction, all dimensions inferred:
    # radius .78, length .90; centres move inward9.3% and down.12m. Transform
    # the connected pod, saddles and fairings together; do not leave full-size
    # collars or free-floating parts around a scaled pressure cylinder.
    for ob in OBJECTS[assembly_start:]:
        for v in ob.data.vertices:
            v.co.x=s*2.24+(v.co.x-x)*.78
            v.co.y=1.0+(v.co.y-1.0)*.90
            v.co.z=2.10+(v.co.z-z)*.78
        for md in ob.modifiers:
            if md.type=='BEVEL':md.width*=.78
    wing(side,s)

def gear():
    for side,s in [('L',-1),('R',1)]:
        prism('Rear_gear_mount_'+side,[(s*1.65,1.10),(s*2.22,1.10),(s*2.22,2.10),(s*1.65,2.10)],1.03,1.48,'PetrolShade',.04)
        beam('Rear_gear_oleo_'+side,(s*1.97,1.7,1.18),(s*2.13,1.86,.24),.115,'Steel')
        beam('Rear_gear_brace_'+side,(s*1.65,1.13,1.25),(s*2.13,1.86,.30),.09,'Graphite')
        prism('Rear_gear_pad_'+side,[(s*1.72,1.35),(s*2.50,1.35),(s*2.50,2.27),(s*1.72,2.27)],0,.24,'Graphite',.06)
    beam('Nose_gear_oleo',(0,-3.75,1.15),(0,-3.52,.22),.10,'Steel')
    beam('Nose_gear_brace',(0,-3.06,1.15),(0,-3.52,.27),.075,'Graphite')
    prism('Nose_gear_pad',[(-.34,-3.97),(.34,-3.97),(.34,-3.05),(-.34,-3.05)],0,.23,'Graphite',.05)

loft('Continuous_fuselage',[(-4.6,.46,1.04,1.4),(-2.60,1.05,1.15,1.60),(-1.25,1.22,1.15,2.64),(.50,1.32,1.24,2.64),(2.65,1.17,1.18,2.55),(3.65,.85,1.30,2.08),(3.90,.66,1.40,1.89)],bevel=.045,paint=lambda j,i:'Ivory' if i==4 and j<3 else 'PetrolShade' if i in (0,1,7) else 'Petrol')
canopy()
for side,s in [('L',-1),('R',1)]:
    engine(side,s)
    # Deep longitudinal fuselage chine flowing from canopy to aft structure.
    prism('Longitudinal_chine_'+side,[(s*.72,-3.0),(s*1.25,-1.72),(s*1.39,2.70),(s*.78,3.95),(s*.52,3.70),(s*.90,1.50)],1.20,[1.56,1.75,1.85,1.70,1.55,1.52],'PetrolShade',.026)
    rail=loft('Paired_rear_armored_rail_'+side,[(.14,.22,2.44,2.86),(.69,.32,2.42,3.00),(2.30,.34,2.26,2.91),(3.45,.28,1.87,2.45),(4.02,.23,1.65,2.16)],'Petrol',.025)
    for vert in rail.data.vertices:vert.co.x+=s*.75
    keel_yz=[(1.5,1.29),(3.48,1.53),(4.15,1.29),(3.95,.96),(2.72,.87)]
    vv=[(s*(.88+layer*.14),y,z) for layer in (0,1) for y,z in keel_yz]
    mesh('Aft_tapered_keel_fin_'+side,vv,[(4,3,2,1,0),(5,6,7,8,9)]+[(i,(i+1)%5,(i+1)%5+5,i+5) for i in range(5)],'PetrolShade',bevel=.018)
prism('Rear_center_ivory_arrow',[(-.24,1.85),(.24,1.85),(.21,3.18),(.11,3.85),(-.11,3.85),(-.21,3.18)],
      [2.41,2.41,2.09,1.84,1.84,2.09],[2.68,2.68,2.38,2.03,2.03,2.38],'Ivory',.016)
# Integrated cannon saddle and tapered receiver, long forward barrel.
loft('Gun_saddle',[(-.62,.38,2.51,2.92),(.15,.53,2.53,3.18),(1.70,.49,2.49,3.16),(2.36,.34,2.47,2.85)],'PetrolShade',.04)
loft('Dorsal_cannon_receiver',[(-.58,.24,3.07,3.45),(-.28,.34,3.03,3.63),(1.70,.34,3.05,3.62),(2.04,.24,3.08,3.42)],'Petrol',.035,lambda j,i:'Ivory' if i==4 else 'Petrol')
beam('Heavy_cannon_barrel',(0,-.53,3.34),(0,-2.67,3.34),.145,'Steel',20)
for k,y in enumerate([-.70,-1.14,-2.34]):beam('Barrel_reinforcement_'+str(k),(0,y-.08,3.34),(0,y+.10,3.34),.19 if k<2 else .18,'Graphite',20)
radial('Open_gun_muzzle',0,3.34,[(-2.77,.17),(-2.60,.18),(-2.58,.105),(-2.77,.105)],['Steel','Steel','Graphite','Graphite'],24)
prism('Gun_ochre_breech',[(-.345,.97),(-.345,1.42),(-.21,1.42),(-.21,.97)],3.36,3.58,'Ochre',.018)
gear()

# Normalize entire evaluated geometry, including gear, using base geometry matrix.
bpy.context.view_layer.update()
pts=[ob.matrix_world@Vector(c) for ob in OBJECTS for c in ob.bound_box]
mn=Vector(tuple(min(v[i] for v in pts) for i in range(3)));mx=Vector(tuple(max(v[i] for v in pts) for i in range(3)))
fac=11/(mx.y-mn.y);shift=Vector(((mn.x+mx.x)/2,(mn.y+mx.y)/2,mn.z))
for ob in OBJECTS:
    for v in ob.data.vertices:v.co=(v.co-shift)*fac
    for md in ob.modifiers:
        if md.type=='BEVEL':md.width*=fac
# Real UVs: islands packed for later painting; constant PBR roles do not depend on UVs.
bpy.ops.object.select_all(action='DESELECT')
for ob in OBJECTS:ob.select_set(True)
bpy.context.view_layer.objects.active=OBJECTS[0]
bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.1519,island_margin=.02);bpy.ops.object.mode_set(mode='OBJECT')

SC.render.engine='CYCLES';SC.cycles.samples=24;SC.cycles.use_denoising=True
SC.render.resolution_x=1440;SC.render.resolution_y=1080;SC.render.resolution_percentage=100
SC.render.image_settings.file_format='PNG';SC.render.film_transparent=True
SC.view_settings.view_transform='AgX';SC.view_settings.look='AgX - Medium High Contrast';SC.view_settings.exposure=-.65
world=bpy.data.worlds.new('Warm_neutral_review_world');world.use_nodes=True;world.node_tree.nodes.get('Background').inputs[0].default_value=(.56,.64,.72,1);world.node_tree.nodes.get('Background').inputs[1].default_value=.45;SC.world=world
def light(name,pos,energy,size,col):
    d=bpy.data.lights.new(name,'AREA');d.energy=energy;d.shape='DISK';d.size=size;d.color=col;o=bpy.data.objects.new(name,d);STAGE.objects.link(o);o.location=pos;o.rotation_euler=(Vector((0,0,1.8))-o.location).to_track_quat('-Z','Y').to_euler()
light('Key',(-6,-8,13),1800,9,(1,.90,.75));light('Fill',(8,-2,8),1100,8,(.78,.87,1));light('Rim',(2,9,12),1900,7,(1,.92,.79))
ca=bpy.data.cameras.new('ReviewCamera');cam=bpy.data.objects.new('ReviewCamera',ca);STAGE.objects.link(cam);SC.camera=cam;ca.type='ORTHO';ca.ortho_scale=14
def render(view):
    dirs={'front':(-22,-17,21),'rear':(-22,17,21),'side':(24,0,7),'top':(0,0,30),'game':(-22,-17,26),'wire':(-22,-17,21),'random':(-22,-17,21)}
    cam.location=Vector(dirs[view]);target=Vector((0,0,2));cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    ca.ortho_scale=16.2 if view!='top' else 17.1
    SC.render.filepath=str(ITER/(view+'.png'));bpy.ops.render.render(write_still=True)

blend=ITER/'buccaneer_master.blend';bpy.ops.wm.save_as_mainfile(filepath=str(blend))
bpy.ops.object.select_all(action='DESELECT')
for ob in OBJECTS:ob.select_set(True)
export=OUT/'buccaneer_01.glb';bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_extras=True,export_animations=False)
stats={'iteration':args.iteration,'normalization':fac,'blend':str(blend),'glb':str(export),'meshes':len(OBJECTS),'materials':list(MATS),'triangles':0,'parts':{}}
dg=bpy.context.evaluated_depsgraph_get()
for ob in OBJECTS:
    eo=ob.evaluated_get(dg);me=eo.to_mesh();me.calc_loop_triangles();stats['parts'][ob.name]={'triangles':len(me.loop_triangles)};stats['triangles']+=len(me.loop_triangles);eo.to_mesh_clear()
(ITER/'build_stats.json').write_text(json.dumps(stats,indent=2),encoding='utf8')
for view in args.views.split(','):
    if view:render(view)
if args.qa:
    sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check
    qa=qa_check.run(objects=[ob.name for ob in OBJECTS],profile='game');(ITER/'source_qa.json').write_text(json.dumps(qa,indent=2),encoding='utf8');print('SOURCE_QA',qa['pass'],len(qa['errors']),len(qa['warnings']))
print('BUILD_COMPLETE',json.dumps({k:v for k,v in stats.items() if k!='parts'}))

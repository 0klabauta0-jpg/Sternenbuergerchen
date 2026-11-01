"""Original, reference-led Cutlass candidate. Blender 5.2 headless; no imported meshes.
Run blender -b --factory-startup -P build_cutlass.py -- --iteration 1
Dimensions are stylised and inferred from perspective concepts, not canonical SC dimensions.
"""
from pathlib import Path
import bpy, bmesh, math, json, sys, argparse, hashlib
from mathutils import Vector, Matrix

ART=Path(__file__).resolve().parents[1]
ROOT=ART.parents[5]
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass05_astra_ultra/refinement_03/cutlass_01.glb'
M={}; PARTS=[]

def mat(name,colour,rough=.65,metal=0,emission=None):
    m=bpy.data.materials.new('M_'+name); m.diffuse_color=(*colour,1)
    p=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    p.inputs['Base Color'].default_value=(*colour,1);p.inputs['Roughness'].default_value=rough;p.inputs['Metallic'].default_value=metal
    if emission: p.inputs['Emission Color'].default_value=(*emission,1);p.inputs['Emission Strength'].default_value=.35
    tex=ART/'textures'/(name+'_basecolor.png')
    if tex.exists():
        im=bpy.data.images.load(str(tex));im.colorspace_settings.name='sRGB';im.pack();node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;m.node_tree.links.new(node.outputs['Color'],p.inputs['Base Color'])
        im=bpy.data.images.load(str(ART/'textures/paint_roughness.png'),check_existing=True);im.colorspace_settings.name='Non-Color';im.pack();node=m.node_tree.nodes.new('ShaderNodeTexImage');node.image=im;m.node_tree.links.new(node.outputs['Color'],p.inputs['Roughness'])
    M[name]=m;return m

def mesh(name,verts,faces,material='Petrol',bevel=.035,smooth=False):
    me=bpy.data.meshes.new('VH_Cutlass_'+name);me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces))
    for e in bm.edges:
        if e.is_manifold:e.smooth=e.calc_face_angle()<.51
    bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new('VH_Cutlass_'+name,me);LOW.objects.link(ob);me.materials.append(M[material]);PARTS.append(ob)
    for p in me.polygons:p.use_smooth=material!='Glass' and not name.startswith(('Swept_ivory_cowl','Cowl_central_chin','Fork_rim'))
    if bevel:
        md=ob.modifiers.new('Construction_edge_radius','BEVEL');md.width=bevel;md.segments=2 if name in ('Cargo_hull','Cabin_ivory_monocoque') else 1;md.limit_method='ANGLE';md.angle_limit=.35;md.harden_normals=True
        md=ob.modifiers.new('Weighted_surface_normals','WEIGHTED_NORMAL');md.keep_sharp=True;md.weight=40
    md=ob.modifiers.new('Explicit_ngon_triangulation','TRIANGULATE');md.min_vertices=5
    return ob

def prism(name,points,z0,z1,material='Petrol',bevel=.035):
    n=len(points);zs=lambda z,i:z[i] if isinstance(z,(list,tuple)) else z
    vs=[(x,y,zs(z,i)) for z in (z0,z1) for i,(x,y) in enumerate(points)]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,material,bevel)

def polyvolume(name,points,normal,thick,material,bevel=.02):
    v=Vector(normal).normalized()*thick; n=len(points)
    vs=[tuple(Vector(p)-v) for p in points]+[tuple(p) for p in points]
    fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,material,min(bevel,abs(thick)*.20))

def box(name,loc,scale,material='Petrol',bevel=.035):
    x,y,z=loc; a,b,c=[v/2 for v in scale]
    return prism(name,[(x-a,y-b),(x+a,y-b),(x+a,y+b),(x-a,y+b)],z-c,z+c,material,bevel)

def loft(name,rings,material='Petrol',bevel=.035):
    n=len(rings[0]);vs=[p for ring in rings for p in ring];fs=[tuple(reversed(range(n))),tuple((len(rings)-1)*n+i for i in range(n))]
    for j in range(len(rings)-1):
        for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    return mesh(name,vs,fs,material,bevel)

def rect_ring(y,width,z0,z1,roof=.72,bottom=.82,ch=.18):
    return [(-width*roof,y,z1),(width*roof,y,z1),(width,y,z1-ch),(width,y,z0+ch),(width*bottom,y,z0),(-width*bottom,y,z0),(-width,y,z0+ch),(-width,y,z1-ch)]

def lathe(name,profile,center,material='Steel',segments=24,axis='Y',bevel=0):
    cx,cy,cz=center;vs=[]
    for along,r in profile:
        for i in range(segments):
            a=2*math.pi*i/segments
            if axis=='Y':vs.append((cx+r*math.cos(a),cy+along,cz+r*math.sin(a)))
            elif axis=='X':vs.append((cx+along,cy+r*math.cos(a),cz+r*math.sin(a)))
            else:vs.append((cx+r*math.cos(a),cy+r*math.sin(a),cz+along))
    n=segments;fs=[]
    for j in range(len(profile)-1):
        for i in range(n):fs.append((j*n+i,j*n+(i+1)%n,(j+1)*n+(i+1)%n,(j+1)*n+i))
    # Profiles are closed curves in radius/axis space for hollow tubes; solid cap tiny rings avoided.
    for i in range(n):fs.append(((len(profile)-1)*n+i,(len(profile)-1)*n+(i+1)%n,(i+1)%n,i))
    return mesh(name,vs,fs,material,bevel,True)

def cylinder_between(name,a,b,r,material='Steel',segments=12):
    va,vb=Vector(a),Vector(b);axis=(vb-va).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((1,0,0)))
    u.normalize();v=axis.cross(u).normalized();vs=[]
    for c in (va,vb):
        for i in range(segments):vs.append(tuple(c+r*(u*math.cos(2*math.pi*i/segments)+v*math.sin(2*math.pi*i/segments))))
    fs=[tuple(reversed(range(segments))),tuple(range(segments,segments*2))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    ob=mesh(name,vs,fs,material,min(.018,r*.12,(vb-va).length*.12),True)
    for p in ob.data.polygons:p.use_smooth=False
    return ob

def inset_face(name,points,material='Glass',margin=.10,offset=.02,thick=.05):
    p=[Vector(v) for v in points]; cen=sum(p,Vector())/len(p);n=(p[1]-p[0]).cross(p[2]-p[0]).normalized()
    # Face orientation independent; requested caller winding determines outward side.
    out=[]
    for v in p:
        d=cen-v;out.append(tuple(v+d.normalized()*margin+n*offset))
    return polyvolume(name,out,n,thick,material,.018)

def mirrored(points,s):return [(s*x,y) for x,y in points]

def build(iteration):
    global LOW
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc=bpy.context.scene;sc.unit_settings.system='METRIC';sc.unit_settings.scale_length=1
    LOW=bpy.data.collections.new('LOW');sc.collection.children.link(LOW)
    mat('Petrol',(.070,.105,.115),.68);mat('Ivory',(.76,.60,.37),.72);mat('Ochre',(.70,.31,.025),.62)
    mat('Dark',(.025,.035,.045),.72);mat('Steel',(.23,.24,.22),.42,1);mat('Glass',(.035,.08,.12),.27)
    mat('PetrolLight',(.105,.15,.16),.64);mat('Thrust',(.75,.19,.025),.45,0,(1,.20,.015))

    # Broad cargo shell with chamfered belly, sloped shoulders and a taper into the cabin.
    cargo=[(-3.3,1.35,1.52,3.30),(-2.2,2.45,1.26,3.48),(.0,2.85,1.15,3.50),(3.5,2.78,1.15,3.45),(5.75,2.58,1.30,3.25),(6.15,2.30,1.55,2.94)]
    loft('Cargo_hull',[rect_ring(y,w,lo,hi,.82,.77,.38) for y,w,lo,hi in cargo],bevel=.07)
    # Continuous ivory longitudinal ridge, fitted to the hull rather than a rectangular stripe.
    spine=[(-4.1,.75,2.8,3.78),(-2.0,.83,3.03,3.88),(1.9,.78,3.12,3.88),(4.8,.70,3.02,3.61),(6.16,.52,2.76,3.17)]
    loft('Ivory_dorsal_spine',[rect_ring(y,w,lo,hi,.78,.85,.20) for y,w,lo,hi in spine],'Ivory',.055)
    # Broad bridge nose with a near-vertical forward face and continuous descending roof.
    # Perspective-reference inference, deliberately larger than refinement01's pointed snout.
    cab=[(-8.05,.61,1.35,2.72),(-7.62,.79,1.35,3.26),(-6.55,1.03,1.54,3.95),(-5.35,1.10,1.80,4.20),(-4.35,1.07,2.00,4.16),(-3.18,.91,2.18,3.88)]
    cabinrings=[rect_ring(y,w,lo,hi,.62,.76,.26) for y,w,lo,hi in cab]
    cabin=loft('Cabin_ivory_monocoque',cabinrings,'Ivory',.055)
    def cabin_section(y):
        for a,b in zip(cab,cab[1:]):
            if a[0]<=y<=b[0]:
                f=(y-a[0])/(b[0]-a[0]);return [y]+[a[i]+f*(b[i]-a[i]) for i in range(1,4)]
        raise ValueError(y)
    # Connected broad side panes: their facets follow the bridge shell without a picket-fence band.
    for s in (-1,1):
        for label,sections in [('Main',[(-7.78,1.95),(-7.62,1.98),(-6.55,2.36),(-5.78,2.70)]),('Aft',[(-5.60,2.80),(-5.35,2.84),(-4.52,2.94)])]:
            rings=[]
            for y,bottom in sections:
                _,w,lo,hi=cabin_section(y);top=hi-.42;x=s*(w+.024)
                rings.append([(x,y,top),(x,y,bottom),(x-s*.10,y,bottom),(x-s*.10,y,top)])
            loft('Bridge_side_%s_%s'%(label,s),rings,'Glass',.008)
            # Main glazing wraps across the sloping upper cheek, separated by a narrow frame.
            rings=[]
            for y,bottom in sections:
                _,w,lo,hi=cabin_section(y)
                a=Vector((s*w*.62,y,hi));b=Vector((s*w,y,hi-.26));n=Vector((s*.26,0,w*.38)).normalized()
                p=a.lerp(b,.12)+n*.026;q=a.lerp(b,.90)+n*.026
                rings.append([tuple(p),tuple(q),tuple(q-n*.09),tuple(p-n*.09)])
            loft('Bridge_upper_cheek_%s_%s'%(label,s),rings,'Glass',.006)
    # Two substantial windscreen panels follow the sloping roof; split only at the main cross-frame.
    for label,ys in [('Forward',[-7.86,-7.62,-6.55,-6.05]),('Rear',[-5.85,-5.35,-4.65])]:
        rings=[]
        for y in ys:
            _,w,lo,hi=cabin_section(y);wx=w*.62-.13
            rings.append([(-wx,y,hi+.022),(wx,y,hi+.022),(wx,y,hi-.065),(-wx,y,hi-.065)])
        loft('Bridge_windscreen_'+label,rings,'Glass',.008)
    # Near-vertical forward windows are separated by a thick cream cross member.
    polyvolume('Bridge_front_window',[(.43,-8.069,2.00),(-.43,-8.069,2.00),(-.43,-8.069,2.51),(.43,-8.069,2.51)],(0,-1,0),.085,'Glass',.008)
    polyvolume('Nose_sensor',[(.33,-8.069,1.53),(-.33,-8.069,1.53),(-.33,-8.069,1.83),(.33,-8.069,1.83)],(0,-1,0),.085,'Glass',.008)
    box('Nose_lower_bumper',(0,-7.76,1.31),(1.12,.55,.24),'Dark',.055)

    # Cargo shoulder decks and long rising rails have distinct sweeps and fitted top surfaces.
    for s in (-1,1):
        tag='L' if s<0 else 'R'
        pts=mirrored([(.88,-2.65),(1.70,-2.3),(2.60,-1.20),(2.74,.12),(.91,.24)],s)
        prism('Shoulder_front_armor_'+tag,pts,[3.10]*5,[3.62+.069*(y+2.65)-.14*(abs(x)-.9) for x,y in pts],'PetrolLight',.06)
        pts=mirrored([(.91,.35),(2.71,.35),(2.76,2.82),(2.53,3.02),(.91,3.02)],s)
        prism('Shoulder_mid_armor_'+tag,pts,[3.10]*5,[3.83-.14*(abs(x)-.9) for x,y in pts],'PetrolLight',.06)
        pts=mirrored([(.91,3.14),(2.62,3.14),(2.55,4.90),(2.34,5.71),(.91,5.78)],s)
        prism('Shoulder_aft_armor_'+tag,pts,[3.05]*5,[3.75-.15*(abs(x)-.9)-.05*(y-3.14) for x,y in pts],'PetrolLight',.06)
        # Small inset service panel and short ochre band belong to one large armor panel.
        pts=mirrored([(1.20,.90),(2.35,.90),(2.43,2.15),(2.25,2.44),(1.20,2.44)],s)
        prism('Deck_service_'+tag,pts,3.63,3.79,'Petrol',.025)
        box('Deck_service_mark_'+tag,(s*1.8,.77,3.765),(1.05,.22,.09),'Ochre',.015)
        pts=mirrored([(1.0,-3.25),(1.18,-3.28),(2.76,.25),(2.84,4.15),(2.65,4.2),(2.56,.40)],s)
        prism('Raised_shoulder_rail_'+tag,pts,[3.0,3.0,3.25,3.08,3.08,3.25],[3.35,3.35,3.90,3.63,3.63,3.90],'Petrol',.04)
        # Front forks wrap the cabin with an open notch on either side.
        pts=mirrored([(.94,-5.58),(1.01,-3.35),(2.47,-1.10),(3.15,-2.06),(5.58,-3.87),(5.58,-5.86),(4.62,-6.13),(2.40,-5.76)],s)
        # Two large plane groups meet along a swept knuckle; outer tips taper to ~.30m thickness.
        tops=[];bottoms=[]
        for x,y in pts:
            hinge=2.4+.75*(y+5.76)/3.70;d=abs(x)-hinge
            z=2.68+.10*(y+4.8)-.025*(abs(x)-1)-(.06*d if d>0 else .10*d)
            tops.append(z);bottoms.append(z-(.70-.40*min(1,max(0,(abs(x)-1)/4.58))))
        n=len(pts);vs=[(x,y,zs[i]) for zs in (bottoms,tops) for i,(x,y) in enumerate(pts)]
        faces=[tuple(reversed(range(n))),tuple(n+i for i in (0,1,2,3,7)),tuple(n+i for i in (3,4,5,6,7))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
        mesh('Front_fork_'+tag,vs,faces,'PetrolLight',.045)
        # Front end plate, chamfered silhouette in side view.
        yz=[(-6.52,.62),(-6.58,3.32),(-6.35,3.51),(-3.08,3.32),(-2.89,3.12),(-2.97,1.91),(-3.82,1.74),(-5.78,.72)]
        outer=5.73*s;inner=5.42*s
        vs=[(x,y,z) for x in (inner,outer) for y,z in yz];n=len(yz)
        mesh('Front_endplate_'+tag,vs,[tuple(reversed(range(n))),tuple(range(n,2*n))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)],'Petrol',.045)
        # Matching low-key ochre tip mark and side reinforcement; genuinely attached.
        polyvolume('Endplate_badge_'+tag,[(outer+s*.018,-5.94,1.49),(outer+s*.018,-4.88,1.67),(outer+s*.018,-4.88,2.32),(outer+s*.018,-5.94,2.32)],(s,0,0),.055,'Ochre',.015)
        # Outer fitted reinforcement has the same swept lower edge, not a square stuck on the plate.
        polyvolume('Endplate_outer_panel_'+tag,[(outer+s*.045,-4.72,1.70),(outer+s*.045,-3.29,1.98),(outer+s*.045,-3.29,2.57),(outer+s*.045,-4.72,2.57)],(s,0,0),.11,'PetrolLight',.02)
        polyvolume('Fork_rim_'+tag,[(outer+s*.035,-6.40,3.28),(outer+s*.035,-3.19,3.10),(outer+s*.035,-3.19,3.22),(outer+s*.035,-6.40,3.40)],(s,0,0),.08,'PetrolLight',.012)
        box('Fork_tip_mark_'+tag,(s*5.60,-6.14,3.48),(.34,.42,.10),'Ochre',.013)
        # Long side recessed cargo closures, bounded by heavy structural uprights.
        for j,y in enumerate((-.30,1.50,3.30)):
            x=(2.83 if j<2 else 2.86)*s
            polyvolume('Cargo_side_inset_%s_%s'%(tag,j),[(x+s*.02,y-.57,1.55),(x+s*.02,y+.57,1.55),(x+s*.02,y+.57,2.97),(x+s*.02,y-.57,2.97)],(s,0,0),.24,'Dark',.035)
            box('Cargo_side_rib_%s_%s'%(tag,j),(x,y+.62,2.27),(.22,.23,1.52),'PetrolLight',.04)
        # Nacelle-to-hull saddle / trunnion; forms carry weight and show a genuine connection.
        prism('Engine_pylon_'+tag,mirrored([(2.25,2.0),(4.7,2.4),(4.7,4.65),(2.25,4.9)],s),2.07,2.87,'Petrol',.09)
        lathe('Trunnion_'+tag,[(-.34,.83),(.34,.83),(.37,.70),(-.37,.70)],(s*3.6,3.25,2.91),'Steel',24,'X')

        # Faceted main engine keel, with full curved cowl above and exposed rear machinery.
        x=s*4.67
        ers=[(.28,.62,1.62,2.74),(1.28,1.05,1.52,3.12),(2.5,1.22,1.55,3.47),(4.65,1.18,1.62,3.42),(5.47,1.02,1.74,3.15)]
        loft('Nacelle_keel_'+tag,[[(px+x,py,pz) for px,py,pz in rect_ring(y,w,lo,hi,.70,.70,.32)] for y,w,lo,hi in ers],'Petrol',.07)
        # The cowl is a closed shell with separate inner and outer sweep, editable cross-sections.
        profile=[(.44,.58,2.48,.50),(1.02,.94,2.55,1.05),(1.92,1.19,2.65,1.45),(3.25,1.26,2.65,1.59),(4.64,1.18,2.71,1.28),(4.98,1.09,2.76,1.02)]
        rings=[];angles=[math.radians(a) for a in (20,40,55,90,125,140,160)]
        for y,rx,zc,rz in profile:
            outerpoints=[(x+rx*math.cos(a),y,zc+rz*min(1.,math.sin(a)/.819152)) for a in angles]
            innerpoints=[(x+(rx-.11)*math.cos(a),y,zc+(rz-.13)*min(1.,math.sin(a)/.819152)) for a in reversed(angles)]
            rings.append(outerpoints+innerpoints)
        loft('Swept_ivory_cowl_'+tag,rings,'Ivory',.025)
        # Short shaped cheek panels, intake slots, and front lower mandibles.
        for flank in (-1,1):
            # Each jaw is a long oblique tapered volume that changes the front silhouette.
            sections=[(-.28,.52,.22,1.35,1.86),(.27,.76,.27,1.38,2.60),(1.30,.99,.28,1.58,3.15),(2.45,1.08,.22,1.76,3.30),(3.25,1.05,.19,1.92,3.25)]
            jaw=[]
            for y,cx,w,lo,hi in sections:
                jaw.append([(x+flank*cx+px,py,pz) for px,py,pz in rect_ring(y,w,lo,hi,.65,.8,.12)])
            loft('Cowl_oblique_jaw_%s_%s'%(tag,flank),jaw,'PetrolLight',.04)
            # Exposed side saddle is segmented behind the cheek, leaving the trunnion readable.
            side=x+flank*1.29
            polyvolume('Cowl_saddle_panel_%s_%s'%(tag,flank),[(side,2.92,1.92),(side,4.62,2.04),(side,4.62,2.88),(side,2.92,3.04)],(flank,0,0),.29,'Petrol',.035)
        loft('Cowl_central_chin_'+tag,[[(x+px,py,pz) for px,py,pz in rect_ring(y,w,lo,hi,.80,.78,.10)] for y,w,lo,hi in [(-.26,.38,1.40,1.84),(.35,.48,1.55,2.60),(1.10,.58,1.80,2.96)]],'Petrol',.045)
        # Conforming dark brow on the sloping ivory snout, echoing the target's inset service visor.
        def cp(y,a):
            q=(y-1.02)/.90;rx=.94+q*.25;zc=2.55+q*.10;rz=1.05+q*.40
            return (x+(rx+.018)*math.cos(a),y,zc+(rz+.025))
        polyvolume('Cowl_service_visor_'+tag,[cp(1.10,math.radians(61)),cp(1.10,math.radians(119)),cp(1.40,math.radians(119)),cp(1.40,math.radians(61))],(0,-.48,.88),.07,'Glass',.006)
        polyvolume('Cowl_front_intake_'+tag,[(x-.40,.20,2.40),(x+.40,.20,2.40),(x+.35,.41,2.73),(x-.35,.41,2.73)],(0,-1,.2),.20,'Dark',.018)
        polyvolume('Nacelle_front_mark_'+tag,[(x-.18,-.22,1.94),(x+.18,-.22,1.94),(x+.20,.27,2.54),(x-.20,.27,2.54)],(0,-.78,.63),.12,'Ochre',.012)
        # Exposed engine barrel and thick machined nozzle, recessed throat not flat discs.
        lathe('Engine_core_'+tag,[(4.65,.90),(6.40,1.02),(6.58,.92),(6.48,.75),(4.65,.70)],(x,0,2.69),'Steel',32)
        lathe('Engine_collar_'+tag,[(5.08,.96),(5.32,1.03),(5.48,1.03),(5.51,.91)],(x,0,2.69),'Dark',32)
        lathe('Ochre_nozzle_band_'+tag,[(6.23,1.01),(6.42,1.09),(6.64,1.09),(6.67,1.0)],(x,0,2.69),'Ochre',32)
        lathe('Nozzle_lip_'+tag,[(6.53,1.03),(6.62,1.08),(7.12,1.08),(7.22,1.12),(7.30,1.12),(7.30,.88),(7.20,.88),(6.65,.73)],(x,0,2.69),'Steel',32)
        lathe('Nozzle_throat_'+tag,[(6.41,.73),(6.98,.83),(6.98,.72),(6.43,.43),(6.30,.43),(6.30,.72)],(x,0,2.69),'Dark',32)
        # Emissive inner plug recessed by .65m; its rim makes the rear readable at distance.
        cylinder_between('Thrust_recess_'+tag,(x,6.25,2.69),(x,6.45,2.69),.51,'Thrust',24)
        # Four sparing longitudinal mechanical ribs on exposed barrel.
        for j,ang in enumerate((0,math.pi/2,math.pi,3*math.pi/2)):
            cx=x+.91*math.cos(ang);cz=2.69+.91*math.sin(ang)
            cylinder_between('Engine_rib_%s_%s'%(tag,j),(cx,4.70,cz),(cx,6.25,cz),.085,'Dark',8)
        # Front fork gun carries from the endplate underside, points forward.
        cylinder_between('Fork_gun_'+tag,(s*5.58,-4.0,1.37),(s*5.58,-6.83,1.37),.095,'Steel',12)
        box('Fork_gun_mount_'+tag,(s*5.58,-4.60,1.43),(.24,.65,.34),'Dark',.035)

    # Closed cargo ramp on the rear bulkhead, visibly separate construction with hinges.
    ramp=[(-1.95,6.19,1.65),(1.95,6.19,1.65),(2.18,6.19,2.77),(-2.18,6.19,2.77)]
    polyvolume('Rear_ramp_outer_frame',ramp,(0,1,0),.23,'Dark',.05)
    inset_face('Rear_ramp_door',list(reversed(ramp)),'PetrolLight',.22,.06,.12)
    for s in (-1,1):
        polyvolume('Rear_ramp_border_'+str(s),[(s*1.85,6.265,1.67),(s*2.07,6.265,2.70),(s*1.85,6.265,2.7),(s*1.65,6.265,1.67)],(0,1,0),.08,'Ochre',.015)
        cylinder_between('Ramp_hinge_'+str(s),(s*1.3-.30,6.24,1.56),(s*1.3+.30,6.24,1.56),.13,'Steel',12)

    # Manned angular turret: enlarged ring, seated torso volume, full-height armored cheeks.
    lathe('Turret_pedestal',[(0,.99),(.27,.99),(.27,.83),(0,.83)],(0,-1.93,3.80),'Steel',32,'Z')
    turret=[rect_ring(-3.13,.73,4.00,4.65,.66,.9,.14),rect_ring(-2.55,1.00,4.00,5.48,.75,.88,.18),rect_ring(-1.27,1.00,4.00,5.48,.75,.88,.18),rect_ring(-.78,.86,4.06,5.25,.75,.88,.18)]
    loft('Turret_housing',turret,'Petrol',.035)
    # Rear cream crown frames rather than conceals the cabin's operator-scale silhouette.
    loft('Turret_ivory_cap',[rect_ring(-1.70,1.01,5.18,5.52,.76,.92,.14),rect_ring(-1.24,1.01,5.18,5.52,.76,.92,.14),rect_ring(-.77,.87,5.02,5.29,.76,.92,.12)],'Ivory',.025)
    # Sloped broad windscreen plus upper side windows, fitted to actual armor planes.
    inset_face('Turret_forward_glass',[turret[0][0],turret[0][1],turret[1][1],turret[1][0]],'Glass',.13,.022,.08)
    for s in (-1,1):
        polyvolume('Turret_side_glass_'+str(s),[(s*1.025,-2.42,4.78),(s*1.025,-1.85,4.78),(s*1.025,-1.85,5.20),(s*1.025,-2.42,5.20)],(s,0,0),.085,'Glass',.012)
    for s in (-1,1):
        cylinder_between('Turret_barrel_'+str(s),(s*1.20,-2.25,4.65),(s*1.20,-4.80,4.65),.105,'Steel',16)
        cylinder_between('Turret_sleeve_'+str(s),(s*1.20,-1.83,4.65),(s*1.20,-3.30,4.65),.19,'Dark',16)
        box('Turret_trunnion_'+str(s),(s*1.05,-2.11,4.60),(.40,.78,.48),'PetrolLight',.045)

    # Load-bearing landing gear inferred because flight concepts don't expose deployed gear.
    for s in (-1,1):
        for j,(x,y) in enumerate(((4.70,-4.55),(2.24,3.64))):
            tag='%s_%s'%(s,j)
            top=(s*x,y,2.36 if j==0 else 1.62);knee=(s*(x+.16),y+.13,.18)
            cylinder_between('Landing_shock_'+tag,top,knee,.12,'Steel',12)
            cylinder_between('Landing_brace_'+tag,(s*(x-.35),y+.55,2.35 if j==0 else 1.55),knee,.095,'Dark',12)
            prism('Landing_foot_'+tag,mirrored([(x-.35,y-.55),(x+.52,y-.55),(x+.60,y+.36),(x-.28,y+.46)],s),0,.24,'Dark',.065)
            box('Landing_cuff_'+tag,(s*(x+.11),y+.12,.36),(.38,.38,.40),'PetrolLight',.045)

    # Sparse constructive fasteners and two fitted spine breaks; no random greeble field.
    for s in (-1,1):
        for j,(x,y) in enumerate(((1.3,1.08),(2.2,2.16))):
            cylinder_between('Deck_fastener_%s_%s'%(s,j),(s*x,y,3.755),(s*x,y,3.83),.045,'Steel',8)
        for j,y in enumerate((-5.65,-3.94)):
            cylinder_between('Fork_fastener_%s_%s'%(s,j),(s*5.71,y,2.80),(s*5.77,y,2.80),.045,'Steel',8)
    for j,y in enumerate((.25,3.02)):
        box('Spine_panel_break_'+str(j),(0,y,3.85 if j==0 else 3.77),(1.48,.065,.12),'Dark',.008)

    # Refinement03 is the user's new four-engine layout, not a claim of original-reference reconstruction.
    # Keep the accepted larger bridge/turret form. Rear axes stay fixed; radial engine size is reduced 13%.
    rear_prefixes=('Nacelle_keel','Swept_ivory_cowl','Cowl_','Nacelle_front_mark','Engine_core','Engine_collar','Ochre_nozzle_band','Nozzle_','Thrust_recess','Engine_rib')
    clone_prefixes=('Nacelle_keel','Swept_ivory_cowl','Cowl_central_chin','Cowl_front_intake','Nacelle_front_mark','Cowl_oblique_jaw','Cowl_service_visor','Engine_core','Engine_collar','Ochre_nozzle_band','Nozzle_lip','Nozzle_throat','Thrust_recess')
    rear_parts=[]
    for ob in list(PARTS):
        name=ob.name.removeprefix('VH_Cutlass_')
        if name.startswith(rear_prefixes):
            s=-1 if '_L' in name else 1
            for v in ob.data.vertices:
                v.co.x=s*4.67+(v.co.x-s*4.67)*.87;v.co.z=2.69+(v.co.z-2.69)*.87
            for md in ob.modifiers:
                if md.type=='BEVEL':md.width*=.87
            rear_parts.append(ob)
        elif name.startswith('Front_fork_'):
            for v in ob.data.vertices:
                s=-1 if v.co.x<0 else 1;v.co.x=s*(1+(abs(v.co.x)-1)*(2.95/4.58))
        elif name.startswith(('Front_endplate_','Endplate_','Fork_')):
            for v in ob.data.vertices:v.co.x-=math.copysign(1.63,v.co.x)
        elif name.startswith('Landing_') and name.endswith('_0'):
            for v in ob.data.vertices:v.co.x-=math.copysign(1.32,v.co.x)
    # New front pods are half the already reduced rear cross-section, with a shorter barrel.
    # Their axes sit .22m inside the rear axes, preserving the rear group's widest silhouette.
    for original in rear_parts:
        name=original.name.removeprefix('VH_Cutlass_')
        if not name.startswith(clone_prefixes):continue
        s=-1 if '_L' in name else 1
        ob=original.copy();ob.data=original.data.copy();ob.name='VH_Cutlass_Forepod_'+name;ob.data.name=ob.name;LOW.objects.link(ob);PARTS.append(ob)
        for v in ob.data.vertices:
            v.co.x=s*4.45+(v.co.x-s*4.67)*.50;v.co.y=-4.75+(v.co.y-3.51)*.43;v.co.z=2.60+(v.co.z-2.69)*.50
        for md in ob.modifiers:
            if md.type=='BEVEL':md.width*=.43
    # A compact horizontal saddle joins each new pod to its shortened wing and inside endplate.
    for s in (-1,1):
        prism('Forepod_mount_'+('L' if s<0 else 'R'),mirrored([(3.65,-5.25),(4.48,-5.14),(4.48,-3.85),(3.65,-3.72)],s),2.22,2.66,'Petrol',.04)

    # UVs: individually packed per construction component; original optional pigment textures.
    for ob in PARTS:
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(angle_limit=1.1519,island_margin=.03);bpy.ops.object.mode_set(mode='OBJECT')
    bpy.context.view_layer.update()
    # Normalize whole asset bbox exactly; retain identity transforms and a single ground pivot.
    pts=[o.matrix_world@v.co for o in PARTS for v in o.data.vertices];lo=Vector(tuple(min(p[k] for p in pts) for k in range(3)));hi=Vector(tuple(max(p[k] for p in pts) for k in range(3)))
    shift=Vector((-(lo.x+hi.x)/2,-(lo.y+hi.y)/2,-lo.z));scale=16/(hi.y-lo.y)
    for ob in PARTS:
        for v in ob.data.vertices:v.co=(v.co+shift)*scale
        for md in ob.modifiers:
            if md.type=='BEVEL':md.width*=scale
    bpy.context.view_layer.update()
    pts=[o.matrix_world@v.co for o in PARTS for v in o.data.vertices];lo=[min(p[k] for p in pts) for k in range(3)];hi=[max(p[k] for p in pts) for k in range(3)]
    out=ART/'source'/('iteration%02d'%iteration);out.mkdir(parents=True,exist_ok=True)
    # Packed originals available for inspection; hidden references never enter the export selection.
    refcol=bpy.data.collections.new('REF');sc.collection.children.link(refcol);refcol.hide_render=True;refcol.hide_viewport=True
    for name in ('08_cutlass_vorne_wimmel.png','09_cutlass_hinten_wimmel.png'):
        im=bpy.data.images.load(str(ROOT/'docs/reports/assets/grafik-2026-11-01'/name));im.pack()
        ref=bpy.data.objects.new('REF_'+name[:-4],None);ref.empty_display_type='IMAGE';ref.data=im;ref.hide_render=True;refcol.objects.link(ref)
    # Hidden, non-exported geometric clearance references; inference, not an ergonomic certification.
    for name,center,dims in [('Turret_clearance',(0,-1.94,4.68),(1.40,1.40,1.30)),('Seated_operator_envelope',(0,-1.94,4.68),(.62,1.13,1.24))]:
        ref=bpy.data.objects.new('REF_'+name,None);ref.empty_display_type='CUBE';ref.empty_display_size=.5;ref.location=(Vector(center)+shift)*scale;ref.scale=Vector(dims)*scale;ref.hide_render=True;refcol.objects.link(ref)
        ref['inferred_reference']='Stylized seated-operator proxy; not a canonical dimension or tested ergonomic specification.'
    metrics={'basis':'Explicit user-designed four-engine layout. This is a deliberate departure from original references 08/09.', 'normalization_factor':scale,'rear_radial_scale_from_refinement02':.87,'forepod_radial_scale_relative_to_new_rear':.50,'forepod_longitudinal_scale_relative_to_rear':.43,'rear_axis_x_authored':[-4.67,4.67],'front_axis_x_authored':[-4.45,4.45],'old_to_new_endplate_span_authored':[11.46,8.20],'cabin_and_turret_geometry':'unchanged from refinement02','turret_clearance_m':[1.40*scale,1.40*scale,1.30*scale],'seated_proxy_m':[.62*scale,1.13*scale,1.24*scale],'clearance_note':'Simple hidden wire envelopes inside upper cabin. The rotating ring opens into the dorsal spine; no interior or rig authored.'}
    (out/'proportion_metrics.json').write_text(json.dumps(metrics,indent=2),encoding='utf8')
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'cutlass_01.blend'))
    EXPORT.parent.mkdir(parents=True,exist_ok=True)
    bpy.ops.object.select_all(action='DESELECT')
    for o in PARTS:o.select_set(True)
    parts=out/'cutlass_parts.glb'
    bpy.ops.export_scene.gltf(filepath=str(parts),export_format='GLB',use_selection=True,export_apply=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False,export_extras=True)
    sys.path.insert(0,str(ART.parents[1]/'qa_tools'))
    from consolidate_glb import consolidate
    consolidate(parts,EXPORT)
    info={'iteration':iteration,'source':str(out/'cutlass_01.blend'),'glb':str(EXPORT),'objects':len(PARTS),'materials':len(M),'bbox_blender':{'min':lo,'max':hi,'dimensions':[hi[k]-lo[k] for k in range(3)]},'normalization_factor':scale,'normalization_shift_before_scale':list(shift),'source_authoring':'original lofted and extruded geometry; no external 3D imported','target_length_stylized_m':16,'runtime_scale_recommendation':.22,'axis':'Blender -Y forward -> glTF/Godot +Z forward','stage':'candidate; no user acceptance or native Godot validation'}
    (out/'build_manifest.json').write_text(json.dumps(info,indent=2),encoding='utf-8')
    print(json.dumps(info))

if __name__=='__main__':
    ap=argparse.ArgumentParser();ap.add_argument('--iteration',type=int,default=1);args=ap.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else[]);build(args.iteration)

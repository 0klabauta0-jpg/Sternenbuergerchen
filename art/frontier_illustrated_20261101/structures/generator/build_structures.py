"""Frontier structure family, pass 02: approved 03 + Rostgrenze/Freihafen.

Blender 5.2.3: blender -b --factory-startup -P build_structures.py -- [--preview]
Geometry is in metres. Front = Blender -Y, glTF/Godot +Z. No engine behavior.
"""
import bpy, bmesh, math, sys, json, hashlib, struct
from pathlib import Path
from mathutils import Vector, Matrix

ROOT=Path(__file__).resolve().parents[4]
ART=ROOT/'art/frontier_illustrated_20261101/structures'
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/structures'
MATS={}
PARTS=[]

def srgb(hexv):
    c=[int(hexv[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in c)+(1,)

def material(key,color,rough=.78):
    mat=bpy.data.materials.new('M_Frontier_'+key)
    mat.diffuse_color=srgb(color)
    bs=next(n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=srgb(color)
    bs.inputs['Roughness'].default_value=rough
    return mat

def reset():
    global MATS,PARTS
    bpy.ops.wm.read_factory_settings(use_empty=True);PARTS=[]
    bpy.context.scene.unit_settings.system='METRIC'
    MATS={k:material(k,c,r) for k,c,r in [('Cream','e0d9c9',.83),('PaleTrim','eee8da',.8),('SlateTeal','567374',.82),('DarkFrame','344447',.85),('Hardware','89918d',.78),('Ochre','df9744',.79),('Glass','395b63',.3),('Deck','aaa99b',.86),('Roof','b7bdb5',.88)]}

def mesh(name,verts,faces,mat,bevel=0):
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=bm.faces[:]);ng=[f for f in bm.faces if len(f.verts)>4]
    if ng:bmesh.ops.triangulate(bm,faces=ng)
    bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me);bpy.context.scene.collection.objects.link(ob);me.materials.append(MATS[mat])
    if bevel:
        mod=ob.modifiers.new('Soft_readable_edges','BEVEL');mod.width=bevel;mod.segments=2;mod.limit_method='ANGLE';mod.use_clamp_overlap=True;mod.harden_normals=True
    PARTS.append(ob);return ob

def box(name,center,size,mat='Cream',bevel=.035):
    x,y,z=center;a,b,c=(v/2 for v in size)
    verts=[(x+sx*a,y+sy*b,z+sz*c) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,verts,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,min(bevel,min(size)*.22))

def profile(name,points,y0,y1,mat='Cream',bevel=.025):
    # Closed X/Z outline extruded through depth.
    n=len(points);verts=[(x,y,z) for y in (y0,y1) for x,z in points]
    faces=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,verts,faces,mat,bevel)

def bar(name,a,b,radius,mat='Hardware',segments=12):
    a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized()
    verts=[tuple(p+radius*(u*math.cos(i*2*math.pi/segments)+v*math.sin(i*2*math.pi/segments))) for p in (a,b) for i in range(segments)]
    faces=[tuple(range(segments-1,-1,-1)),tuple(range(segments,segments*2))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,verts,faces,mat,.006 if radius>.04 else 0)

def path_pipe(name,points,radius,mat='Hardware'):
    for i,(a,b) in enumerate(zip(points,points[1:])):bar(name+'_%02d'%i,a,b,radius,mat)

def octagon(width,bottom,top,chamfer=.18):
    w=width/2;c=chamfer
    return [(-w+c,bottom),(w-c,bottom),(w,bottom+c),(w,top-c),(w-c,top),(-w+c,top),(-w,top-c),(-w,bottom+c)]

def ring(name,outer,inner,y0,y1,mat):
    n=len(outer)
    verts=[(x,y,z) for y,pts in [(y0,outer),(y0,inner),(y1,outer),(y1,inner)] for x,z in pts]
    faces=[]
    for i in range(n):
        j=(i+1)%n
        faces.extend([(i,j,n+j,n+i),(2*n+i,3*n+i,3*n+j,2*n+j),(i,2*n+i,2*n+j,j),(n+i,n+j,3*n+j,3*n+i)])
    mesh(name,verts,faces,mat,.018)

def front_window(name,cx,width,y=-2.365,z=1.7,height=1.05):
    box(name+'_Recess',(cx,y+.018,z),(width+.2,.075,height+.2),'DarkFrame',.04)
    box(name+'_Glazing',(cx,y-.035,z),(width,.035,height),'Glass',.025)
    for xx in (cx-width/2-.045,cx+width/2+.045):box(name+'_SideFrame',(xx,y-.055,z),(.09,.08,height-.10),'Hardware',.012)
    for zz in (z-height/2-.04,z+height/2+.04):box(name+'_Sill',(cx,y-.06,zz),(width+.18,.11,.08),'Hardware',.015)
    # A single substantial mullion; no texture-sized pane grids.
    bar(name+'_Mullion',(cx-.13,y-.075,z-height/2),(cx+.13,y-.075,z+height/2),.025,'DarkFrame',8)

def roof_panel(name,xz,y0,y1,mat='SlateTeal'):
    profile(name,xz,y0,y1,mat,.018)

def habitat():
    box('Habitat_GroundPlinth',(0,0,.16),(6.5,4.65,.32),'Hardware',.075)
    box('Habitat_RaisedFloor',(0,0,.46),(6.38,4.5,.34),'DarkFrame',.045)
    # Thick front wall assembled around actual window/door recesses.
    for sx in (-1,1):
        cx=sx*2.03
        box('Habitat_FrontLower',(cx,-2.22,.88),(2.45,.2,.56),'Cream')
        box('Habitat_FrontHeader',(cx,-2.22,2.66),(2.45,.2,.72),'Cream')
        for dx in (-1.12,1.12):box('Habitat_WindowJamb',(cx+dx,-2.22,1.72),(.2,.2,1.25),'PaleTrim',.025)
        front_window('Habitat_FrontWindow',cx,1.78,z=1.72,height=1.05)
        box('Habitat_CornerPost',(sx*3.15,-2.14,1.82),(.28,.34,2.52),'PaleTrim',.045)
    box('Habitat_DoorLintel',(0,-2.22,2.84),(1.7,.26,.37),'Cream')
    # Side wall module with two large openings on each side.
    for sx in (-1,1):
        box('Habitat_SideLower',(sx*3.1,0,.88),(.22,4.35,.56),'Cream')
        box('Habitat_SideHeader',(sx*3.1,0,2.66),(.22,4.35,.72),'Cream')
        for y in (-2.08,0,2.08):box('Habitat_SideJamb',(sx*3.1,y,1.73),(.23,.23,1.25),'PaleTrim',.025)
        for y in (-1.03,1.03):
            box('Habitat_SideWindow',(sx*3.22,y,1.72),(.06,1.8,1.16),'Glass',.025)
            for yy in (y-.92,y+.92):box('Habitat_SideWindowFrame',(sx*3.25,yy,1.72),(.08,.1,1.08),'Hardware',.012)
            for z in (1.11,2.33):box('Habitat_SideWindowSill',(sx*3.25,y,z),(.08,1.94,.1),'Hardware',.012)
    box('Habitat_RearWall',(0,2.15,1.83),(6.25,.25,2.46),'Cream')
    for sx in (-1,1):box('Habitat_RearCorner',(sx*3.1,2.16,1.81),(.3,.32,2.56),'PaleTrim',.04)
    outer=octagon(2.0,.56,2.99,.25);inner=octagon(1.36,.61,2.72,.16)
    ring('Habitat_AirlockOuter',outer,inner,-2.68,-2.15,'PaleTrim')
    ring('Habitat_AirlockSeal',octagon(1.38,.605,2.74,.17),octagon(1.2,.68,2.65,.16),-2.7,-2.35,'SlateTeal')
    profile('Habitat_AirlockDoor',octagon(1.19,.68,2.65,.16),-2.51,-2.36,'DarkFrame',.035)
    box('Habitat_DoorInset',(0,-2.555,1.62),(.87,.07,1.43),'Hardware',.045)
    box('Habitat_DoorSeam',(0,-2.60,1.62),(.035,.04,1.35),'DarkFrame',.006)
    for x in (-.19,.19):bar('Habitat_DoorHandle',(x,-2.66,1.36),(x,-2.66,1.85),.033,'Ochre')
    # Chamfered roof shell and three wide slate panel bays.
    profile('Habitat_RoofShell',[(-3.34,2.94),(-3.34,3.18),(-2.62,3.91),(2.62,3.91),(3.34,3.18),(3.34,2.94)],-2.4,2.4,'PaleTrim',.06)
    for i,(a,b) in enumerate([(-2.23,-.82),(-.72,.72),(.82,2.23)]):
        box('Habitat_TopPanel_%d'%i,(0,(a+b)/2,3.94),(5.15,b-a,.075),'SlateTeal',.025)
        for sx in (-1,1):
            pts=[(sx*2.65,3.93),(sx*3.30,3.27),(sx*3.30,3.19),(sx*2.65,3.85)]
            roof_panel('Habitat_SlopedPanel_%d'%i,pts,a,b)
    bar('Habitat_VentBase',(1.35,.55,3.98),(1.35,.55,4.17),.58,'DarkFrame',24)
    bar('Habitat_VentRim',(1.35,.55,4.13),(1.35,.55,4.29),.52,'PaleTrim',24)
    bar('Habitat_VentInner',(1.35,.55,4.285),(1.35,.55,4.31),.42,'SlateTeal',24)
    for y in (-.23,0,.23):box('Habitat_VentSlat',(1.35,.55+y,4.325),(.72,.06,.05),'Hardware',.008)
    # Landing and supported block stair risers, 0.15m rise.
    box('Habitat_EntryLanding',(0,-2.9,.3),(1.85,.95,.60),'Hardware',.04)
    for i,top in enumerate((.45,.30,.15)):
        y=-3.525-i*.3
        box('Habitat_Stair_%d'%i,(0,y,top/2),(1.85,.32,top),'Hardware',.022)
        box('Habitat_Tread_%d'%i,(0,y,top+.012),(1.79,.27,.025),'PaleTrim',.007)
    for x in (-.94,.94):
        for y,base in [(-2.65,.58),(-3.3,.58),(-4.10,.15)]:bar('Habitat_RailPost',(x,y,base),(x,y,base+.85),.027,'Ochre',10)
        path_pipe('Habitat_Handrail',[(x,-2.61,1.43),(x,-3.3,1.43),(x,-4.13,1.0)],.029,'Ochre')
    box('Habitat_ServicePanel',(-2.5,2.31,1.45),(1.0,.12,1.2),'DarkFrame',.03)
    for z in (1.09,1.27,1.45,1.63,1.81):box('Habitat_ServiceLouvre',(-2.5,2.40,z),(.82,.12,.08),'Hardware',.01)
    path_pipe('Habitat_UtilityPipe',[(2.8,2.32,.5),(2.8,2.32,2.8),(2.25,2.32,3.13)],.075,'SlateTeal')

def workshop():
    box('Workshop_GroundPlinth',(0,0,.125),(6.95,5.4,.25),'Hardware',.06)
    box('Workshop_Deck',(0,-.05,.285),(6.65,5.1,.13),'Deck',.025)
    for sx in (-1,1):
        for i,(ya,yb) in enumerate([(-2.58,-.9),(-.86,.86),(.9,2.58)]):
            box('Workshop_WallPanel_%d'%i,(sx*3.23,(ya+yb)/2,1.63),(.23,yb-ya,2.58),'Cream',.04)
        for y in (-2.6,-.88,.88,2.6):box('Workshop_SideRib',(sx*3.27,y,1.64),(.34,.18,2.63),'PaleTrim',.025)
        box('Workshop_SideWindow',(sx*3.37,1.6,1.85),(.08,.65,.93),'DarkFrame',.03)
        box('Workshop_SideWindowGlass',(sx*3.42,1.6,1.85),(.035,.47,.73),'Glass',.012)
    box('Workshop_RearWall',(0,2.58,1.63),(6.5,.24,2.58),'Cream',.04)
    profile('Workshop_RearUpperPanel',[(-3.02,2.88),(-2.45,3.82),(2.45,3.82),(3.02,2.88)],2.43,2.66,'Cream',.025)
    # Portal frame uses thick closed section segments, not a front wall.
    outer=[(-3.52,.25),(-3.52,2.92),(-2.77,4.17),(2.77,4.17),(3.52,2.92),(3.52,.25)]
    inner=[(-3.08,.25),(-3.08,2.80),(-2.48,3.73),(2.48,3.73),(3.08,2.80),(3.08,.25)]
    for y in (-2.62,2.42):profile('Workshop_PortalFrame',outer+list(reversed(inner)),y,y+.26,'PaleTrim',.04)
    box('Workshop_RoofCore',(0,0,4.02),(5.5,5.0,.28),'PaleTrim',.035)
    for sx in (-1,1):
        profile('Workshop_RoofShoulder',[(sx*2.57,4.04),(sx*2.78,4.16),(sx*3.53,2.94),(sx*3.27,2.86)],-2.34,2.40,'PaleTrim',.035)
    for i,(a,b) in enumerate([(-2.35,-.88),(-.77,.77),(.88,2.35)]):
        box('Workshop_TopPanel_%d'%i,(0,(a+b)/2,4.185),(5.12,b-a,.075),'SlateTeal',.025)
        for sx in (-1,1):roof_panel('Workshop_ShoulderPanel_%d'%i,[(sx*2.80,4.18),(sx*3.45,3.12),(sx*3.45,3.04),(sx*2.80,4.10)],a,b)
    # Supported lifting gantry; legs, beam, trolley, cable and readable hook.
    for x in (-2.72,2.72):box('Workshop_HoistColumn',(x,-1.65,1.7),(.17,.2,2.75),'Ochre',.022)
    box('Workshop_HoistBeam',(0,-1.65,3.16),(5.6,.24,.26),'Ochre',.026)
    box('Workshop_HoistRail',(0,-1.65,3.00),(5.42,.15,.07),'DarkFrame',.008)
    box('Workshop_HoistTrolley',(.82,-1.65,3.03),(.49,.36,.35),'Ochre',.035)
    bar('Workshop_HoistCable',(.82,-1.65,2.95),(.82,-1.65,2.14),.022,'DarkFrame',10)
    path_pipe('Workshop_HoistHook',[(.82,-1.65,2.17),(.82,-1.65,2.02),(.94,-1.65,1.94),(1.09,-1.65,2.04),(1.09,-1.65,2.17)],.04,'Ochre')
    # Actual bench with thick top, supported legs, drawer pedestal and large vise.
    box('Workshop_BenchTop',(-.72,.45,1.04),(2.5,1.15,.15),'PaleTrim',.045)
    for x in (-1.79,.35):
        for y in (.0,.9):box('Workshop_BenchLeg',(x,y,.68),(.13,.13,.7),'DarkFrame',.015)
    box('Workshop_BenchPedestal',(-1.26,.45,.68),(.78,.93,.68),'SlateTeal',.035)
    for z in (.49,.72,.94):
        box('Workshop_DrawerFace',(-1.26,-.038,z),(.68,.065,.16),'Hardware',.015)
        box('Workshop_DrawerHandle',(-1.26,-.095,z),(.27,.08,.035),'DarkFrame',.009)
    box('Workshop_ViseBase',(.01,.45,1.15),(.39,.4,.11),'DarkFrame',.022)
    for x in (-.13,.15):box('Workshop_ViseJaw',(x,.45,1.29),(.12,.4,.22),'Hardware',.015)
    bar('Workshop_ViseScrew',(-.31,.45,1.28),(.36,.45,1.28),.038,'DarkFrame')
    # Rear tool cabinet is grounded and supported, no decorative floaters.
    box('Workshop_ToolCabinet',(1.94,2.12,1.05),(1.35,.67,1.43),'SlateTeal',.05)
    for x in (1.61,2.27):box('Workshop_CabinetDoor',(x,1.755,1.1),(.59,.06,1.25),'Cream',.025)
    box('Workshop_CabinetHandle',(1.94,1.69,1.15),(.19,.07,.08),'Ochre',.015)
    for x in (-2.84,2.84):box('Workshop_EntryBumper',(x,-2.78,.7),(.32,.36,.75),'DarkFrame',.045)
    for x in (-2.8,2.8):box('Workshop_SafetyBand',(x,-2.975,.77),(.30,.03,.18),'Ochre',.005)

def tank_mesh():
    points=[(-1.8,0),(-1.79,.37),(-1.64,.68),(-1.38,.88),(-1.2,.92),(1.2,.92),(1.38,.88),(1.64,.68),(1.79,.37),(1.8,0)]
    segments=24;verts=[]
    # Tiny nonzero end radii are avoided; explicit axis vertices close the caps.
    verts.append((-1.4,.40,1.40))
    for x,r in points[1:-1]:
        for i in range(segments):
            a=2*math.pi*i/segments;verts.append((x+.4,.40+math.sin(a)*r,1.40+math.cos(a)*r))
    end=len(verts);verts.append((2.2,.40,1.40));faces=[]
    for i in range(segments):faces.append((0,1+i,1+(i+1)%segments))
    for j in range(len(points)-3):
        a=1+j*segments;b=a+segments
        for i in range(segments):faces.append((a+i,b+i,b+(i+1)%segments,a+(i+1)%segments))
    last=1+(len(points)-3)*segments
    for i in range(segments):faces.append((last+i,end,last+(i+1)%segments))
    return mesh('Service_TankShell',verts,faces,'Cream',0)

def service():
    box('Service_GroundPlinth',(0,0,.11),(4.85,3.2,.22),'Hardware',.065)
    tank_mesh()
    for x in (-.65,1.45):
        box('Service_TankSaddle',(x,.4,.405),(.32,1.58,.42),'DarkFrame',.055)
        for y in (-.35,1.15):box('Service_SaddleFoot',(x,y,.26),(.57,.4,.15),'Hardware',.025)
        # Circular retaining band, surrounding the shell with deliberate contact.
        seg=24
        for i in range(seg):
            a,b=i*2*math.pi/seg,(i+1)*2*math.pi/seg
            p=(x,.4+math.sin(a)*.925,1.4+math.cos(a)*.925);q=(x,.4+math.sin(b)*.925,1.4+math.cos(b)*.925)
            bar('Service_RetainingBand',p,q,.034,'SlateTeal',8)
    # Distinct broad centre saddle/panel belt, not many small mechanical bands.
    v=[(x,.4+math.sin(i*2*math.pi/24)*r,1.4+math.cos(i*2*math.pi/24)*r) for x,r in [(.18,.925),(.18,.97),(.62,.97),(.62,.925)] for i in range(24)]
    f=[(j*24+i,j*24+(i+1)%24,((j+1)%4)*24+(i+1)%24,((j+1)%4)*24+i) for j in range(4) for i in range(24)]
    mesh('Service_CentreBelt',v,f,'SlateTeal',0)
    # Pump cabinet sits on the same plinth and pipes visibly connect both systems.
    profile('Service_PumpHousing',[(-2.23,.23),(-1.24,.23),(-1.16,.4),(-1.16,1.64),(-1.30,1.80),(-2.12,1.80),(-2.25,1.65)],-1.32,-.55,'PaleTrim',.05)
    box('Service_PumpFront',(-1.72,-1.355,1.02),(.77,.08,1.2),'DarkFrame',.04)
    for z in (.64,.84,1.04,1.24,1.44):box('Service_Grille',(-1.72,-1.425,z),(.62,.09,.085),'Hardware',.012)
    box('Service_PumpTop',(-1.72,-.93,1.86),(.76,.63,.15),'SlateTeal',.035)
    box('Service_PumpSafetyBand',(-1.72,-1.405,1.63),(.72,.06,.14),'Ochre',.012)
    path_pipe('Service_FeedPipe',[(-1.6,.4,1.4),(-1.88,.4,1.4),(-1.88,-.36,1.4),(-1.72,-.60,1.4)],.085,'DarkFrame')
    path_pipe('Service_ReturnPipe',[(-1.28,-1.32,.56),(-.93,-1.32,.56),(-.93,-.68,.56),(.4,-.68,.56),(.4,-.45,1.11)],.07,'Hardware')
    bar('Service_ValveStem',(-.93,-.68,.56),(-.93,-.68,.82),.035,'Ochre')
    bar('Service_ValveHandle',(-1.12,-.68,.82),(-.74,-.68,.82),.037,'Ochre')
    path_pipe('Service_TankVent',[(1.25,.40,2.2),(1.25,.40,2.62)],.095,'Hardware')
    bar('Service_VentCap',(1.25,.4,2.59),(1.25,.4,2.71),.17,'DarkFrame',16)


def assign_material(ob,key):
    ob.data.materials.clear();ob.data.materials.append(MATS[key])


def pass02(asset):
    """Large readable changes only; additions stay inside the previous bounds."""
    if asset=='habitat_01':
        for ob in PARTS:
            if ob.name.startswith('Habitat_TopPanel'):assign_material(ob,'Roof')
        # A single continuous low orange band ties the whole kit together.
        for sx in (-1,1):
            box('Habitat_OrangeFrontBand',(sx*2.03,-2.329,.77),(2.39,.04,.16),'Ochre',.009)
            box('Habitat_OrangeSideBand',(sx*3.217,0,.77),(.04,4.26,.16),'Ochre',.009)
        box('Habitat_OrangeRearBand',(0,2.285,.77),(6.1,.04,.16),'Ochre',.009)
        for sx in (-1,1):
            box('Habitat_AirlockOrangeInset',(sx*.866,-2.692,1.58),(.10,.06,1.30),'Ochre',.015)
        box('Habitat_AirlockEyebrow',(0,-2.69,2.91),(1.31,.065,.095),'Ochre',.01)
    elif asset=='workshop_01':
        for ob in PARTS:
            if ob.name.startswith('Workshop_TopPanel'):assign_material(ob,'Roof')
            # Move the existing coherent workbench as a group, not loose props.
            if ob.name.startswith(('Workshop_Bench','Workshop_Drawer','Workshop_Vise')):
                ob.data.transform(Matrix.Translation(Vector((0,-1.45,0))))
        for sx in (-1,1):
            for ya,yb in [(-2.50,-.99),(-.78,.78),(.99,2.50)]:
                box('Workshop_OrangeWallBand',(sx*3.342,(ya+yb)/2,1.04),(.045,yb-ya,.18),'Ochre',.01)
        box('Workshop_OrangeRearBand',(0,2.708,1.04),(6.15,.04,.18),'Ochre',.01)
        box('Workshop_PortalEyebrow',(0,-2.625,3.99),(4.65,.06,.16),'Ochre',.012)
        # One supported storage rack with three large shelves and grouped cargo.
        for x in (1.35,2.55):
            for y in (-2.30,-1.30):
                box('Workshop_RackUpright',(x,y,1.46),(.12,.12,2.24),'Hardware',.016)
        for z in (.62,1.26,1.90):
            box('Workshop_RackShelf',(1.95,-1.80,z),(1.30,1.10,.10),'DarkFrame',.016)
        for x,z,color in [(1.66,.885,'Ochre'),(2.24,.885,'Cream'),(1.66,1.525,'Cream'),(2.24,1.525,'SlateTeal'),(1.95,2.165,'Ochre')]:
            box('Workshop_StoredCase',(x,-1.80,z),(.48,.72,.43),color,.035)
        # A broad front floor cue gives the open bay a useful visual threshold.
        for x in (-1.95,1.95):
            box('Workshop_BayFloorMark',(x,-2.20,.354),(.15,.60,.008),'Ochre',.001)
    else:
        for ob in PARTS:
            if ob.name.startswith('Service_CentreBelt'):assign_material(ob,'Ochre')
            if ob.name.startswith('Service_PumpTop'):assign_material(ob,'Roof')
        # Broad, connected service outlets; no disconnected decorative nozzles.
        for x in (-1.96,-1.50):
            bar('Service_OutputCollar',(x,-1.375,.47),(x,-1.49,.47),.10,'Ochre',12)
            bar('Service_OutputSocket',(x,-1.465,.47),(x,-1.575,.47),.065,'DarkFrame',12)

def bounds(obs):
    bpy.context.view_layer.update();pts=[o.matrix_world@Vector(c) for o in obs for c in o.bound_box]
    lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)))
    return lo,hi

def export_mesh(asset):
    # Collapse evaluated parts into one glTF mesh with one surface per palette
    # material. The .blend keeps the named, editable construction pieces.
    verts=[];faces=[];mids=[];matkeys=list(MATS);dg=bpy.context.evaluated_depsgraph_get()
    for ob in PARTS:
        ev=ob.evaluated_get(dg);me=ev.to_mesh();offset=len(verts)
        verts.extend(tuple(ob.matrix_world@v.co) for v in me.vertices)
        key=next(k for k,m in MATS.items() if m==ob.data.materials[0]);mi=matkeys.index(key)
        for p in me.polygons:faces.append(tuple(offset+i for i in p.vertices));mids.append(mi)
        ev.to_mesh_clear()
    me=bpy.data.meshes.new(asset+'_ExportMesh');me.from_pydata(verts,[],faces);me.update()
    for mat in MATS.values():me.materials.append(mat)
    for p,i in zip(me.polygons,mids):p.material_index=i
    ob=bpy.data.objects.new(asset,me);bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    dest=EXPORT/(asset+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',use_selection=True,export_animations=False,export_cameras=False,export_lights=False,export_yup=True)
    data=dest.read_bytes();n=struct.unpack_from('<I',data,12)[0];g=json.loads(data[20:20+n]);acc=g.get('accessors',[])
    stats={'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'meshes':len(g.get('meshes',[])),'materials':len(g.get('materials',[])),'triangles':sum(acc[p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),'animations':len(g.get('animations',[])),'skins':len(g.get('skins',[])),'nodes':len(g.get('nodes',[]))}
    bpy.data.objects.remove(ob,do_unlink=True);return stats

def preview(asset,size):
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1100;sc.render.resolution_y=850;sc.render.resolution_percentage=100
    sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_shadows=True;sc.display.shading.show_cavity=True;sc.display.shading.cavity_type='BOTH';sc.display.shading.curvature_ridge_factor=1.15;sc.display.shading.curvature_valley_factor=.7
    sc.display.shading.background_type='WORLD';sc.world=bpy.data.worlds.new('QA_BlueSky');sc.world.color=(.39,.58,.70)
    camd=bpy.data.cameras.new('QA_Camera');cam=bpy.data.objects.new('QA_Camera',camd);sc.collection.objects.link(cam);sc.camera=cam;camd.type='ORTHO';camd.ortho_scale=max(size.x,size.y)*1.65
    target=Vector((0,0,size.z*.44))
    for name,vec in [('front',(1,-1.55,1.05)),('rear',(-1,1.6,1.1))]:
        cam.location=target+Vector(vec).normalized()*max(size)*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
        sc.render.filepath=str(ART/'qa'/(asset+'_'+name+'.png'));bpy.ops.render.render(write_still=True)
    # Deterministic per-part colors expose intersections and detached components.
    sc.display.shading.color_type='OBJECT'
    colors=[(.70,.22,.12,1),(.14,.45,.62,1),(.46,.63,.25,1),(.68,.48,.14,1),(.42,.25,.60,1)]
    for i,ob in enumerate(PARTS):ob.color=colors[i%len(colors)]
    cam.location=target+Vector((1,-1.55,1.05)).normalized()*max(size)*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=str(ART/'qa'/(asset+'_random.png'));bpy.ops.render.render(write_still=True)
    # Temporary QA copies: genuine evaluated polygon wires, never exported.
    sc.display.shading.color_type='OBJECT';wires=[]
    for ob in PARTS:
        ob.color=(.65,.69,.70,1);w=ob.copy();w.color=(.008,.013,.016,1);mod=w.modifiers.new('QA_only_Wire','WIREFRAME');mod.thickness=max(size)*.0005;sc.collection.objects.link(w);wires.append(w)
    cam.location=target+Vector((1,-1.55,1.05)).normalized()*max(size)*3;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=str(ART/'qa'/(asset+'_wire.png'));bpy.ops.render.render(write_still=True)
    for ob in wires:bpy.data.objects.remove(ob,do_unlink=True)
    bpy.data.objects.remove(cam,do_unlink=True)

def main():
    sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check
    records={}
    for asset,fn in [('habitat_01',habitat),('workshop_01',workshop),('service_unit_01',service)]:
        reset();fn();pass02(asset);lo,hi=bounds(PARTS)
        offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
        for ob in PARTS:ob.data.transform(Matrix.Translation(-offset))
        bpy.context.view_layer.update();lo,hi=bounds(PARTS)
        # Solid-colour untextured palette: UV-specific gates intentionally excluded.
        qa=qa_check.run(objects=[o.name for o in PARTS],profile='game',uv=False,eps=.0003,tol=.006)
        (ART/'qa'/(asset+'_qa_raw.json')).write_text(json.dumps(qa,indent=2),encoding='utf8')
        assert qa['pass'],asset+' has uncorrected new geometry errors: '+str(qa['errors'])
        glb=export_mesh(asset)
        bpy.ops.wm.save_as_mainfile(filepath=str(ART/'source'/(asset+'.blend')))
        if '--preview' in sys.argv:preview(asset,hi-lo)
        rec={'asset':asset,'front_axis_blender':'-Y','front_axis_godot':'+Z','units':'metres','dimensions_blender_xyz':list(hi-lo),'pivot':'full bounds XY centre, ground Z=0','part_count':len(PARTS),'palette':list(MATS),'source_blend':str((ART/'source'/(asset+'.blend')).relative_to(ROOT)).replace('\\','/'),'source_blend_sha256':hashlib.sha256((ART/'source'/(asset+'.blend')).read_bytes()).hexdigest(),'export_glb':str((EXPORT/(asset+'.glb')).relative_to(ROOT)).replace('\\','/'),'glb':glb,'qa_pass':qa['pass'],'qa_errors':qa['errors'],'qa_warnings':qa['warnings'],'warning_acceptance':{'hidden back-to-back faces':'Accepted internal mounting/contact caps at separately editable closed parts. No visible coplanar overlap; not a watertight boolean union.','fully enclosed handles':'Heuristic on nested airlock ring; both ochre handle bars visibly protrude and were inspected in front/side view.'},'qa_scope':'all new geometry, including z-fight/contact checks; UV excluded for constant-color untextured palette','door_height_m':2.1 if asset=='habitat_01' else None,'references':['docs/reports/assets/grafik-2026-11-01/03_aussenposten_stilstudie.png','docs/reports/assets/grafik-2026-11-01/01_rostwelt_landschaft.png'],'status':'original first-pass static visual; no collision/navigation; Godot integration by parent task'}
        rec.update({
            'revision':'pass02',
            'status':'pass02 static visual candidate; user visual acceptance pending; no collision/navigation',
            'references':[
                'docs/reports/assets/grafik-2026-11-01/03_aussenposten_stilstudie.png',
                'docs/reports/assets/grafik-2026-11-01/references/current/01_rostgrenze_cutaway.png',
                'docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png'],
            'reference_scope':'03 shape family + current warm pale shells/orange bands and coherent work/storage groups. No room capacity, cutaway gameplay or logistics.',
            'generator':'art/frontier_illustrated_20261101/structures/generator/build_structures.py',
            'generator_sha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
            'changes':{
                'habitat_01':['pale neutral roof panels','warm pale shell palette','continuous orange wall bands','orange chamfered airlock accents'],
                'workshop_01':['pale neutral roof panels','orange wall/portal bands','existing workbench moved 1.45m toward open front','supported cargo rack inside unchanged width/height'],
                'service_unit_01':['orange tank belt','pale pump lid','two connected front service couplings']
            }[asset],
            'native_import_checked':False,
            'user_visual_acceptance':False,
        })
        records[asset]=rec;print('FRONTIER_ASSET '+json.dumps(rec),flush=True)
    (ART/'manifest.json').write_text(json.dumps({'schema':'sternenbuergerchen.frontier_structures.v1','blender':bpy.app.version_string,'assets':records},indent=2),encoding='utf8')

if __name__=='__main__':main()

"""Original Pass03 cutaway architecture, in metres, Blender -Y/Godot +Z front.

blender -b --factory-startup --python-exit-code 1 -P build_cutaways.py
Optional assets after --. No previous structures/citizens are written.
"""
from pathlib import Path
import bpy,bmesh,json,hashlib,struct,sys,math
from mathutils import Vector,Matrix
ROOT=Path(__file__).resolve().parents[5]
ART=ROOT/'art/frontier_illustrated_20261101/structures/pass03'
EXPORT=ROOT/'Assets/curated/frontier_illustrated_20261101/structures_pass03'
QA=ART/'qa'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
MATS={};PARTS=[];ZONE='architecture';PROVENANCE=[]
sys.path.insert(0,str(Path(__file__).resolve().parent))
import kenney_modules
PALETTE={'Cream':'dfd7c5','PaleTrim':'eee8db','Frame':'3d4b4c','Orange':'d7863a','Deck':'9a9b8e','Soft':'c4c7bb','Glass':'477780','Warm':'b99664'}

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def dump(p,d):Path(p).write_text(json.dumps(d,indent=2),encoding='utf-8')
def srgb(h):
    rgb=[int(h[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(x/12.92 if x<.04045 else ((x+.055)/1.055)**2.4 for x in rgb)+(1,)
def reset():
    global MATS,PARTS,ZONE,PROVENANCE
    bpy.ops.wm.read_factory_settings(use_empty=True);PARTS=[];PROVENANCE=[];ZONE='architecture';MATS={}
    bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
    for key,color in PALETTE.items():
        m=bpy.data.materials.new('M_Frontier03_'+key);m.diffuse_color=srgb(color)
        bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Base Color'].default_value=srgb(color);bs.inputs['Roughness'].default_value=.84 if key!='Glass' else .42
        MATS[key]=m
def zone(name):
    global ZONE
    ZONE=name
def mesh(name,verts,faces,mat='Cream',bevel=.02):
    me=bpy.data.meshes.new(name+'_Mesh');me.from_pydata(verts,[],faces);me.update()
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    ob=bpy.data.objects.new(name,me)
    co=bpy.data.collections.get(ZONE)
    if not co:co=bpy.data.collections.new(ZONE);bpy.context.scene.collection.children.link(co)
    co.objects.link(ob);me.materials.append(MATS[mat]);ob['functional_zone']=ZONE
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    if bevel:
        mod=ob.modifiers.new('Subtle_broad_edges','BEVEL');mod.width=bevel;mod.segments=1;mod.limit_method='ANGLE';mod.use_clamp_overlap=True;mod.harden_normals=True
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bm=bmesh.new();bm.from_mesh(me);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
    PARTS.append(ob);return ob
def box(name,c,size,mat='Cream',bevel=.02):
    x,y,z=c;a,b,d=(v/2 for v in size)
    vs=[(x+sx*a,y+sy*b,z+sz*d) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
    return mesh(name,vs,[(0,3,2,1),(4,5,6,7),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7)],mat,min(bevel,min(size)*.18))
def plate(name,xy,z0,z1,mat='Cream',bevel=.018):
    n=len(xy);vs=[(x,y,z) for z in (z0,z1) for x,y in xy]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel)
def profile(name,xz,y0,y1,mat='Cream',bevel=.018):
    n=len(xz);vs=[(x,y,z) for y in (y0,y1) for x,z in xz]
    fs=[tuple(range(n-1,-1,-1)),tuple(range(n,n*2))]+[(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
    return mesh(name,vs,fs,mat,bevel)
def rect_chamfer(cx,cy,w,d,c=.15):
    x0,x1=cx-w/2,cx+w/2;y0,y1=cy-d/2,cy+d/2
    return [(x0+c,y0),(x1-c,y0),(x1,y0+c),(x1,y1-c),(x1-c,y1),(x0+c,y1),(x0,y1-c),(x0,y0+c)]
def bar(name,a,b,r,mat='Frame',segments=10):
    a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
    if u.length<.1:u=axis.cross(Vector((0,1,0)))
    u.normalize();v=axis.cross(u).normalized()
    vs=[tuple(p+r*(u*math.cos(i*math.tau/segments)+v*math.sin(i*math.tau/segments))) for p in (a,b) for i in range(segments)]
    fs=[tuple(range(segments-1,-1,-1)),tuple(range(segments,2*segments))]+[(i,(i+1)%segments,(i+1)%segments+segments,i+segments) for i in range(segments)]
    return mesh(name,vs,fs,mat,0)
def crate(name,x,y,bottom,w=.65,d=.56,h=.5,mat='Cream'):
    box(name+'_Body',(x,y,bottom+h/2),(w,d,h),mat,.035)
    # One broad lid and one recessed-looking dark face panel; no bolt noise.
    box(name+'_Lid',(x,y,bottom+h-.015),(w+.025,d+.025,.065),'Frame',.014)
    box(name+'_Latch',(x,y-d/2-.008,bottom+h*.55),(.14,.045,.08),'Orange' if mat!='Orange' else 'Cream',.008)
def rack(name,cx,cy,w=2.2,d=.68,h=2.1,bottom=.30):
    for ix,x in enumerate((cx-w/2+.045,cx+w/2-.045)):
        for iy,y in enumerate((cy-d/2+.045,cy+d/2-.045)):
            box(name+'_Upright_%d_%d'%(ix,iy),(x,y,bottom+h/2),(.09,.09,h),'Frame',.012)
    for i,level in enumerate((.12,(h-.50)/2,h-.55)):
        box(name+'_Shelf_%d'%i,(cx,cy,bottom+level),(w+.04,d+.04,.10),'Orange',.012)
        # Large grouped cases on each level, not many small inventory objects.
        for j,x in enumerate((cx-w*.25,cx+w*.25)):
            crate(name+'_Case_%d_%d'%(i,j),x,cy,bottom+level+.04,w*.40,d*.78,.48 if i<2 else .42,'Cream' if (i+j)%3 else 'Soft')
def chair(name,x,y,floor=.30,back_sign=-1):
    box(name+'_Base',(x,y,floor+.05),(.48,.46,.12),'Frame',.025)
    box(name+'_Support',(x,y,floor+.25),(.18,.18,.44),'Frame',.02)
    box(name+'_Seat',(x,y,floor+.48),(.51,.49,.12),'Warm',.035)
    box(name+'_Back',(x,y+back_sign*.235,floor+.74),(.51,.10,.58),'Cream',.035)
def monitor(name,x,y,z,width=.72):
    box(name+'_Foot',(x,y,z+.035),(.38,.29,.09),'Frame',.018)
    box(name+'_Stand',(x,y+.025,z+.23),(.12,.12,.40),'Frame',.015)
    box(name+'_Frame',(x,y,z+.49),(width,.13,.49),'Frame',.028)
    box(name+'_Screen',(x,y-.071,z+.49),(width-.10,.035,.37),'Glass',.012)
    box(name+'_ScreenBand',(x-width*.13,y-.092,z+.46),(width*.52,.018,.032),'PaleTrim',.003)
def bed(name,x,y,floor=.30):
    box(name+'_Frame',(x,y,floor+.16),(1.03,2.07,.34),'Frame',.04)
    box(name+'_Mattress',(x,y,floor+.385),(.94,1.98,.18),'PaleTrim',.065)
    box(name+'_Blanket',(x,y-.28,floor+.475),(.945,1.16,.075),'Orange',.035)
    box(name+'_Pillow',(x,y+.66,floor+.515),(.72,.42,.14),'Soft',.065)
    box(name+'_Headboard',(x,y+1.005,floor+.43),(1.05,.13,.86),'Frame',.045)
def habitat():
    zone('Habitat_shell')
    plate('Habitat_Foundation',rect_chamfer(0,.05,6.9,6.1,.27),0,.265,'Frame',.035)
    # Four calm floor areas establish the room grouping without painted labels.
    for name,x,y,w,d,mat in [('Sleep',-1.66,1.5,2.9,2.75,'Warm'),('Storage',1.66,1.5,2.9,2.75,'Deck'),('Work',-1.66,-1.48,2.9,2.75,'Deck'),('Stay',1.66,-1.48,2.9,2.75,'Soft')]:
        if name in ['Sleep','Work']:x=-1.625;w=2.75
        box('Habitat_'+name+'Floor',(x,y,.274),(w,d,.072),mat,.025)
    # High left/back walls, genuinely open roof and low front/right cut faces.
    leftback=[(-3.28,-2.82),(-3.28,2.94),(3.28,2.94),(3.28,2.72),(-3.06,2.72),(-3.06,-2.82)]
    plate('Habitat_BackLeftWall',leftback,.25,2.94,'Cream',.024)
    band=[(-3.301,-2.839),(-3.301,2.961),(3.302,2.961),(3.302,2.699),(-3.039,2.699),(-3.039,-2.839)]
    plate('Habitat_BackLeftOrangeBand',band,.79,.94,'Orange',.008)
    plate('Habitat_BackLeftCoping',band,2.913,3.005,'Frame',.016)
    box('Habitat_RightCutWall',(3.155,-.02,.64),(.22,5.66,.78),'Cream',.024)
    box('Habitat_RightCutBand',(3.18,-.02,.82),(.25,5.70,.16),'Orange',.008)
    box('Habitat_RightCutCoping',(3.17,-.02,1.025),(.26,5.68,.09),'Frame',.012)
    for side,x in [('Left',-1.98),('Right',1.98)]:
        box('Habitat_FrontCutWall_'+side,(x,-2.84,.64),(2.35,.22,.78),'Cream',.025)
        box('Habitat_FrontCutBand_'+side,(x,-2.852,.82),(2.40,.25,.16),'Orange',.008)
        box('Habitat_FrontCutCoping_'+side,(x,-2.84,1.025),(2.38,.27,.09),'Frame',.013)
    for side,x in [('Left',-.735),('Right',.735)]:
        box('Habitat_EntryJamb_'+side,(x,-2.80,.96),(.18,.38,1.45),'Cream',.024)
        box('Habitat_EntryOrange_'+side,(x,-3.006,1.04),(.11,.072,.86),'Orange',.012)
    box('Habitat_EntryThreshold',(0,-2.88,.28),(1.27,.52,.16),'Frame',.02)
    box('Habitat_LowerStep',(0,-3.58,.071),(1.46,.84,.142),'Deck',.018)
    box('Habitat_UpperStep',(0,-3.18,.18),(1.43,.75,.23),'Deck',.018)
    box('Habitat_StepNosing',(0,-3.565,.158),(1.36,.08,.035),'Orange',.004)
    # Low partitions keep the elevated view into all rooms clear.
    box('Habitat_CentralDivider',(0,1.56,.89),(.16,2.54,1.20),'Cream',.018)
    box('Habitat_CentralDividerCap',(0,1.56,1.505),(.20,2.58,.07),'Frame',.008)
    for side,x in [('Left',-2.67),('Right',-.60)]:
        box('Habitat_SleepWorkDivider_'+side,(x,.035,.68),(.85,.15,.78),'Cream',.018)
        box('Habitat_SleepWorkCap_'+side,(x,.035,1.085),(.89,.19,.07),'Frame',.008)
    box('Habitat_StorageStayDivider',(2.25,.035,.68),(1.72,.15,.78),'Cream',.018)
    box('Habitat_StorageStayCap',(2.25,.035,1.085),(1.76,.19,.07),'Frame',.008)
    zone('Habitat_sleep')
    for i,x in enumerate((-2.48,-1.18)):bed('Sleep_Bed_%d'%i,x,1.61)
    box('Sleep_Locker',(-.415,2.37,1.07),(.47,.59,1.55),'Soft',.035)
    box('Sleep_LockerFace',(-.415,2.061,1.10),(.39,.055,1.28),'Frame',.012)
    zone('Habitat_storage');rack('Storage_Rack',1.67,2.20,2.35,.72,2.1)
    crate('Storage_GroundCaseA',.83,.83,.30,.77,.68,.59,'Orange')
    crate('Storage_GroundCaseB',2.11,.86,.30,.87,.68,.62,'Cream')
    zone('Habitat_work')
    # Supported bench beside a substantial wall-mounted tool board.
    for i,y in enumerate((-2.15,-.86)):
        box('Work_BenchSupport_%d'%i,(-2.62,y,.69),(.68,.40,.80),'Frame',.025)
    box('Work_BenchTop',(-2.632,-1.51,1.13),(.88,1.96,.15),'Warm',.03)
    box('Work_ToolBoard',(-3.015,-1.49,1.90),(.13,1.85,.90),'Frame',.02)
    for i,y in enumerate((-2.08,-1.52,-.95)):
        box('Work_HangingTool_%d'%i,(-2.92,y,1.94),(.11,.15,.57),'Orange' if i==1 else 'Soft',.012)
        box('Work_ToolHead_%d'%i,(-2.905,y,2.19),(.15,.34,.13),'Soft',.012)
    box('Work_ViseFoot',(-2.48,-2.10,1.255),(.34,.38,.14),'Frame',.015)
    box('Work_ViseBody',(-2.48,-2.10,1.43),(.22,.26,.28),'Soft',.018)
    box('Work_ViseJaw',(-2.48,-2.10,1.58),(.40,.12,.11),'Frame',.013)
    crate('Work_SupplyCase',-1.50,-2.20,.30,.64,.56,.51,'Orange')
    zone('Habitat_stay')
    box('Stay_TableBase',(1.25,-1.54,.36),(.73,.62,.14),'Frame',.03)
    box('Stay_TablePedestal',(1.25,-1.54,.67),(.27,.27,.64),'Frame',.025)
    box('Stay_TableTop',(1.25,-1.54,1.04),(1.44,.84,.14),'Warm',.045)
    chair('Stay_ChairFront',1.25,-2.28,back_sign=-1);chair('Stay_ChairBack',1.25,-.78,back_sign=1)
    box('Stay_TerminalCabinet',(2.69,-1.52,.72),(.66,1.02,.86),'Cream',.03)
    monitor('Stay_Terminal',2.69,-1.60,1.17,.64)
    return {'functional_zones':['sleep: two beds and locker','storage: six shelf cases and two floor cases','work: supported bench, wall tool board and vise','stay: table, two chairs and terminal'],
        'cutaway':'roof absent; front/right outer walls low; rear/left high; low internal partitions',
        'human_scale':'beds 1.03x2.07m; chair seat0.48m above floor; bench0.83m above floor; entrance1.27m clear width'}

def hall():
    zone('Hall_shell')
    plate('Hall_Foundation',rect_chamfer(0,0,10.5,6.5,.32),0,.265,'Frame',.035)
    box('Hall_InteriorDeck',(-1.60,0,.275),(6.85,6.10,.075),'Deck',.025)
    box('Office_InteriorDeck',(3.52,0,.275),(2.85,6.08,.075),'Soft',.025)
    leftback=[(-5.10,-2.91),(-5.10,3.08),(1.95,3.08),(1.95,2.86),(-4.88,2.86),(-4.88,-2.91)]
    plate('Hall_BackLeftWall',leftback,.25,4.04,'Cream',.025)
    band=[(-5.12,-2.932),(-5.12,3.10),(1.976,3.10),(1.976,2.84),(-4.86,2.84),(-4.86,-2.932)]
    plate('Hall_BackLeftOrangeBand',band,.78,.96,'Orange',.008)
    plate('Hall_BackLeftRoofRim',band,3.99,4.16,'Frame',.018)
    # Chamfered U-shaped structural portal; roof intentionally cut behind it.
    portal=[(-5.13,.24),(-5.13,3.65),(-4.70,4.15),(1.45,4.15),(1.94,3.65),(1.94,.24),(1.55,.24),(1.55,3.49),(1.18,3.77),(-4.45,3.77),(-4.75,3.47),(-4.75,.24)]
    profile('Hall_FrontPortal',portal,-3.13,-2.76,'Cream',.035)
    box('Hall_PortalOrangeHeader',(-1.63,-3.158,3.92),(5.73,.095,.15),'Orange',.012)
    for side,x in [('Left',-4.94),('Right',1.75)]:
        box('Hall_PortalOrangeJamb_'+side,(x,-3.158,1.78),(.18,.095,1.76),'Orange',.014)
        box('Hall_PortalFootGuard_'+side,(x,-3.166,.60),(.27,.12,.65),'Frame',.015)
    box('Hall_LoadingLip',(-1.62,-3.34,.19),(6.45,.72,.22),'Deck',.025)
    for i,x in enumerate((-4.56,1.31)):
        box('Hall_LoadingStripe_%d'%i,(x,-3.24,.311),(.17,.86,.035),'Orange',.004)
    # Narrow rear roof and left strip are supported by walls and front portal.
    box('Hall_RearRoof',(-1.57,2.76,4.105),(7.18,.76,.19),'Soft',.028)
    box('Hall_LeftRoofStrip',(-4.63,-.04,4.105),(1.02,4.96,.19),'Soft',.028)
    box('Hall_LeftRoofEdge',(-4.08,-.04,4.12),(.10,4.96,.16),'Frame',.012)
    box('Hall_BackRoofOrange',(-1.57,3.15,4.11),(6.92,.11,.12),'Orange',.01)
    # A clear center aisle with quiet broad load-zone boundaries.
    for i,x in enumerate((-2.35,-.72)):
        box('Hall_AisleBoundary_%d'%i,(x,-.45,.319),(.075,4.30,.022),'PaleTrim',.003)
    zone('Hall_storage')
    rack('Hall_RackLeft',-3.61,2.12,2.17,.88,2.74)
    rack('Hall_RackRight',-.49,2.12,2.65,.88,2.74)
    # Large freight containers in coherent corner groups.
    crate('Hall_CargoLeftBase',-3.70,-.57,.30,1.55,1.10,.95,'Orange')
    crate('Hall_CargoLeftUpper',-3.70,-.57,1.26,1.40,.98,.75,'Cream')
    crate('Hall_CargoLeftSmall',-3.72,-1.85,.30,1.17,.89,.78,'Soft')
    crate('Hall_CargoRight',.49,.45,.30,1.40,1.02,1.05,'Cream')
    # Staged pallet stays outside the visual center aisle.
    box('Hall_Pallet',(.58,-1.63,.37),(1.39,1.14,.15),'Frame',.025)
    crate('Hall_StagedCase',.58,-1.63,.435,1.21,.95,.71,'Orange')
    zone('Office_shell')
    box('Office_BackWall',(3.48,2.96,1.57),(3.26,.23,2.64),'Cream',.025)
    box('Office_RightRearWall',(5.00,1.90,1.57),(.23,2.08,2.64),'Cream',.025)
    box('Office_SharedRearWall',(1.99,1.91,1.57),(.23,2.06,2.64),'Cream',.025)
    box('Office_RearRoof',(3.48,2.00,2.97),(3.32,2.26,.21),'Soft',.025)
    box('Office_RearRoofRim',(3.48,.84,2.99),(3.38,.13,.16),'Frame',.012)
    # Low camera-side cut walls let the office desk read beside the tall hall.
    box('Office_RightCutWall',(5.00,-1.03,.77),(.23,3.67,1.04),'Cream',.023)
    box('Office_RightCutCoping',(5.00,-1.03,1.31),(.28,3.69,.09),'Frame',.012)
    box('Office_FrontCutWall',(4.14,-2.97,.77),(1.96,.23,1.04),'Cream',.023)
    box('Office_FrontCutCoping',(4.14,-2.97,1.31),(2.00,.28,.09),'Frame',.012)
    box('Office_RightOrangeBand',(5.02,-.02,.85),(.26,5.72,.16),'Orange',.008)
    box('Office_FrontOrangeBand',(4.14,-2.99,.85),(2.00,.26,.16),'Orange',.008)
    box('Office_EntryJamb',(2.22,-2.91,1.23),(.23,.28,1.96),'Cream',.02)
    box('Office_EntryThreshold',(2.70,-3.12,.25),(.83,.54,.12),'Frame',.014)
    # Exterior glazing and supported roof service unit establish the office form.
    box('Office_WindowFrame',(5.129,1.99,1.84),(.055,1.52,.79),'Frame',.02)
    box('Office_WindowGlass',(5.165,1.99,1.84),(.040,1.34,.61),'Glass',.012)
    box('Office_WindowMullion',(5.190,1.99,1.84),(.035,.055,.64),'Cream',.006)
    for i,x in enumerate((3.02,3.98)):
        box('Office_RoofUnitRail_%d'%i,(x,2.21,3.12),(.18,.90,.15),'Frame',.016)
    box('Office_RoofUnit',(3.50,2.21,3.29),(1.39,.87,.30),'Cream',.035)
    box('Office_RoofUnitGrille',(3.50,1.756,3.30),(.98,.055,.17),'Frame',.012)
    zone('Office_stay')
    for i,x in enumerate((2.90,4.15)):
        box('Office_DeskPedestal_%d'%i,(x,-.08,.69),(.48,.65,.79),'Frame',.025)
    box('Office_DeskTop',(3.53,-.08,1.15),(1.90,.84,.16),'Warm',.035)
    monitor('Office_Computer',3.53,.08,1.23,.89)
    chair('Office_Chair',3.53,-1.05,back_sign=-1)
    box('Office_WallCabinet',(3.41,2.60,1.11),(1.58,.46,1.61),'Cream',.035)
    box('Office_CabinetDoors',(3.41,2.348,1.16),(1.40,.07,1.32),'Frame',.018)
    crate('Office_FileCase',4.35,1.05,.30,.58,.58,.54,'Orange')
    return {'functional_zones':['tall freight hall: two six-case racks, grouped cargo containers and staging pallet','clear central loading aisle','attached lower office: desk, terminal, chair, cabinet and roof service unit'],
        'cutaway':'hall roof retained only at rear and left; front open under supported chamfered portal; office front/right low and forward roof removed',
        'human_scale':'main opening6.3m wide/3.5m high; office doorway0.83m wide; desk0.85m above floor; lower office roof2.97m'}

def bounds(obs):
    bpy.context.view_layer.update();pts=[o.matrix_world@Vector(p) for o in obs for p in o.bound_box]
    lo=Vector([min(p[i] for p in pts) for i in range(3)]);hi=Vector([max(p[i] for p in pts) for i in range(3)])
    return lo,hi
def stats(obs):
    return {'vertices':sum(len(o.data.vertices) for o in obs),'triangles':sum(len(p.vertices)-2 for o in obs for p in o.data.polygons),'editable_parts':len(obs),'materials':len({m.name for o in obs for m in o.data.materials})}
def remove_parts(prefixes):
    global PARTS
    gone=[o for o in PARTS if any(o.name.startswith(p) for p in prefixes)]
    PARTS=[o for o in PARTS if o not in gone]
    for ob in gone:bpy.data.objects.remove(ob,do_unlink=True)
def reuse(pack,asset,name,center,size,bottom,mode='default',rotation=0,select_objects=None,frame_only=False):
    co=bpy.data.collections.get(ZONE)
    if not co:co=bpy.data.collections.new(ZONE);bpy.context.scene.collection.children.link(co)
    obs,record=kenney_modules.module(ROOT,MATS,pack,asset,name,center,size,bottom,co,mode,rotation,select_objects,frame_only)
    PARTS.extend(obs);PROVENANCE.append(record);return obs
def panel_run(prefix,axis,fixed,a,b,count,height,bottom=.25,mode='wall'):
    width=(b-a)/count
    for i in range(count):
        mid=a+(i+.5)*width
        center=(mid,fixed) if axis=='x' else (fixed,mid)
        reuse('space_station','wall',prefix+'_%02d'%i,center,(width,.22,height),bottom,mode,0 if axis=='x' else math.pi/2)
def rebuild_with_kenney(asset):
    if asset=='habitat_cutaway_01':
        zone('Habitat_shell')
        remove_parts(['Habitat_BackLeftWall','Habitat_RightCutWall','Habitat_FrontCutWall_'])
        panel_run('Kenney_Habitat_BackWall','x',2.83,-3.28,3.28,3,2.69)
        panel_run('Kenney_Habitat_LeftWall','y',-3.148,-2.82,2.80,3,2.675,.238)
        panel_run('Kenney_Habitat_RightCut','y',3.155,-2.85,2.81,3,.78)
        for side,x in [('Left',-1.98),('Right',1.98)]:
            reuse('space_station','wall','Kenney_Habitat_FrontCut_'+side,(x,-2.84),(2.35,.22,.78),.25,'wall')
        zone('Habitat_sleep');remove_parts(['Sleep_Bed_'])
        for i,x in enumerate((-2.48,-1.18)):
            reuse('space_station','bed-single','Kenney_Bed_%d'%i,(x,1.61),(1.03,2.07,.60),.30,'bed')
            box('Sleep_Bed_%d_Blanket'%i,(x,1.33,.834),(.94,1.16,.064),'Orange',.025)
            box('Sleep_Bed_%d_Headboard'%i,(x,2.615,.73),(1.05,.13,.86),'Frame',.035)
        zone('Habitat_stay');remove_parts(['Stay_Table','Stay_Terminal'])
        reuse('space_station','table-display','Kenney_Stay_DisplayTable',(1.25,-1.54),(1.44,.84,.75),.30,'display',select_objects=['table-display'])
        reuse('space_station','computer','Kenney_Stay_Terminal',(2.56,-1.52),(.70,.70,1.35),.30,'console')
        zone('Habitat_storage');remove_parts(['Storage_GroundCaseA','Storage_GroundCaseB'])
        reuse('space_station','container-wide','Kenney_Storage_CanisterA',(.83,.83),(.77,.68,.66),.30,'cargo-orange')
        reuse('space_station','container-wide','Kenney_Storage_CanisterB',(2.11,.86),(.87,.68,.69),.30,'cargo-cream')
    else:
        zone('Hall_shell');remove_parts(['Hall_BackLeftWall','Hall_FrontPortal'])
        panel_run('Kenney_Hall_BackWall','x',2.97,-5.10,1.95,4,3.79)
        panel_run('Kenney_Hall_LeftWall','y',-4.99,-2.91,2.85,3,3.775)
        reuse('factory','door','Kenney_Factory_OpenPortal',(-1.595,-2.945),(7.07,.37,3.91),.24,'frame',frame_only=True)
        # The original lift's casing is mounted into the actual factory-derived
        # portal header. Its chain and magnetic lifting head remain original.
        reuse('factory','crane-lift','Kenney_Factory_Lift',(-1.60,-2.945),(.43,.43,1.50),2.54,'default')
        zone('Office_shell')
        remove_parts(['Office_BackWall','Office_RightRearWall','Office_SharedRearWall','Office_RightCutWall','Office_FrontCutWall','Office_Window','Office_RoofUnit'])
        panel_run('Kenney_Office_BackWall','x',2.96,1.85,5.11,2,2.64)
        panel_run('Kenney_Office_SharedWall','y',1.99,.88,2.94,1,2.625,.238)
        reuse('space_station','wall-window','Kenney_Office_WindowWall',(5.00,1.90),(2.08,.23,2.64),.235,'wall-window',math.pi/2)
        panel_run('Kenney_Office_RightCut','y',5.00,-2.865,.805,2,1.04)
        panel_run('Kenney_Office_FrontCut','x',-2.97,3.16,5.12,1,1.04)
        reuse('factory','detail-tank','Kenney_Office_RoofTank',(3.50,2.21),(1.45,.82,.58),3.065,'tank')
        zone('Office_stay');remove_parts(['Office_Computer'])
        reuse('space_station','computer-wide','Kenney_Office_Console',(3.53,.04),(1.32,.66,.68),1.215,'console')
        zone('Hall_storage');remove_parts(['Hall_CargoLeftSmall'])
        reuse('space_station','container-wide','Kenney_Hall_CargoCanister',(-3.72,-1.85),(1.17,.89,.86),.30,'cargo-cream')
def export(asset):
    vs=[];fs=[];mids=[];keys=list(MATS)
    for ob in PARTS:
        offset=len(vs);vs.extend(tuple(ob.matrix_world@v.co) for v in ob.data.vertices)
        for p in ob.data.polygons:
            mat=next(k for k,m in MATS.items() if m==ob.data.materials[p.material_index]);idx=keys.index(mat)
            fs.append(tuple(offset+i for i in p.vertices));mids.append(idx)
    me=bpy.data.meshes.new(asset+'_Mesh');me.from_pydata(vs,[],fs);me.update()
    for m in MATS.values():me.materials.append(m)
    for p,i in zip(me.polygons,mids):p.material_index=i
    ob=bpy.data.objects.new(asset,me);bpy.context.scene.collection.objects.link(ob)
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
    dest=EXPORT/(asset+'.glb')
    bpy.ops.export_scene.gltf(filepath=str(dest),export_format='GLB',use_selection=True,export_yup=True,export_animations=False,export_cameras=False,export_lights=False)
    b=dest.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n])
    rec={'path':str(dest.relative_to(ROOT)),'sha256':sha(dest),'bytes':len(b),'meshes':len(g.get('meshes',[])),'materials':len(g.get('materials',[])),
         'triangles':sum(g['accessors'][p['indices']]['count']//3 for m in g['meshes'] for p in m['primitives']),'animations':len(g.get('animations',[])),'skins':len(g.get('skins',[])),'nodes':len(g['nodes'])}
    bpy.data.objects.remove(ob,do_unlink=True);return rec
def main():
    choices={'habitat_cutaway_01':habitat,'freihafen_hall_01':hall}
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else choices
    for asset in args or choices:
        reset();meta=choices[asset]();rebuild_with_kenney(asset);lo,hi=bounds(PARTS);offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
        for ob in PARTS:ob.data.transform(Matrix.Translation(-offset))
        bpy.context.view_layer.update();lo,hi=bounds(PARTS)
        raw=qa_check.run(objects=[o.name for o in PARTS],profile='game',eps=.0003,tol=.006,uv=False)
        dump(QA/(asset+'_raw.json'),raw)
        # Keep full failed raw reports if a newly mounted module needs another
        # adjustment; the finalizer is the required successful delivery gate.
        measured=stats(PARTS);assert measured['triangles']<25000
        src=ART/'source'/(asset+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(src));glb=export(asset)
        rec={'asset':asset,'status':'separate Pass03 Kenney-based assembly with original cutaway fitting/additions; not user-approved','geometry':measured,'dimensions_blender_m':list(hi-lo),'bounds_blender_m':{'min':list(lo),'max':list(hi)},
            'pivot':'full BBox XY-centered, groundZ0','front_blender':'-Y','front_godot':'+Z','units':'metres','runtime_scale':.35,'palette':PALETTE,
            'source':str(src.relative_to(ROOT)),'source_sha256':sha(src),'export':glb,'qa_pass':raw['pass'],'qa_errors':raw['errors'],'qa_warnings':raw['warnings'],
            'qa_scope':'entire assembled asset, including contact/zfight; UV excluded for solid-color untextured materials','functional':meta,'kenney_geometry_reuse':PROVENANCE,
            'zones':{z:[o.name for o in PARTS if o['functional_zone']==z] for z in sorted({o['functional_zone'] for o in PARTS})}}
        dump(QA/(asset+'_manifest.json'),rec);print('CUTAWAY_BUILD '+json.dumps(rec))
if __name__=='__main__':main()

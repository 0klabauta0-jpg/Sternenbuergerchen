"""Pass04 derivatives: retained P03 Kenney rooms + connected twin-tank utility.
Blender5.2.3 CLI. Writes only pass04 sources/exports/QA; never prior originals.
"""
from pathlib import Path
import bpy,bmesh,sys,json,hashlib,math,shutil
from mathutils import Vector,Matrix
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3]
P3=HERE.parent/'pass03';OUT=ROOT/'Assets/curated/frontier_illustrated_20261101/structures_pass04';QA=HERE/'qa'
sys.path.insert(0,str(P3/'generator'))
import build_cutaways as b
import kenney_modules
b.ART=HERE;b.EXPORT=OUT;b.QA=QA
EXTRA={'CreamWarm':'d5c5a8','CreamLight':'e8deca','Dust':'817e6b','CargoOlive':'747a61'}

def material(key,color):
    m=bpy.data.materials.new('M_Frontier04_'+key);m.diffuse_color=b.srgb(color)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=b.srgb(color);bs.inputs['Roughness'].default_value=.93
    return m

def palette():
    for key in b.PALETTE:
        m=next((m for m in bpy.data.materials if m.name.startswith('M_Frontier03_'+key)),None)
        if m is not None:b.MATS[key]=m;m.name='M_Frontier04_'+key
    for key,color in EXTRA.items():b.MATS[key]=material(key,color)
    for key in ['Cream','PaleTrim','Frame','Orange','Deck','Soft','Warm']:
        bs=next(n for n in b.MATS[key].node_tree.nodes if n.type=='BSDF_PRINCIPLED')
        bs.inputs['Roughness'].default_value=.91

def recolor_face(ob,polygon,key):
    mat=b.MATS[key]
    if mat.name not in ob.data.materials:ob.data.materials.append(mat)
    polygon.material_index=list(ob.data.materials).index(mat)

def stable(name):return int(hashlib.sha256(name.encode()).hexdigest()[:8],16)

def warm_used_shell():
    changed=0
    for ob in b.PARTS:
        is_wall=('Wall' in ob.name or 'Cut' in ob.name) and 'Cap' not in ob.name
        is_case=('Case' in ob.name or 'Cargo' in ob.name) and 'Body' in ob.name
        if not is_wall and not is_case:continue
        for p in ob.data.polygons:
            old=ob.data.materials[p.material_index]
            z=sum(ob.data.vertices[i].co.z for i in p.vertices)/len(p.vertices)
            if is_wall and old==b.MATS['Frame'] and z<.74:
                recolor_face(ob,p,'Dust');changed+=1
            elif old==b.MATS['Cream']:
                recolor_face(ob,p,'CreamWarm' if stable(ob.name)%3==0 else 'CreamLight');changed+=1
            elif is_case and old==b.MATS['Soft']:
                recolor_face(ob,p,'CargoOlive');changed+=1
    return changed

def source_module(asset,name,center,size,bottom,mode='default',rotation=0):
    source_root=HERE/'source_assets'
    co=bpy.data.collections.get(b.ZONE)
    if co is None:co=bpy.data.collections.new(b.ZONE);bpy.context.scene.collection.children.link(co)
    objects,record=kenney_modules.module(source_root,b.MATS,'factory',asset,name,center,size,bottom,co,mode,rotation)
    for key in ['source','license_path']:record[key]=str((source_root/record[key]).relative_to(ROOT)).replace('\\','/')
    record['original_pack_path']='C:/Users/bjoer/Pictures/Kenney Game Assets All-in-1 3.4.0/kenney_factory-kit_3.0/Models/GLB format/'+asset+'.glb'
    for ob in objects:ob['kenney_source']=record['source']
    b.PARTS.extend(objects);b.PROVENANCE.append(record)
    return objects

def move_group(prefixes,translation=Vector((0,0,0)),angle=0):
    objects=[o for o in b.PARTS if any(o.name.startswith(p) for p in prefixes)]
    lo,hi=b.bounds(objects);center=(lo+hi)/2
    matrix=Matrix.Translation(translation)@Matrix.Translation(center)@Matrix.Rotation(angle,4,'Z')@Matrix.Translation(-center)
    for ob in objects:ob.data.transform(matrix)

def load_rooms(asset):
    source=P3/'source'/(asset+'.blend');old=json.loads((P3/'qa'/(asset+'_manifest.json')).read_text())
    bpy.ops.wm.open_mainfile(filepath=str(source));b.PARTS=[o for o in bpy.context.scene.objects if o.type=='MESH'];b.MATS={}
    b.PROVENANCE=json.loads(json.dumps(old['kenney_geometry_reuse']));palette()
    faces=warm_used_shell()
    if asset=='habitat_cutaway_01':
        b.zone('Habitat_work')
        top=bpy.data.objects['Work_BenchTop'];lo,hi=b.bounds([top]);center=(lo+hi)/2
        source_module('box-small','Kenney_Work_MaintenanceCase',(center.x,center.y+.36),(.43,.36,.22),hi.z-.003,'cargo-cream')
        # A backed short service conduit, not a loose cable hovering in the room.
        b.bar('Habitat_ServiceRiser',(-3.01,-.70,.48),(-3.01,-.70,1.48),.045,'Frame',10)
        b.bar('Habitat_ServiceElbow',(-3.01,-.70,1.48),(-3.01,-.40,1.48),.045,'Frame',10)
        move_group(['Kenney_Storage_CanisterB'],Vector((-.08,.11,0)),math.radians(8))
        # Distinguish the spare bunk without changing the retained Kenney body.
        for ob in b.PARTS:
            if ob.name=='Sleep_Bed_1_Blanket':
                for p in ob.data.polygons:recolor_face(ob,p,'CargoOlive')
    else:
        b.zone('Hall_storage')
        move_group(['Hall_CargoLeftUpper'],Vector((-.035,0,0)),math.radians(4))
        source_module('box-small','Kenney_Hall_MaintenanceCase',(-4.33,.72),(.61,.48,.38),.30,'cargo-orange')
        b.bar('Hall_ServiceRiser',(-4.88,1.18,.35),(-4.88,1.18,2.15),.065,'Frame',10)
        b.bar('Hall_ServiceBranch',(-4.88,1.18,2.15),(-4.88,2.65,2.15),.065,'Frame',10)
    for record in b.PROVENANCE:
        record['operations'].append('Pass04 retained assembly: subtle solid-color panel/base wear; selected cargo grouping shifted/rotated; original mesh identity retained')
    return {'retained_pass03_source':str(source.relative_to(ROOT)),'retained_pass03_source_sha256':b.sha(source),
        'retained_pass03_export_sha256':old['export']['sha256'],'functional':old['functional'],'material_faces_reassigned':faces,
        'intent':'retain room layout and readable Kenney forms; warmer quiet panels, dusty base color fields and asymmetric working groups'}

def hose(name,points,radius=.065):
    curve=bpy.data.curves.new(name+'_Curve','CURVE');curve.dimensions='3D';curve.resolution_u=8;curve.bevel_depth=radius;curve.bevel_resolution=1;curve.use_fill_caps=True
    spline=curve.splines.new('BEZIER');spline.bezier_points.add(len(points)-1)
    for p,co in zip(spline.bezier_points,points):p.co=co;p.handle_left_type='AUTO';p.handle_right_type='AUTO'
    ob=bpy.data.objects.new(name,curve);bpy.context.scene.collection.objects.link(ob);ob.data.materials.append(b.MATS['Frame']);ob['functional_zone']=b.ZONE
    bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob;bpy.ops.object.convert(target='MESH')
    bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free();b.PARTS.append(ob)

def upright_tank(name,x):
    objects=b.reuse('factory','detail-tank',name,(0,0),(2.25,1.12,1.12),0,'tank')
    # Actual Kenney horizontal tank geometry rotated upright in the derivative.
    for ob in objects:ob.data.transform(Matrix.Rotation(-math.pi/2,4,'Y'))
    lo,hi=b.bounds(objects);size=hi-lo;c=(lo+hi)/2;target=Vector((1.25,1.25,2.40))
    for ob in objects:
        for v in ob.data.vertices:
            p=v.co;v.co=Vector(((p.x-c.x)*target.x/size.x+x,(p.y-c.y)*target.y/size.y+.43,(p.z-lo.z)*target.z/size.z+.27))
        ob.data.update()
    b.PROVENANCE[-1]['operations'].append('Pass04 rotate actual tank source around Y to vertical pressure-vessel axis; fit1.25x1.25x2.40m; inherited bands/mount shapes retained')
    b.PROVENANCE[-1]['upright_tank_fit_m']=[1.25,1.25,2.40]

def utility():
    b.reset();palette();b.zone('Utility_support')
    # Deep, connected beams and feet carry vessels and machinery. No floating slab.
    for x in [-2.15,2.15]:
        b.box('Utility_SideBeam',(x,0,.20),(.30,3.20,.30),'Frame',.025)
        for y in [-1.28,1.28]:b.box('Utility_Foot',(x,y,.08),(.38,.42,.16),'Dust',.018)
    for y in [-1.30,1.28]:b.box('Utility_CrossBeam',(0,y,.20),(4.40,.24,.30),'Frame',.022)
    for x in [-.78,.78]:b.box('Utility_VesselRail',(x,.40,.19),(.28,2.48,.26),'Frame',.02)
    b.box('Utility_ServiceDeck',(0,-.90,.205),(4.25,.82,.13),'Deck',.025)
    b.zone('Utility_tanks')
    for index,x in enumerate([-.78,.78]):upright_tank('Kenney_UprightTank_%d'%index,x)
    for x in [-1.52,1.52]:b.box('Utility_BackUpright',(x,1.03,1.41),(.12,.14,2.28),'Frame',.014)
    b.box('Utility_BackTie',(0,1.03,2.49),(3.04,.15,.16),'Frame',.014)
    b.zone('Utility_pump')
    source_module('machine-connection-pipe','Kenney_Factory_Pump',(-1.52,-.68),(.88,.78,1.14),.265,'default')
    b.box('Utility_ControlCabinet',(1.52,-.70,.75),(.87,.67,.96),'CreamWarm',.045)
    source_module('screen-panel-small','Kenney_Factory_ControlPanel',(1.52,-.91),(.62,.35,.47),1.17,'console')
    b.zone('Utility_connections')
    for x in [-.78,.78]:
        b.bar('Utility_TankOutlet',(x,.42,.56),(x,-.46,.56),.09,'Frame',12)
        b.bar('Utility_TankCollar',(x,.39,.56),(x,.13,.56),.135,'Orange',12)
    b.bar('Utility_Manifold',(-1.28,-.46,.56),(1.52,-.46,.56),.09,'Frame',12)
    source_module('pipe-large-valve','Kenney_Factory_ManifoldValve',(0,-.46),(.62,.29,.32),.40,'default')
    hose('Utility_PumpFeed',[(-1.52,-.68,1.37),(-1.52,-.38,1.55),(-1.18,-.25,1.20),(-1.23,-.46,.56)],.075)
    hose('Utility_DispenseHose',[(1.52,-.81,.63),(1.03,-1.12,.58),(.53,-1.18,.30),(.17,-1.00,.27)],.06)
    for z in [.58,.88]:
        b.bar('Utility_OutputCollar',(1.52,-1.00,z),(1.52,-1.18,z),.10,'Orange',12)
        b.bar('Utility_OutputSocket',(1.52,-1.15,z),(1.52,-1.29,z),.062,'Frame',12)
    b.box('Utility_CabinetScuff',(1.52,-1.041,.42),(.64,.027,.19),'Dust',.01)
    return {'functional':{'groups':['two vertical original Kenney tank derivatives','carrying steel frame and footings','actual Factory connection machine as pump','Factory panel and valve','connected outlet collars/manifold/flexible lines'],
        'static_only':True,'no_vehicle':True,'no_refuelling_mechanic':True},'intent':'compact stationary pressure-vessel/pump assembly with useful service front; no horizontal rice-roll tank or toy vehicle'}

def main():
    for directory in [HERE/'source',QA,OUT]:directory.mkdir(parents=True,exist_ok=True)
    choices=['habitat_cutaway_01','freihafen_hall_01','utility_fuel_01']
    for asset in choices:
        metadata=utility() if asset=='utility_fuel_01' else load_rooms(asset)
        lo,hi=b.bounds(b.PARTS)
        if asset=='utility_fuel_01':
            offset=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
            for ob in b.PARTS:ob.data.transform(Matrix.Translation(-offset))
            lo,hi=b.bounds(b.PARTS)
        raw=b.qa_check.run(objects=[o.name for o in b.PARTS],profile='game',eps=.0003,tol=.006,uv=False)
        b.dump(QA/(asset+'_raw.json'),raw)
        measured=b.stats(b.PARTS);assert measured['triangles']<25000
        src=HERE/'source'/(asset+'.blend');bpy.ops.wm.save_as_mainfile(filepath=str(src));glb=b.export(asset)
        record={'asset':asset,'status':'Pass04 Kenney-based visual candidate; user approval pending','geometry':measured,'dimensions_blender_m':list(hi-lo),'bounds_blender_m':{'min':list(lo),'max':list(hi)},
            'pivot':'full BBox XY-centered, groundZ0','front_blender':'-Y','front_godot':'+Z','units':'metres','runtime_scale':.35,
            'source':str(src.relative_to(ROOT)),'source_sha256':b.sha(src),'export':glb,'qa_pass':raw['pass'],'qa_errors':raw['errors'],'qa_warnings':raw['warnings'],
            'kenney_geometry_reuse':b.PROVENANCE,'qa_scope':'entire assembled source; full contact/zfight/normal checks; UV excluded for untextured palette',**metadata}
        b.dump(QA/(asset+'_manifest.json'),record);print('PASS04_STRUCTURE '+json.dumps(record),flush=True)
        # Failed first revisions remain inspectable, but are never a delivery PASS.
if __name__=='__main__':main()

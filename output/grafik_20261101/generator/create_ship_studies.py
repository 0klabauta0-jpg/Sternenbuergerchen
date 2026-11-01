import bpy,sys,json,hashlib,math
from pathlib import Path
from mathutils import Vector,Matrix
ROOT=Path(r'C:/Users/bjoer/.codex/worktrees/grafikreferenzen-20261101/SternenBuergerchen')
SRC=Path(r'C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE')
OUT=ROOT/'output/grafik_20261101/model_studies'
RND=ROOT/'docs/reports/assets/grafik-2026-11-01/ship_studies'

def aim(obj,point):obj.rotation_euler=(Vector(point)-obj.location).to_track_quat('-Z','Y').to_euler()
def setup_camera(radius,view):
    sc=bpy.context.scene
    if not sc.camera:
        data=bpy.data.cameras.new('Study_Camera'); cam=bpy.data.objects.new('Study_Camera',data);sc.collection.objects.link(cam);sc.camera=cam
    cam=sc.camera;cam.data.type='ORTHO';cam.data.ortho_scale=radius*2.7
    cam.location=Vector(view).normalized()*radius*3;aim(cam,(0,0,0));cam.data.clip_end=radius*20

def load(ship,length):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    p=SRC/('DRAKE-'+ship.upper()+'.obj')
    bpy.ops.wm.obj_import(filepath=str(p),forward_axis='NEGATIVE_Z',up_axis='Y')
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    pts=[o.matrix_world@Vector(c) for o in obs for c in o.bound_box];lo=Vector(tuple(min(p[i] for p in pts) for i in range(3)));hi=Vector(tuple(max(p[i] for p in pts) for i in range(3)));center=(hi+lo)/2;scale=length/(hi.y-lo.y)
    for ob in obs:
        ob.data.transform(Matrix.Scale(scale,4)@Matrix.Translation(-center)@ob.matrix_world);ob.matrix_world=Matrix.Identity(4);ob.name='Study_'+ship
    bpy.context.view_layer.update()
    return obs,p,hi-lo,scale

def inspect():
    for ship,length in [('cutlass',37.5),('buccaneer',15.25)]:
        obs,p,dim,scale=load(ship,length);dest=OUT/ship;dest.mkdir(exist_ok=True,parents=True)
        sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=900;sc.render.resolution_y=650;sc.render.resolution_percentage=100
        sc.display.shading.light='STUDIO';sc.display.shading.studiolight_rotate_z=0.6;sc.display.shading.color_type='SINGLE';sc.display.shading.single_color=(.46,.52,.55);sc.display.shading.show_cavity=True;sc.display.shading.cavity_type='BOTH';sc.display.shading.show_shadows=True;sc.display.shading.background_type='WORLD';sc.world=bpy.data.worlds.new('Sky');sc.world.color=(.25,.38,.50)
        r=length*.52
        for name,view in [('yminus',(1,-1,.8)),('yplus',(1,1,.8)),('top',(0,0,1))]:
            setup_camera(r,view);sc.render.filepath=str(dest/('inspect_'+name+'.png'));bpy.ops.render.render(write_still=True)
        data={'source':str(p),'raw_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'import_dims':list(dim),'scale_applied':scale,'objects':[{'name':o.name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'dimensions':list(o.dimensions)} for o in obs]}
        (dest/'inspect.json').write_text(json.dumps(data,indent=2))
        bpy.ops.wm.save_as_mainfile(filepath=str(dest/'normalized_source.blend'))
        print('STUDY_INSPECT '+json.dumps(data),flush=True)

if __name__=='__main__' and '--final' not in sys.argv:inspect()

def srgb(hexv):
    rgb=[int(hexv[i:i+2],16)/255 for i in (0,2,4)]
    return tuple(c/12.92 if c<.04045 else ((c+.055)/1.055)**2.4 for c in rgb)+(1,)
def material(name,color,roughness=.7,metallic=0,emission=0):
    m=bpy.data.materials.new(name);m.diffuse_color=srgb(color)
    bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
    bs.inputs['Base Color'].default_value=srgb(color);bs.inputs['Roughness'].default_value=roughness;bs.inputs['Metallic'].default_value=metallic
    if emission:bs.inputs['Emission Color'].default_value=srgb(color);bs.inputs['Emission Strength'].default_value=emission
    return m

def fingerprint(obs):
    import numpy as np
    h=hashlib.sha256()
    for ob in obs:
        co=np.empty(len(ob.data.vertices)*3,dtype=np.float32);ob.data.vertices.foreach_get('co',co)
        vi=np.empty(len(ob.data.loops),dtype=np.int32);ob.data.loops.foreach_get('vertex_index',vi)
        lengths=np.empty(len(ob.data.polygons),dtype=np.int32);ob.data.polygons.foreach_get('loop_total',lengths)
        for a in (co,vi,lengths):h.update(a.tobytes())
    return h.hexdigest()

def assign_materials(ship,obs,length):
    import numpy as np
    mats=[material('M_SlateTeal','54666d',.78),material('M_WarmIvory','d8cfb3',.76),material('M_Ochre','ba8c43',.75),material('M_DarkGlaze','243e49',.2),material('M_EngineHardware','455259',.6,1),material('M_WarmEngine','d99a52',.52,0,.35)]
    counts={m.name:0 for m in mats}
    for ob in obs:
        me=ob.data;me.materials.clear()
        for mat in mats:me.materials.append(mat)
        # Connected coplanar surfaces receive one assignment together; this keeps
        # existing panels coherent instead of cutting triangle-shaped paint masks.
        parent=list(range(len(me.polygons)))
        def find(i):
            while parent[i]!=i:parent[i]=parent[parent[i]];i=parent[i]
            return i
        edges={}
        for p in me.polygons:
            for edge in p.edge_keys:
                q=edges.get(edge)
                if q is None:edges[edge]=p.index
                elif p.normal.dot(me.polygons[q].normal)>.9995:
                    a,b=find(p.index),find(q)
                    if a!=b:parent[a]=b
        groups={}
        for p in me.polygons:groups.setdefault(find(p.index),[]).append(p.index)
        for ids in groups.values():
            area=sum(me.polygons[i].area for i in ids)
            if area<1e-10:area=1
            center=sum((me.polygons[i].center*me.polygons[i].area for i in ids),Vector())/area
            normal=sum((me.polygons[i].normal*me.polygons[i].area for i in ids),Vector())/area
            x,y,z=center;nx,ny,nz=normal;a=abs(x);idx=0
            if ship=='cutlass':
                if z<-.8 or (a>9 and y<-7):idx=4
                if z>.55 and ((a<2.1 and -14<y<17) or (a>9 and -12<y<-3 and abs(nz)>.25)):idx=1
                if a<2.7 and y>8.4 and z>.25 and (nz>.05 or abs(nx)>.25):idx=3
                if a>7 and y>7.5 and 10.2<y<12.2 and abs(nz)>.4 and z>0 and area<8:idx=2
                if a>9 and -11.3<y<-10.1 and z>.2 and area<.7:idx=2
                if a>9 and y<-13.5 and abs(ny)>.8:idx=5
            else:
                if z<-.45 or (a>3.4 and y<-1.5):idx=4
                if z>.25 and abs(nz)>.25 and ((a>3.4 and -4.8<y<-1.4) or (1.25<a<3.6 and -4.5<y<1) or (a>5.7 and -2<y<1.5)):idx=1
                if a<1.12 and y>2.8 and z>.03 and (nz>.2 or abs(nx)>.3):idx=3
                if a>3.3 and -.1<y<.6 and z>-.5 and area<.4:idx=2
                if a>5.5 and -1.1<y<-.5 and abs(nz)>.1 and z>0 and area<.5:idx=2
                if a>3.4 and y<-4.8 and abs(ny)>.8:idx=5
            for i in ids:me.polygons[i].material_index=idx
            counts[mats[idx].name]+=len(ids)
    return counts

def lighting(length):
    sc=bpy.context.scene;sc.unit_settings.system='METRIC';sc.unit_settings.scale_length=1
    world=bpy.data.worlds.new('Study_PaleSky');world.use_nodes=True
    bg=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');bg.inputs['Color'].default_value=(.43,.62,.78,1);bg.inputs['Strength'].default_value=.35;sc.world=world
    sun_data=bpy.data.lights.new('Study_Sun','SUN');sun_data.energy=2;sun_data.angle=math.radians(8)
    sun=bpy.data.objects.new('Study_Sun',sun_data);sc.collection.objects.link(sun);sun.rotation_euler=(math.radians(25),math.radians(-18),math.radians(-35))
    for name,pos,power,size in [('Fill',(-.8,.5,1),7*length*length,length*.9),('Rim',(.3,-.8,.8),10*length*length,length*.6)]:
        ld=bpy.data.lights.new('Study_'+name,'AREA');ld.energy=power;ld.shape='DISK';ld.size=size
        ob=bpy.data.objects.new(ld.name,ld);sc.collection.objects.link(ob);ob.location=Vector(pos)*length;aim(ob,(0,0,0))
    sc.render.engine='CYCLES';sc.cycles.device='GPU';sc.cycles.samples=32;sc.cycles.use_denoising=True;sc.cycles.adaptive_threshold=.05;sc.cycles.max_bounces=4
    prefs=bpy.context.preferences.addons['cycles'].preferences;prefs.compute_device_type='OPTIX';prefs.get_devices()
    for d in prefs.devices:d.use=d.type=='OPTIX'
    sc.render.resolution_x=1280;sc.render.resolution_y=900;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG';sc.render.image_settings.color_mode='RGB';sc.render.film_transparent=False
    try:sc.view_settings.view_transform='Khronos PBR Neutral'
    except TypeError:sc.view_settings.view_transform='AgX'
    sc.render.use_persistent_data=True

def render_views(ship,stage,length):
    sc=bpy.context.scene;paths={}
    for name,vec,factor in [('front',(1.15,1.7,1.15),1.16),('rear',(-1.25,-1.7,1.25),1.16),('distance',(1.15,1.7,1.5),3.45)]:
        setup_camera(length*.52,vec);sc.camera.data.ortho_scale=length*factor
        path=RND/(ship+'_'+stage+'_'+name+'.png');sc.render.filepath=str(path);bpy.ops.render.render(write_still=True);paths[name]=str(path.relative_to(ROOT)).replace('\\','/')
    return paths

def glb_summary(path):
    import struct
    data=path.read_bytes();n=struct.unpack_from('<I',data,12)[0];j=json.loads(data[20:20+n].decode('utf8'))
    acc=j.get('accessors',[]);tris=sum(acc[p['indices']]['count']//3 for m in j.get('meshes',[]) for p in m['primitives'] if 'indices' in p)
    return {'bytes':len(data),'meshes':len(j.get('meshes',[])),'materials':len(j.get('materials',[])),'triangles':tris,'images':len(j.get('images',[])),'animations':len(j.get('animations',[])),'skins':len(j.get('skins',[])),'extensions_used':j.get('extensionsUsed',[])}

def final():
    import time
    sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts');import qa_check
    for ship,length in [('cutlass',37.5),('buccaneer',15.25)]:
        start=time.time();dest=OUT/ship;obs,source,raw_dims,scale=load(ship,length);before=fingerprint(obs)
        neutral=material('M_NeutralSource','899397',.78)
        for ob in obs:ob.data.materials.clear();ob.data.materials.append(neutral)
        lighting(length);baseline=render_views(ship,'source',length)
        bpy.ops.wm.save_as_mainfile(filepath=str(dest/'neutral_source.blend'))
        counts=assign_materials(ship,obs,length);after=fingerprint(obs)
        assert before==after,'Geometry changed during material assignment'
        candidate=render_views(ship,'candidate',length)
        # Both sources are intentionally high poly. Retain full raw QA, including
        # skipped high-cost pair checks and failed source-derived game criteria.
        qa=qa_check.run(objects=[o.name for o in obs],profile='game',max_tris=100000,uv=False)
        (dest/'qa_check_raw.json').write_text(json.dumps(qa,indent=2),encoding='utf8')
        sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.display.shading.light='STUDIO';sc.display.shading.color_type='MATERIAL';sc.display.shading.show_cavity=True;sc.display.shading.cavity_type='BOTH';sc.display.shading.background_type='WORLD';sc.world.color=(.35,.5,.62);setup_camera(length*.52,(1.15,1.7,1.15));sc.camera.data.ortho_scale=length*1.16
        sc.render.filepath=str(RND/(ship+'_qa_solid.png'));bpy.ops.render.render(write_still=True)
        # Run verify_ship_wire.py after this generator for actual barycentric
        # triangle wire renders; Workbench object overlays are not rendered.
        sc.render.engine='CYCLES';setup_camera(length*.52,(1.15,1.7,1.15));sc.camera.data.ortho_scale=length*1.16
        bpy.ops.wm.save_as_mainfile(filepath=str(dest/'material_candidate.blend'))
        bpy.ops.object.select_all(action='DESELECT')
        for ob in obs:ob.select_set(True)
        bpy.context.view_layer.objects.active=obs[0]
        export=dest/'material_candidate.glb';bpy.ops.export_scene.gltf(filepath=str(export),export_format='GLB',use_selection=True,export_cameras=False,export_lights=False,export_animations=False,export_yup=True)
        manifest={'schema':'sternenbuergerchen.ship_material_study.v1','ship':ship,'tool':'Blender '+bpy.app.version_string,'source_path':str(source),'source_sha256':hashlib.sha256(source.read_bytes()).hexdigest(),'source_material_information':'None present in OBJ. Neutral baseline is a new clay material, not original game appearance.','geometry_change':'None beyond common centering and nominal length normalization before both baseline and candidate. Identical normalized vertices and topology.','raw_import_dimensions':list(raw_dims),'uniform_scale_applied':scale,'nominal_length_m':length,'source_front':'positive Y in Blender after OBJ import (-Z forward, Y up)','geometry_sha256_before':before,'geometry_sha256_after':after,'geometry_unchanged':before==after,'objects':[{'name':o.name,'vertices':len(o.data.vertices),'faces':len(o.data.polygons),'triangles':sum(len(p.vertices)-2 for p in o.data.polygons),'dimensions_m':list(o.dimensions),'uv_layers':len(o.data.uv_layers),'materials':len(o.data.materials),'scale':list(o.scale)} for o in obs],'material_face_counts':counts,'baseline_renders':baseline,'candidate_renders':candidate,'qa_raw_file':'qa_check_raw.json','qa_pass':qa['pass'],'qa_errors':qa['errors'],'qa_warnings':qa['warnings'],'qa_scope':'Full topology scan. Expensive intertriangle z-fighting/floating checks skipped above 100000 tris. UV scan disabled because source has no UV layers, recorded explicitly in raw stats.','status':'Isolated high-poly material reference study; not runtime ready; no integration, collision or navigation.','glb':glb_summary(export),'render_conditions':{'engine':'Cycles','device':'OptiX GPU','samples':32,'view_transform':sc.view_settings.view_transform,'resolution':[1280,900],'world':'Pale blue constant sky','camera':'Orthographic, matched source/candidate per view','distance_ortho_scale':length*3.45},'elapsed_seconds':round(time.time()-start,2)}
        manifest['files']={p.name:{'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in (dest/'neutral_source.blend',dest/'material_candidate.blend',export,dest/'qa_check_raw.json')}
        (dest/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf8');print('STUDY_FINAL '+json.dumps({'ship':ship,'qa_pass':qa['pass'],'glb':manifest['glb'],'elapsed':manifest['elapsed_seconds']}),flush=True)

if __name__=='__main__' and '--final' in sys.argv:final()

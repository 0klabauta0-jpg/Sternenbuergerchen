"""Reference-facing front/rear and native-angle game-distance source views."""
from pathlib import Path
import bpy,sys,json,math
from mathutils import Vector
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
ASSETS=['cutlass_01','buccaneer_01']
def direction(yaw,pitch):
    a,b=math.radians(yaw),math.radians(pitch)
    return Vector((math.sin(a)*math.cos(b),-math.cos(a)*math.cos(b),math.sin(b)))
def setup():
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1400;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
    sc.render.film_transparent=False;sc.render.image_settings.file_format='PNG';sc.world=bpy.data.worlds.new('QA_BlueSky');sc.world.color=(.34,.53,.65)
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='MATERIAL';sh.show_cavity=True;sh.cavity_type='BOTH';sh.curvature_ridge_factor=1.05;sh.curvature_valley_factor=.55;sh.show_shadows=True;sh.show_object_outline=False;sh.background_type='WORLD'
    sc.view_settings.view_transform='Standard'
    cam=bpy.data.objects.new('QA_Camera',bpy.data.cameras.new('QA_Camera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL'
    return sc,cam
def fitted_camera(obs,d,aspect):
    q=(-Vector(d)).to_track_quat('-Z','Y');right=q@Vector((1,0,0));up=q@Vector((0,1,0))
    pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices];xs=[p.dot(right) for p in pts];ys=[p.dot(up) for p in pts]
    target=right*((min(xs)+max(xs))/2)+up*((min(ys)+max(ys))/2)
    ortho=max(max(xs)-min(xs),(max(ys)-min(ys))*aspect)*1.13
    return target,ortho
def render(path,sc,cam,d,ortho,target):
    cam.data.ortho_scale=ortho;cam.location=target+Vector(d).normalized()*60;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=str(path);bpy.ops.render.render(write_still=True)
def review(asset):
    bpy.ops.wm.open_mainfile(filepath=str(HERE/'source'/(asset+'.blend')));obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    sc,cam=setup();aspect=sc.render.resolution_x/sc.render.resolution_y;views=[]
    for name,d in [('front',direction(38,32)),('rear',direction(-142,32)),('top',Vector((0,-.001,1))),('game',direction(24,50))]:
        target,ortho=fitted_camera(obs,d,aspect)
        if name=='game':ortho=12/.22*aspect
        path=QA/(asset+'_'+name+'.png');render(path,sc,cam,d,ortho,target)
        views.append({'view':name,'path':str(path.relative_to(ROOT)).replace('\\','/'),'direction_blender':list(d),'orthographic_height_source_m':ortho/aspect,'runtime_scale_assumption':.22 if name=='game' else None,'camera_size_world':12 if name=='game' else None,'engine':'Blender5.2.3 Workbench; not native Godot'})
    target,ortho=fitted_camera(obs,direction(38,32),aspect)
    sc.display.shading.color_type='RANDOM';render(QA/(asset+'_random.png'),sc,cam,direction(38,32),ortho,target)
    sc.display.shading.color_type='OBJECT';copies=[]
    for ob in obs:
        ob.color=(.65,.70,.72,1);w=ob.copy();w.color=(.01,.016,.021,1);md=w.modifiers.new('QA_only_wire','WIREFRAME');md.thickness=.006;md.use_even_offset=False
        sc.collection.objects.link(w);copies.append(w)
    render(QA/(asset+'_wire.png'),sc,cam,direction(38,32),ortho,target)
    for w in copies:bpy.data.objects.remove(w,do_unlink=True)
    (QA/(asset+'_views.json')).write_text(json.dumps(views,indent=2),encoding='utf-8')
if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ASSETS
    for asset in args or ASSETS:review(asset)

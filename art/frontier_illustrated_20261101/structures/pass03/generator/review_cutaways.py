"""Source Workbench multi-view/part/wire review at native camera directions."""
from pathlib import Path
import bpy,sys,math,json
from mathutils import Vector
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
ASSETS=['habitat_cutaway_01','freihafen_hall_01']
def camera_direction(yaw,pitch):
    a,b=math.radians(yaw),math.radians(pitch)
    return Vector((math.sin(a)*math.cos(b),-math.cos(a)*math.cos(b),math.sin(b)))
def setup():
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1200;sc.render.resolution_y=900;sc.render.resolution_percentage=100
    sc.render.film_transparent=False;sc.render.image_settings.file_format='PNG';sc.world=bpy.data.worlds.new('QA_BlueSky');sc.world.color=(.38,.55,.64)
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='MATERIAL';sh.show_cavity=True;sh.cavity_type='BOTH';sh.curvature_ridge_factor=1.0;sh.curvature_valley_factor=.65;sh.show_shadows=True;sh.background_type='WORLD';sh.show_object_outline=False
    sc.view_settings.view_transform='Standard'
    cam=bpy.data.objects.new('QA_Camera',bpy.data.cameras.new('QA_Camera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL'
    return sc,cam
def render(path,sc,cam,direction,ortho,target):
    cam.data.ortho_scale=ortho;cam.location=target+Vector(direction).normalized()*40;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler()
    sc.render.filepath=str(path);bpy.ops.render.render(write_still=True)
def fitted_camera(obs,direction,aspect):
    rotation=(-Vector(direction)).to_track_quat('-Z','Y');right=rotation@Vector((1,0,0));up=rotation@Vector((0,1,0))
    points=[o.matrix_world@Vector(v) for o in obs for v in o.bound_box]
    xs=[p.dot(right) for p in points];ys=[p.dot(up) for p in points]
    center=right*((min(xs)+max(xs))/2)+up*((min(ys)+max(ys))/2)
    scale=max(max(xs)-min(xs),(max(ys)-min(ys))*aspect)*1.12
    return center,scale
def review(asset):
    bpy.ops.wm.open_mainfile(filepath=str(HERE/'source'/(asset+'.blend')))
    obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];sc,cam=setup();metadata=[]
    record=json.loads((QA/(asset+'_manifest.json')).read_text());dims=record['dimensions_blender_m'];aspect=sc.render.resolution_x/sc.render.resolution_y
    for name,direction in [('front',camera_direction(24,42)),('rear',camera_direction(204,38)),('top',Vector((0,-.001,1))),('game',camera_direction(24,50))]:
        target,ortho=fitted_camera(obs,direction,aspect)
        if name=='game':ortho=12/.35*aspect
        p=QA/(asset+'_'+name+'.png');render(p,sc,cam,direction,ortho,target)
        metadata.append({'view':name,'path':str(p.relative_to(ROOT)),'camera_direction_blender':list(direction),'orthographic_width_m':ortho,'orthographic_height_m':ortho/aspect,'target_blender_m':list(target),'engine':'Blender5.2.3 Workbench; not native Godot'})
    target,near=fitted_camera(obs,camera_direction(24,50),aspect)
    sc.display.shading.color_type='RANDOM'
    render(QA/(asset+'_random.png'),sc,cam,camera_direction(24,50),near,target)
    sc.display.shading.color_type='OBJECT';wires=[]
    for ob in obs:
        ob.color=(.65,.70,.72,1);w=ob.copy();w.color=(.008,.014,.019,1);md=w.modifiers.new('QA_only_wire','WIREFRAME');md.thickness=.004;md.use_even_offset=False
        sc.collection.objects.link(w);wires.append(w)
    render(QA/(asset+'_wire.png'),sc,cam,camera_direction(24,50),near,target)
    for ob in wires:bpy.data.objects.remove(ob,do_unlink=True)
    (QA/(asset+'_views.json')).write_text(json.dumps(metadata,indent=2),encoding='utf-8')
    print('REVIEW_READY '+asset)
if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else ASSETS
    for a in args or ASSETS:review(a)

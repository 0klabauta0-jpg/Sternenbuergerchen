"""Reproducible matched material, assembly and wire views; separate CLI scene only."""
from pathlib import Path
import bpy,sys,math,json,argparse
from mathutils import Vector
ART=Path(__file__).resolve().parents[1]; ROOT=ART.parents[5]
def direction(yaw,elev):
    a,b=map(math.radians,(yaw,elev));return Vector((math.sin(a)*math.cos(b),-math.cos(a)*math.cos(b),math.sin(b)))
def setup():
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1500;sc.render.resolution_y=1125;sc.render.resolution_percentage=100;sc.render.image_settings.file_format='PNG'
    sc.render.film_transparent=False;sc.world=bpy.data.worlds.new('Review_studio');sc.world.color=(.68,.74,.76)
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='MATERIAL';sh.show_shadows=True;sh.show_cavity=True;sh.cavity_type='BOTH';sh.curvature_ridge_factor=.4;sh.curvature_valley_factor=.6;sh.show_object_outline=False;sh.background_type='WORLD'
    sc.view_settings.view_transform='Standard'
    ca=bpy.data.cameras.new('Review_camera');ca.type='ORTHO';ca.sensor_fit='HORIZONTAL';cam=bpy.data.objects.new('Review_camera',ca);sc.collection.objects.link(cam);sc.camera=cam
    return sc,cam
def fit(obs,d,asp):
    q=(-d).to_track_quat('-Z','Y');right=q@Vector((1,0,0));up=q@Vector((0,1,0));pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    xs=[p.dot(right) for p in pts];ys=[p.dot(up) for p in pts]
    return right*((min(xs)+max(xs))/2)+up*((min(ys)+max(ys))/2),max(max(xs)-min(xs),(max(ys)-min(ys))*asp)*1.13
def shot(sc,cam,out,d,target,width):
    cam.location=target+d*60;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();cam.data.ortho_scale=width;sc.render.filepath=str(out);bpy.ops.render.render(write_still=True)
def main(iteration,quick=False,final=False):
    dirname='final' if final else ('iteration%02d'%iteration)
    qa=ART/'review'/dirname;qa.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(ART/'source'/dirname/'cutlass_01.blend'))
    obs=[o for o in bpy.data.collections['LOW'].all_objects if o.type=='MESH'];sc,cam=setup();asp=sc.render.resolution_x/sc.render.resolution_y
    cams={};views=[('front',direction(-38,33)),('rear',direction(-142,33))]
    if not quick:views+=[('side',direction(-90,12)),('top',Vector((0,0,1))),('game',direction(-35,50))]
    for name,d in views:
        target,width=fit(obs,d,asp)
        if name=='game':width=12/.22*asp
        cams[name]={'direction':list(d),'target':list(target),'ortho_width':width,'resolution':[1500,1125],'renderer':'Blender Workbench','view_transform':'Standard'}
        shot(sc,cam,qa/(name+'.png'),d,target,width)
    if not quick:
        p=cams['front'];d=Vector(p['direction']);t=Vector(p['target']);w=p['ortho_width']
        sc.display.shading.color_type='RANDOM';shot(sc,cam,qa/'assembly.png',d,t,w)
        sc.display.shading.color_type='OBJECT'
        for ob in obs:
            ob.color=(.70,.74,.76,1);wire=ob.copy();wire.data=ob.data.copy();sc.collection.objects.link(wire);wire.color=(.025,.035,.045,1);md=wire.modifiers.new('Review_wire','WIREFRAME');md.thickness=.008;md.use_even_offset=False
        shot(sc,cam,qa/'wire.png',d,t,w)
    (qa/'cameras.json').write_text(json.dumps(cams,indent=2),encoding='utf8')
if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--iteration',type=int,default=1);p.add_argument('--quick',action='store_true');p.add_argument('--final',action='store_true');a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else[]);main(a.iteration,a.quick,a.final)

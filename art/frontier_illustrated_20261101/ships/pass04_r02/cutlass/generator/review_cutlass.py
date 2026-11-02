"""Matched Cutlass form-review cameras; headless Workbench, source stays untouched."""
from pathlib import Path
import bpy,math,sys,json
from mathutils import Vector
ART=Path(__file__).resolve().parents[1];ROOT=ART.parents[4]
def direction(yaw,pitch):
    a,b=math.radians(yaw),math.radians(pitch);return Vector((math.sin(a)*math.cos(b),-math.cos(a)*math.cos(b),math.sin(b)))
def setup():
    sc=bpy.context.scene;sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1400;sc.render.resolution_y=1000;sc.render.resolution_percentage=100
    sc.render.film_transparent=False;sc.render.image_settings.file_format='PNG';sc.world=bpy.data.worlds.new('QA_Sky');sc.world.color=(.37,.56,.68)
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='MATERIAL';sh.show_cavity=True;sh.cavity_type='BOTH';sh.curvature_ridge_factor=.65;sh.curvature_valley_factor=.55;sh.show_shadows=True;sh.show_object_outline=False;sh.background_type='WORLD'
    sc.view_settings.view_transform='Standard'
    cam=bpy.data.objects.new('QA_Camera',bpy.data.cameras.new('QA_Camera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL'
    return sc,cam
def fit(obs,d,aspect):
    q=(-Vector(d)).to_track_quat('-Z','Y');right=q@Vector((1,0,0));up=q@Vector((0,1,0));pts=[o.matrix_world@v.co for o in obs for v in o.data.vertices]
    xs=[p.dot(right) for p in pts];ys=[p.dot(up) for p in pts]
    return right*((min(xs)+max(xs))/2)+up*((min(ys)+max(ys))/2),max(max(xs)-min(xs),(max(ys)-min(ys))*aspect)*1.14
def render(path,sc,cam,d,ortho,target):
    cam.data.ortho_scale=ortho;cam.location=target+Vector(d).normalized()*60;cam.rotation_euler=(target-cam.location).to_track_quat('-Z','Y').to_euler();sc.render.filepath=str(path);bpy.ops.render.render(write_still=True)
def review(iteration):
    path=ART/'source'/('iteration%02d'%iteration)/'cutlass_01.blend';qa=ART/'qa'/('iteration%02d'%iteration);qa.mkdir(parents=True,exist_ok=True)
    bpy.ops.wm.open_mainfile(filepath=str(path));obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];sc,cam=setup();asp=sc.render.resolution_x/sc.render.resolution_y;views=[]
    cams={}
    for name,d in [('front',direction(-38,30)),('rear',direction(142,30)),('side',direction(-90,15)),('top',Vector((0,-.001,1))),('game',direction(24,50))]:
        target,ortho=fit(obs,d,asp)
        if name=='game':ortho=12/.22*asp
        render(qa/(name+'.png'),sc,cam,d,ortho,target);cams[name]=(d,ortho,target)
        views.append({'view':name,'direction_blender':list(d),'orthographic_width_source_m':ortho,'target':list(target),'engine':'Blender5.2.3 Workbench','runtime_scale':.22 if name=='game' else None})
    d,ortho,target=cams['front'];sc.display.shading.color_type='RANDOM';render(qa/'random.png',sc,cam,d,ortho,target)
    sc.display.shading.color_type='OBJECT';copies=[]
    for ob in obs:
        ob.color=(.65,.70,.72,1);w=ob.copy();w.color=(.01,.016,.021,1);md=w.modifiers.new('QA_wire','WIREFRAME');md.thickness=.006;md.use_even_offset=False;sc.collection.objects.link(w);copies.append(w)
    render(qa/'wire.png',sc,cam,d,ortho,target)
    for o in copies:bpy.data.objects.remove(o,do_unlink=True)
    (qa/'views.json').write_text(json.dumps(views,indent=2),encoding='utf-8')
    if iteration==2:
        bpy.ops.wm.open_mainfile(filepath=str(ROOT/'art/frontier_illustrated_20261101/ships/pass04/source/cutlass_01.blend'));sc,cam=setup()
        for name in ['front','rear','game']:
            d,ortho,target=cams[name];render(qa/('r01_matched_'+name+'.png'),sc,cam,d,ortho,target)
if __name__=='__main__':review(int(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else 1)

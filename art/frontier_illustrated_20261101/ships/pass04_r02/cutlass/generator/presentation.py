"""Non-exported EEVEE review rig. Same cameras/light/exposure for R01 and R02 GLB."""
from pathlib import Path
import bpy,json,sys,math
from mathutils import Vector
ART=Path(__file__).resolve().parents[1];ROOT=ART.parents[4];QA=ART/'qa/iteration02'
sys.path.insert(0,str(ART/'generator'));import review_cutlass as review
def lighting():
    sc=bpy.context.scene;sc.render.engine='BLENDER_EEVEE';sc.render.resolution_x=1600;sc.render.resolution_y=1100;sc.render.resolution_percentage=100
    sc.render.image_settings.file_format='PNG';sc.render.film_transparent=False
    sc.view_settings.view_transform='AgX';sc.view_settings.look='AgX - Medium High Contrast';sc.view_settings.exposure=-1.0
    if hasattr(sc.eevee,'taa_render_samples'):sc.eevee.taa_render_samples=48
    world=bpy.data.worlds.new('Presentation_blue_sky');world.use_nodes=True;sc.world=world
    bs=next(n for n in world.node_tree.nodes if n.type=='BACKGROUND');bs.inputs['Color'].default_value=(.38,.62,.80,1);bs.inputs['Strength'].default_value=.8
    sun=bpy.data.lights.new('Presentation_sun','SUN');sun.energy=2.2;sun.angle=math.radians(9);ob=bpy.data.objects.new(sun.name,sun);sc.collection.objects.link(ob);ob.rotation_euler=Vector((.6,.7,-1)).to_track_quat('-Z','Y').to_euler()
    for name,pos,power,size in [('Fill',(10,-14,15),11000,15),('Rim',(-8,10,13),9000,12)]:
        light=bpy.data.lights.new('Presentation_'+name,'AREA');light.energy=power;light.shape='DISK';light.size=size
        ob=bpy.data.objects.new(light.name,light);sc.collection.objects.link(ob);ob.location=pos;ob.rotation_euler=(Vector((0,0,2.6))-ob.location).to_track_quat('-Z','Y').to_euler()
    cam=bpy.data.objects.new('Presentation_Camera',bpy.data.cameras.new('Presentation_Camera'));sc.collection.objects.link(cam);sc.camera=cam;cam.data.type='ORTHO';cam.data.sensor_fit='HORIZONTAL'
    return sc,cam
def main():
    cams={};metadata=[]
    for revision,path in [('r02',ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04_r02/cutlass_01.glb'),('r01',ROOT/'Assets/curated/frontier_illustrated_20261101/ships_pass04/cutlass_01.glb')]:
        bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(path),merge_vertices=True);bpy.context.view_layer.update();obs=[o for o in bpy.context.scene.objects if o.type=='MESH'];sc,cam=lighting();asp=sc.render.resolution_x/sc.render.resolution_y
        for name,d in [('front',review.direction(-38,30)),('rear',review.direction(142,30))]:
            if revision=='r02':cams[name]=review.fit(obs,d,asp)
            target,ortho=cams[name];p=QA/('presentation_'+revision+'_'+name+'.png');review.render(p,sc,cam,d,ortho,target)
            metadata.append({'revision':revision,'view':name,'path':str(p.relative_to(ROOT)).replace('\\','/'),'engine':'Blender5.2.3 EEVEE, fresh GLB','matched_camera_and_lighting':True,'direction_blender':list(d),'target':list(target),'orthographic_width_source_m':ortho,'resolution':[1600,1100],'view_transform':'AgX','look':'AgX - Medium High Contrast','exposure':-1.0,'asset_geometry_not_modified':True})
    (QA/'presentation_views.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
if __name__=='__main__':main()

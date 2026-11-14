import bpy,json
from pathlib import Path
from mathutils import Vector
OUT=Path(__file__).resolve().parents[1]/'art/ship_models_20261114/caterpillar'
views={'three_quarter':(10,-14,9),'side':(12,0,2.4),'top':(0,-.001,12)}
manifest={'engine':'BLENDER_WORKBENCH','resolution':[1280,800],'ortho_scale':9.0,'target':[0,0,.46],'cameras':views,'outputs':[]}
for label,blend in [('source','normalized_source.blend'),('candidate','caterpillar.blend')]:
    bpy.ops.wm.open_mainfile(filepath=str(OUT/blend));sc=bpy.context.scene;sc.frame_set(1)
    sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=1280;sc.render.resolution_y=800;sc.render.resolution_percentage=100
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='SINGLE';sh.single_color=(.58,.58,.58);sh.show_cavity=True;sh.show_shadows=True;sh.show_object_outline=True;sh.background_type='WORLD'
    sc.world.color=(.045,.045,.045);sc.render.image_settings.file_format='PNG'
    camdata=bpy.data.cameras.new('ComparisonCamera');cam=bpy.data.objects.new('ComparisonCamera',camdata);sc.collection.objects.link(cam);sc.camera=cam;camdata.type='ORTHO';camdata.ortho_scale=9
    for name,loc in views.items():
        cam.location=loc;cam.rotation_euler=(Vector((0,0,.46))-cam.location).to_track_quat('-Z','Y').to_euler()
        path=OUT/f'comparison_{label}_{name}.png';sc.render.filepath=str(path);bpy.ops.render.render(write_still=True);manifest['outputs'].append(path.name)
(OUT/'comparison_manifest.json').write_text(json.dumps(manifest,indent=2))

"""Render a transparent crew-card portrait from the existing white astronaut.
Blender --background --factory-startup --python tools/render_crew_portrait.py
Read-only source .blend; creates only assets/ui/crew_portrait.png.
"""
from pathlib import Path
import hashlib
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
SOURCE=ROOT/'assets/curated/crew/source/white_astronaut.blend'
OUTPUT=ROOT/'assets/ui/crew_portrait.png'
source_hash=hashlib.sha256(SOURCE.read_bytes()).hexdigest()
bpy.ops.wm.open_mainfile(filepath=str(SOURCE))
scene=bpy.context.scene
rig=bpy.data.objects['AstronautRig']
idle=bpy.data.actions.get('Idle')
if idle:
    rig.animation_data.action=idle
    if idle.slots:rig.animation_data.action_slot=idle.slots[0]
scene.frame_set(1)
bpy.context.view_layer.update()
helmet=bpy.data.objects['White_Astro_Helmet']
points=[helmet.matrix_world@Vector(point) for point in helmet.bound_box]
minimum=Vector([min(point[k] for point in points) for k in range(3)])
maximum=Vector([max(point[k] for point in points) for k in range(3)])
center=(minimum+maximum)*0.5
focus=center+Vector((0,0,-0.37))

def aim(obj,target):obj.rotation_euler=(target-obj.location).to_track_quat('-Z','Y').to_euler()
def area(name,offset,energy,size):
    bpy.ops.object.light_add(type='AREA',location=focus+Vector(offset))
    lamp=bpy.context.object;lamp.name=name;lamp.data.energy=energy;lamp.data.size=size;aim(lamp,focus)
area('Portrait key',(-3,-5,5),650,4)
area('Portrait fill',(4,-3,2),370,3)
area('Portrait rim',(2,3,4),700,3)
scene.world.use_nodes=True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value=(0.30,0.36,0.42,1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value=0.35
bpy.ops.object.camera_add(location=focus+Vector((2.5,-8,1.3)))
camera=bpy.context.object;camera.name='Crew portrait camera';aim(camera,focus)
camera.data.type='ORTHO';camera.data.ortho_scale=2.55
scene.camera=camera
scene.render.engine='CYCLES';scene.cycles.samples=64
scene.render.film_transparent=True
scene.render.resolution_x=256;scene.render.resolution_y=256;scene.render.resolution_percentage=100
scene.render.image_settings.file_format='PNG';scene.render.image_settings.color_mode='RGBA';scene.render.image_settings.color_depth='8'
scene.render.filepath=str(OUTPUT)
scene.view_settings.view_transform='AgX'
OUTPUT.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.render.render(write_still=True)
portrait=bpy.data.images.load(str(OUTPUT),check_existing=False)
assert tuple(portrait.size)==(256,256)
alpha=list(portrait.pixels)[3::4]
assert min(alpha)==0 and max(alpha)>0.99
assert hashlib.sha256(SOURCE.read_bytes()).hexdigest()==source_hash
print('CREW_PORTRAIT_VERIFIED',str(OUTPUT),'256x256 RGBA','source_sha256',source_hash,'helmet_bounds',list(minimum),list(maximum))

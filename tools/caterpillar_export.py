import bpy,json
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'caterpillar.blend'))
bpy.context.scene.frame_set(1)
bpy.ops.object.select_all(action='SELECT')
bpy.ops.export_scene.gltf(filepath=str(OUT/'caterpillar.glb'),export_format='GLB',use_selection=True,export_apply=True,export_extras=True,export_materials='EXPORT',export_yup=True,export_animations=True,export_animation_mode='SCENE',export_anim_scene_split_object=False,export_force_sampling=True)

"""Frame the deliverable copies for opening, preserving all mesh and texture data."""
from pathlib import Path
import bpy
from mathutils import Vector

ROOT=Path(__file__).resolve().parents[1]
for name in ('tanker_102m_clean_segmented.blend','tanker_102m_atlas_segmented.blend'):
    path=ROOT/'editable'/name
    bpy.ops.wm.open_mainfile(filepath=str(path),load_ui=False,use_scripts=False)
    bpy.context.preferences.filepaths.save_version=0
    direction=Vector((1,-1,0.72)).normalized()
    for screen in bpy.data.screens:
        for area in screen.areas:
            if area.type!='VIEW_3D':continue
            for space in area.spaces:
                if space.type!='VIEW_3D':continue
                space.clip_start=0.1;space.clip_end=10000
                space.shading.type='MATERIAL'
                space.shading.use_scene_world=False
                space.shading.use_scene_lights=False
                space.region_3d.view_perspective='ORTHO'
                space.region_3d.view_distance=155.0
                space.region_3d.view_location=Vector((0,0,14.44))
                space.region_3d.view_rotation=(-direction).to_track_quat('-Z','Y')
    for obj in bpy.context.scene.objects:obj.select_set(False)
    root=bpy.data.objects.get('Tanker_Rescue')
    if root:
        root.select_set(True);bpy.context.view_layer.objects.active=root
    bpy.ops.wm.save_as_mainfile(filepath=str(path),compress=True)
print('EDITABLE_VIEWPORTS_FRAMED')

"""Export the original Kenney medium rig in a white astro skin with its helmet.

Blender 5.1 --background --factory-startup --python tools/prepare_crew.py
Original FBX/PNG inputs are read only. Idle, walk and interaction are Kenney
animations. The attached helmet follows Head.
"""
from pathlib import Path
import shutil
import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
SOURCE = Path(r"C:\Users\bjoer\Pictures\Kenney Game Assets All-in-1 3.4.0\3D assets\Animated Characters Bundle")
OUTPUT = ROOT / "assets/curated/crew"
OUTPUT.mkdir(parents=True, exist_ok=True)
EDITABLE = OUTPUT / "source"
EDITABLE.mkdir(parents=True, exist_ok=True)
(EDITABLE / ".gdignore").write_text("",encoding="utf-8")
bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.fbx(filepath=str(SOURCE / "Models/characterMedium.fbx"))
rig = next(o for o in bpy.context.selected_objects if o.type == "ARMATURE")
body = next(o for o in bpy.context.selected_objects if o.type == "MESH")
rig.name = "AstronautRig"
rig.animation_data_clear()
for bone in rig.pose.bones:
    bone.matrix_basis.identity()
bpy.context.view_layer.update()

skin = bpy.data.materials.new("White_Astronaut_Suit")
skin.use_nodes = True
bsdf = skin.node_tree.nodes.get("Principled BSDF")
bsdf.inputs["Roughness"].default_value = 0.82
texture = skin.node_tree.nodes.new("ShaderNodeTexImage")
texture.image = bpy.data.images.load(str(SOURCE / "Skins/astroMaleA.png"))
texture.interpolation = "Closest"
skin.node_tree.links.new(texture.outputs["Color"], bsdf.inputs["Base Color"])
body.data.materials.clear()
body.data.materials.append(skin)
for face in body.data.polygons:
    face.material_index = 0

bpy.ops.import_scene.fbx(filepath=str(SOURCE / "Accessories/astroHelmet.fbx"))
helmet = next(o for o in bpy.context.selected_objects if o.type == "MESH")
helmet.name = "White_Astro_Helmet"
for mat in helmet.data.materials:
    # Legacy FBX materials import with an unused alpha of zero in Blender 5.
    mat.diffuse_color[3] = 1.0
    if mat.use_nodes:
        shader = mat.node_tree.nodes.get("Principled BSDF")
        if shader:
            shader.inputs["Alpha"].default_value = 1.0
points = [helmet.matrix_world @ Vector(v) for v in helmet.bound_box]
center = (Vector(tuple(min(p[i] for p in points) for i in range(3))) + Vector(tuple(max(p[i] for p in points) for i in range(3)))) * 0.5
head = rig.data.bones["Head"]
target = rig.matrix_world @ ((head.head_local + head.tail_local) * 0.5)
helmet.location += target - center
bpy.context.view_layer.update()
world = helmet.matrix_world.copy()
helmet.parent = rig
helmet.parent_type = "BONE"
helmet.parent_bone = "Head"
helmet.matrix_world = world

animations = []
rig.animation_data_create()
for file_name, display_name in [("idle.fbx", "Idle"), ("walk.fbx", "Walk"), ("interactStanding.fbx", "Work")]:
    prior_objects = set(bpy.data.objects)
    prior_actions = set(bpy.data.actions)
    bpy.ops.import_scene.fbx(filepath=str(SOURCE / "Animations" / file_name))
    imported = list(set(bpy.data.objects) - prior_objects)
    candidates = list(set(bpy.data.actions) - prior_actions)
    source_action = max(candidates, key=lambda a: a.frame_range[1] - a.frame_range[0])
    source_rig = next(obj for obj in imported if obj.type == "ARMATURE")
    source_rig.animation_data.action = source_action
    source_rig.animation_data.action_slot = source_action.slots[0]
    action = bpy.data.actions.new(display_name)
    action.use_fake_user = True
    rig.animation_data.action = action
    # Bundle animation FBXs use animation-specific rest poses. Bake rotations
    # relative to each parent onto the medium model's own rest skeleton.
    for frame in range(int(source_action.frame_range[0]), int(source_action.frame_range[1]) + 1):
        bpy.context.scene.frame_set(frame)
        for bone in rig.pose.bones:
            source_bone = source_rig.pose.bones.get(bone.name)
            if source_bone is None:
                continue
            target_rest = bone.bone.matrix_local
            source_rest = source_bone.bone.matrix_local
            if bone.parent:
                target_rest = bone.parent.bone.matrix_local.inverted() @ target_rest
            if source_bone.parent:
                source_rest = source_bone.parent.bone.matrix_local.inverted() @ source_rest
            bone.rotation_mode = "QUATERNION"
            bone.rotation_quaternion = target_rest.to_quaternion().inverted() @ source_rest.to_quaternion() @ source_bone.rotation_quaternion
            bone.location = (0, 0, 0)
            bone.scale = (1, 1, 1)
            bone.keyframe_insert(data_path="rotation_quaternion", frame=frame, group=bone.name)
    animations.append(action)
    for obj in imported:
        bpy.data.objects.remove(obj, do_unlink=True)
for action in list(bpy.data.actions):
    if action not in animations:
        bpy.data.actions.remove(action)

rig.animation_data_create()
for action in animations:
    track = rig.animation_data.nla_tracks.new()
    track.name = action.name
    strip = track.strips.new(action.name, int(action.frame_range[0]), action)
    strip.extrapolation = "NOTHING"
    track.mute = True
rig.animation_data.action = animations[0]
if len(animations[0].slots):
    rig.animation_data.action_slot = animations[0].slots[0]
bpy.context.scene.frame_set(1)
bpy.context.view_layer.update()
bpy.ops.object.select_all(action="DESELECT")
for obj in [rig, body, helmet]:
    obj.select_set(True)
bpy.context.view_layer.objects.active = rig

bpy.ops.file.pack_all()
bpy.ops.wm.save_as_mainfile(filepath=str(EDITABLE / "white_astronaut.blend"))
bpy.ops.export_scene.gltf(filepath=str(OUTPUT / "white_astronaut.glb"), export_format="GLB", use_selection=True, export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True, export_frame_range=False, export_apply=False)
shutil.copy2(SOURCE / "License.txt", ROOT / "assets/licenses/Animated-Characters-Bundle.txt")
print("CREW_EXPORT", OUTPUT / "white_astronaut.glb", "verts",sum(len(o.data.vertices) for o in [body,helmet]), "faces",sum(len(o.data.polygons) for o in [body,helmet]), "materials",len(body.data.materials)+len(helmet.data.materials), "animations",[a.name for a in animations])

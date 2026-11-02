"""FINAL USER CHOICE: unmodified Kenney astronaut forms, original skins/clips.

Uniform size normalization only. All custom heads, armor, anatomy and palettes
belong to rejected studies; none is loaded by this stock exporter.
"""
from pathlib import Path
import json,hashlib,struct,sys,shutil
import bpy
from mathutils import Matrix
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[2]
OUT=ROOT/'Assets/curated/frontier_illustrated_20261101/citizens'
PACK=Path('C:/Users/bjoer/Pictures/Kenney Game Assets All-in-1 3.4.0/3D assets/Animated Characters Bundle')
SRC=PACK/'Models/Source/characterMedium.blend'
SKINS=ROOT/'Assets/used/npc/animated_characters/skins'
QA=HERE/'qa'
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check,review_shots
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()

def motion(rig,scale):
 meta=[];samples={};control=[]
 for clip in ['idle','walk']:
  path=PACK/'Animations/Source'/(clip+'.blend')
  with bpy.data.libraries.load(str(path),link=False) as (df,dt):dt.actions=[n for n in df.actions if n.lower()==clip]
  a=dt.actions[0];a.name='StockSource_'+clip;control.append(a)
  for layer in a.layers:
   for strip in layer.strips:
    for cb in strip.channelbags:
     for fc in cb.fcurves:
      if fc.data_path.endswith('location'):
       for key in fc.keyframe_points:
        key.co[1]*=scale;key.handle_left[1]*=scale;key.handle_right[1]*=scale
  rig.animation_data_create();rig.animation_data.action=a;rig.animation_data.action_slot=next(iter(a.slots))
  rows=[]
  for f in range(round(a.frame_range[0]),round(a.frame_range[1])+1):
   bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
   rows.append((f,{p.name:p.matrix.copy() for p in rig.pose.bones}))
  samples[clip]=rows;meta.append({'name':clip,'source':str(path),'sha256':sha(path),'source_frames':list(a.frame_range)})
 rig.animation_data.action=None
 for p in rig.pose.bones:
  for c in list(p.constraints):p.constraints.remove(c)
 for clip,rows in samples.items():
  a=bpy.data.actions.new(clip);a.use_fake_user=True;rig.animation_data.action=a
  for f,matrices in rows:
   bpy.context.scene.frame_set(f)
   for p in rig.pose.bones:
    p.rotation_mode='QUATERNION';p.matrix=matrices[p.name];bpy.context.view_layer.update()
    p.keyframe_insert('location',frame=f);p.keyframe_insert('rotation_quaternion',frame=f);p.keyframe_insert('scale',frame=f)
  err=0
  for f,matrices in rows:
   bpy.context.scene.frame_set(f);bpy.context.view_layer.update()
   err=max(err,max((p.matrix.translation-matrices[p.name].translation).length for p in rig.pose.bones))
  meta[[m['name'] for m in meta].index(clip)]['bake_position_error_m']=err
  if err>.0001:raise RuntimeError('Stock animation bake mismatch')
  track=rig.animation_data.nla_tracks.new();track.name='CLIP_'+clip
  st=track.strips.new(clip,0,a);st.action_slot=rig.animation_data.action_slot;track.mute=True
 rig.animation_data.action=None
 for a in control:bpy.data.actions.remove(a)
 for p in rig.pose.bones:p.matrix_basis=Matrix.Identity(4)
 bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
 return meta

def build(role,skin):
 bpy.ops.wm.open_mainfile(filepath=str(SRC))
 rig=bpy.data.objects['Root'];body=bpy.data.objects['characterMedium'];rig.animation_data_clear()
 for o in list(bpy.context.scene.objects):
  if o not in [rig,body]:bpy.data.objects.remove(o,do_unlink=True)
 points=[v.co for v in body.data.vertices];floor=min(p.z for p in points);height=max(p.z for p in points)-floor;scale=1.78/height
 def fit(v):return (v.x*scale,v.y*scale,(v.z-floor)*scale)
 for v in body.data.vertices:v.co=fit(v.co)
 bpy.context.view_layer.objects.active=rig;rig.select_set(True);bpy.ops.object.mode_set(mode='EDIT')
 old={b.name:(b.head.copy(),b.tail.copy(),b.use_connect) for b in rig.data.edit_bones}
 for b in rig.data.edit_bones:b.use_connect=False
 for b in rig.data.edit_bones:b.head=fit(old[b.name][0]);b.tail=fit(old[b.name][1])
 for b in rig.data.edit_bones:b.use_connect=old[b.name][2]
 bpy.ops.object.mode_set(mode='OBJECT')
 m=bpy.data.materials.new('M_Kenney_'+skin);bs=next(n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(str(SKINS/(skin+'.png')),check_existing=True)
 tex.interpolation='Linear';m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);bs.inputs['Roughness'].default_value=.8
 body.data.materials.clear();body.data.materials.append(m)
 for p in body.data.polygons:p.material_index=0
 clips=motion(rig,scale)
 bpy.context.scene.render.fps=30;bpy.context.scene.frame_start=0;bpy.context.scene.frame_end=32
 bpy.context.scene.unit_settings.system='METRIC';bpy.context.scene.unit_settings.scale_length=1
 raw=qa_check.run(objects=[body.name],profile='game',uv=True)
 (QA/(role+'_stock_raw.json')).write_text(json.dumps(raw,indent=2),encoding='utf-8')
 blend=HERE/(role+'_stock.blend');bpy.ops.wm.save_as_mainfile(filepath=str(blend))
 bpy.ops.object.select_all(action='DESELECT');body.select_set(True);rig.select_set(True);bpy.context.view_layer.objects.active=rig
 target=OUT/(role+'.glb')
 bpy.ops.export_scene.gltf(filepath=str(target),export_format='GLB',use_selection=True,export_yup=True,
  export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=True,export_skins=True,
  export_def_bones=True,export_all_influences=False,export_materials='EXPORT')
 buf=target.read_bytes();n=struct.unpack_from('<I',buf,12)[0];gl=json.loads(buf[20:20+n])
 result={'role_label':role,'choice':'FINAL USER CHOICE: stock Kenney astronaut; no custom body/head/gear/material reinterpretation',
  'source':str(SRC),'source_sha256':sha(SRC),'source_bundle':'Kenney Animated Characters Bundle 4.0','license':'CC0',
  'editable':str(blend.relative_to(ROOT)),'editable_sha256':sha(blend),'glb':str(target.relative_to(ROOT)),'glb_sha256':sha(target),
  'skin':str((SKINS/(skin+'.png')).relative_to(ROOT)),'skin_sha256':sha(SKINS/(skin+'.png')),
  'uniform_scale':scale,'source_floor':floor,'source_height':height,'height_m':1.78,'vertices':len(body.data.vertices),
  'triangles':sum(len(p.vertices)-2 for p in body.data.polygons),'bones':[b.name for b in rig.data.bones],
  'mesh_count':len(gl.get('meshes',[])),'skin_count':len(gl.get('skins',[])),'material_count':len(gl.get('materials',[])),
  'embedded_images':len(gl.get('images',[])),'animations':[a['name'] for a in gl.get('animations',[])],
  'original_motion':clips,'raw_qa_pass':raw['pass'],'errors':raw['errors'],'warnings':raw['warnings'],
  'coordinates':'Blender -Y front/Z up -> glTF and Godot +Z front/Y up; uniform metres; floor origin',
  'note':'Role labels select original skins only; stock geometry/proportions/UV and original weights retained.'}
 (QA/(role+'_stock_manifest.json')).write_text(json.dumps(result,indent=2),encoding='utf-8')
 print('STOCK_READY '+json.dumps(result));return result

if __name__=='__main__':
 roles=[('operator','astroMaleA'),('pilot','astroFemaleB'),('mechanic','astroMaleB'),('medic','astroFemaleA')]
 records=[build(role,skin) for role,skin in roles]
 (QA/'stock_manifest.json').write_text(json.dumps({'generator':str(Path(__file__).relative_to(ROOT)),'generator_sha256':sha(Path(__file__)),'assets':records},indent=2),encoding='utf-8')
 shutil.copy2(ROOT/'Assets/used/npc/animated_characters/License.txt',HERE/'KENNEY_LICENSE.txt')

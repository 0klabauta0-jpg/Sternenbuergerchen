"""Re-open editable native Blender source and render actual mesh multi-views."""
import bpy, sys, json
from pathlib import Path
from collections import defaultdict
ART=Path(__file__).resolve().parent
bpy.ops.wm.open_mainfile(filepath=str(ART/'armor_r06_editable.blend'))
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import review_shots
reviews=[]
for name in ['torso_light','torso_medium','torso_heavy','pauldron_light','pauldron_medium','pauldron_heavy','knee_light','knee_medium','knee_heavy','forearm_medium','shin_medium','shin_heavy','thigh_medium','thigh_heavy']:
 ob=bpy.data.objects[name]
 coords=defaultdict(list)
 for v in ob.data.vertices:coords[tuple(round(x,6) for x in v.co)].append(v.index)
 print('DUPLICATES',name,{str(k):v for k,v in coords.items() if len(v)>1})
 for mode in ['material','wire']:
  reviews.append(review_shots.run(objects=[name],out=str(ART/(name+'_'+mode+'.png')),mode=mode,res=512,views=['front','right','top','three_quarter']))
(ART/'review_shots.json').write_text(json.dumps(reviews,indent=2),encoding='utf8')
bpy.ops.wm.open_mainfile(filepath=str(ART/'body_r06_editable.blend'))
for mode in ['material','wire']:
 reviews.append(review_shots.run(objects=['characterMedium'],out=str(ART/('body_'+mode+'.png')),mode=mode,res=512,views=['front','right','back','three_quarter']))
(ART/'review_shots.json').write_text(json.dumps(reviews,indent=2),encoding='utf8')
print('R06_REVIEW_DONE',len(reviews))

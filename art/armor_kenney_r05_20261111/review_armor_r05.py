"""Re-open editable native Blender source and render actual mesh multi-views."""
import bpy, sys, json
from pathlib import Path
from collections import defaultdict
ART=Path(__file__).resolve().parent
sys.path.insert(0,str(Path.home()/'.codex/skills/blender-asset-qa/scripts'))
import review_shots
reviews=[]
for name in ['helmet_light','helmet_medium','helmet_heavy','torso_medium','torso_heavy','pauldron_medium','pauldron_heavy','forearm_medium','shin_medium','thigh_heavy','boot_medium']:
 ob=bpy.data.objects[name]
 coords=defaultdict(list)
 for v in ob.data.vertices:coords[tuple(round(x,6) for x in v.co)].append(v.index)
 print('DUPLICATES',name,{str(k):v for k,v in coords.items() if len(v)>1})
 for mode in ['material','wire']:
  reviews.append(review_shots.run(objects=[name],out=str(ART/(name+'_'+mode+'.png')),mode=mode,res=512,views=['front','right','top','three_quarter']))
(ART/'review_shots.json').write_text(json.dumps(reviews,indent=2),encoding='utf8')
print('R05_REVIEW_DONE',len(reviews))

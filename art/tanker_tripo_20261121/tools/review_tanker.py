"""Independent background Blender review; does not save or touch the live scene."""
import json, sys
from pathlib import Path
import bpy

ROOT=Path(__file__).resolve().parents[1]
sys.path.insert(0,r'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
sys.path.insert(0,str(Path(__file__).parent))
import review_shots_safe as review_shots
bpy.ops.wm.open_mainfile(filepath=str(ROOT/'editable/tanker_102m_clean_segmented.blend'),load_ui=False,use_scripts=False)
obs=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
reports={}
for mode in ('random','wire'):
    reports[mode]=review_shots.run(objects=obs,out=str(ROOT/'qa'/('review_'+mode+'.png')),
        views=['front','back','top','three_quarter'],mode=mode,res=640)
(ROOT/'qa/review_sheets.json').write_text(json.dumps(reports,indent=2)+'\n',encoding='utf-8')
print('REVIEW_SHEETS_COMPLETE')

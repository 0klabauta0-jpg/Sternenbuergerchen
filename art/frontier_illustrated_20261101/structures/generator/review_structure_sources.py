"""Refresh QA views without changing final source or curated exports."""
import bpy,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).parent))
import build_structures as b
for asset in ('habitat_01','workshop_01','service_unit_01'):
    bpy.ops.wm.open_mainfile(filepath=str(b.ART/'source'/(asset+'.blend')))
    b.PARTS=[o for o in bpy.context.scene.objects if o.type=='MESH']
    lo,hi=b.bounds(b.PARTS)
    b.preview(asset,hi-lo)

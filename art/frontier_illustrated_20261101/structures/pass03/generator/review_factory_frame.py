from pathlib import Path
import bpy,sys,json
from mathutils import Vector
HERE=Path(__file__).resolve().parents[1];sys.path.insert(0,str(HERE/'generator'))
import review_cutaways as review
bpy.ops.wm.open_mainfile(filepath=str(HERE/'source/freihafen_hall_01.blend'))
ob=bpy.data.objects['Kenney_Factory_OpenPortal']
for o in bpy.context.scene.objects:o.hide_render=o!=ob
sc,cam=review.setup();target,ortho=review.fitted_camera([ob],Vector((0,-1,0)),sc.render.resolution_x/sc.render.resolution_y)
review.render(HERE/'qa/kenney_sources/derived_factory_frame.png',sc,cam,(0,-1,0),ortho,target)
print(json.dumps({'z':sorted({round(v.co.z,5) for v in ob.data.vertices}),'x':sorted({round(v.co.x,5) for v in ob.data.vertices})}))

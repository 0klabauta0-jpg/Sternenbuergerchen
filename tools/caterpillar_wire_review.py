"""Use QA renderer with non-mitered wire overlay for skinny decimated triangles.
The default Wireframe even-offset miters create artificial long spikes. This
changes only the temporary diagnostic overlay, never the source/export mesh.
"""
import bpy
from pathlib import Path
OUT=Path(__file__).resolve().parents[1]/'art/ship_models_20261114/caterpillar'
bpy.ops.wm.open_mainfile(filepath=str(OUT/'caterpillar.blend'))
path=Path('C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts/review_shots.py')
code=path.read_text();old='w.modifiers.new("QA_Wire", "WIREFRAME").thickness = wire_t'
new='wire = w.modifiers.new("QA_Wire", "WIREFRAME"); wire.thickness = wire_t; wire.use_even_offset = False'
assert old in code
scope={'__name__':'caterpillar_review_shots','__file__':str(path)};exec(compile(code.replace(old,new),str(path),'exec'),scope)
names=[o.name for o in bpy.context.scene.objects if o.type=='MESH']
scope['run'](objects=names,out=str(OUT/'candidate_wire.png'),views=['front','back','left','right','top','three_quarter'],mode='wire',res=700)

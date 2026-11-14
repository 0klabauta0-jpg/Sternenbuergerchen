"""Apply an inspected Godot rock proposal to the unchanged task foundation.
Only this task's GM01 cells/metadata and four legacy access ramps are authored.
"""
import json,subprocess,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
proposal=json.loads(Path(sys.argv[1]).read_text(encoding='utf-8'))
path=ROOT/'maps/Ground_Mission01_32x32.json'
source=json.loads(subprocess.check_output(['git','show','c3ab18593:maps/Ground_Mission01_32x32.json'],cwd=ROOT).decode('utf-8'))
tiles={(v['grid_position']['x'],v['grid_position']['y']):v for v in source['tiles']}
for q,r in proposal['new_blockers']:tiles[int(q),int(r)].update(object_type_id='frontier_scene_solid',walkable=False,blocks_los=True,object_height=3,cover_value=65)
for q,r,level,owner in proposal['cells']:tiles[int(q),int(r)].update(height_level=int(level),walkable=True,blocks_los=False,object_height=0,cover_value=0,edge_type='cliff',surface_type='rock')
source['terrain_height_rules']='explicit_hex_ramps_v1'
for tile in source['tiles']:
 if tile['type_id']=='slope_se':tile.update(type_id='ground_flat',height_level=0,ramp_direction=0,surface_type='road',edge_type='slope')
source.setdefault('place_presentation',{}).update(rock_surface_cells=proposal['cells'],rock_surfaces_revision='physical_mesa_caps_v1',rock_envelope_cells=proposal['new_blockers'])
path.write_text(json.dumps(source,ensure_ascii=False,indent='\t')+'\n',encoding='utf-8')
print('Applied',len(proposal['cells']),'full rock surface cells')

"""Offline authored map revision; all navigation/LOS facts are saved in MapData."""
import json,math,hashlib
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
def migrate_station(d):
 layout=d['place_presentation']['station_module_layout']
 if layout.get('rooms_revision')=='closed_cross_v1':return
 ts={(t['grid_position']['x'],t['grid_position']['y']):t for t in d['tiles']}
 for reg in layout['regions']:
  a=reg['row_anchor'];l,t,r,b=reg['floor_boundary'];cx=(l+r)//2;cy=(t+b)//2
  def tile(q,y):return ts[(q-(y-a)//2,y)]
  # Clear the former incomplete divider and displaced leaves, then author the
  # complete ring. Existing exterior east doorway remains the scenario owner.
  east={k:dict(tile(*k)) for k in [(r,cy),(r+1,cy)]}
  for y in range(t-1,b+2):
   for q in range(l-1,r+2):
    v=tile(q,y)
    if v.get('object_type_id','').startswith(('station_set_wall','station_set_door')):
     v.update(object_type_id='',walkable=True,blocks_los=False,object_height=0,cover_value=0,object_rotation_degrees=0)
  for y in range(t,b+1):
   for q in range(l,r+1):
    v=tile(q,y)
    if q not in [l,r,cx] and y not in [t,b,cy]:continue
    v.update(type_id='station_set_floor_panel',height_level=1,object_type_id='station_set_wall',walkable=False,blocks_los=True,object_height=2,cover_value=60,object_rotation_degrees=90.0 if q in [l,r,cx] else 0.0)
    if q in [l,r] and y in [t,b]:v['object_type_id']='station_set_wall_corner'
  # Open single-leaf passage assets are actual reachable cells; the external
  # east breach retains the existing two-cell authoritative door interaction.
  doors=[(cx,t+3),(cx,b-3),(l+3,cy),(r-3,cy)]
  for q,y in doors:
   tile(q,y).update(object_type_id='station_set_door_single',walkable=True,blocks_los=False,object_height=0,cover_value=0,object_rotation_degrees=90.0 if q==cx else 0.0)
  for (q,y),v in east.items():tile(q,y).update(v)
  reg['rooms']=[{'id':str(i+1),'source_center':[q,y]} for i,(q,y) in enumerate([(l+3,t+3),(r-3,t+3),(l+3,b-3),(r-3,b-3)])]
  reg['single_door_cells']=[[q-(y-a)//2,y] for q,y in doors]
  reg['module_count']=sum(1 for y in range(t-1,b+2) for q in range(l-1,r+2) if tile(q,y).get('object_type_id','').startswith(('station_set_wall','station_set_door')))
 layout['rooms_revision']='closed_cross_v1'
 # Former white flower models are replaced by sparse existing desert stone,
 # keeping each authored cover/blocker fact and making the replacement editable.
 for v in d['tiles']:
  if v.get('object_type_id')=='nature_bush_cover':v['object_type_id']='nature_rock_cover'
 return d

def main():
 for n in ['station_outpost_64x64','station_outpost_192x192']:
  p=ROOT/'maps'/(n+'.json');d=json.loads(p.read_text(encoding="utf-8"));migrate_station(d);p.write_text(json.dumps(d,ensure_ascii=False,indent='\t')+'\n',encoding='utf-8')
if __name__=='__main__':main()

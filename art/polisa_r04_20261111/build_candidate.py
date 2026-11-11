"""Deterministic authored Polisa facts. No product map or runtime mutation."""
import json, math, hashlib
from pathlib import Path
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
ART=Path(__file__).resolve().parent
OUT=ROOT/'output/native_glut_maps/polisa_r04_20261111'
OUT.mkdir(parents=True,exist_ok=True)
L=json.loads((ART/'layout.json').read_text(encoding='utf-8'))
D=[(1,0),(1,-1),(0,-1),(-1,0),(-1,1),(0,1)]
def rect(center,size):
 x,z=center; w,h=size
 return [x-w/2,z-h/2,x+w/2,z+h/2]
def inside(p,r):return r[0]-1e-7<=p[0]<=r[2]+1e-7 and r[1]-1e-7<=p[1]<=r[3]+1e-7
def plane(g):return (g[0]+g[1]/2,g[1]*math.sqrt(3)/2)
def nearest(p,grids):return min(grids,key=lambda g:((plane(g)[0]-p[0])**2+(plane(g)[1]-p[1])**2,g))
# Exact convex SAT between a full hex and every authored rectangular blocker.
corners=[(math.cos(math.radians(30+60*i))/math.sqrt(3),math.sin(math.radians(30+60*i))/math.sqrt(3)) for i in range(6)]
def overlaps(poly,r):
 box=[(r[0],r[1]),(r[2],r[1]),(r[2],r[3]),(r[0],r[3])]
 axes=[(1,0),(0,1)]
 for a,b in zip(poly,poly[1:]+poly[:1]):axes.append((a[1]-b[1],b[0]-a[0]))
 for ax in axes:
  ap=[p[0]*ax[0]+p[1]*ax[1] for p in poly]; bp=[p[0]*ax[0]+p[1]*ax[1] for p in box]
  if max(ap)<=min(bp)+1e-6 or max(bp)<=min(ap)+1e-6:return False
 return True

origin=L['origin_plane']
def world(p):return [p[0]+origin[0],p[1]+origin[1]]
def wr(r):return [r[0]+origin[0],r[1]+origin[1],r[2]+origin[0],r[3]+origin[1]]
decks=L['decks']+[{'id':p['id'],'rect':rect(p['center'],p['size']),'kind':'pad'} for p in L['pads']]
world_decks=[wr(d['rect']) for d in decks]
solids=[dict(w,kind='wall') for w in L['walls']]+L['furniture']
world_solids=[wr(s['rect']) for s in solids]
tiles=[];walk=set();allgrids=set()
left,top,right,bottom=L['grid_offset_bounds']
for r in range(top,bottom+1):
 for column in range(left,right+1):
  g=(column-r//2,r);x,z=plane(g);poly=[(x+cx,z+cz) for cx,cz in corners]
  if not all(any(inside(v,d) for d in world_decks) for v in [(x,z)]+poly):continue
  blocked=any(overlaps(poly,s) for s in world_solids)
  tiles.append({'grid_position':{'x':g[0],'y':g[1]},'type_id':'ground_flat','height_level':0,'surface_type':'road','edge_type':'none','walkable':not blocked,'blocks_los':blocked,'object_height':3 if blocked else 0,'cover_value':60 if blocked else 0})
  allgrids.add(g)
  if not blocked:walk.add(g)
# Frozen R03 candidate is provenance, never the concurrently changed production map.
baseline=ART/'source_r03_map.json'
data=json.loads(baseline.read_text(encoding='utf-8'))
data['grid_size']={'x':256,'y':256};data['map_name']='Polisa / Stationskante R04';data['tiles']=tiles
retained=set(data['markers'])-{'polisa_pad_06'}
data['markers'].pop('polisa_pad_06',None)
anchors={}
for mid,p in L['markers'].items():
 g=nearest(world(p),walk);x,z=plane(g)
 marker=data['markers'].get(mid,{'marker_type_id':'spawn_alpha','name':mid,'placement_context':'editor_only','symbol':'circle'})
 marker.update({'x':(x-z)*64,'y':(x+z)*32});data['markers'][mid]=marker
 anchors[mid]={'local_plane':p,'world_plane':[x,z],'grid':g,'world_iso':[marker['x'],marker['y']]}
data['place_presentation']['initial_camera_size']=66
data['place_presentation']['props']=[{'path':'res://art/polisa_r04_20261111/polisa_r04_visual.tscn','center':origin,'scale':1.0}]
data['place_presentation']['pads']=[] # This field spawns FrontierOutpostPad dressing; owned station pads are already rendered.
data['place_world']['layout_revision']='polisa_r04'
data['place_world']['space_bounds_plane']=L['space_bounds']
data['place_world']['station_origin_plane']=origin
path=OUT/'polisa_station_candidate.json';path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
derived={k:L[k] for k in ['schema','origin_plane','space_bounds','walls','rooms','furniture','pads','engineering','globe','standard_camera']}
derived['decks']=decks;derived['layout_sha256']=hashlib.sha256((ART/'layout.json').read_bytes()).hexdigest()
(ART/'layout_compiled.json').write_text(json.dumps(derived,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
start=nearest(world(L['markers']['trade_service']),walk);seen={start};queue=deque([start])
while queue:
 g=queue.popleft()
 for dx,dy in D:
  n=(g[0]+dx,g[1]+dy)
  if n in walk and n not in seen:seen.add(n);queue.append(n)
room_anchors={}
for room in L['rooms']:
 g=nearest(world(room['service_anchor']),walk)
 room_anchors[room['id']]={'grid':g,'world_plane':plane(g),'reachable':g in seen and inside(plane(g),wr(room['rect']))}
checks={'single_walkable_component':walk==seen,'retained_marker_ids':retained.issubset(data['markers']),'exactly_five_front_pads':len(L['pads'])==5 and all(p['center'][1]-p['size'][1]/2>=40 for p in L['pads']),'pad06_removed':'polisa_pad_06' not in data['markers'],'rooms_reachable':all(r['reachable'] for r in room_anchors.values()),'markers_reachable':all(tuple(a['grid']) in seen for a in anchors.values()),'no_deck_behind_wall':min(plane(g)[1] for g in allgrids)>=-88,'rings_diameter_covers_large_pad':L['engineering']['ring_radius']*2>=max(p['size'][1] for p in L['pads'])}
envelopes=[]
for pad in L['pads']:
 er=rect(world(pad['center']),pad['reserve_envelope']);entries=[g for g in allgrids if inside(plane(g),er)]
 envelopes.append({'id':pad['id'],'deck':pad['size'],'reserve_envelope':pad['reserve_envelope'],'clear_cells':len(entries),'clear':bool(entries) and all(g in walk for g in entries),'margin_per_side':[3,3]})
ring_inset=min(abs(x) for x in L['engineering']['ring_x'])-L['engineering']['ring_radius']*abs(math.sin(math.radians(L['engineering']['ring_yaw_degrees'])))-1.15*abs(math.cos(math.radians(L['engineering']['ring_yaw_degrees'])))
checks['rings_clear_all_pad_rectangles']=ring_inset>max(abs(p['center'][0])+p['size'][0]/2 for p in L['pads'])
checks['no_duplicate_pad_dressing']=data['place_presentation']['pads']==[]
checks['pad_envelopes_clear']=all(e['clear'] for e in envelopes)
gc=world(L['globe']['center']);ring=[(gc[0]+4.8*math.cos(i*math.tau/24),gc[1]+4.8*math.sin(i*math.tau/24)) for i in range(24)]
checks['globe_walkaround']=all(nearest(p,walk) in seen and math.dist(plane(nearest(p,walk)),p)<.8 for p in ring)
report={'checks':checks,'tile_count':len(tiles),'walkable':len(walk),'reachable':len(seen),'blocked':len(allgrids-walk),'unreachable_sample':list(sorted(walk-seen))[:10],'pad_envelopes':envelopes,'marker_anchors':anchors,'room_service_anchors':room_anchors,'rooms':len(L['rooms']),'walls':len(L['walls']),'furniture':len(L['furniture']),'layout_sha256':derived['layout_sha256'],'map_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'space_bounds_plane':L['space_bounds'],'station_deck_z_bounds':[min(plane(g)[1] for g in allgrids),max(plane(g)[1] for g in allgrids)],'scope':'offline authoring graph; not live navigation, travel, shop or landing acceptance'}
(OUT/'offline_checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:report[k] for k in ['checks','tile_count','walkable','reachable','blocked','unreachable_sample','station_deck_z_bounds']},indent=2))
assert all(checks.values()),'Authoring checks failed'

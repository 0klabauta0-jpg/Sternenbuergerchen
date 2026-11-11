"""Deterministic authored Polisa facts. No product map or runtime mutation."""
import json, math, hashlib
from pathlib import Path
from collections import deque
ROOT=Path(__file__).resolve().parents[2]
ART=Path(__file__).resolve().parent
OUT=ROOT/'output/native_glut_maps/polisa_r03_20261111'
OUT.mkdir(parents=True,exist_ok=True)
L=json.loads((ART/'layout.json').read_text(encoding='utf-8'))
D=[(1,0),(1,-1),(0,-1),(-1,0),(-1,1),(0,1)]
def rect(center,size):
 x,z=center; w,h=size
 return [x-w/2,z-h/2,x+w/2,z+h/2]
def inside(p,r):return r[0]-1e-7<=p[0]<=r[2]+1e-7 and r[1]-1e-7<=p[1]<=r[3]+1e-7
def plane(g):return (g[0]+g[1]/2,g[1]*math.sqrt(3)/2)
def nearest(p,grids):return min(grids,key=lambda g:((plane(g)[0]-p[0])**2+(plane(g)[1]-p[1])**2,g))
decks=[{'id':'hub','rect':L['hub'],'kind':'hub'}]
for p in L['pads']:
 decks += [{'id':p['id'],'rect':rect(p['center'],p['size']),'kind':'pad'}, {'id':p['id']+'_bridge','rect':p['bridge'],'kind':'bridge'}]
walls=[]
def wall(r,height,rid,window=False):
 walls.append({'rect':r,'height':height,'room':rid,'window':window})
def horizontal(lo,hi,z,door,width,height,rid,window):
 if door is None:wall([lo,z-.35,hi,z+.35],height,rid,window);return
 for a,b in [(lo,door-width/2),(door+width/2,hi)]:
  if b>a:wall([a,z-.35,b,z+.35],height,rid,window)
for room in L['rooms']:
 x0,z0,x1,z1=room['rect']; rid=room['id']
 # Real door apertures in both corridor frontage and outer pad-facing walls.
 horizontal(x0,x1,room['inner_z'],room['door_x'],room['door_width'],1.25,rid,True)
 horizontal(x0,x1,room['outer_z'],room['outer_door_x'],4.4,3.15 if room['outer_z']<0 else 1.25,rid,room['outer_z']>0)
 wall([x0-.35,z0,x0+.35,z1],2.6,rid)
 wall([x1-.35,z0,x1+.35,z1],2.6,rid)
solids=[dict(w,kind='wall') for w in walls]+L['furniture']
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
tiles=[]; walk=set(); allgrids=set(); owner={}
for r in range(-96,96):
 for q in range(-96,96):
  g=(q,r); x,z=plane(g); poly=[(x+cx,z+cz) for cx,cz in corners]
  if not all(any(inside(v,d['rect']) for d in decks) for v in [(x,z)]+poly):continue
  blocked=[i for i,s in enumerate(solids) if overlaps(poly,s['rect'])]
  tile={'grid_position':{'x':q,'y':r},'type_id':'ground_flat','height_level':0,'surface_type':'road','edge_type':'none','walkable':not blocked,'blocks_los':bool(blocked),'object_height':3 if blocked else 0,'cover_value':60 if blocked else 0}
  tiles.append(tile);allgrids.add(g)
  if not blocked:walk.add(g)
  else:owner[f'{q},{r}']=blocked
data=json.loads((ROOT/'maps/polisa_station.json').read_text(encoding='utf-8'))
data['grid_size']={'x':192,'y':192};data['map_name']='Polisa / Handelsring R03';data['tiles']=tiles
for mid,p in L['markers'].items():
 g=nearest(p,walk);x,z=plane(g)
 marker=data['markers'].get(mid,{'marker_type_id':'spawn_alpha','name':mid,'placement_context':'editor_only','symbol':'circle'})
 marker.update({'x':(x-z)*64,'y':(x+z)*32}); data['markers'][mid]=marker
data['place_presentation']['initial_camera_size']=118
data['place_presentation']['props']=[{'path':'res://art/polisa_r03_20261111/polisa_r03_visual.tscn','center':[0,0],'scale':1.0}]
data['place_presentation']['pads']=[{'id':p['id'],'center':p['center'],'size':p['size'],'class':p['class']} for p in L['pads']]
data['place_world']['layout_revision']='polisa_r03'
path=OUT/'polisa_station_candidate.json'
path.write_text(json.dumps(data,ensure_ascii=False,separators=(',',':'))+'\n',encoding='utf-8')
derived={'schema':L['schema'],'decks':decks,'walls':walls,'rooms':L['rooms'],'furniture':L['furniture'],'pads':L['pads'],'engineering':L['engineering'],'layout_sha256':hashlib.sha256((ART/'layout.json').read_bytes()).hexdigest()}
(ART/'layout_compiled.json').write_text(json.dumps(derived,indent=2)+'\n',encoding='utf-8')
# Bounded, offline authoring checks, including full deck connectivity and actual apertures.
start=nearest(L['markers']['trade_service'],walk);seen={start};queue=deque([start])
while queue:
 g=queue.popleft()
 for dx,dy in D:
  n=(g[0]+dx,g[1]+dy)
  if n in walk and n not in seen:seen.add(n);queue.append(n)
checks={'single_walkable_component':seen==walk,'retained_marker_ids':set(json.loads((ROOT/'maps/polisa_station.json').read_text())['markers']).issubset(data['markers']), 'six_pads':len(L['pads'])==6,'three_pads_each_z':all(sum(1 for p in L['pads'] if p['center'][1]*sign>0)==3 for sign in [-1,1]),'no_x_end_pads':all(abs(p['center'][0])<=26 for p in L['pads']), 'rooms_reachable':all(nearest(r['service_anchor'],walk) in seen for r in L['rooms']), 'markers_reachable':all(nearest(p,walk) in seen for p in L['markers'].values())}
envelopes=[]
for p in L['pads']:
 size=p['size'];env=L['large_pad_design_envelope'] if p['class']=='L' else [14,14]
 er=rect(p['center'],env); entries=[g for g in allgrids if inside(plane(g),er)]
 ok=bool(entries) and all(g in walk for g in entries) and all(size[i]-env[i]>=4 for i in [0,1])
 envelopes.append({'id':p['id'],'deck':size,'reserve_envelope':env,'clear_cells':len(entries),'clear':ok,'margin_per_side':[(size[i]-env[i])/2 for i in [0,1]]})
checks['pad_envelopes_clear']=all(e['clear'] for e in envelopes)
report={'checks':checks,'tile_count':len(tiles),'walkable':len(walk),'reachable':len(seen),'blocked':len(allgrids-walk),'unreachable_sample':list(sorted(walk-seen))[:10],'pad_envelopes':envelopes,'rooms':len(L['rooms']),'walls':len(walls),'furniture':len(L['furniture']),'layout_sha256':derived['layout_sha256'],'map_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'scope':'offline authored facts only; no actual navigation/travel/shop/ship landing validation'}
(OUT/'offline_checks.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
assert all(checks.values()),'Authoring checks failed'

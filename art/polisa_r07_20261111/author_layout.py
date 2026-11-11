"""R07: owning homebase pad dimensions; new composition, unchanged human assets."""
import json,hashlib
from pathlib import Path
A=Path(__file__).resolve().parent
ROOT=A.parents[1]
SOURCE=ROOT/'maps/homebase_frontier_exploration.json'
H=json.loads(SOURCE.read_text(encoding='utf-8'))
assert H['grid_topology']=='hex_axial_v1'
homepads=H['homebase_exploration']['landing_pads']
S=[float(v) for v in homepads[0]['size']]
assert S==[float(v) for v in homepads[1]['size']], 'Homebase pads diverged; authoring needs review'
M=[S[0]*1.5,S[1]*2];LARGE=[S[0]*2,S[1]*4]
def rr(x,z,w,d):return [x-w/2,z-d/2,x+w/2,z+d/2]
L={'schema':'polisa_authored_layout_v7','origin_plane':[0,-70],'grid_size':[512,256],'grid_offset_bounds':[-256,-104,255,151],'space_bounds':[-256,-90,256,132],'standard_camera':{'yaw':24,'pitch':50,'size':62,'focus_local':[0,14]},'sectors':[{'id':'B','center_x':0,'hub':[-14,0,14,20],'concourse':[-42,18,42,24]}],'decks':[{'id':'hub','rect':[-14,0,14,20],'kind':'hub'},{'id':'concourse','rect':[-42,18,42,24],'kind':'bridge'}],'walls':[],'rooms':[],'furniture':[],'pads':[],'markers':{},'blocked_zones':[],'technical_modules':[],'globe':{'centers':[[0,10]]},'pad_aliases':{},'pad_scale_source':{'path':SOURCE.relative_to(ROOT).as_posix(),'json_pointer':'/homebase_exploration/landing_pads/0/size','checked_peer':'/homebase_exploration/landing_pads/1/size','sha256':hashlib.sha256(SOURCE.read_bytes()).hexdigest(),'small_size':S,'medium_multipliers':[1.5,2],'large_multipliers':[2,4],'reserve_margin':.65},'engineering':{'ring_x':[-42,42],'ring_z':21,'ring_center_y':-12,'ring_radius':24,'ring_width':3.2,'ring_yaw_degrees':0,'axle_x':[-82,82],'solar_x':[-60,60],'solar_z':[-3,45],'solar_size':[12,18],'outer_ports':[]}}
rooms=[('infantry','INFANTERIE',[-18,-12,-6,0],[-12,0],'front'),('armor','R\u00dcSTUNG',[-6,-12,6,0],[0,0],'front'),('engineering','TECHNIK',[6,-12,18,0],[12,0],'front'),('supplies','VERSORGUNG',[-26,2,-14,14],[-14,8],'right'),('freight','FRACHT',[14,2,26,14],[14,8],'left')]
for rid,title,r,door,side in rooms:
 anchor=[door[0],door[1]-1.4] if side=='front' else [door[0]+(-2 if side=='right' else 2),door[1]]
 L['rooms'].append({'id':rid,'title':title,'rect':r,'door':door,'door_side':side,'door_width':3.6,'accent':'cyan' if rid in ['engineering','supplies'] else 'yellow','service_anchor':anchor,'sector':'B'})
 L['decks'].append({'id':rid,'rect':r,'kind':'room'})
 for face,wall,h,window in [('back',[r[0],r[1]-.25,r[2],r[1]+.25],3.3 if side=='front' else 1.05,False),('front',[r[0],r[3]-.25,r[2],r[3]+.25],.65,True),('left',[r[0]-.25,r[1],r[0]+.25,r[3]],1.05,True),('right',[r[2]-.25,r[1],r[2]+.25,r[3]],1.05,True)]:
  parts=[wall]
  if face==side:
   if face=='front':parts=[[wall[0],wall[1],door[0]-1.8,wall[3]],[door[0]+1.8,wall[1],wall[2],wall[3]]]
   else:parts=[[wall[0],wall[1],wall[2],door[1]-1.8],[wall[0],door[1]+1.8,wall[2],wall[3]]]
  L['walls'] += [{'rect':part,'height':h,'window':window,'room':rid} for part in parts]
def item(name,kind,x,z,w,d,h,room,accent='cyan',**extra):
 L['furniture'].append(dict(id=name,kind=kind,rect=rr(x,z,w,d),height=h,room=room,accent=accent,sector='B',**extra))
for rid,cx in [('infantry',-12),('engineering',12)]:
 item(rid+'_counter','counter',cx+(-2.7 if cx<0 else 2.7),-3.2,3.8,1.2,.9,rid)
 for n,dx in enumerate([-3,3]):item(rid+f'_goods{n}','goods',cx+dx,-9.3,3.2,1.5,1.7,rid)
item('armor_counter','counter',-3.8,-3,2.8,1.2,.9,'armor','yellow')
for x,armor in [(-4,'light'),(0,'medium'),(4,'heavy')]:item('showcase_'+armor,'armor',x,-9.8,3.2,2.5,.3,'armor','yellow',armor=armor)
item('supplies_counter','counter',-18.5,10.7,3.8,1.2,.9,'supplies')
for n,z in enumerate([5,10]):item(f'supplies_goods{n}','goods',-23,z,3.2,1.5,1.7,'supplies')
item('freight_counter','counter',18.5,10.7,3.2,1.2,.9,'freight','yellow')
for n,(x,z) in enumerate([(20,4.8),(23,10.5)]):item(f'freight_goods{n}','cargo',x,z,5,4,.35,'freight','yellow')
item('globe','globe',0,10,4.4,4.4,.65,'hub')
for x in [-9,9]:item(f'bench{x}','bench',x,16,6,1.4,.5,'hub')
for n,(x,z,size,cls) in enumerate([(-29,24+M[1]/2,M,'M'),(-15,24+M[1]/2,M,'M'),(0,24+LARGE[1]/2,LARGE,'L'),(14,24+S[1]/2,S,'S'),(24,24+S[1]/2,S,'S'),(14,26+S[1]*1.5,S,'S'),(24,26+S[1]*1.5,S,'S')],1):
 pid=f'polisa_pad_{n:02d}'
 L['pads'].append({'id':pid,'number':f'{n:02d}','center':[x,z],'size':size,'reserve_envelope':[v-2*L['pad_scale_source']['reserve_margin'] for v in size],'class':cls,'sector':'B'})
 L['markers'][pid]=[x,z];L['pad_aliases'][f'B_{cls}{n}']=pid
for x in [14,24]:L['decks'].append({'id':f'small_connector{x}','rect':[x-1.5,24+S[1],x+1.5,26+S[1]],'kind':'bridge'})
for name,r in [('rear',[-42,-20,42,-12]),('left',[-42,-12,-28,18]),('right',[28,-12,42,18])]:L['blocked_zones'].append({'id':name,'rect':r,'height':4,'kind':'technical_zone'})
for i,x in enumerate([-35,-21,-7,7,21,35]):L['technical_modules'].append({'id':f'rear{i}','rect':rr(x,-16,12,6),'height':3+i%2,'kind':'reactor' if i%2 else 'plant'})
for sign in [-1,1]:
 for i,z in enumerate([-5,10]):L['technical_modules'].append({'id':f'side{sign}_{i}','rect':rr(sign*35,z,12,12),'height':3+i*1.5,'kind':'plant' if i==0 else 'tank'})
 L['engineering']['outer_ports'].append({'id':'port_left' if sign<0 else 'port_right','center':[sign*76,21],'approach_rect':rr(sign*76,55,18,42),'arm_from':[sign*42,21],'arm_to':[sign*76,21],'visual_only':True})
L['markers'].update({'trade_service':[0,17],'objective_point':[0,17],'spawn_alpha':L['markers']['polisa_pad_01'],'ship_return':L['markers']['polisa_pad_01'],'spawn_bravo':L['markers']['polisa_pad_05']})
L['walls']=list({tuple(w['rect']):w for w in L['walls']}.values())
(A/'layout.json').write_text(json.dumps(L,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Homebase S:',S,'M:',M,'L:',LARGE,'source SHA256',L['pad_scale_source']['sha256'])

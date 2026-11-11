"""R06 deterministic authoring recipe. All sizes are world units; no global shrink."""
import json, copy
from pathlib import Path
A=Path(__file__).resolve().parent
old=json.loads((A/'baseline_r04/layout.json').read_text(encoding='utf-8'))
L={'schema':'polisa_authored_layout_v6','origin_plane':[0,-48],'grid_size':[512,256],'grid_offset_bounds':[-256,-104,255,151],'space_bounds':[-256,-90,256,132],'standard_camera':{'yaw':24,'pitch':50,'size':135,'focus_local':[0,44]},'sectors':[],'decks':[],'rooms':[],'walls':[],'furniture':[],'pads':[],'markers':{},'blocked_zones':[],'technical_modules':[],'engineering':{'ring_x':[-120,120],'ring_z':46,'ring_center_y':-30,'ring_radius':56,'ring_width':4.8,'ring_yaw_degrees':0,'solar_x':[-177,177],'solar_z':[-10,94],'solar_size':[44,44],'outer_ports':[]},'globe':{'centers':[]},'pad_aliases':{}}
def rr(cx,cz,w,d):return [cx-w/2,cz-d/2,cx+w/2,cz+d/2]
def shift(r,x):return [r[0]+x,r[1],r[2]+x,r[3]]
rooms=[('infantry','INFANTERIE',[-42,-28,-14,0],[-25,0],'front'),('armor','R\u00dcSTUNG',[-14,-28,14,0],[0,0],'front'),('engineering','TECHNIK',[14,-28,42,0],[25,0],'front'),('supplies','VERSORGUNG',[-64,4,-36,32],[-36,18],'right'),('freight','FRACHT',[36,4,64,32],[36,18],'left')]
for sector,cx,base in [('B',0,1)]:
 L['sectors'].append({'id':sector,'center_x':cx,'hub':shift([-36,0,36,44],cx),'concourse':shift([-120,42,120,52],cx)})
 L['decks'] += [{'id':sector+'_hub','rect':shift([-36,0,36,44],cx),'kind':'hub'},{'id':sector+'_concourse','rect':shift([-120,42,120,52],cx),'kind':'bridge'}]
 for rid,title,r,door,side in rooms:
  key=sector+'_'+rid;rc=[(r[0]+r[2])/2,(r[1]+r[3])/2]
  anchor=[door[0],door[1]-3] if side=='front' else [door[0]+(-3 if side=='right' else 3),door[1]]
  L['rooms'].append({'id':key,'title':title,'rect':shift(r,cx),'door':[door[0]+cx,door[1]],'door_side':side,'door_width':6,'accent':'cyan' if rid in ['engineering','supplies'] else 'yellow','service_anchor':[anchor[0]+cx,anchor[1]],'sector':sector})
  L['decks'].append({'id':key,'rect':shift(r,cx),'kind':'room'})
  # Rear full-height wall, camera-facing wall low, side separators low cutaway.
  sides=[('back',[r[0],r[1]-.4,r[2],r[1]+.4],3.3 if side=='front' else 1.05,False),('front',[r[0],r[3]-.4,r[2],r[3]+.4],.65,True),('left',[r[0]-.4,r[1],r[0]+.4,r[3]],1.05,True),('right',[r[2]-.4,r[1],r[2]+.4,r[3]],1.05,True)]
  for face,wall,h,window in sides:
   parts=[wall]
   if face==side:
    if face=='front':parts=[[wall[0],wall[1],door[0]-3,wall[3]],[door[0]+3,wall[1],wall[2],wall[3]]]
    else:parts=[[wall[0],wall[1],wall[2],door[1]-3],[wall[0],door[1]+3,wall[2],wall[3]]]
   for part in parts:L['walls'].append({'rect':shift(part,cx),'height':h,'window':window,'room':key})
  previous=next(a for a in old['rooms'] if a['id']==rid);pr=previous['rect'];pc=[(pr[0]+pr[2])/2,(pr[1]+pr[3])/2]
  for item in old['furniture']:
   if item['room']!=rid:continue
   new=copy.deepcopy(item);sr=item['rect'];ic=[(sr[0]+sr[2])/2,(sr[1]+sr[3])/2];nc=[cx+rc[0]+(ic[0]-pc[0])*1.15,rc[1]+(ic[1]-pc[1])*1.15]
   new.update(id=sector+'_'+item['id'],room=key,rect=rr(*nc,sr[2]-sr[0],sr[3]-sr[1]),sector=sector)
   L['furniture'].append(new)
 L['furniture'].append({'id':sector+'_globe','kind':'globe','rect':rr(cx,22,4.4,4.4),'height':.65,'accent':'cyan','room':sector+'_hub'})
 L['globe']['centers'].append([cx,22])
 for dx in [-23,23]:L['furniture'].append({'id':f'{sector}_bench{dx}','kind':'bench','rect':rr(cx+dx,34,6,1.4),'height':.5,'accent':'cyan','room':sector+'_hub'})
 for idx,(px,pz,w,d,cls) in enumerate([(-80,72,28,40,'M'),(-46,72,28,40,'M'),(0,92,40,80,'L'),(42,62,18,20,'S'),(66,62,18,20,'S'),(42,88,18,20,'S'),(66,88,18,20,'S')]):
  number=f'{base+idx:02d}';pid='polisa_pad_'+number
  L['pads'].append({'id':pid,'number':number,'center':[cx+px,pz],'size':[w,d],'reserve_envelope':[w-6,d-6],'class':cls,'sector':sector})
  L['markers'][pid]=[cx+px,pz];L['pad_aliases'][f'{sector}_{cls}{idx+1}']=pid
 for px in [42,66]:L['decks'].append({'id':f'{sector}_small_connector{px}','rect':rr(cx+px,75,6,6),'kind':'bridge'})
 for name,r in [('rear',[-120,-42,120,-28]),('left',[-118,-28,-66,42]),('right',[66,-28,118,42])]:
  L['blocked_zones'].append({'id':sector+'_tech_'+name,'rect':shift(r,cx),'height':5,'kind':'technical_zone'})
 for i,px in enumerate([-100,-60,-20,20,60,100]):L['technical_modules'].append({'id':f'{sector}_rear_{i}','rect':rr(cx+px,-35,32,10),'height':4+(i%3),'kind':'reactor' if i%2 else 'plant'})
 for sign in [-1,1]:
  for i,pz in enumerate([-10,18]):L['technical_modules'].append({'id':f'{sector}_side_{sign}_{i}','rect':rr(cx+sign*92,pz,40,23),'height':3+2*i,'kind':'plant' if i==0 else 'tank'})
for sign in [-1,1]:
 # Large exposed ports flank station, approach is foreward in world+Z and clear of solar.
 L['engineering']['outer_ports'].append({'id':'port_left' if sign<0 else 'port_right','center':[sign*227,58],'approach_rect':rr(sign*227,131,42,98),'arm_from':[sign*120,46],'arm_to':[sign*227,58],'visual_only':True})
L['markers'].update({'trade_service':[0,33],'objective_point':[0,33],'spawn_alpha':[-80,72],'ship_return':[-80,72],'spawn_bravo':[66,62]})
# Deduplicate physical shared separators before compiler/visual projections.
seen=set();walls=[]
for wall in L['walls']:
 key=tuple(wall['rect'])
 if key not in seen:walls.append(wall);seen.add(key)
L['walls']=walls
(A/'layout.json').write_text(json.dumps(L,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Authored',len(L['pads']),'pads,',len(L['rooms']),'rooms; no production changes.')

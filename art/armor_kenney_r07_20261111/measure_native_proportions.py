from pathlib import Path
import json
import numpy as np
from PIL import Image
ART=Path(__file__).resolve().parent;ROOT=ART.parents[1]
p=ART/'proportion_landmarks.json';data=json.loads(p.read_text())
if 'initial_r06_broad_band_estimate' not in data:
 data['initial_r06_broad_band_estimate']=data.get('r06',{})
for revision in ['r06','r07']:
 a=np.array(Image.open(ROOT/f'output/native_glut_maps/armor_{revision}_native.png')).astype(int)
 rows={}
 for index,family in enumerate(['light','medium','heavy']):
  x0=index*636;x1=x0+632
  h0,h1=(90,410) if revision=='r06' else (110,400)
  crop=a[h0:h1,x0:x1];mask=crop[:,:,0]>80;xx=np.where(mask)[1]
  hx=[int(xx.min()+x0),int(xx.max()+x0)]
  y0,y1={'light':(430,512),'medium':(410,535),'heavy':(410 if revision=='r07' else 481,555)}[family]
  crop=a[y0:y1,x0:x1];r,g,b=crop[:,:,0],crop[:,:,1],crop[:,:,2]
  mask=(r>g+2)&(g>b+2)&(r-g<45)&(g-b<45)&(r>90)
  xx=np.where(mask)[1];sx=[int(xx.min()+x0),int(xx.max()+x0)]
  height=933 if revision=='r06' else 911
  hw=hx[1]-hx[0]+1;sw=sx[1]-sx[0]+1
  rows[family]={'helmet_x':hx,'shoulder_x':sx,'helmet_width_px':hw,'shoulder_width_px':sw,'height_px':height,'shoulder_over_helmet':sw/hw,'helmet_over_height':hw/height,'shoulder_over_height':sw/height,'shoulder_y_band':[y0,y1]}
 data[revision]=rows
data['native_measurement_note']='Refined shoulder-cap landmarks isolate ceramic colors, excluding dark upper-arm silhouettes and amber uniform patches. Initial R06 broad-band estimate is retained separately. These silhouette measurements are not anatomical bone widths.'
p.write_text(json.dumps(data,indent=2),encoding='utf8')
print(json.dumps({key:{family:round(row['shoulder_over_helmet'],3) for family,row in data[key].items()} for key in ['reference','r06','r07']}))

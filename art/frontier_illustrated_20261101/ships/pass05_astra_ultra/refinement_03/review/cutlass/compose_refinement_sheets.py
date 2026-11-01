"""Compose comparison evidence without altering any reference/model image."""
import argparse,hashlib,json
from pathlib import Path
from PIL import Image,ImageDraw,ImageFont,ImageOps
p=argparse.ArgumentParser(description=__doc__)
p.add_argument('--asset',required=True);p.add_argument('--comparison-dir',required=True)
p.add_argument('--reference-front',required=True);p.add_argument('--reference-rear',required=True)
a=p.parse_args();base=Path(a.comparison_dir).resolve();dest=base/'sheets';dest.mkdir(parents=True,exist_ok=True)
font_path=Path('C:/Windows/Fonts/arial.ttf')
font=ImageFont.truetype(str(font_path),28);small=ImageFont.truetype(str(font_path),21);title=ImageFont.truetype(str(font_path),34)
W,H,HEAD,GAP=1200,900,54,18
MODEL_CROP=(80,70,1040,760)
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def panel(canvas,path,box,label,is_model):
    x,y=box;draw=ImageDraw.Draw(canvas);draw.rectangle((x,y,x+W,y+HEAD),fill=(232,229,221));draw.text((x+16,y+10),label,font=font,fill=(27,38,41))
    image=Image.open(path).convert('RGB')
    if is_model:
        if image.size!=(1200,900):raise ValueError('Fixed model crop requires a 1200x900 render')
        image=image.crop(MODEL_CROP)
    image=ImageOps.contain(image,(W,H),Image.Resampling.LANCZOS)
    canvas.paste(image,(x+(W-image.width)//2,y+HEAD+(H-image.height)//2))
def sheet(name,lefts,rights,left_label,right_label,note,left_is_model=False):
    canvas=Image.new('RGB',(2*W+3*GAP,2*(H+HEAD)+3*GAP+110),(246,244,237));d=ImageDraw.Draw(canvas)
    visible_title={'Ziel_und_Neu':'Vorlage und Überarbeitung','Vorher_und_Neu':'Vorher und Überarbeitung'}.get(name,name.replace('_',' '))
    d.text((GAP,18),a.asset+' – '+visible_title,font=title,fill=(27,38,41))
    inputs=[]
    for row,view in enumerate(('front','rear')):
        y=70+GAP+row*(H+HEAD+GAP)
        caption='Vorn' if view=='front' else 'Hinten'
        panel(canvas,lefts[row],(GAP,y),caption+' · '+left_label,left_is_model)
        panel(canvas,rights[row],(2*GAP+W,y),caption+' · '+right_label,True)
        inputs.extend([{'path':str(Path(path).resolve()),'sha256':sha(path),'display_crop_xyxy':list(MODEL_CROP) if crop else None}
                       for path,crop in ((lefts[row],left_is_model),(rights[row],True))])
    d.text((GAP,canvas.height-30),note,font=small,fill=(60,68,69))
    path=dest/(name+'.png');canvas.save(path)
    return {'path':str(path),'sha256':sha(path),'inputs':inputs}
new=[base/'new'/f'material_{v}.png' for v in ('front','rear')]
prev=[base/'previous'/f'material_{v}.png' for v in ('front','rear')]
records=[]
records.append(sheet('Ziel_und_Neu',[Path(a.reference_front),Path(a.reference_rear)],new,'2D-Zielvorlage','neuer Blender-Kandidat',
                     'Perspektivisches Konzept und Blender-Modell: Bildstil/Licht verschieden; keine behauptete exakte Kamerarekonstruktion.'))
records.append(sheet('Vorher_und_Neu',prev,new,'Verfeinerung 02','Verfeinerung 03',
                     'Identische 3D-Kameras und identischer fester Bildausschnitt; Prüfstatus getrennt von gestalterischer Nutzerfreigabe.',True))
top_canvas=Image.new('RGB',(2*W+3*GAP,H+HEAD+3*GAP+110),(246,244,237))
top_draw=ImageDraw.Draw(top_canvas)
top_draw.text((GAP,18),a.asset+' – Draufsicht: Vorher und Überarbeitung',font=title,fill=(27,38,41))
top_inputs=[]
for column,(folder,label) in enumerate((('previous','Verfeinerung 02'),('new','Verfeinerung 03'))):
    source=base/folder/'material_top.png'
    panel(top_canvas,source,(GAP+column*(W+GAP),70+GAP),'Oben · '+label,False)
    top_inputs.append({'path':str(source.resolve()),'sha256':sha(source),'display_crop_xyxy':None})
top_draw.text((GAP,top_canvas.height-30),'Identische Kamera und vollständige Renderbilder; gleicher Maßstab, ohne Beschnitt oder individuelle Anpassung.',font=small,fill=(60,68,69))
top_path=dest/'Vorher_und_Neu_Oben.png'
top_canvas.save(top_path)
records.append({'path':str(top_path),'sha256':sha(top_path),'inputs':top_inputs,
                'method':'Side-by-side original full 1200x900 top frames, identical uniform fit, no crop or per-model fitting.'})
(dest/'manifest.json').write_text(json.dumps({'asset':a.asset,'sheets':records,
                                            'fixed_model_display_crop_xyxy':list(MODEL_CROP),
                                            'method':'Original full renders preserved. Front/rear sheets use identical fixed (80,70,1040,760) display crop for model images; references uncropped. Top sheet uses full frames without crop. All fitting is uniform, with no per-model fitting or image content generation.'},indent=2),encoding='utf8')
print(json.dumps({'sheets':[r['path'] for r in records]}))

"""Extract the requested four separate views without regenerating or retouching them."""
from pathlib import Path
from PIL import Image
import hashlib,json,shutil,zipfile

ROOT=Path(__file__).resolve().parent
source=ROOT/'satellite_mission01_four_views_v3.png'
image=Image.open(source)
assert image.mode=='RGBA' and image.size==(1254,1254)
original_hash=hashlib.sha256(source.read_bytes()).hexdigest()
output=ROOT/'single_views'
download=Path('C:/Users/bjoer/Downloads/Satellit_Tripo_Einzelansichten_20261121')
output.mkdir(exist_ok=True);download.mkdir(exist_ok=True)
views=[('01_Vorne',(0,0,627,627)),('02_Rechts',(627,0,1254,627)),
       ('03_Hinten',(0,627,627,1254)),('04_Links',(627,627,1254,1254))]
manifest={'source':source.name,'source_sha256':original_hash,'operation':'lossless_quadrant_extraction',
          'resampled':False,'retouched':False,'transparent_padding_px':32,'images':[]}
for view,box in views:
    crop=image.crop(box)
    canvas=Image.new('RGBA',(691,691),(0,0,0,0))
    canvas.paste(crop,(32,32))
    path=output/('Satellit_'+view+'.png')
    canvas.save(path)
    reloaded=Image.open(path)
    assert reloaded.mode=='RGBA'
    assert reloaded.crop((32,32,659,659)).tobytes()==crop.tobytes()
    assert reloaded.getpixel((0,0))==(0,0,0,0)
    shutil.copy2(path,download/path.name)
    assert (download/path.name).read_bytes()==path.read_bytes()
    manifest['images'].append({'view':view,'file':path.name,'source_box':box,'size':list(reloaded.size),
       'alpha_bounds':list(crop.getchannel('A').point(lambda a:255 if a>=16 else 0).getbbox()),
       'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
assert hashlib.sha256(source.read_bytes()).hexdigest()==original_hash
(output/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
bundle=download.parent/'Satellit_Tripo_Einzelansichten_20261121.zip'
with zipfile.ZipFile(bundle,'w',compression=zipfile.ZIP_DEFLATED) as archive:
    for record in manifest['images']:archive.write(output/record['file'],record['file'])
with zipfile.ZipFile(bundle) as archive:
    assert len(archive.namelist())==4 and archive.testzip() is None
print(json.dumps({'download':str(download),'zip':str(bundle),'images':manifest['images']},indent=2))

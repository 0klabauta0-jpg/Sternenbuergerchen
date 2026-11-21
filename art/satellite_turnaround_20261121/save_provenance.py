"""Copy AI-generated originals and record provenance; never edit image pixels."""
from pathlib import Path
from PIL import Image
import hashlib,json,shutil

ROOT=Path(__file__).resolve().parent
GENERATED=Path('C:/Users/bjoer/.codex/generated_images/01a1da7f-f02f-7580-b98c-dbc5230c0b56')
source=GENERATED/'exec-3ef87fd1-f4bd-4b24-9057-36843fc0b1d7.png'
output=ROOT/'satellite_mission01_four_views_v3.png'
shutil.copy2(source,output)
download=Path('C:/Users/bjoer/Downloads/Satellit_Mission01_Vier_Ansichten_20261121_v3.png')
shutil.copy2(output,download)
doc=json.loads((ROOT/'provenance.json').read_text(encoding='utf-8'))
doc.setdefault('earlier_selected_original',doc['selected_original'])
doc['selected_original']=str(source)
doc['final_file']=output.name
doc['download_copy']=str(download)
prompt=(ROOT/'final_consistency_prompt.txt').read_text(encoding='utf-8').strip()
if prompt not in doc['prompts']:doc['prompts'].append(prompt)
doc['reference_hashes']=[]
(ROOT/'references').mkdir(exist_ok=True)
for ref in doc['reference_images']:
    src=Path(ref); dst=ROOT/'references'/src.name
    shutil.copy2(src,dst)
    doc['reference_hashes'].append({'file':str(dst.relative_to(ROOT)),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest()})
doc['output_sha256']=hashlib.sha256(output.read_bytes()).hexdigest()
im=Image.open(output)
doc['output_image']={'mode':im.mode,'size':list(im.size),'alpha_extrema':list(im.getchannel('A').getextrema())}
assert doc['output_image']['mode']=='RGBA' and doc['output_image']['alpha_extrema'][0]==0
assert hashlib.sha256(download.read_bytes()).hexdigest()==doc['output_sha256']
(ROOT/'provenance.json').write_text(json.dumps(doc,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print(json.dumps({'output':str(output),'download':str(download),'image':doc['output_image'],'sha256':doc['output_sha256']}))

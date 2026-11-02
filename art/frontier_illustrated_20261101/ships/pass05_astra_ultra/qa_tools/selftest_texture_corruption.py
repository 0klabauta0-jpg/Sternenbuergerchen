"""Change exactly one embedded albedo pixel without damaging GLB structure."""
import argparse,io,json,struct
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser();p.add_argument('--glb',required=True);p.add_argument('--out',required=True);a=p.parse_args()
raw=Path(a.glb).read_bytes();size=struct.unpack_from('<I',raw,12)[0]
doc=json.loads(raw[20:20+size]);binary=raw[28+size:]
texture=next(m['pbrMetallicRoughness']['baseColorTexture']['index'] for m in doc['materials'] if 'baseColorTexture' in m.get('pbrMetallicRoughness',{}))
image=doc['images'][doc['textures'][texture]['source']];target=image['bufferView']
chunks=[];offset=0
for i,view in enumerate(doc['bufferViews']):
    data=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
    if i==target:
        im=Image.open(io.BytesIO(data)).convert('RGBA');r,g,b,alpha=im.getpixel((0,0))
        im.putpixel((0,0),(255-r,255-g,255-b,alpha));buf=io.BytesIO();im.save(buf,format='PNG');data=buf.getvalue()
    view['byteOffset']=offset;view['byteLength']=len(data)
    pad=(-len(data))%4;chunks.append(data+b'\0'*pad);offset+=len(data)+pad
binary=b''.join(chunks);doc['buffers'][0]['byteLength']=len(binary)
encoded=json.dumps(doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
out=struct.pack('<III',0x46546c67,2,12+8+len(encoded)+8+len(binary))
out+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(binary),0x004e4942)+binary
Path(a.out).write_bytes(out)
print('Changed exactly one embedded albedo pixel:',a.out)

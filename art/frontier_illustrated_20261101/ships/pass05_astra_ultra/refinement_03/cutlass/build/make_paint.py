"""Original deterministic subtle pigment textures, not photographed/baked lighting."""
from pathlib import Path
from PIL import Image,ImageDraw,ImageFilter
import numpy as np,random
out=Path(__file__).resolve().parents[1]/'textures';out.mkdir(exist_ok=True)
colours={'Petrol':(.070,.105,.115),'Ivory':(.76,.60,.37),'Ochre':(.70,.31,.025),'PetrolLight':(.105,.15,.16)}
n=512;rng=np.random.default_rng(31);noise=np.zeros((n,n))
for size,w in [(8,.045),(32,.025),(128,.007)]:
    img=Image.fromarray(np.uint8(np.clip(rng.normal(128,40,(size,size)),0,255)))
    noise+=(np.asarray(img.resize((n,n),Image.Resampling.BICUBIC))/128-1)*w
paint=Image.new('L',(n,n),128);d=ImageDraw.Draw(paint);r=random.Random(31)
for i in range(180):
    x,y=r.randrange(n),r.randrange(n);w,h=r.randrange(12,65),r.randrange(5,20)
    d.polygon([(x,y),(x+w,y+2),(x+w-3,y+h),(x+4,y+h-2)],fill=r.randrange(112,145))
noise+=(np.asarray(paint.filter(ImageFilter.GaussianBlur(.8)))/128-1)*.34
for name,color in colours.items():
    v=np.array(color)[None,None,:]*(1+noise[:,:,None]);s=np.where(v<=.0031308,12.92*v,1.055*np.maximum(v,0)**(1/2.4)-.055)
    Image.fromarray(np.uint8(np.clip(s*255,0,255))).save(out/(name+'_basecolor.png'))
Image.fromarray(np.uint8(np.clip(.68+noise*.9,0,1)*255)).save(out/'paint_roughness.png')

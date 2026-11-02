"""Consolidate static GLB nodes into one mesh, one primitive per material.

Preserves original evaluated export attributes without Blender's custom-normal
re-encoding. Node transforms are baked into positions/normals; embedded images
are copied byte-for-byte. Run with ordinary Python + numpy or inside Blender.
This deliberately supports only ordinary static triangle GLBs.
"""
import argparse,copy,hashlib,json,struct,sys
from collections import defaultdict
from pathlib import Path
import numpy as np


def consolidate(input_path,output_path):
    original=Path(input_path).read_bytes()
    magic,version,length=struct.unpack_from('<III',original)
    if (magic,version,length)!=(0x46546c67,2,len(original)):raise ValueError('Invalid GLB')
    offset=12;doc=None;binary=None
    while offset<len(original):
        size,kind=struct.unpack_from('<II',original,offset);offset+=8
        chunk=original[offset:offset+size];offset+=size
        if kind==0x4e4f534a:doc=json.loads(chunk)
        elif kind==0x004e4942:binary=chunk
    if doc is None or binary is None:raise ValueError('Missing chunks')
    if doc.get('animations') or doc.get('skins'):raise ValueError('Only static unskinned GLB supported')
    types={5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
    widths={'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4}
    def read_accessor(index):
        a=doc['accessors'][index]
        if 'sparse' in a:raise ValueError('Sparse accessors unsupported')
        v=doc['bufferViews'][a['bufferView']]
        if v.get('buffer',0)!=0 or v.get('extensions'):raise ValueError('External/compressed buffers unsupported')
        dtype=np.dtype(types[a['componentType']]);width=widths[a['type']]
        arr=np.ndarray((a['count'],width),dtype=dtype,buffer=binary,
                       offset=v.get('byteOffset',0)+a.get('byteOffset',0),
                       strides=(v.get('byteStride',dtype.itemsize*width),dtype.itemsize)).copy()
        if not np.isfinite(arr).all():raise ValueError('Non-finite accessor')
        return arr,{'componentType':a['componentType'],'type':a['type'],**({'normalized':True} if a.get('normalized') else {})}
    def matrix(node):
        if 'matrix' in node:return np.asarray(node['matrix'],dtype=float).reshape(4,4).T
        x,y,z,w=node.get('rotation',[0,0,0,1]);q=np.array([x,y,z,w]);q=q/np.linalg.norm(q);x,y,z,w=q
        r=np.array([[1-2*y*y-2*z*z,2*x*y-2*z*w,2*x*z+2*y*w],
                    [2*x*y+2*z*w,1-2*x*x-2*z*z,2*y*z-2*x*w],
                    [2*x*z-2*y*w,2*y*z+2*x*w,1-2*x*x-2*y*y]])
        result=np.eye(4);result[:3,:3]=r@np.diag(node.get('scale',[1,1,1]));result[:3,3]=node.get('translation',[0,0,0])
        return result
    groups=defaultdict(list);node_count=0
    def walk(index,parent,trail):
        nonlocal node_count
        if index in trail:raise ValueError('Node cycle')
        node=doc['nodes'][index];world=parent@matrix(node)
        if 'mesh' in node:
            node_count+=1
            for prim in doc['meshes'][node['mesh']]['primitives']:
                if prim.get('mode',4)!=4 or prim.get('extensions') or prim.get('targets'):raise ValueError('Only plain triangle primitives supported')
                attrs={};schemas={}
                for semantic,index_a in prim['attributes'].items():attrs[semantic],schemas[semantic]=read_accessor(index_a)
                if not {'POSITION','NORMAL'}<=set(attrs):raise ValueError('Position and normal attributes required')
                if not np.allclose(world,np.eye(4),rtol=0,atol=1e-12):
                    p=attrs['POSITION'];attrs['POSITION']=(p@world[:3,:3].T+world[:3,3]).astype(np.float32)
                    nm=np.linalg.inv(world[:3,:3]).T;n=attrs['NORMAL']@nm.T
                    attrs['NORMAL']=(n/np.linalg.norm(n,axis=1)[:,None]).astype(np.float32)
                    if 'TANGENT' in attrs:
                        t=attrs['TANGENT'].copy();xyz=t[:,:3]@world[:3,:3].T;t[:,:3]=xyz/np.linalg.norm(xyz,axis=1)[:,None]
                        if np.linalg.det(world[:3,:3])<0:t[:,3]*=-1
                        attrs['TANGENT']=t
                if 'indices' in prim:indices=read_accessor(prim['indices'])[0].reshape(-1).astype(np.uint32)
                else:indices=np.arange(len(attrs['POSITION']),dtype=np.uint32)
                if np.linalg.det(world[:3,:3])<0:indices=indices.reshape(-1,3)[:,[0,2,1]].reshape(-1)
                groups[prim.get('material',-1)].append((attrs,schemas,indices))
        for child in node.get('children',[]):walk(child,world,trail+[index])
    for node in doc['scenes'][doc.get('scene',0)].get('nodes',[]):walk(node,np.eye(4),[])
    out={k:copy.deepcopy(doc[k]) for k in ['asset','materials','textures','samplers','extensionsUsed','extensionsRequired'] if k in doc}
    out['asset']['generator']=out['asset'].get('generator','')+'; lossless static primitive consolidation'
    out.update({'accessors':[],'bufferViews':[],'images':[],'meshes':[{'name':'VH_Consolidated_LOD0','primitives':[]}],
                'nodes':[{'name':'VH_Consolidated_LOD0','mesh':0,'extras':{'candidate':'not_user_approved','consolidation':'evaluated GLB attributes preserved'}}],
                'scenes':[{'nodes':[0]}],'scene':0})
    chunks=[];size=0
    def append_buffer(data,target=None):
        nonlocal size
        view={'buffer':0,'byteOffset':size,'byteLength':len(data)}
        if target:view['target']=target
        out['bufferViews'].append(view);chunks.append(data+b'\0'*((-len(data))%4));size+=len(chunks[-1])
        return len(out['bufferViews'])-1
    def append_accessor(arr,schema,target,position=False):
        arr=np.ascontiguousarray(arr)
        record=dict(schema,bufferView=append_buffer(arr.tobytes(),target),count=len(arr))
        if position:record['min']=arr.min(axis=0).tolist();record['max']=arr.max(axis=0).tolist()
        out['accessors'].append(record);return len(out['accessors'])-1
    triangles=0
    for material,parts in sorted(groups.items()):
        keys=set(parts[0][0]);schema=parts[0][1]
        if any(set(attrs)!=keys or sc!=schema for attrs,sc,_ in parts):raise ValueError('Attribute schema varies inside material group')
        counts=[len(attrs['POSITION']) for attrs,_,_ in parts]
        offsets=np.cumsum([0]+counts[:-1]);indices=np.concatenate([indices+offset for (_,_,indices),offset in zip(parts,offsets)]).astype(np.uint32)
        attrs={key:np.concatenate([p[0][key] for p in parts],axis=0) for key in keys}
        prim={'attributes':{key:append_accessor(attrs[key],schema[key],34962,key=='POSITION') for key in sorted(keys)},'mode':4}
        if material>=0:prim['material']=material
        index_type=5123 if sum(counts)<65536 else 5125
        indices=indices.astype(types[index_type]);prim['indices']=append_accessor(indices.reshape(-1,1),{'componentType':index_type,'type':'SCALAR'},34963)
        out['meshes'][0]['primitives'].append(prim);triangles+=len(indices)//3
    image_hashes=[]
    for img in doc.get('images',[]):
        if 'bufferView' not in img:raise ValueError('Embedded images only')
        view=doc['bufferViews'][img['bufferView']];encoded=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        record=copy.deepcopy(img);record['bufferView']=append_buffer(encoded);out['images'].append(record)
        image_hashes.append(hashlib.sha256(encoded).hexdigest())
    out['buffers']=[{'byteLength':size}];encoded=json.dumps(out,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
    packed=b''.join(chunks);header=struct.pack('<III',0x46546c67,2,28+len(encoded)+len(packed))
    payload=header+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(packed),0x004e4942)+packed
    output=Path(output_path);output.parent.mkdir(parents=True,exist_ok=True);output.write_bytes(payload)
    return {'input':str(input_path),'output':str(output),'input_sha256':hashlib.sha256(original).hexdigest(),
            'output_sha256':hashlib.sha256(payload).hexdigest(),'source_mesh_nodes':node_count,'meshes':1,
            'primitives':len(groups),'triangles':triangles,'image_sha256_unchanged':image_hashes,'bytes':len(payload)}


if __name__=='__main__':
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('--input',required=True);p.add_argument('--output',required=True)
    a=p.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else None)
    print(json.dumps(consolidate(a.input,a.output),indent=2))

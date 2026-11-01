"""Independent static-ship source/GLB audit. Run in a fresh background Blender.

Does not modify the source BLEND or GLB. Checks evaluated geometry and split
corner normals, including multiplicities, before and after a factory reset.
Only uncompressed, unskinned triangle GLBs with Principled constants or direct
image textures are supported. Unsupported data is an error, never implicit pass.
"""
import argparse
from collections import Counter, defaultdict
import hashlib
import json
import math
from pathlib import Path
import struct
import sys
import traceback

import bpy
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

SKILL_DIR = Path(r"C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts")


def sha(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def image_pixels(image):
    width,height=image.size
    if width<=0 or height<=0: raise ValueError(f'Image {image.name} has no pixels')
    data=np.empty(width*height*4,dtype=np.float32)
    image.pixels.foreach_get(data)
    data=data.reshape(height,width,4)
    if not np.isfinite(data).all(): raise ValueError(f'Image {image.name} has non-finite pixels')
    colorspace=image.colorspace_settings.name
    meta={'image':image.name,'filepath':image.filepath,'size':[width,height],
          'colorspace':colorspace,'decoded_storage_pixels_sha256':hashlib.sha256(data.tobytes()).hexdigest()}
    if colorspace=='sRGB':
        if image.is_float:raise ValueError('Float sRGB image decoding is not covered by this byte-PNG audit')
        # Image.pixels exposes normalized byte-buffer samples; the texture node
        # applies the sRGB transfer function. Compare its effective linear RGB.
        rgb=data[:,:,:3]
        data[:,:,:3]=np.where(rgb<=.04045,rgb/12.92,((rgb+.055)/1.055)**2.4)
    elif colorspace not in ('Non-Color','Linear Rec.709','Linear'):
        raise ValueError(f'Unsupported image colorspace {colorspace}')
    meta['decoded_effective_pixels_sha256']=hashlib.sha256(data.tobytes()).hexdigest()
    if image.packed_file: meta['encoded_sha256']=hashlib.sha256(image.packed_file.data).hexdigest()
    else:
        path=Path(bpy.path.abspath(image.filepath))
        if path.is_file():meta['encoded_sha256']=sha(path)
    return data,meta


def socket_value(socket,channels):
    if not socket.is_linked:
        value=socket.default_value
        return np.asarray(list(value)[:channels] if channels>1 else float(value),dtype=np.float32),None
    link=socket.links[0];node=link.from_node;channel=None
    if node.type=='MATH' and node.operation=='MULTIPLY':
        a,ma=socket_value(node.inputs[0],1);b,mb=socket_value(node.inputs[1],1)
        if ma and mb:raise ValueError('Multiplication of two images unsupported')
        return a*b,ma or mb
    if node.type in ('SEP_COLOR','SEPRGB','SEPARATE_COLOR'):
        channel={'Red':0,'Green':1,'Blue':2,'R':0,'G':1,'B':2}.get(link.from_socket.name)
        if channel is None:raise ValueError(f'Unsupported separated channel {link.from_socket.name}')
        upstream=node.inputs[0]
        if not upstream.is_linked:raise ValueError('Unlinked channel separator')
        link=upstream.links[0];node=link.from_node
    if node.type!='TEX_IMAGE' or node.image is None:
        raise ValueError(f'Unsupported material socket graph {node.type}; only direct image or image-channel separator allowed')
    if node.inputs['Vector'].is_linked or node.projection!='FLAT':
        raise ValueError('Custom texture mapping/projection unsupported by pixel+UV audit')
    data,meta=image_pixels(node.image)
    if channel is not None: data=data[:,:,channel];meta['channel']=channel
    elif link.from_socket.name=='Alpha': data=data[:,:,3];meta['channel']=3
    elif channels==1:
        if float(np.max(np.abs(data[:,:,:3]-data[:,:,:1])))>1e-6:
            raise ValueError('Non-grayscale image Color -> scalar conversion is not covered; use explicit channel')
        data=data[:,:,0];meta['channel']=0
    else:data=data[:,:,:channels];meta['channel']='RGBA' if channels==4 else 'RGB'
    return data,meta


def roles_record(name,roles,textures):
    for role,data in roles.items():
        if not np.isfinite(data).all():raise ValueError(f'{name}: non-finite {role} data')
    base=np.asarray(roles['base_color']).reshape(-1,4).mean(axis=0).tolist()
    metallic=float(np.asarray(roles['metallic']).mean());roughness=float(np.asarray(roles['roughness']).mean())
    emiss=np.asarray(roles['emission']).reshape(-1,3).mean(axis=0).tolist()
    return {'name':name,'base_color_linear':base,'metallic':metallic,'roughness':roughness,
            'emission_linear':emiss,'values':base+[metallic,roughness]+emiss,
            'textures':textures,'values_note':'Means when textured; full decoded effective pixels are compared separately.',
            '_roles':roles}


def material_record(mat):
    if mat is None or mat.node_tree is None:
        raise ValueError("Missing node material")
    bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
    if bsdf is None:
        raise ValueError(f"{mat.name}: no Principled BSDF")
    if bsdf.inputs['Normal'].is_linked:raise ValueError('Normal-map audit is not implemented')
    roles={};textures={}
    for role,socket,count in [('base_color','Base Color',4),('metallic','Metallic',1),('roughness','Roughness',1),('emission','Emission Color',3)]:
        data,meta=socket_value(bsdf.inputs[socket],count);roles[role]=data
        if meta:textures[role]=meta
    alpha,alpha_meta=socket_value(bsdf.inputs['Alpha'],1)
    roles['base_color']=roles['base_color'].copy()
    roles['base_color'][...,3]=alpha
    if alpha_meta:textures['alpha']=alpha_meta
    strength,strength_meta=socket_value(bsdf.inputs['Emission Strength'],1)
    if strength_meta:raise ValueError('Textured emission strength unsupported')
    roles['emission']=roles['emission']*strength
    return roles_record(mat.name,roles,textures)


def bbox(points):
    p = np.asarray(points, dtype=float)
    if not len(p) or not np.isfinite(p).all():
        raise ValueError('Empty or non-finite position data')
    lo, hi = p.min(axis=0), p.max(axis=0)
    return {'min': lo.tolist(), 'max': hi.tolist(), 'size': (hi-lo).tolist(),
            'center': ((hi+lo)*.5).tolist()}


def snapshot(objects):
    bpy.context.view_layer.update()
    dg = bpy.context.evaluated_depsgraph_get()
    pts, norms, labels, mesh_parts, mats, object_meta = [], [], [], [], {}, []
    uvs,uv_present=[],[]
    for ob in objects:
        if ob.type != 'MESH':
            continue
        evaluated = ob.evaluated_get(dg)
        me = evaluated.to_mesh(preserve_all_data_layers=True, depsgraph=dg)
        try:
            me.calc_loop_triangles()
            wm = evaluated.matrix_world.copy()
            nm = wm.to_3x3().inverted().transposed()
            world = [wm @ v.co for v in me.vertices]
            tri_list = [tuple(t.vertices) for t in me.loop_triangles]
            edge_list = [tuple(e.vertices) for e in me.edges]
            for tri in me.loop_triangles:
                mi = tri.material_index
                mat = me.materials[mi] if mi < len(me.materials) else None
                if mat is None:
                    raise ValueError(f'{ob.name}: triangle has empty material')
                if mat.name not in mats:
                    mats[mat.name] = material_record(mat)
                for vi, li in zip(tri.vertices, tri.loops):
                    n = nm @ me.corner_normals[li].vector
                    if n.length < 1e-9:
                        raise ValueError(f'{ob.name}: zero-length corner normal')
                    n.normalize()
                    pts.append(tuple(world[vi])); norms.append(tuple(n)); labels.append(mat.name)
                    uv=me.uv_layers.active.data[li].uv if me.uv_layers.active else None
                    uvs.append(tuple(uv) if uv is not None else (0,0));uv_present.append(uv is not None)
            mesh_parts.append({'name': ob.name, 'vertices': world, 'triangles': tri_list, 'edges': edge_list})
            object_meta.append({'name': ob.name, 'vertices': len(me.vertices), 'triangles': len(tri_list),
                                'scale': list(ob.scale), 'rotation_euler': list(ob.rotation_euler),
                                'matrix_world': [list(r) for r in wm], 'uv_layers': len(me.uv_layers)})
        finally:
            evaluated.to_mesh_clear()
    p = np.asarray(pts, dtype=float); n = np.asarray(norms, dtype=float)
    if not len(p) or not np.isfinite(p).all() or not np.isfinite(n).all():
        raise ValueError('Empty or non-finite source/import data')
    if not np.isfinite(np.asarray(uvs,dtype=float)).all():
        raise ValueError('Non-finite source/import UV data')
    return {'points': p, 'normals': n, 'labels': labels, 'materials': mats,
            'uvs':np.asarray(uvs,dtype=float),'uv_present':uv_present,
            'parts': mesh_parts, 'objects': object_meta, 'bbox': bbox(p), 'triangles': len(p)//3}


def match_materials(source, target, tol):
    mapping, diffs, errors = {}, [], []
    available = set(target)
    for name, mat in source.items():
        def difference(other):
            try:return max(float(np.max(np.abs(mat['_roles'][role]-other['_roles'][role]))) for role in mat['_roles'])
            except ValueError:return 1e30
        candidates = [(difference(target[t]), t) for t in available]
        if not candidates:
            errors.append(f'Missing target material for {name}'); continue
        # Preserve same-name match when values also agree; duplicate-looking materials stay distinct.
        candidates.sort(key=lambda row: (target[row[1]]['name'] != mat['name'], row[0]))
        error, tn = candidates[0]
        if error > tol:
            errors.append(f'Material {name} differs: closest {tn}, max value error {error:.9g}')
        mapping[tn] = name; available.remove(tn)
        diffs.append({'source': name, 'target': tn, 'max_value_error': error,
                      'full_effective_image_pixels_compared':bool(mat.get('textures') or target[tn].get('textures')),
                      'source_textures':mat.get('textures',{}),'target_textures':target[tn].get('textures',{})})
    if available:
        errors.append(f'Extra target materials: {sorted(available)}')
    return mapping, {'pass': not errors, 'matches': diffs, 'errors': errors}


def compare_corners(source, target, position_tol, normal_tol, material_tol):
    mapping, mat_result = match_materials(source['materials'], target['materials'], material_tol)
    src_groups, tgt_groups = defaultdict(list), defaultdict(list)
    for i, m in enumerate(source['labels']): src_groups[m].append(i)
    for i, m in enumerate(target['labels']): tgt_groups[mapping.get(m, '__unmatched__'+m)].append(i)
    errors = list(mat_result['errors']); unmatched = []
    max_position = max_normal = max_uv = 0.0
    uv_presence_errors=0
    worst_normal=worst_uv=None
    matched = 0
    for mat, indices in src_groups.items():
        candidates = tgt_groups.get(mat, [])
        if len(indices) != len(candidates):
            errors.append(f'{mat}: triangle-corner multiplicity {len(indices)} -> {len(candidates)}')
        tree = KDTree(len(candidates))
        for local, idx in enumerate(candidates): tree.insert(target['points'][idx], local)
        tree.balance()
        used = set()
        for idx in indices:
            near = tree.find_range(source['points'][idx], position_tol)
            options = []
            for _, local, distance in near:
                if local in used: continue
                j = candidates[local]
                nd = float(np.linalg.norm(source['normals'][idx]-target['normals'][j]))
                ud=float(np.max(np.abs(source['uvs'][idx]-target['uvs'][j]))) if source['uv_present'][idx] and target['uv_present'][j] else 0.0
                # Resolve practically coincident corners by position and UV
                # before shading. Otherwise a nearby seam corner with a closer
                # normal can mask a UV mismatch or steal an exact-position match.
                options.append((round(float(distance),6),round(ud,6),nd,float(distance),ud,local,j))
            if not options:
                if len(unmatched) < 20:
                    unmatched.append({'source_corner': idx, 'material': mat,
                                      'position': source['points'][idx].tolist(), 'reason': 'no unused matching position'})
                continue
            _, _, nd, pd, ud, local, j = min(options)
            used.add(local); matched += 1
            example={'source_corner':idx,'target_corner':j,'material':mat,
                     'source_position':source['points'][idx].tolist(),'target_position':target['points'][j].tolist(),
                     'source_normal':source['normals'][idx].tolist(),'target_normal':target['normals'][j].tolist(),
                     'source_uv':source['uvs'][idx].tolist(),'target_uv':target['uvs'][j].tolist()}
            if nd>max_normal:worst_normal=example
            if ud>max_uv:worst_uv=example
            max_position = max(max_position, float(pd)); max_normal = max(max_normal, nd);max_uv=max(max_uv,ud)
            uv_presence_errors+=source['uv_present'][idx]!=target['uv_present'][j]
    if matched != len(source['points']) or matched != len(target['points']):
        errors.append(f'Full corner multiset differs: {matched} matched, source {len(source["points"])}, target {len(target["points"])}')
    if max_normal > normal_tol:
        errors.append(f'Corner-normal max vector error {max_normal:.9g} > {normal_tol}')
    if max_uv>position_tol:errors.append(f'UV max coordinate error {max_uv:.9g} > {position_tol}')
    if uv_presence_errors:errors.append(f'UV presence differs on {uv_presence_errors} corners')
    return {'pass': not errors, 'errors': errors, 'source_triangles': source['triangles'],
            'target_triangles': target['triangles'], 'matched_corners': matched,
            'max_position_error_m': max_position, 'max_normal_vector_error': max_normal,
            'max_uv_coordinate_error':max_uv,'uv_presence_errors':uv_presence_errors,
            'worst_normal_case':worst_normal,'worst_uv_case':worst_uv,
            'normal_tolerance_vector': normal_tol, 'position_tolerance_m': position_tol,
            'unmatched_examples': unmatched, 'materials': mat_result,
            'method': 'One-to-one material-labelled triangle-corner multiset; KD radius positions, then nearest split normal. Multiplicities retained.'}


def read_glb(path,scratch):
    data = Path(path).read_bytes()
    magic, version, length = struct.unpack_from('<III', data)
    if (magic, version, length) != (0x46546c67, 2, len(data)):
        raise ValueError('Invalid GLB header')
    offset, doc, binary = 12, None, None
    while offset < len(data):
        size, kind = struct.unpack_from('<II', data, offset); offset += 8
        chunk = data[offset:offset+size]; offset += size
        if kind == 0x4e4f534a: doc = json.loads(chunk)
        if kind == 0x004e4942: binary = chunk
    if doc is None or binary is None: raise ValueError('GLB missing JSON/BIN')
    if doc.get('skins') or doc.get('animations'): raise ValueError('Static audit received skins/animations')
    dtype = {5120:np.int8,5121:np.uint8,5122:np.int16,5123:np.uint16,5125:np.uint32,5126:np.float32}
    comps = {'SCALAR':1,'VEC2':2,'VEC3':3,'VEC4':4,'MAT4':16}
    def accessor(i):
        a = doc['accessors'][i]
        if 'sparse' in a or a.get('normalized'): raise ValueError('Sparse/normalized accessor unsupported')
        v = doc['bufferViews'][a['bufferView']]
        if v.get('buffer',0) != 0 or v.get('extensions'): raise ValueError('External/compressed buffer unsupported')
        dt = np.dtype(dtype[a['componentType']]); n = comps[a['type']]
        stride = v.get('byteStride', dt.itemsize*n)
        arr = np.ndarray((a['count'],n), dtype=dt, buffer=binary,
                         offset=v.get('byteOffset',0)+a.get('byteOffset',0), strides=(stride,dt.itemsize)).copy()
        if not np.isfinite(arr).all(): raise ValueError(f'Non-finite GLB accessor {i}')
        return arr
    for i in range(len(doc.get('accessors',[]))): accessor(i)
    scratch=Path(scratch).resolve();scratch.mkdir(parents=True,exist_ok=True)
    def glb_image(texture_index,colorspace):
        texture=doc['textures'][texture_index]
        if texture.get('extensions'):raise ValueError('Extended/compressed textures unsupported')
        index=texture['source'];desc=doc['images'][index]
        if 'bufferView' not in desc:raise ValueError('External GLB image unsupported')
        view=doc['bufferViews'][desc['bufferView']]
        encoded=binary[view.get('byteOffset',0):view.get('byteOffset',0)+view['byteLength']]
        suffix={'image/png':'.png','image/jpeg':'.jpg'}.get(desc.get('mimeType'))
        if suffix is None:raise ValueError('Unsupported embedded image format')
        dest=scratch/f'image_{index}_{colorspace}{suffix}'
        dest.write_bytes(encoded)
        image=bpy.data.images.load(str(dest),check_existing=False);image.colorspace_settings.name=colorspace
        pixels,meta=image_pixels(image);meta['encoded_sha256']=hashlib.sha256(encoded).hexdigest()
        return pixels,meta
    def texture_info(info,colorspace):
        if info.get('texCoord',0)!=0 or info.get('extensions'):raise ValueError('Non-UV0/custom texture transform unsupported')
        return glb_image(info['index'],colorspace)
    materials = {}
    for i,m in enumerate(doc.get('materials', [])):
        pbr=m.get('pbrMetallicRoughness',{}); ex=m.get('extensions',{})
        if m.get('normalTexture') or m.get('occlusionTexture'):raise ValueError('Normal/AO texture audit unsupported')
        base = np.asarray(pbr.get('baseColorFactor',[1,1,1,1]),dtype=np.float32)
        emiss=np.asarray(m.get('emissiveFactor',[0,0,0]),dtype=np.float32)
        strength=ex.get('KHR_materials_emissive_strength',{}).get('emissiveStrength',1)
        roles={'base_color':base,'metallic':np.asarray(pbr.get('metallicFactor',1),dtype=np.float32),
               'roughness':np.asarray(pbr.get('roughnessFactor',1),dtype=np.float32),'emission':emiss*strength};textures={}
        if 'baseColorTexture' in pbr:
            pixels,meta=texture_info(pbr['baseColorTexture'],'sRGB')
            roles['base_color']=pixels*base;textures['base_color']=meta
        if m.get('alphaMode','OPAQUE')=='OPAQUE':roles['base_color'][...,3]=1
        if 'metallicRoughnessTexture' in pbr:
            pixels,meta=texture_info(pbr['metallicRoughnessTexture'],'Non-Color')
            roles['roughness']=pixels[:,:,1]*roles['roughness'];textures['roughness']=dict(meta,channel=1)
            roles['metallic']=pixels[:,:,2]*roles['metallic'];textures['metallic']=dict(meta,channel=2)
        if 'emissiveTexture' in m:
            pixels,meta=texture_info(m['emissiveTexture'],'sRGB')
            roles['emission']=pixels[:,:,:3]*roles['emission'];textures['emission']=meta
        materials[str(i)]=roles_record(m.get('name',str(i)),roles,textures)
    points, normals, labels, nodes = [], [], [], doc.get('nodes',[])
    uvs,uv_present=[],[]
    def visit(index, parent, trail):
        if index in trail: raise ValueError('Cyclic GLB node graph')
        node=nodes[index]
        if 'matrix' in node:
            local=Matrix(np.array(node['matrix']).reshape(4,4).T.tolist())
        else:
            q=node.get('rotation',[0,0,0,1]); t=node.get('translation',[0,0,0]); s=node.get('scale',[1,1,1])
            local=Matrix.Translation(Vector(t))@Quaternion((q[3],q[0],q[1],q[2])).to_matrix().to_4x4()@Matrix.Diagonal(Vector((*s,1)))
        world=parent@local; nm=world.to_3x3().inverted().transposed()
        if 'mesh' in node:
            for prim in doc['meshes'][node['mesh']]['primitives']:
                if prim.get('mode',4)!=4 or prim.get('extensions'): raise ValueError('Non-triangle/compressed primitive')
                att=prim['attributes']; p=accessor(att['POSITION']); n=accessor(att['NORMAL'])
                texcoord=accessor(att['TEXCOORD_0']) if 'TEXCOORD_0' in att else None
                idx=accessor(prim['indices']).reshape(-1) if 'indices' in prim else np.arange(len(p))
                if len(idx)%3: raise ValueError('Bad triangle index count')
                for k in idx:
                    nv=nm@Vector(n[k]); nv.normalize()
                    points.append(tuple(world@Vector(p[k]))); normals.append(tuple(nv)); labels.append(str(prim['material']))
                    uvs.append(tuple(texcoord[k]) if texcoord is not None else (0,0));uv_present.append(texcoord is not None)
        for child in node.get('children',[]): visit(child,world,trail+[index])
    scene=doc['scenes'][doc.get('scene',0)]
    for node in scene.get('nodes',[]): visit(node,Matrix.Identity(4),[])
    used=set(labels); materials={k:v for k,v in materials.items() if k in used}
    return {'points':np.asarray(points), 'normals':np.asarray(normals), 'labels':labels,
            'uvs':np.asarray(uvs),'uv_present':uv_present,
            'materials':materials,'bbox':bbox(points),'triangles':len(points)//3,
            'raw_summary':{'nodes':len(nodes),'meshes':len(doc.get('meshes',[])),
                           'materials':len(doc.get('materials',[])),'images':len(doc.get('images',[])),
                           'accessors':len(doc.get('accessors',[])), 'bytes':len(data)}}


def contact_graph(parts, tolerance):
    islands=[]
    for part in parts:
        verts, tris=part['vertices'],part['triangles']; parent=list(range(len(verts)))
        def find(i):
            while parent[i]!=i: parent[i]=parent[parent[i]]; i=parent[i]
            return i
        for a,b in part['edges']:
            a,b=find(a),find(b)
            if a!=b: parent[a]=b
        groups=defaultdict(list)
        for i in range(len(verts)): groups[find(i)].append(i)
        for number, ids in enumerate(groups.values()):
            remap={old:new for new,old in enumerate(ids)}; v=[verts[i].copy() for i in ids]
            ts=[tuple(remap[i] for i in t) for t in tris if t[0] in remap]
            if not ts: continue
            edges=Counter(tuple(sorted((t[k],t[(k+1)%3]))) for t in ts for k in range(3))
            islands.append({'label':f'{part["name"]}#{number}','v':v,'t':ts,'bbox':bbox(v),
                            'closed':all(c==2 for c in edges.values()),'bvh':BVHTree.FromPolygons(v,ts,all_triangles=True)})
    adjacency={i:set() for i in range(len(islands))}; evidence=[]
    def contains(container, point):
        if not container['closed']: return False
        votes=[]
        for d in (Vector((.173,.439,.882)).normalized(),Vector((.511,.719,.471)).normalized()):
            p=point.copy(); hits=0
            for _ in range(256):
                loc,_,_,_=container['bvh'].ray_cast(p,d)
                if loc is None: break
                hits+=1; p=loc+d*1e-5
            else: return False
            votes.append(hits%2==1)
        return all(votes)
    for i,a in enumerate(islands):
        for j in range(i):
            b=islands[j]
            if any(a['bbox']['min'][k] > b['bbox']['max'][k]+tolerance or b['bbox']['min'][k] > a['bbox']['max'][k]+tolerance for k in range(3)): continue
            method=None; distance=None
            if a['bvh'].overlap(b['bvh']): method='triangle_intersection'
            if method is None:
                for one,other in ((a,b),(b,a)):
                    for p in one['v']:
                        _,_,_,dist=other['bvh'].find_nearest(p,tolerance)
                        if dist is not None and dist<=tolerance:
                            method='surface_gap_within_tolerance'; distance=dist; break
                    if method: break
            if method is None and (contains(a,b['v'][0]) or contains(b,a['v'][0])):
                method='enclosed_volume'
            if method:
                adjacency[i].add(j); adjacency[j].add(i)
                evidence.append({'a':a['label'],'b':b['label'],'method':method,'gap_m':distance})
    unseen=set(adjacency); components=[]
    while unseen:
        todo=[unseen.pop()]; group=[]
        while todo:
            i=todo.pop();group.append(i)
            new=adjacency[i]&unseen;unseen-=new;todo.extend(new)
        components.append(group)
    components.sort(key=lambda g:sum(len(islands[i]['t']) for i in g),reverse=True)
    detached_details=[]
    if len(components)>1:
        largest_vertices=[];largest_triangles=[];largest_labels=[]
        for i in components[0]:
            offset=len(largest_vertices);largest_vertices.extend(islands[i]['v'])
            largest_triangles.extend(tuple(offset+j for j in t) for t in islands[i]['t'])
            largest_labels.extend([islands[i]['label']]*len(islands[i]['t']))
        hull=BVHTree.FromPolygons(largest_vertices,largest_triangles,all_triangles=True)
        for group in components[1:]:
            nearest=None
            for i in group:
                for v in islands[i]['v']:
                    loc,_,tri,distance=hull.find_nearest(v)
                    if distance is not None and (nearest is None or distance<nearest['sampled_min_gap_m']):
                        nearest={'part':islands[i]['label'],'nearest_main_part':largest_labels[tri],
                                 'sampled_min_gap_m':distance,'part_vertex':list(v),'nearest_main_surface':list(loc)}
            detached_details.append({'parts':[islands[i]['label'] for i in group],'nearest_main_contact':nearest})
    return {'pass':len(components)<=1,'islands':len(islands),'components':[[islands[i]['label'] for i in g] for g in components],
            'detached_details':detached_details,
            'contact_tolerance_m':tolerance,'connections':evidence,
            'method':'Mesh-island graph: actual BVH triangle intersection, bidirectional vertex-to-triangle proximity, or two-ray closed-volume containment. Full geometry, no origin/bbox-only acceptance.',
            'limits':'Sub-tolerance gaps count as contact; vertex-surface proximity may miss near-parallel edge-only gaps without intersection; full enclosure is an explicit review warning.'}


def summarize(snap):
    return {'triangles':snap['triangles'],'bbox':snap['bbox'],
            'materials':{name:{k:v for k,v in mat.items() if not k.startswith('_')}
                         for name,mat in snap['materials'].items()}}


def run(args):
    result={'schema':'sternenbuergerchen.ship_independent_audit.v1','blender':bpy.app.version_string,
            'inputs':{'blend':str(Path(args.blend).resolve()),'glb':str(Path(args.glb).resolve()),
                      'blend_sha256':sha(args.blend),'glb_sha256':sha(args.glb)},'errors':[],'warnings':[],
            'limitations':['Blender source/GLB audit only; no native Godot import or visual/user acceptance.',
                           'Principled constants/direct image textures, effective decoded pixels; not a high-to-low texture bake audit.',
                           'Static landing pose only; no animation, load-bearing physics or rig validation.']}
    bpy.ops.wm.open_mainfile(filepath=str(Path(args.blend).resolve()))
    if args.collection == '*': objects=[o for o in bpy.context.scene.objects if o.type=='MESH']
    else:
        coll=bpy.data.collections.get(args.collection)
        if coll is None: raise ValueError(f'Missing collection {args.collection}; use --collection * only if scene has no helpers')
        objects=[o for o in coll.all_objects if o.type=='MESH']
    if not objects: raise ValueError('No selected source meshes')
    source=snapshot(objects); result['source']=summarize(source); result['source']['objects']=source['objects']
    for ob in source['objects']:
        if any(abs(v-1)>1e-5 for v in ob['scale']): result['errors'].append(f'{ob["name"]}: unapplied scale {ob["scale"]}')
    bb=source['bbox']
    if abs(bb['min'][2])>args.position_tol: result['errors'].append(f'Ground z={bb["min"][2]}')
    if max(abs(bb['center'][i]) for i in (0,1))>args.position_tol: result['errors'].append(f'Full XY bounds not centered: {bb["center"][:2]}')
    if args.length is not None and abs(bb['size'][1]-args.length)>args.position_tol: result['errors'].append(f'Length {bb["size"][1]} != {args.length}')
    if source['triangles']>args.max_tris: result['errors'].append(f'Triangle budget {source["triangles"]}>{args.max_tris}')
    sys.path.insert(0,str(SKILL_DIR)); import qa_check
    result['source_skill_qa']=qa_check.run(objects=[o.name for o in objects],profile='game',eps=args.zfight_tol,tol=args.contact_tol,uv=not args.no_uv,max_tris=300000)
    result['errors']+=['Source QA: '+s for s in result['source_skill_qa']['errors']]
    result['warnings']+=['Source QA: '+s for s in result['source_skill_qa']['warnings']]
    if args.no_uv: result['warnings'].append('UV audit explicitly disabled: permitted only for untextured constant materials; unique texture baking is not validated.')
    result['contact_graph']=contact_graph(source['parts'],args.contact_tol)
    if not result['contact_graph']['pass']: result['errors'].append('Disconnected source mesh-island contact components')
    enclosed=[e for e in result['contact_graph']['connections'] if e['method']=='enclosed_volume']
    if enclosed: result['warnings'].append(f'{len(enclosed)} connections rely on closed-volume containment; review hidden internal assemblies.')
    direct=read_glb(args.glb,Path(args.out).parent/(Path(args.out).stem+'_embedded_images'))
    expected=dict(source)
    rotation=np.array([[1,0,0],[0,0,1],[0,-1,0]],dtype=float)
    expected['points']=source['points']@rotation.T; expected['normals']=source['normals']@rotation.T
    expected['uvs']=source['uvs'].copy();expected['uvs'][:,1]=1-expected['uvs'][:,1]
    result['direct_glb']=summarize(direct); result['direct_glb']['raw_summary']=direct['raw_summary']
    result['direct_glb_comparison']=compare_corners(expected,direct,args.position_tol,args.normal_tol,args.material_tol)
    result['direct_glb_comparison']['axis_contract']='Blender (X,Y,Z) -> glTF/Godot (X,Z,-Y); -Y front -> +Z front'
    result['errors']+=['Direct GLB: '+s for s in result['direct_glb_comparison']['errors']]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.glb).resolve()))
    imported=snapshot([o for o in bpy.context.scene.objects if o.type=='MESH'])
    result['fresh_roundtrip']=summarize(imported); result['fresh_roundtrip']['objects']=imported['objects']
    result['roundtrip_comparison']=compare_corners(source,imported,args.position_tol,args.roundtrip_normal_tol,args.material_tol)
    result['errors']+=['Fresh roundtrip: '+s for s in result['roundtrip_comparison']['errors']]
    result['pass']=not result['errors']
    result['warnings_review_required']=list(result['warnings'])
    if args.accept_warnings:
        accepted=json.loads(Path(args.accept_warnings).read_text(encoding='utf-8'))
        result['warning_dispositions']=[]
        for warning in result['warnings']:
            reasons=[v for k,v in accepted.items() if k in warning and isinstance(v,str) and v.strip()]
            result['warning_dispositions'].append({'warning':warning,'accepted':bool(reasons),'reason':'; '.join(reasons)})
        result['warnings_review_required']=[d['warning'] for d in result['warning_dispositions'] if not d['accepted']]
    result['ready_for_technical_handoff']=result['pass'] and not result['warnings_review_required']
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--blend',required=True);parser.add_argument('--glb',required=True)
    parser.add_argument('--out',required=True);parser.add_argument('--collection',default='LOW')
    parser.add_argument('--length',type=float);parser.add_argument('--max-tris',type=int,default=25000)
    parser.add_argument('--position-tol',type=float,default=2e-5)
    parser.add_argument('--normal-tol',type=float,default=2e-4)
    parser.add_argument('--roundtrip-normal-tol',type=float,default=.002,
                        help='Fresh Blender reconstructed split normals: max vector error .002 = approx .115 degrees; raw GLB retains tighter --normal-tol')
    parser.add_argument('--material-tol',type=float,default=2e-5)
    parser.add_argument('--contact-tol',type=float,default=.002)
    parser.add_argument('--zfight-tol',type=float,default=.001)
    parser.add_argument('--no-uv',action='store_true')
    parser.add_argument('--accept-warnings',help='JSON object substring -> concrete manual-review rationale; never accepts errors')
    args=parser.parse_args(sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else [])
    try: result=run(args)
    except Exception as exc:
        result={'pass':False,'ready_for_technical_handoff':False,'exception':str(exc),'traceback':traceback.format_exc()}
    out=Path(args.out);out.parent.mkdir(parents=True,exist_ok=True)
    out.write_text(json.dumps(result,indent=2,allow_nan=False),encoding='utf-8')
    print('@@SHIP_QA@@'+json.dumps({'pass':result['pass'],'out':str(out),'errors':result.get('errors',result.get('exception')),'warnings':len(result.get('warnings',[]))}))
    if not result['pass']: raise SystemExit(2)


if __name__=='__main__': main()

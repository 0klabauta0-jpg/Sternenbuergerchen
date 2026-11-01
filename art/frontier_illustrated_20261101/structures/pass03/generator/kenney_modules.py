"""Actual, attributed Kenney mesh reuse; source files are read-only.

Texture-atlas colors are sampled only to select semantic palette fields. New
derivatives have solid materials. Source geometry is welded/recalculated and
zero-area faces are removed in the derivative, never in curated originals.
"""
from pathlib import Path
import bpy,bmesh,json,hashlib,math,colorsys
from mathutils import Vector,Matrix

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def color_of_face(ob,p):
    mat=ob.data.materials[p.material_index];tex=next((n for n in mat.node_tree.nodes if n.type=='TEX_IMAGE' and n.image),None)
    if not tex or not ob.data.uv_layers:return (.5,.5,.5)
    im=tex.image;uv=ob.data.uv_layers.active
    u=sum(uv.data[i].uv.x for i in p.loop_indices)/len(p.loop_indices);v=sum(uv.data[i].uv.y for i in p.loop_indices)/len(p.loop_indices)
    w,h=im.size;x=min(w-1,max(0,int(u*w)));y=min(h-1,max(0,int(v*h)))
    return tuple(im.pixels[(y*w+x)*4:(y*w+x)*4+3])
def semantic(color,mode,z):
    r,g,b=color;h,s,v=colorsys.rgb_to_hsv(r,g,b)
    warm=r>b*1.15 and s>.25
    dark=v<.42
    if mode=='wall':return 'Frame' if z<.155 else ('PaleTrim' if z>.945 else 'Cream')
    if mode=='wall-window':return 'Orange' if warm else ('Frame' if z<.155 else 'Cream')
    if mode=='frame':return 'Cream'
    if mode=='bed':return 'Soft' if warm else ('Frame' if dark else 'PaleTrim')
    if mode=='console':return 'Glass' if warm else ('Frame' if dark else 'Cream')
    if mode=='display':return 'Orange' if warm else ('Glass' if b>r*1.23 else ('Frame' if dark else 'Cream'))
    if mode=='tank':return 'Cream' if warm else 'Frame'
    if mode=='cargo-orange':return 'Orange' if warm else 'Frame'
    if mode=='cargo-cream':return 'Cream' if warm else 'Frame'
    return 'Orange' if warm else ('Frame' if dark else 'Cream')

def module(root,mats,pack,asset,name,center,size,bottom,collection,mode='default',rotation=0,select_objects=None,frame_only=False):
    path=root/'Assets/curated/kenney'/pack/'models'/(asset+'.glb');lic=root/'Assets/curated/kenney'/pack/'License.txt'
    existing=set(bpy.data.objects);bpy.ops.import_scene.gltf(filepath=str(path),merge_vertices=True)
    added=[o for o in bpy.data.objects if o not in existing]
    selected=[o for o in added if o.type=='MESH' and (not select_objects or o.name.split('.')[0] in select_objects)]
    matslist=list(mats);new=[];changes=[]
    for i,ob in enumerate(selected):
        oldname=ob.name;original_v=len(ob.data.vertices);original_f=len(ob.data.polygons)
        rgb=[color_of_face(ob,p) for p in ob.data.polygons]
        zcenters=[sum(ob.data.vertices[j].co.z for j in p.vertices)/len(p.vertices) for p in ob.data.polygons]
        palette=[semantic(c,mode,z) for c,z in zip(rgb,zcenters)]
        # Factory door carries a small hinge yaw; use its local geometry to
        # square the frame with this building. Other modules keep world layout.
        matrix=Matrix.Identity(4) if frame_only else ob.matrix_world.copy()
        me=ob.data.copy();ob.data=me
        for p,col in zip(me.polygons,palette):p.material_index=matslist.index(col)
        bm=bmesh.new();bm.from_mesh(me)
        discarded=0
        if frame_only:
            # Clip the two actual jamb regions and header separately. Capping a
            # single open U as one contour can triangulate across its doorway;
            # three clipped source solids avoid that unwanted diagonal sheet.
            verts=[];faces=[]
            specs=[[((-.68,0,0),(1,0,0),False,True),((0,0,.105),(0,0,1),True,False)],
                   [((-.12,0,0),(1,0,0),True,False),((0,0,.105),(0,0,1),True,False)],
                   [((-.68,0,0),(1,0,0),True,False),((-.12,0,0),(1,0,0),False,True),((0,0,1.48),(0,0,1),True,False)]]
            for spec in specs:
                sub=bm.copy();bmesh.ops.remove_doubles(sub,verts=list(sub.verts),dist=.000001)
                for co,no,inner,outer in spec:
                    bmesh.ops.bisect_plane(sub,geom=list(sub.verts)+list(sub.edges)+list(sub.faces),dist=.000001,plane_co=co,plane_no=no,clear_inner=inner,clear_outer=outer)
                    edges=[e for e in sub.edges if e.is_boundary]
                    if edges:bmesh.ops.holes_fill(sub,edges=edges,sides=0)
                sub.verts.ensure_lookup_table();sub.verts.index_update();offset=len(verts);verts.extend(tuple(v.co) for v in sub.verts)
                faces.extend(tuple(offset+v.index for v in f.verts) for f in sub.faces);sub.free()
            bm.free();bm=bmesh.new();vmap=[bm.verts.new(p) for p in verts]
            for face in faces:
                try:f=bm.faces.new([vmap[i] for i in face]);f.material_index=matslist.index('Cream')
                except ValueError:pass
            discarded=original_f-sum(len(f.verts)-2 for f in bm.faces)
        bmesh.ops.remove_doubles(bm,verts=list(bm.verts),dist=.000001)
        before=len(bm.faces)
        bmesh.ops.dissolve_degenerate(bm,edges=list(bm.edges),dist=.00001)
        bad=[f for f in bm.faces if f.calc_area()<1e-9]
        if bad:bmesh.ops.delete(bm,geom=bad,context='FACES')
        # Vertices shared by back-to-back source mounting caps create >2-face
        # edges. Keep the separate source shells at those edges; do not invent
        # a boolean volume or alter their visible surfaces.
        nonmanifold=[e for e in bm.edges if len(e.link_faces)>2]
        if nonmanifold:bmesh.ops.split_edges(bm,edges=nonmanifold)
        loose=[v for v in bm.verts if not v.link_faces]
        if loose:bmesh.ops.delete(bm,geom=loose,context='VERTS')
        bmesh.ops.recalc_face_normals(bm,faces=list(bm.faces));bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(me);bm.free()
        me.transform(matrix);saved_material_indices=[p.material_index for p in me.polygons];me.materials.clear()
        for mat in mats.values():me.materials.append(mat)
        for p,idx in zip(me.polygons,saved_material_indices):p.material_index=idx
        for uv in list(me.uv_layers):me.uv_layers.remove(uv)
        for p in me.polygons:p.use_smooth=False
        # Factory movable props may import object Actions (door hinge/lift).
        # This is a static assembly: freeze their sampled source geometry and
        # clear object animation before applying the fitted identity transform.
        ob.animation_data_clear()
        for constraint in list(ob.constraints):ob.constraints.remove(constraint)
        ob.parent=None;ob.matrix_world=Matrix.Identity(4);ob.name=name+('_'+str(i) if len(selected)>1 else '')
        for co in list(ob.users_collection):co.objects.unlink(ob)
        collection.objects.link(ob)
        ob['functional_zone']=collection.name;ob['kenney_source']=str(path.relative_to(root)).replace('\\','/');ob['kenney_source_sha256']=sha(path)
        ob['kenney_source_object']=oldname;ob['license']='Kenney CC0'
        new.append(ob)
        changes.append({'source_object':oldname,'original_vertices':original_v,'original_faces':original_f,'derivative_vertices':len(me.vertices),'derivative_triangles':sum(len(p.vertices)-2 for p in me.polygons),
                        'closed_leaf_and_sill_omitted':frame_only,'closed_leaf_faces_omitted':None if frame_only else 0,
                        'degenerate_faces_removed_or_dissolved':before-len(me.polygons) if before>len(me.polygons) else len(bad),'source_nonmanifold_mount_edges_split':len(nonmanifold)})
    for ob in added:
        if ob not in new:bpy.data.objects.remove(ob,do_unlink=True)
    if not new:raise RuntimeError('No selected source geometry '+str(path))
    points=[v.co for ob in new for v in ob.data.vertices]
    lo=Vector([min(v[i] for v in points) for i in range(3)]);hi=Vector([max(v[i] for v in points) for i in range(3)]);oldsize=hi-lo
    c=(lo+hi)/2;scale=Vector([size[i]/oldsize[i] for i in range(3)]);rot=Matrix.Rotation(rotation,4,'Z')
    for ob in new:
        for v in ob.data.vertices:
            q=Vector(((v.co.x-c.x)*scale.x,(v.co.y-c.y)*scale.y,(v.co.z-lo.z)*scale.z))
            q=rot@q;v.co=q+Vector((center[0],center[1],bottom))
        ob.data.update()
    provenance={'source':str(path.relative_to(root)).replace('\\','/'),'source_sha256':sha(path),'pack':('Kenney Space Station Kit 1.0' if pack=='space_station' else 'Kenney Factory Kit 3.0'),
                'license':'Creative Commons Zero (CC0)','license_path':str(lic.relative_to(root)).replace('\\','/'),'license_sha256':sha(lic),
                'instance':name,'retained_objects':[c['source_object'] for c in changes],'new_objects':[o.name for o in new],
                'geometry_taken':'Actual imported source vertices/faces, including distinctive profiles; not recreated from primitives',
                'changes':changes,'operations':['attribute seam weld1micrometre','remove zero-area faces / dissolve short edges in derivative','split nonmanifold source mounting contacts if needed','recalculate outward winding','constant palette replacing original texture atlas','freeze sampled movable modules; remove imported object animation on static derivative','nonuniform fit to source-metre dimensions; apply rotation/scale'],
                'fit_dimensions_before_rotation_m':list(size),'center_xy_before_pivot_normalization_m':list(center),'bottom_before_pivot_normalization_m':bottom,'rotation_z_radians':rotation,
                'frame_cut':frame_only,'omitted_objects':select_objects and 'Any source objects outside '+str(select_objects) or None}
    return new,provenance

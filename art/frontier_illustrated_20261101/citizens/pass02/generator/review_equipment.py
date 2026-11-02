"""Matched stock/equipment Workbench texture views and sampled deformation QA."""
from pathlib import Path
import bpy,json,sys,math
import numpy as np
from mathutils import Vector,Quaternion,Matrix
HERE=Path(__file__).resolve().parents[1]
sys.path.insert(0,str(HERE/'generator'))
import build_equipment as build
sys.path.insert(0,'C:/Users/bjoer/.codex/skills/blender-asset-qa/scripts')
import qa_check
QA=HERE/'qa'

def render(path,obs,direction,mode='texture',ortho=2.13):
    sc=bpy.context.scene
    sc.render.engine='BLENDER_WORKBENCH';sc.render.resolution_x=560;sc.render.resolution_y=640;sc.render.resolution_percentage=100
    sc.render.film_transparent=False;sc.render.image_settings.file_format='PNG'
    sc.world=bpy.data.worlds.new('QA_Sky');sc.world.color=(.38,.55,.64)
    sh=sc.display.shading;sh.light='STUDIO';sh.color_type='TEXTURE' if mode=='texture' else ('RANDOM' if mode=='random' else 'OBJECT')
    sh.show_cavity=True;sh.cavity_type='BOTH';sh.curvature_ridge_factor=1.1;sh.curvature_valley_factor=.65
    sh.show_shadows=True;sh.show_object_outline=False;sh.background_type='WORLD'
    sc.view_settings.view_transform='Standard'
    for o in sc.objects:o.hide_render=o not in obs
    camera=bpy.data.objects.new('QA_Camera',bpy.data.cameras.new('QA_Camera'))
    sc.collection.objects.link(camera);sc.camera=camera;camera.data.type='ORTHO';camera.data.ortho_scale=ortho
    center=Vector((0,0,.89));camera.location=center+Vector(direction).normalized()*5
    camera.rotation_euler=(center-camera.location).to_track_quat('-Z','Y').to_euler()
    wires=[]
    if mode=='wire':
        for ob in obs:
            ob.color=(.65,.71,.73,1);w=ob.copy();w.name='QA_Wire_'+ob.name;w.color=(.008,.014,.02,1)
            # The original Armature modifier remains before QA wireframe.
            md=w.modifiers.new('QA_wire_only','WIREFRAME');md.thickness=.0012
            sc.collection.objects.link(w);wires.append(w)
    sc.render.filepath=str(path);bpy.ops.render.render(write_still=True)
    for o in wires:bpy.data.objects.remove(o,do_unlink=True)
    bpy.data.objects.remove(camera,do_unlink=True)

def sheet(paths,target,cols=3):
    arrays=[]
    for p in paths:
        im=bpy.data.images.load(str(p),check_existing=False);w,h=im.size
        a=np.empty(w*h*4,dtype=np.float32);im.pixels.foreach_get(a);arrays.append(a.reshape(h,w,4));bpy.data.images.remove(im)
    rows=math.ceil(len(paths)/cols);out=np.ones((h*rows,w*cols,4),np.float32)
    for i,a in enumerate(arrays):
        rr=rows-1-i//cols;cc=i%cols;out[rr*h:(rr+1)*h,cc*w:(cc+1)*w]=a
    im=bpy.data.images.new('QA_Sheet',w*cols,h*rows,alpha=True);im.pixels.foreach_set(out.ravel());im.filepath_raw=str(target);im.file_format='PNG';im.save();bpy.data.images.remove(im)

def action_hash(rig):
    import hashlib
    data={}
    for clip in ['idle','walk']:
        a=bpy.data.actions[clip];data[clip]=[]
        for layer in a.layers:
            for strip in layer.strips:
                for cb in strip.channelbags:
                    for fc in cb.fcurves:
                        data[clip].append([fc.data_path,fc.array_index,[[*k.co,*k.handle_left,*k.handle_right,k.interpolation] for k in fc.keyframe_points]])
    return hashlib.sha256(json.dumps(data,separators=(',',':')).encode()).hexdigest()

def stress(rig):
    build.set_pose(rig)
    for name,axis,angle in [('UpperChest',(1,0,0),12),('LeftArm',(0,1,0),-75),('RightForeArm',(0,0,1),140),('LeftLeg',(1,0,0),110)]:
        b=rig.pose.bones[name];local=b.bone.matrix_local.to_quaternion().inverted()@Vector(axis)
        b.rotation_mode='QUATERNION';b.rotation_quaternion=Quaternion(local,math.radians(angle))
    bpy.context.view_layer.update()

def verify_rigid(obs,rig):
    maximum=0;dg=bpy.context.evaluated_depsgraph_get()
    for ob in obs:
        if not ob.get('rigid_bind_bone'):continue
        name=ob['rigid_bind_bone'];mx=rig.pose.bones[name].matrix@rig.data.bones[name].matrix_local.inverted()
        ev=ob.evaluated_get(dg);me=ev.to_mesh()
        maximum=max(maximum,max((me.vertices[v.index].co-mx@v.co).length for v in ob.data.vertices));ev.to_mesh_clear()
    return maximum

def review(role):
    stock=HERE.parent/(role+'_stock.blend');candidate=HERE/'source'/(role+'_equipment.blend')
    bpy.ops.wm.open_mainfile(filepath=str(stock));rig=bpy.data.objects['Root'];stock_motion=action_hash(rig)
    body=bpy.data.objects['characterMedium'];build.set_pose(rig,'idle',8)
    before=QA/(role+'_stock_idle_front.png');render(before,[body],(.3,-1,.22))
    bpy.ops.wm.open_mainfile(filepath=str(candidate));rig=bpy.data.objects['Root'];obs=[o for o in bpy.context.scene.objects if o.type=='MESH']
    assert action_hash(rig)==stock_motion
    checks=[];paths=[]
    settings=[('idle_front','idle',8,(.3,-1,.22)),('idle_rear','idle',8,(-.5,1,.27)),('walk_contact','walk',0,(.85,-1,.28)),('walk_passing','walk',8,(1,-.3,.2)),('walk_opposite','walk',24,(-.7,-1,.28))]
    for label,clip,f,direction in settings:
        build.set_pose(rig,clip,f);err=verify_rigid(obs,rig);assert err<.00002
        p=QA/(role+'_'+label+'.png');render(p,obs,direction);paths.append(p)
        raw=qa_check.run(objects=[o.name for o in obs],profile='game',eps=.0003,tol=.006,uv=False)
        build.dump(QA/(role+'_'+label+'_raw.json'),raw)
        checks.append({'pose':label,'clip':clip,'frame':f,'rigid_position_error_m':err,'raw_qa_pass':raw['pass'],'errors':raw['errors'],'warnings':raw['warnings'],'stats':build.mesh_stats(obs),'image':str(p.relative_to(build.ROOT))})
    stress(rig);err=verify_rigid(obs,rig);assert err<.00002
    p=QA/(role+'_stress.png');render(p,obs,(.65,-1,.3));paths.append(p)
    checks.append({'pose':'diagnostic_stress','note':'not a delivered clip; chest12deg, leftshoulder75deg, rightelbow140deg, leftknee110deg','rigid_position_error_m':err,'image':str(p.relative_to(build.ROOT))})
    sheet(paths,QA/(role+'_poses.png'))
    build.set_pose(rig,'idle',8)
    render(QA/(role+'_random.png'),obs,(.7,-1,.3),mode='random')
    render(QA/(role+'_wire.png'),obs,(.7,-1,.3),mode='wire')
    result={'role':role,'motion_curves_match_stock':True,'motion_curve_signature':stock_motion,'pose_checks':checks,
        'render':'Blender5.2.3 Workbench studio texture mode; no native engine or PBR acceptance inferred',
        'matched_comparison':[str(before.relative_to(build.ROOT)),str(paths[0].relative_to(build.ROOT))]}
    build.dump(QA/(role+'_poses.json'),result);print('POSE_REVIEW_RESULT '+json.dumps(result))

if __name__=='__main__':
    args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else build.ROLES
    for r in args or build.ROLES:review(r)

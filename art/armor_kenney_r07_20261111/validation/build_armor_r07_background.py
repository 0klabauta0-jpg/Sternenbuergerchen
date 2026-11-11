import subprocess,pathlib,sys,time
root=pathlib.Path(__file__).resolve().parents[2]
script=sys.argv[1] if len(sys.argv)>1 else 'art/armor_kenney_r07_20261111/build_armor_r07.py'
args=['C:/Program Files/Blender Foundation/Blender 5.1/blender.exe','--background','--factory-startup','--python-exit-code','1','--python',str(root/script)]
t=time.time();p=subprocess.run(args,cwd=root,capture_output=True,text=True,timeout=300)
log=p.stdout+p.stderr
(root/'output/native_glut_maps'/(pathlib.Path(script).stem+'.log')).write_text(log,encoding='utf8')
print(log[-4000:]);print('EXIT',p.returncode,'SECONDS',time.time()-t);sys.exit(p.returncode)

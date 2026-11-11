import subprocess,os,sys,pathlib,time
root=pathlib.Path(__file__).resolve().parents[2]
env=os.environ.copy();env['APPDATA']=str(root/'output/native_glut_maps/private_armor_profile/astra_r07')
script=sys.argv[1] if len(sys.argv)>1 else 'armor_r07_probe.gd'
args=['C:/Users/bjoer/AppData/Local/Programs/Godot/Godot_v4.6.2-stable_win64.exe','--path',str(root),'--script','output/native_glut_maps/'+script]
if '--headless' in sys.argv:args+=['--headless']
else:args+=['--position','-10000,-10000','--windowed']
si=subprocess.STARTUPINFO();si.dwFlags|=subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
t=time.time();p=subprocess.run(args,cwd=root,env=env,capture_output=True,text=True,timeout=120,startupinfo=si)
log=p.stdout+p.stderr
(root/'output/native_glut_maps'/(script+'.log')).write_text(log,encoding='utf8')
(root/'output/native_glut_maps'/(script+('_headless' if '--headless' in sys.argv else '_native')+'.log')).write_text(log,encoding='utf8')
print(log[-7000:]);print('EXIT',p.returncode,'SECONDS',time.time()-t)
sys.exit(p.returncode)

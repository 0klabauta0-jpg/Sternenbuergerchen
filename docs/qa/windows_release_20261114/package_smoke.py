import os,sys,json,hashlib,subprocess,re,time
from pathlib import Path
root=Path(__file__).resolve().parents[3]
qa=root/'docs/qa/windows_release_20261114'
pkg=Path('C:/dev/SternenBuergerchen-releases/2026-11-14-a377c7346')
real=Path(os.environ['APPDATA'])/'Godot/app_userdata/Sternenbuergerchen'
def fp(p):
 return {str(x.relative_to(p)):[x.stat().st_mtime_ns,hashlib.sha256(x.read_bytes()).hexdigest()] for x in p.rglob('*') if x.is_file()} if p.exists() else {}
before=fp(real)
private=root/'tmp/windows_release_20261114/profile'
private.mkdir(parents=True,exist_ok=True)
env=dict(os.environ,APPDATA=str(private),LOCALAPPDATA=str(private/'local'))
results=[]
for name,args in [('normal_main_menu',['--quit-after','120'])]:
 cmd=[str(pkg/'SternenBuergerchen.exe'),'--headless','--log-file',str(qa/(name+'_engine.log')),*args]
 started=time.monotonic()
 try:
  proc=subprocess.run(cmd,cwd=pkg,env=env,capture_output=True,timeout=75)
  out=(proc.stdout+proc.stderr).decode('utf-8','replace')
  (qa/(name+'.log')).write_text(out,encoding='utf-8')
  errors=re.findall(r'^.*(?:SCRIPT ERROR:|ERROR:|Parse Error:|Compile Error:|ObjectDB instances leaked|resources still in use at exit).*$',out,re.M)
  passed=proc.returncode==0 and not errors and 'Godot Engine v4.6.2.stable.official.71f334935' in out and 'netfox::NetworkPerformance' in out
  results.append(dict(name=name,exit_code=proc.returncode,passed=passed,errors=errors,seconds=round(time.monotonic()-started,2),command=cmd))
  if not passed: break
 except subprocess.TimeoutExpired:
  results.append(dict(name=name,passed=False,error='timeout'))
report=dict(profile_unchanged=before==fp(real),isolated_appdata=str(private),tests=results,scope='Headless exported EXE normal main menu startup only; external packed probe timed out and is excluded; no campaign/WAN/FPS/visual acceptance.')
(qa/'package_smoke.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps(report,indent=2))
sys.exit(0 if report['profile_unchanged'] and all(x['passed'] for x in results) else 1)

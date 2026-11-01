"""Verify frozen-previous/new/GLB render conditions and actual artifact hashes."""
import argparse,hashlib,json
from pathlib import Path

def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
p=argparse.ArgumentParser(description=__doc__);p.add_argument('--comparison-dir',required=True);p.add_argument('--audit')
a=p.parse_args();base=Path(a.comparison_dir).resolve()
manifests={name:json.loads((base/name/'render_manifest.json').read_text()) for name in ('previous','new','roundtrip')}
if (base/'source_diagnostics'/'render_manifest.json').is_file():
    manifests['source_diagnostics']=json.loads((base/'source_diagnostics'/'render_manifest.json').read_text())
checks=[];errors=[]
shot_keys=['location','rotation_euler','ortho_scale','resolution','azimuth','elevation']
scene_keys=['target_length','target','engine','samples','color_management','lights','floor','transparent']
for left,right,views in [('previous','new',['front','rear','side','top','game']),('new','roundtrip',['front','rear','game'])]:
    for view in views:
        aa=next((s for s in manifests[left]['shots'] if s['mode']=='material' and s['view']==view),None)
        bb=next((s for s in manifests[right]['shots'] if s['mode']=='material' and s['view']==view),None)
        equality={'both_material_shots':aa is not None and bb is not None}
        if equality['both_material_shots']:
            equality.update({k:aa[k]==bb[k] for k in shot_keys})
            equality.update({k:manifests[left][k]==manifests[right][k] for k in scene_keys})
        passed=all(equality.values())
        checks.append({'left':left,'right':right,'view':view,'pass':passed,'conditions':equality})
        if not passed:errors.append(f'Unequal conditions: {left}/{right}/{view}')
bindings=[]
for name,manifest in manifests.items():
    input_path=Path(manifest['input']);actual=sha(input_path) if input_path.is_file() else None
    bindings.append({'type':'render_input','set':name,'path':str(input_path),'expected':manifest['input_sha256'],'actual':actual,'pass':actual==manifest['input_sha256']})
    if name=='source_diagnostics' and manifest['input_sha256']!=manifests['new']['input_sha256']:
        errors.append('Source diagnostics bind a different source than final material renders')
    for shot in manifest['shots']:
        local=base/name/Path(shot['file']).name;actual=sha(local) if local.is_file() else None
        bindings.append({'type':'image','set':name,'path':str(local),'expected':shot['sha256'],'actual':actual,'pass':actual==shot['sha256']})
if a.audit:
    audit=json.loads(Path(a.audit).read_text());inputs=audit['inputs']
    for key,set_name in [('blend','new'),('glb','roundtrip')]:
        actual=sha(inputs[key]);expected=inputs[key+'_sha256']
        bindings.append({'type':'numeric_audit_input','set':set_name,'path':inputs[key],'expected':expected,'actual':actual,
                         'pass':actual==expected and expected==manifests[set_name]['input_sha256']})
    if not audit.get('pass') or not audit.get('ready_for_technical_handoff'):
        errors.append('Numeric audit not ready for technical handoff')
errors+=['Hash binding failed: '+b['path'] for b in bindings if not b['pass']]
result={'schema':'sternenbuergerchen.refinement_matched_conditions.v1','pass':not errors,'errors':errors,
        'checks':checks,'hash_bindings':bindings,'numeric_audit':a.audit,
        'note':'Blender diagnostic comparison of frozen previous candidate and refinement; not native Godot or user acceptance.'}
dest=base/'matched_conditions.json';dest.write_text(json.dumps(result,indent=2),encoding='utf8')
print(json.dumps({'pass':result['pass'],'pairs':len(checks),'hash_bindings':len(bindings),'errors':errors,'out':str(dest)}))
raise SystemExit(0 if result['pass'] else 1)

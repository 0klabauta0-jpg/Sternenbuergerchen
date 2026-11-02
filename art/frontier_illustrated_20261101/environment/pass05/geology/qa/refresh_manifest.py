"""Refresh frozen geology evidence from an explicit strict run and native pairs."""
from pathlib import Path
import argparse,hashlib,json,re
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[4]
def sha(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def record(path):return {'path':Path(path).relative_to(ROOT).as_posix(),'sha256':sha(path)}
def main():
    args=argparse.ArgumentParser();args.add_argument('--run',type=Path,default=HERE/'qa/check_runs/20261101T174053Z-pid120688');options=args.parse_args()
    manifest=HERE/'manifest.json';data=json.loads(manifest.read_text(encoding='utf-8'))
    probe=json.loads((HERE/'qa/native_probe.json').read_text(encoding='utf-8'))
    runtime=ROOT/'scripts/terrain/frontier_art_geology.gd'
    assert sha(runtime)==probe['source_sha256']==sha(HERE/'source/frontier_art_geology_pass05.gd')
    assert sha(ROOT/data['before_source']['path'])==data['before_source']['sha256']
    report=options.run/'metadata/report.json';log=options.run/'logs/check-geology_contract.log'
    status=json.loads(report.read_text(encoding='utf-8'))
    assert status['summary']['failed']==0 and status['summary']['passed']>=1
    assert all(row['passed'] and row['exit_code']==0 and not row['timed_out'] and row['marker_found'] and row['error_count']==0 for row in status['checks'])
    text=log.read_text(encoding='utf-8');assert not re.search(r'(?im)^\s*(?:SCRIPT ERROR|ERROR:|.*Parse Error|.*Compile Error|.*ObjectDB instances leaked|.*resources still in use at exit)',text)
    line=next(line for line in text.splitlines() if line.startswith('FRONTIER_PASS03_GEOLOGY '))
    contract=json.loads(line.split(' ',1)[1]);assert contract['passed']==12 and contract['failed']==0
    assert probe['pass'] and len(probe['captures'])==8
    for name in ['landscape','near_detail','wall_detail','rear_detail']:
        before,after=[row for row in probe['captures'] if row['view']==name]
        assert before['camera_transform']==after['camera_transform'] and before['camera_size']==after['camera_size']
        assert before['error']==after['error']==0
    geometry=contract['geometry'];assert geometry['finite'] and geometry['caps_up'] and geometry['walls_out']
    assert geometry['degenerate_triangles']==geometry['outside_footprint_vertices']==0 and geometry['vertices']<=30000
    data['runtime_source']=record(runtime);data['editable_source_copy']=record(HERE/'source/frontier_art_geology_pass05.gd')
    data['geometry'].update(geometry);data['geometry']['triangles']=geometry['vertices']//3
    data['contract']=contract;data['contract_report']=record(report);data['contract_log']=record(log)
    data['native_probe']=probe;data['native_probe_source']=record(HERE/'qa/probe_geology.gd')
    data['opened_images']=[record(ROOT/row['path'].removeprefix('res://')) for row in probe['captures']]
    data['pair_material_note']='Each isolated pair uses the same runtime-loaded profile/shader and light. Before means Pass04 geometry with the paired current probe route, not historical Pass04 material equality. Parent changes Pass05 material route separately.'
    data['analysis']=record(HERE/'ANALYSIS.md');data['readme']=record(HERE/'README.md')
    data['metadata_helper']=record(Path(__file__))
    manifest.write_text(json.dumps(data,indent=2),encoding='utf-8')
    print(json.dumps({'pass':True,'source_sha256':sha(runtime),'meshes':geometry['meshes'],'vertices':geometry['vertices'],'contract_passed':contract['passed'],'manifest':record(manifest)},indent=2))
if __name__=='__main__':main()

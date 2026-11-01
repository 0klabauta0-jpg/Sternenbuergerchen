"""Bind real captures/checks to the adopted Git source; preserve earlier diagnostics."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASE = ROOT / 'output/grafik_20261101'
HERE = BASE / 'main_adoption'
CODE = '177991ac4962c17be0d02ef909949826967c7f57'

def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def local(path):
    return ROOT / path.removeprefix('res://')

def record(path):
    return {'path':path.relative_to(ROOT).as_posix(),'sha256':sha(path)}

checks_path = HERE / 'final_check_runs/20261101T213909Z-pid27448/metadata/report.json'
checks = read(checks_path)
assert checks['summary'] == {'selected':29,'passed':29,'failed':0}
assert all(row['passed'] for row in checks['checks'])
native_path = BASE / 'main_adoption_runtime/native_final.json'
headless_path = BASE / 'main_adoption_runtime/headless_probe_r02.json'
native, headless = read(native_path), read(headless_path)
assert (native['passed'], native['failed']) == (45,0)
assert (headless['passed'], headless['failed']) == (33,0)
assert len(native['captures']) == 6 and len(native['stages']) == 8
assert not native['facts']['forced_arrival'] and not native['facts']['forced_unloading']
capture_path = BASE / 'main_adoption_after_capture.json'
capture = read(capture_path)
before = read(BASE / 'pass07_paths_after_capture.json')
assert len(capture['captures']) == len(before['captures']) == 20
assert capture['renderer'] == before['renderer'] and capture['light'] == before['light']
previous = {row['id']:row for row in before['captures']}
for row in capture['captures']:
    for key in ['camera_size','camera_transform','camera_projection','viewport_size','building_shells_visible']:
        if key in row:
            assert row[key] == previous[row['id']][key], (row['id'],key)
    assert row['error'] == 0 and local(row['path']).is_file()
menu = read(HERE / 'menu_background_capture.json')
assert sha(local(menu['image'])) == menu['sha256']
sources = dict(capture['runtime_sources_sha256'])
sources.update(menu['source_sha256'])
sources.update(native['facts']['sources_sha256'])
for path in ['data/background_image_catalog.json','maps/Ground_Mission01_32x32.json',
             'scripts/tests/frontier_start_graphics_verifier.gd',
             'scripts/tests/frontier_main_environment_verifier.gd',
             'scripts/tests/frontier_main_ship_adoption_verifier.gd']:
    sources['res://'+path] = sha(ROOT/path)
source_records = []
for path, digest in sources.items():
    relative = path.removeprefix('res://')
    blob = subprocess.check_output(['git','show',CODE+':'+relative],cwd=ROOT)
    assert sha(local(path)) == hashlib.sha256(blob).hexdigest() == digest, path
    source_records.append({'path':relative,'sha256':digest,'git_source_commit':CODE})
package_path = ROOT / 'art/frontier_illustrated_20261101/ships/main_adoption/manifest.json'
package = read(package_path)
for row in package['files']:
    assert sha(local(row['path'])) == row['sha256'], row['path']
isolated_log = (HERE/'fresh_asset_import/import.log').read_text(encoding='utf-8-sig')
assert not any(x in isolated_log for x in ['SCRIPT ERROR','ERROR:','leaked','resources still in use'])
for row in read(HERE/'fresh_asset_import/source_provenance.json')['files']:
    assert sha(local(row['source'])) == sha(local(row['isolated_copy'])) == row['source_sha256']
remote = subprocess.check_output(['git','ls-remote','--heads','origin','main'],cwd=ROOT,text=True).split()[0]
main_head = subprocess.check_output(['git','-C','C:/dev/SternenBuergerchen','rev-parse','HEAD'],text=True).strip()
assert remote == main_head == CODE
raw = HERE/'preview_capture_raw.json'
if not raw.exists():
    raw.write_bytes(capture_path.read_bytes())
capture['report_ready'] = True
capture_path.write_bytes((json.dumps(capture,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
proof = {
    'schema':'sternenbuergerchen.main_graphics_adoption.v1',
    'code_commit':CODE,'main_integrated':True,'origin_main_verified':remote,
    'engine_checks_passed':29,'engine_checks_selected':29,
    'native_start_passed':45,'headless_start_passed':33,'native_captures':27,
    'local_checks':'29/29 aktuelle strenge Gates; echter Normalstart 33/33 headless und 45/45 nativ; Ref03-Modellgate 86/86. Die historischen R02-20k- und P06-alle-Assets-unverändert-Prüfungen sind ausdrücklich durch neue versionierte Adoptionsgates ersetzt. Alte Quellen/Diagnosen bleiben erhalten.',
    'git_status':'Code '+CODE+' auf Main und origin/main bestätigt. Der abschließende Reportcommit ergänzt nur Dokumentation und Browserbelege.',
    'material_route':'Ref03-GLBs und Originalmaterialien bytegleich übernommen; Umgebung/Kameras/Licht aus P07 erhalten.',
    'scope':'Neue Startgrafik, gespeichertes Frontier-Theme auf GM01 und echter Cutlass-Anflug. GM01 bleibt square8; Hex-Werft gesondert. Buccaneer ist aktives statisches Modell, kein neuer Fighter-Spielpfad. Keine allgemeine Kampagnen-, Performance- oder gestalterische Abnahme.',
    'full_editor_import_clean':False,
    'editor_import_limits':'Normale Projektimporte: Exit0 mit bestehenden Asset-Placer-UID-Warnungen und Plugin-Shutdown-Leak. Recovery-Mode-Diagnose verworfen: deaktiviert Terrain3D-Typen. Isolierter frischer Import identischer aktiver GLBs/PNG ist fehler-/leakfrei; reale Runtime-Gates oben separat.',
    'native_os_exit_code_collected':False,
    'native_exit_evidence':'Native45/0 JSON, Erfolgsmarker, beendeter Prozess und Runtimefehler-freies Log; externer OS-Exitcode wurde vom nativen Wrapper nicht gesondert erfasst.',
    'evidence':[record(p) for p in [checks_path,native_path,headless_path,package_path,HERE/'native_visual_review.json',HERE/'fresh_asset_import/import.log']],
    'source_records':source_records,
    'capture_records':[dict(record(local(row['path'])),id=row['id'],kind=kind) for kind,rows in [('fixture',capture['captures']),('real_normal_start',native['captures'])] for row in rows],
    'menu_image':record(local(menu['image'])),
    'known_legacy_limits':'TASK158/159 bleiben mit13/6 alten Fehlern dokumentiert; ihr früherer isolierter Baselinevergleich bleibt historisch, hier keine neue Vollsuite/Releasefreigabe.'
}
(HERE/'verification_manifest.json').write_bytes((json.dumps(proof,ensure_ascii=False,indent=2)+'\n').encode('utf-8'))
print('Pinned',len(source_records),'Git source blobs; 29/29 gates, 45/45 native, 33/33 headless; Main and origin verified.')

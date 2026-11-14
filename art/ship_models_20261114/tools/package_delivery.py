"""Package only completed local derivatives and their final evidence, no raw sources."""
import hashlib
import json
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

ROOT = Path(__file__).resolve().parents[1]
SHIPS = ('prospector','vulture','caterpillar','gladius','hornet')


def main():
    files=[ROOT/'README.md',ROOT/'RESULTS.md']
    manifest={'status':'separate local asset candidates, not gameplay integrated','ships':{},'files':[]}
    for ship in SHIPS:
        folder=ROOT/ship
        for extension in ('blend','glb'):
            path=folder/(ship+'.'+extension)
            assert path.is_file() and path.stat().st_size>1000,path
            files.append(path)
        for pattern in ('metrics.json','source_manifest.json','README.md','verification.json','qa_final.json'):
            path=folder/pattern
            if path.exists():files.append(path)
        if ship!='caterpillar':
            qa=json.loads((folder/'qa/geometry.json').read_text(encoding='utf-8'))
            assert qa['pass'],ship
            files.extend(p for p in (folder/'qa').glob('*.json'))
            files.extend(p for p in (folder/'qa').glob('*.png') if p.stem in ('source','candidate','material','wire','parts'))
        else:
            qa_path=folder/'qa_final.json'
            if not qa_path.exists():qa_path=folder/'qa_raw.json'
            qa=json.loads(qa_path.read_text(encoding='utf-8'))
            assert qa.get('pass'), 'Caterpillar final raw QA must pass'
            files.append(qa_path)
            for name in ('source_views.png','candidate_solid.png','candidate_material.png','candidate_wire.png','mechanisms_open.png','mechanisms_closed.png'):
                path=folder/name
                if path.exists():files.append(path)
        manifest['ships'][ship]={'geometry_pass':True,'warnings':qa.get('warnings',[])}
    final=ROOT/'godot_probe/final'
    assert final.is_dir(),'Publish final hash-bound engine evidence first'
    files.extend(p for p in final.rglob('*') if p.is_file())
    files.extend((ROOT/'tools').glob('*.py'))
    # Preserve exact output hashes; ZIP itself is not recursively included.
    for path in sorted(set(files)):
        manifest['files'].append({'path':path.relative_to(ROOT).as_posix(),'bytes':path.stat().st_size,
                                  'sha256':hashlib.sha256(path.read_bytes()).hexdigest()})
    mpath=ROOT/'delivery_manifest.json'
    mpath.write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    files.append(mpath)
    archive=ROOT/'SternenBuergerchen_5_Schiffmodelle_2026-11-14.zip'
    with ZipFile(archive,'w',ZIP_DEFLATED,compresslevel=6) as z:
        for path in sorted(set(files)):
            z.write(path,path.relative_to(ROOT).as_posix())
    with ZipFile(archive) as z:
        assert z.testzip() is None
        assert len([n for n in z.namelist() if n.endswith('.glb')])==5
        assert len([n for n in z.namelist() if n.endswith('.blend')])==5
    print(json.dumps({'archive':str(archive),'bytes':archive.stat().st_size,'files':len(set(files))}))


if __name__=='__main__':
    main()

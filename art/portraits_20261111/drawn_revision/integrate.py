"""Integrate the generated drawn atlas without changing character identities."""
from pathlib import Path
import hashlib
import json
import shutil
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parents[3]
PACK = Path(__file__).resolve().parent
source = Path(sys.argv[1])
target = ROOT / 'Assets/curated/portraits/frontier_20261105/sheets/crew_l_drawn_20261111.png'
shutil.copy2(source, target)
shutil.copy2(source, PACK / 'original_atlas.png')
size = Image.open(target).size
assert size[0] == size[1] and size[0] % 2 == 0, size
cell = size[0] // 2
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
reference = ROOT / 'Assets/curated/portraits/frontier_20261105/sheets/crew_a.png'
shutil.copy2(reference, PACK / 'style_reference.png')
catalog_path = ROOT / 'data/portrait_identity_catalog.json'
catalog = json.loads(catalog_path.read_text(encoding='utf-8'))
old_manifest = json.loads((PACK/'manifest.json').read_text(encoding='utf-8')) if (PACK/'manifest.json').exists() else {}
previous_entries = {r['id']: r['previous_entry'] for r in old_manifest.get('records', [])}
records = []
for number in range(45, 49):
    id = f'char_portrait_{number:03d}'
    entry = next(e for e in catalog['entries'] if e['id'] == id)
    previous = previous_entries.get(id, dict(entry))
    region = [((number-45) % 2)*cell, ((number-45)//2)*cell, cell, cell]
    resource = ROOT / entry['path'].removeprefix('res://')
    resource.write_text('[gd_resource type="AtlasTexture" load_steps=2 format=3]\n\n'
                        '[ext_resource type="Texture2D" path="res://' + target.relative_to(ROOT).as_posix() + '" id="1"]\n\n'
                        '[resource]\natlas = ExtResource("1")\nregion = Rect2(' + ', '.join(map(str,region)) + ')\nfilter_clip = true\n', encoding='utf-8')
    entry.update(width=cell, height=cell, bytes=resource.stat().st_size,
                 sheet_path='res://' + target.relative_to(ROOT).as_posix(), sheet_sha256=sha(target),
                 region=region, tags=['frontier', 'drawn_revision_20261111'],
                 presentation_source={'prompt_path':'res://art/portraits_20261111/drawn_revision/prompt.txt',
                                      'authored_group':entry['presentation_group'],
                                      'policy':'authored_synthetic_character_intent'})
    records.append({'id':id, 'previous_entry':previous, 'active_entry':entry})
catalog_path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
manifest = {'date':'2026-11-11', 'tool':'image_gen.imagegen', 'status':'drawn revision integrated; user judgment pending',
            'request':'Neue fotografisch wirkende Porträts zurück zur gezeichneten Bildsprache.',
            'original_tool_output':str(source), 'original_size':list(size), 'atlas_sha256':sha(target),
            'reference_path':'res://' + reference.relative_to(ROOT).as_posix(), 'reference_sha256':sha(reference),
            'prompt_file':'prompt.txt', 'prompt_sha256':sha(PACK/'prompt.txt'),
            'processing':'Original atlas copied without raster editing; four equal native AtlasTexture regions.',
            'records':records}
(PACK/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Integrated four drawn portraits, quadrant',cell,'x',cell)

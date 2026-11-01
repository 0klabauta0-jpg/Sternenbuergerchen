"""Hash the shipped task utilities and their unmodified external QA dependency."""
from pathlib import Path
import hashlib,json
HERE=Path(__file__).resolve().parent
def row(p):return {'path':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
scripts=sorted(HERE.glob('*.py'))+sorted(HERE.glob('README*.md'))
dependency=Path(r'C:/Users/bjoer/.codex/skills/blender-asset-qa')
doc={'schema':'sternenbuergerchen.ship_qa_tools.v1','tool_files':[row(p) for p in scripts],
     'external_dependencies':[row(dependency/'scripts/qa_check.py'),row(dependency/'scripts/_bpyx.py')],
     'external_license':'blender-asset-qa SKILL.md declares MIT; external scripts unmodified',
     'runtime':'Blender 5.2.3 LTS / bundled Python and numpy; Pillow only for deliberate test-image corruption',
     'scope':'Standalone source/GLB geometry-material-texture audit and matched Blender renders; not native Godot or user acceptance'}
(HERE/'tool_manifest.json').write_text(json.dumps(doc,indent=2),encoding='utf8')
print('Wrote',HERE/'tool_manifest.json')

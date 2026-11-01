"""Portable dependency adapter; preserves the frozen Astra tool bytes.
Blender: -P this.py -- --tool repo/relative/script.py [-- tool arguments...]
"""
from pathlib import Path
import runpy,sys
HERE=Path(__file__).resolve().parent
ROOT=next(p for p in HERE.parents if (p/'project.godot').is_file())
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
if len(args)<2 or args[0]!='--tool':
    raise SystemExit('Expected -- --tool repo/relative/tool.py [-- tool args]')
tool=(ROOT/args[1]).resolve()
if not tool.is_relative_to(ROOT) or not tool.is_file():
    raise SystemExit('Tool must be an existing file inside this repository')
sys.path.insert(0,str(HERE/'vendor/blender_asset_qa'))
sys.argv=[str(tool)]+args[2:]
runpy.run_path(str(tool),run_name='__main__')

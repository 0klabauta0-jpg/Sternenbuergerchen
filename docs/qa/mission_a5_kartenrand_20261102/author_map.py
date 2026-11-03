"""Run the existing offline map author after import, in task-only user data."""
import hashlib
import json
import subprocess
from _qa_common import ROOT, isolated_profile, new_run_dir, error_lines, write_json

scenario = ROOT / 'data/mission_scenarios/ground_mission01_default.json'
original_scenario = scenario.read_bytes()
backup = ROOT / 'docs/qa/mission_a5_kartenrand_20261102/before/Ground_Mission01_48x48.json'
assert hashlib.sha256(backup.read_bytes()).hexdigest() == '31daf2d4943ec4a2007fc4f5246249f309c52436a0675143184d060b6999c925'
run = new_run_dir('authoring')
command = ['godot_console', '--headless', '--path', str(ROOT), '--script', 'res://scripts/tools/build_gm01_frontier.gd']
with isolated_profile('SternenBuergerchen_Mission_A5_Edge_Authoring_QA') as profile:
    process = subprocess.run(command, cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=180)
(run / 'authoring.log').write_bytes(process.stdout)
assert scenario.read_bytes() == original_scenario, 'Scenario bytes changed'
errors = error_lines(process.stdout.decode('utf-8', errors='replace'))
assert process.returncode == 0 and not errors, f'Map authoring failed: {run}'
path = ROOT / 'maps/Ground_Mission01_32x32.json'
data = json.loads(path.read_text(encoding='utf-8'))
result = {**profile, 'passed': True, 'exit_code': process.returncode, 'error_count': len(errors), 'command': command,
          'map_sha256': hashlib.sha256(path.read_bytes()).hexdigest(), 'grid_size': data['grid_size'], 'tile_count': len(data['tiles']),
          'solid_cells': sum(t.get('object_type_id') == 'frontier_scene_solid' for t in data['tiles']),
          'walkable_cover_cells': sum(t.get('walkable', False) and t.get('cover_value', 0) > 0 for t in data['tiles']),
          'scenario_byte_exact': True, 'scenario_sha256': hashlib.sha256(original_scenario).hexdigest()}
write_json(run / 'authoring.json', result)
print(json.dumps(result, indent=2))

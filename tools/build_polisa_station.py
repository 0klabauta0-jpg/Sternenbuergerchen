"""Rebuild Polisa R08 at home-pad scale; preserve production scene IDs."""
from pathlib import Path
import json
import runpy
ROOT = Path(__file__).resolve().parents[1]

def main():
    package = ROOT / 'art/polisa_r08_20261111'
    runpy.run_path(str(package / 'build_candidate.py'), run_name='__main__')
    candidate = ROOT / 'output/native_glut_maps/polisa_r08_20261111/polisa_station_candidate.json'
    data = json.loads(candidate.read_text(encoding='utf-8'))
    layout = json.loads((package / 'layout.json').read_text(encoding='utf-8'))
    camera = layout['standard_camera']
    x, z = [layout['origin_plane'][i] + camera['focus_local'][i] for i in range(2)]
    data['markers']['station_camera_focus'] = {'x': (x-z)*64, 'y': (x+z)*32, 'marker_type_id': 'objective_point', 'name': 'Stationsübersicht', 'placement_context': 'editor_only', 'symbol': 'circle'}
    data['place_presentation']['station_initial_camera'] = {'focus_marker': 'station_camera_focus', 'yaw_degrees': camera['yaw'], 'pitch_degrees': camera['pitch'], 'size': camera['size']}
    data['place_presentation']['space_bounds_plane'] = layout['space_bounds']
    data['map_name'] = 'Polisa / Freie Raumstation'
    data['place_presentation']['props'][0]['path'] = 'res://scenes/terrain/polisa_station_visual.tscn'
    (ROOT / 'maps/polisa_station.json').write_text(json.dumps(data, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')

if __name__ == '__main__':
    main()

"""Read-only pixel counts for the central front-road shadow strip."""
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parent
report = json.loads((root / 'pass07_shadow_report.json').read_text())
box = (430, 650, 1015, 683)
baseline = Image.open(root / 'pass07_shadow_baseline.png').convert('RGB')
base_pixels = list(baseline.crop(box).get_flattened_data())
rows = []
for capture in report['captures']:
    image = Image.open(root / Path(capture['path']).name).convert('RGB')
    pixels = list(image.crop(box).get_flattened_data())
    dark = sum(max(pixel) < 90 for pixel in pixels)
    changed = sum(max(abs(a-b) for a, b in zip(pixel, base)) > 12 for pixel, base in zip(pixels, base_pixels))
    rows.append({'id': capture['id'], 'dark_pixels_max_channel_under_90': dark, 'pixels_changed_over_12': changed})
result = {'diagnostic_only': True, 'roi_xyxy': box, 'measure': 'Darkness count is limited to the visually identified central lower road edge; not a generic acceptance metric.', 'variants': rows}
(root / 'pass07_shadow_pixels.json').write_text(json.dumps(result, indent=2))
print(json.dumps(result, indent=2))

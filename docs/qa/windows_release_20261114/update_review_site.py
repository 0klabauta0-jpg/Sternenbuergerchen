"""Copy the bounded delivery section into the existing private Site checkout."""
from pathlib import Path
import argparse, shutil

parser = argparse.ArgumentParser()
parser.add_argument('checkout', type=Path)
args = parser.parse_args()
root = Path(__file__).resolve().parents[3]
source = (root / 'docs/reports/SPIELREVIEW_2026_11_12.html').read_bytes().decode('utf8')
target = args.checkout / 'dist/index.html'
existing = target.read_bytes().decode('utf8')
start, end = '<!-- delivery-20261114:start -->', '<!-- delivery-20261114:end -->'
fragment = source[source.index(start):source.index(end) + len(end)]
fragment = fragment.replace('assets/map-services-20261114/', 'evidence/map-services-20261114/')
if start in existing:
    existing = existing[:existing.index(start)] + fragment + existing[existing.index(end) + len(end):]
else:
    anchor = '<section id="overview" class="tab-panel active">'
    assert existing.count(anchor) == 1
    existing = existing.replace(anchor, anchor + fragment, 1)
header = source[source.index('<header>'):source.index('</header>') + len('</header>')]
existing = existing[:existing.index('<header>')] + header + existing[existing.index('</header>') + len('</header>'):]
target.write_bytes(existing.encode('utf8'))
dest = args.checkout / 'dist/evidence/map-services-20261114'
dest.mkdir(parents=True, exist_ok=True)
for path in (root / 'docs/reports/assets/map-services-20261114').iterdir():
    if path.suffix in ('.png', '.json'):
        shutil.copyfile(path, dest / path.name)
print('Updated delivery section and revision images; historical Site evidence preserved.')

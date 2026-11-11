"""Derived plan from the exact compiled layout facts, no second authoring state."""
import json
from pathlib import Path
A=Path(__file__).resolve().parent
L=json.loads((A/'layout.json').read_text(encoding='utf-8'))
svg=['<svg xmlns="http://www.w3.org/2000/svg" width="1600" height="800" viewBox="-260 -60 520 260"><rect x="-260" y="-60" width="520" height="260" fill="#08141d"/>']
for key,color in [('blocked_zones','#253a45'),('decks','#52656b'),('rooms','#83918e'),('technical_modules','#4f6169'),('walls','#d4ddd8'),('furniture','#d4ac4f')]:
 for p in L[key]:
  r=p['rect'];svg.append(f'<rect x="{r[0]}" y="{r[1]}" width="{r[2]-r[0]}" height="{r[3]-r[1]}" fill="{color}" stroke="#a3bbc2" stroke-width=".3"/>')
for p in L['pads']:
 x,z=p['center'];w,d=p['size'];svg.append(f'<rect x="{x-w/2}" y="{z-d/2}" width="{w}" height="{d}" fill="#475960" stroke="#d4ac4f"/><text x="{x}" y="{z}" fill="#f5dfaa" text-anchor="middle" font-size="6">{p["number"]} / {p["class"]}</text>')
for x in L['engineering']['ring_x']:svg.append(f'<path d="M{x} -10V102" stroke="#c9cfc8" stroke-width="4.8"/>')
for port in L['engineering']['outer_ports']:
 r=port['approach_rect'];svg.append(f'<rect x="{r[0]}" y="{r[1]}" width="{r[2]-r[0]}" height="{r[3]-r[1]}" fill="none" stroke="#70c7c5" stroke-dasharray="3 3"/>')
svg.append('<text x="0" y="-50" fill="white" font-size="6" text-anchor="middle">POLISA R06 — DERIVED AUTHORING PLAN, NOT A NATIVE CAPTURE</text></svg>')
(A/'layout_final.svg').write_text(''.join(svg),encoding='utf-8')

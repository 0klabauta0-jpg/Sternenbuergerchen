from PIL import Image
import os

base = r"C:\dev\SternenBuergerchen\Assets\kenney_space-kit\Isometric"

# The diamond in Kenney sprites is always 128x64 pixels.
# It is the flat top surface - a rhombus shape.
# Top point, right point, bottom point, left point.
# I need to find these 4 points for each sprite.

# Strategy: The diamond top is the topmost opaque pixel of the DIAMOND SHAPE.
# But cliff sprites have cliff geometry too. The diamond is the flat top.
# The diamond s top point is a single pixel or very narrow row at the top of the diamond.

# For each sprite, let me find:
# 1. The topmost row that has a narrow (1-4 pixel) opaque horizontal extent
#    This would be the top point of the diamond
# 2. Then the diamond center is 32px below and at the same x as the top point

files = [
    "terrain_SW.png",
    "terrain_sideCliff_SE.png",
    "terrain_sideCliff_SW.png",
    "terrain_sideCliff_NE.png",
    "terrain_sideCliff_NW.png",
    "terrain_sideCorner_SE.png",
    "terrain_sideCorner_SW.png",
    "terrain_sideCorner_NE.png",
    "terrain_sideCorner_NW.png",
]

for f in files:
    path = os.path.join(base, f)
    if not os.path.exists(path):
        print(f"{f}: FILE NOT FOUND")
        continue
    img = Image.open(path).convert("RGBA")
    px = img.load()
    
    # Find all rows with opaque pixels and their horizontal extent
    rows = []
    width_img, height_img = img.size
    for y in range(height_img):
        xs = [x for x in range(width_img) if px[x, y][3] > 10]
        if xs:
            width = max(xs) - min(xs) + 1
            center = (min(xs) + max(xs)) // 2
            rows.append((y, width, center, min(xs), max(xs), len(xs)))
    
    # The diamond has a distinctive pattern:
    # - Starts very narrow at top (1-2px)
    # - Grows by ~4px per row (2px each side) to 128px wide
    # - Then shrinks back
    # Find the widest row (should be at diamond center-y)
    
    if not rows:
        print(f"{f}: NO OPAQUE PIXELS")
        continue
    
    # Find the topmost narrow row (potential diamond top)
    # Diamond top should be 1-4px wide
    diamond_top_y = None
    diamond_top_x = None
    for (y, w, center, minx, maxx, count) in rows:
        if w <= 6:  # Very narrow - likely diamond tip
            diamond_top_y = y
            diamond_top_x = center
            break
    
    # Also find widest row
    widest = max(rows, key=lambda r: r[1])
    
    # Diamond center estimate
    if diamond_top_y is not None:
        dc_y = diamond_top_y + 32  # half of 64px diamond height
        dc_x = diamond_top_x
        print(f"{f}: diamond_top=({diamond_top_x},{diamond_top_y}), diamond_center=({dc_x},{dc_y}), widest_row=y={widest[0]} w={widest[1]}")
    else:
        # No narrow top found - try different approach
        # Find topmost row
        first = rows[0]
        print(f"{f}: NO NARROW TOP, first_row=(y={first[0]}, w={first[1]}, center={first[2]}), widest=y={widest[0]} w={widest[1]}")

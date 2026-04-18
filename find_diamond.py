from PIL import Image
import os

base = r"C:\dev\SternenBuergerchen\Assets\kenney_space-kit\Isometric"

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
        print(f"File not found: {path}")
        continue
    img = Image.open(path).convert("RGBA")
    pixels = img.load()
    w, h = img.size
    
    # Find bounding box of non-transparent pixels
    min_x, min_y, max_x, max_y = w, h, 0, 0
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 10:  # alpha > 10
                min_x = min(min_x, x)
                min_y = min(min_y, y)
                max_x = max(max_x, x)
                max_y = max(max_y, y)
    
    # Find the topmost non-transparent pixel (top of diamond)
    top_pixel_x = 0
    top_y = 0
    found = False
    for y in range(h):
        for x in range(w):
            if pixels[x, y][3] > 10:
                top_pixel_x = x
                top_y = y
                found = True
                break
        if found:
            break
    
    print(f"{f}: size={w}x{h}, bbox=({min_x},{min_y})-({max_x},{max_y}), top_pixel=({top_pixel_x},{top_y})")

"""Plot actual candidate data as annotated authoring diagrams, not game captures."""
import json
from pathlib import Path
import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.colors import ListedColormap, LightSource

ROOT=Path(__file__).resolve().parents[2]
OUT=ROOT/"output/native_glut_maps/explicit_ramps_candidate"
ART=Path(__file__).resolve().parent
names={"A":"satellite_crash_site","B":"trade_outpost","C":"fortified_outpost"}
palette=ListedColormap(["#9c5b3d","#b66b42","#c88150","#cc8858","#d99b68",
                       "#e2a774","#e7b27e","#edbf8a","#f5d49e"])
for zone,name in names.items():
    data=json.loads((OUT/(name+".json")).read_text(encoding="utf8"))
    heights=np.zeros((256,512))
    ramps=[];objects=[];blocked=[]
    for tile in data["tiles"]:
        q,r=tile["grid_position"]["x"],tile["grid_position"]["y"]
        x=int(q+r//2+170);y=int(r+108)
        heights[y,x]=tile["height_level"]+(0.5 if tile["ramp_direction"]>=0 else 0)
        if tile["ramp_direction"]>=0:ramps.append((q+r*.5,r))
        if tile.get("object_type_id") not in (None,"","glut_sandstone_04","spacekit_rock_large_a"):objects.append((q+r*.5,r))
        if not tile.get("walkable",True) and not tile.get("object_type_id"):blocked.append((q+r*.5,r))
    fig,ax=plt.subplots(figsize=(18,9),facecolor="#171c20")
    ax.set_facecolor("#171c20")
    shade=LightSource(azdeg=315,altdeg=44).shade(heights,cmap=palette,vert_exag=2.0,blend_mode="soft",vmin=0,vmax=8)
    ax.imshow(shade,origin="lower",extent=(-170,342,-108,148),interpolation="nearest",aspect="equal")
    ax.contour(heights,levels=[.5,1.5,3.5,5.5,7.5],colors="#502e23",linewidths=.28,
               extent=(-170,342,-108,148),origin="lower",alpha=.55)
    for points,color,size in ((blocked,"#172328",1),(objects,"#8af8e0",5),(ramps,"#fff0a1",7)):
        if points:ax.scatter(*zip(*points),s=size,c=color,linewidths=0)
    report=json.loads((OUT/f"{zone}_authoring_check.json").read_text())
    for stair in report["stairs"]:
        q,r=stair["start_axial"];x=q+r*.5
        ax.annotate(stair["id"].replace("_"," "),(x,r),xytext=(7,9),textcoords="offset points",
                    fontsize=8,color="#ffffff",bbox=dict(boxstyle="round,pad=.25",fc="#16282c",alpha=.8,ec="none"))
    ax.set_title(f"GLUT {zone}  |  512 x 256  |  H0–H8  |  explicit whole-hex ramps",color="white",loc="left",pad=16,fontsize=16)
    ax.set_xlabel("Actual candidate data · contour diagram · not a Godot capture · gold: ramps · mint: persistent footprints",color="#c7d7d9",labelpad=13)
    ax.tick_params(colors="#9fadb0",labelsize=9)
    for edge in ax.spines.values():edge.set_color("#4a565a")
    fig.tight_layout()
    fig.savefig(ART/f"{zone}_composition_data.png",dpi=120,facecolor=fig.get_facecolor())
    plt.close(fig)

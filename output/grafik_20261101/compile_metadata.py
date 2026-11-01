"""Rebuild provenance and hashes for the graphics reference package. No image edits."""
import json, hashlib, subprocess
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
PACKAGE=ROOT/"output/grafik_20261101"
def sha(p):
    return hashlib.sha256(Path(p).read_bytes()).hexdigest()
style=Path("C:/dev/InselKrieg/game/docs/art/referenzen/Illustrationsserie_20261029/01_sichelbucht.png")
pics=Path("C:/Users/bjoer/Pictures/StarCitizen - Screenshots/LIVE/4.6.0-live.11377160")
sources=[
("insel_style",style,"Freigegebene InselKrieg-2D-Stilreferenz; keine SternenBuergerchen-Integration"),
("sc_ground",pics/"ScreenShot-2026-03-08_16-00-35-254.jpg","Nutzerscreenshot: Boden/Klippen, keine Schiff-Formvorlage"),
("sc_landscape",pics/"ScreenShot-2025-09-15_21-57-40-AD5.jpg","Nutzerscreenshot: Landschaft und Himmel"),
("sc_industry",pics/"ScreenShot-2026-01-19_20-55-35-867.jpg","Nutzerscreenshot: Industriekonstruktion und Arbeitsflaechen"),
("sc_people",pics/"ScreenShot-2026-02-15_20-07-35-C11.jpg","Nutzerscreenshot: Raumanzuege/Helme/Rucksaecke"),
("sc_armor",pics/"Squadron_42_-_Star_Citizen_Screenshot_2025.01.10_-_20.41.59.11.png","Nutzerscreenshot: Ruestung und Oberflaechen"),
("sc_sky",pics/"ScreenShot-2025-11-04_21-28-50-B29.jpg","Nutzerscreenshot: Himmel/Licht; abgebildetes Schiff ist keine Cutlass/Buccaneer")]
source_entries=[dict(id=i,path=str(p),sha256=sha(p),role=r) for i,p,r in sources]
model_dir=Path("C:/Users/bjoer/3D Objects/drive-download-20250521T120706Z-1-001/DRAKE")
for name in ("CUTLASS","BUCCANEER"):
    p=model_dir/("DRAKE-"+name+".obj")
    source_entries.append(dict(id=name.lower()+"_obj",path=str(p),sha256=sha(p),role="Unveraenderte lokale Geometrie-Referenz; kein integriertes Spielmodell"))
gen=json.loads((PACKAGE/"generation_manifest.json").read_text(encoding="utf-8-sig"))
revisions=json.loads((PACKAGE/"generation_revisions.json").read_text(encoding="utf-8-sig"))
existing={item["id"] for item in gen["targets"]}
gen["targets"].extend(item for item in revisions["additional_targets"] if item["id"] not in existing)
gen["latest_ship_targets"]=revisions["latest_ship_targets"]
gen["final_consistency_note"]=revisions["final_consistency_note"]
for item in gen["targets"]:
    if item["id"]=="buccaneer_front_v2": item["status"]="superseded_equipment_simplification_preserved"
for item in gen["targets"]:
    p=ROOT/item["project_file"]
    item["sha256"]=sha(p)
    item["bytes"]=p.stat().st_size
(PACKAGE/"generation_manifest.json").write_text(json.dumps(gen,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
mapping=json.loads((ROOT/"data/terrain_3d_asset_mapping.json").read_text(encoding="utf-8-sig"))
paths=[v["model_path"] for v in mapping["models"].values() if "model_path" in v]
scope=[
dict(id="terrain",actual="Natives schaltbares Grafikprofil, gebatchte Hexfelder, Hintergrundgeologie und Basis-Preview",runtime_changed=True,mesh_changed=True),
dict(id="structures",actual="Drei neue editierbare Habitat-/Werkstatt-/Versorgungsmodelle, GLB und native Godot-Ansichten",runtime_changed=True,mesh_changed=True,qa_pass=True),
dict(id="people",actual="Letzte Nutzerwahl: originale Kenney-Astronauten, vier Originalskins, unveraenderte Geometrie/Proportionen mit einheitlicher Skalierung und Originalanimationen; eigene Figuren verworfen",runtime_changed=True,mesh_changed=False,qa_pass=True),
dict(id="cutlass",actual="Zwei vereinfachte Wimmelbild-2D-Ansichten und isolierte native Materialprobe",runtime_changed=False,mesh_changed=False,qa_pass=False),
dict(id="buccaneer",actual="Zwei vereinfachte Wimmelbild-2D-Ansichten und isolierte native Materialprobe",runtime_changed=False,mesh_changed=False,qa_pass=False),
dict(id="rules",actual="Grafikvertrag und zwei verlinkte Arbeitsregeln",runtime_changed=False),
dict(id="hex",actual="Versionierte Hexkoordinaten, A*/HPA, Registry, Bewegungsmass, LOS/FoW, native Auswahl und Picking; Legacy square8 kompatibel",runtime_changed=True)]
manifest=dict(schema="sternenbuergerchen.graphics_reference_package.v1",date="2026-11-01",
base_commit="3cae5a216d380b58fef92724540e95fbc49bde7e",branch="task/grafikreferenzen-20261101",
runtime_unchanged=False,generated_target_count=len(gen["targets"]),latest_ship_target_count=4,
approved_2d_references=["01_rostwelt_landschaft.png","03_aussenposten_stilstudie.png","02_menschen_stilstudie.png"],
latest_citizen_choice="Original Kenney astronauts are the provisional base; rejected custom figures stay outside runtime. Future armor, equipment and appearance changes are explicitly requested.",
engine_capture="output/grafik_20261101/frontier_engine_capture.json",
hex_contract="docs/dev/hex_grid_v1_contract.md",
scope=scope,source_images_and_models=source_entries,
active_mapping=dict(model_entries=len(paths),unique_model_paths=len(set(paths)),ship_identity="Kenney craft_speederB; Cutlass/Buccaneer nicht im Integrationsmapping"),
official_ship_shape_sources=[
dict(title="CIG Cutlass Black 2017 Galerie",url="https://robertsspaceindustries.com/en/promotions/promocutlassblack2017",
image_url="https://robertsspaceindustries.com/media/m3vgrlxyx9978r/source/Drake_Cutlass_Black_WhiteRoom.jpg"),
dict(title="CIG Drake Lineup 2017 / Buccaneer",url="https://robertsspaceindustries.com/en/comm-link/transmission/15805-Drake-Sale-The-2947-Lineup",
image_url="https://robertsspaceindustries.com/media/wlj2pveux0yjqr/source/Buccaneer_Action_01.png")],
generation_manifest="output/grafik_20261101/generation_manifest.json",
native_study_index="output/grafik_20261101/model_studies/study_index.json",
limitations=["Erster nativer synthetischer Hex-Basis-Ausschnitt; keine vollstaendige Kampagnen- oder Altinhaltsmigration.",
"Eigene Citizen-Koerper sind verworfen; native Figuren behalten auf Nutzerwunsch die originalen Kenney-Proportionen und Skins.",
"Hex-Editor-Neukartenpfad, Altinhaltskonvertierung, sechsfaches Wandsegment-Authoring und weitere Combat-Verbraucher bleiben Migrationsarbeit.",
"Native Schiffe sind Materialstudien auf unveraenderter hochaufloesender Geometrie.",
"Source-Mesh-QA und native visuelle Runtime-Abnahme fuer beide Schiffe fehlgeschlagen.",
"Neu verlangte Detailreduktion ist in den vier 2D-Zielen umgesetzt; 3D-Vereinfachung steht aus.",
"Keine generelle Gameplay-, Grosskarten-Performance-, Multiplayer- oder Release-Abnahme."])
(PACKAGE/"asset_source_manifest.json").write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
print(json.dumps(dict(targets=len(gen["targets"]),sources=len(source_entries),scope=len(scope),mapping_entries=len(paths),unique_models=len(set(paths)))))

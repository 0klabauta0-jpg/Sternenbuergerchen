"""Record the bounded Godot-only exterior revision after opening native images."""
from pathlib import Path
import hashlib,json,re,subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[4]
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return str(Path(p).relative_to(ROOT)).replace('\\','/')
def read(p):return json.loads(Path(p).read_text(encoding='utf-8-sig'))
def main():
    builder=ROOT/'scripts/terrain/frontier_closed_buildings.gd'
    before=HERE/'source/frontier_closed_buildings_before.gd'
    after=HERE/'source/frontier_closed_buildings_pass05.gd'
    qa=read(HERE/'qa/geometry_raw.json')
    assert qa['failed']==0 and qa['passed']==21 and len(qa['diagnostics'])==2
    assert sha(builder)==sha(after)==qa['builder_sha256']
    regression=(HERE/'qa/pass04_regression.log').read_text(encoding='utf-8-sig')
    reg=json.loads(re.search(r'FRONTIER_PASS04 (\{[^\n]+\})',regression).group(1))
    assert reg['failed']==0 and reg['passed']==22
    for name in ['geometry_check.log','native_probe.log','pass04_regression.log','native_probe.err']:
        text=(HERE/'qa'/name).read_text(encoding='utf-8-sig')
        assert not re.search(r'SCRIPT ERROR|\bERROR:|Parse Error|leaked at exit',text),name
    assert subprocess.run(['git','diff','--quiet','--','scripts/terrain/frontier_art_profile.gd'],cwd=ROOT).returncode==0
    views=read(HERE/'qa/native_views.json')
    assert len(views)==10
    for key in [(v['building'],v['view']) for v in views if v['revision']=='after']:
        pair=[v for v in views if (v['building'],v['view'])==key]
        assert len(pair)==2 and pair[0]['camera']==pair[1]['camera'] and pair[0]['size']==pair[1]['size'] and pair[0]['resolution']==pair[1]['resolution']
    for view in views:
        path=ROOT/view['path'].removeprefix('res://');view.update({'path':rel(path),'sha256':sha(path),'opened':True})
    refroot=ROOT/'docs/reports/assets/grafik-2026-11-01'
    references=[{'path':rel(refroot/p),'sha256':sha(refroot/p),'role':'generated style/form target'} for p in ['references/current/01_rostgrenze_cutaway.png','references/current/02_freihafen_distribution_center.png']]
    previous=[{'path':rel(refroot/p),'sha256':sha(refroot/p),'role':'archived native P4 closed view, opened before modeling'} for p in ['engine_pass05_environment/before/closed_habitat.png','engine_pass05_environment/before/closed_hall.png','engine_pass05_environment/before/closed_outpost.png']]
    originals=[]
    for name in ['habitat_cutaway_01.glb','freihafen_hall_01.glb']:
        path=ROOT/'Assets/curated/frontier_illustrated_20261101/structures_pass04'/name
        originals.append({'path':rel(path),'sha256':sha(path),'role':'existing Kenney-based cutaway asset, not edited/re-exported by this task'})
    manifest={'schema':'sternenbuergerchen.pass05_closed_buildings.v1','task':'docs/tasks/ART_2026_11_01_pass05_environment.md','status':'bounded native geometry candidate; no user artistic acceptance claimed','source':{'runtime_path':rel(builder),'sha256':sha(builder),'before_path':rel(before),'before_sha256':sha(before),'editable_snapshot':rel(after),'snapshot_sha256':sha(after),'generator_api':'build(bounds:AABB,hall:bool); once-only Godot geometry, no Blender/GLB conversion'},'assets':qa['diagnostics'],'references':references,'opened_previous_native_views':previous,'unchanged_cutaway_assets':originals,'implemented':{'habitat':'Three varied chamfered petrol roof masses, lower service channel and compact life-support unit; deep cast portal with supported hood, warm insets; broad recessed facade bays and grounded dark plinth.','hall':'Actual asymmetric high industrial bay/lower office profile, heavy portal and dark segmented shutter; raised longitudinal roof monitor and supported exhaust manifold; structural facade ribs and office window.','shared':'Finite closed clockwise mesh geometry with physical chamfers, restrained broad panel repair colors, shared local material cache; all shell geometry under one visibility root.'},'interface':{'closed_cutaway':'existing parent visibility toggle, no state/door/interior behavior added','stable_node_names':['DoorFrame','FrontWindowFrame'],'navigation':'unchanged original footprints/reservations; all mesh and sign AABBs fit original XZ+0.22m, height<=original+0.20m','new_collision_navigation_light_nodes':False,'environment_and_directional_light':'unchanged FrontierArtProfile; warm accents are only framed emissive material surfaces','front_godot':'+Z','source_units':'existing fixture world units at underlying structure scale0.35'},'qa':{'geometry_raw':rel(HERE/'qa/geometry_raw.json'),'geometry_checks':{'passed':qa['passed'],'failed':qa['failed']},'legacy_regression':{'script':'scripts/tests/frontier_pass04_verifier.gd','passed':22,'failed':0,'log':rel(HERE/'qa/pass04_regression.log')},'scope':qa['scope'],'ground':'minimum visual Y0.0; supported overlapping assembly parts are intentional','limitations':'AABB assembly connectivity is conservative, not an exact triangle contact/intersection oracle. Closed topology is per generated mesh, not a boolean-unioned single building. No general runtime/performance/release acceptance.'},'native_views':views,'native_conditions':{'isolated_probe':'look_probe.gd -- --render; actual Godot4.6.2 Forward+/Vulkan','lighting':'unchanged scripts/terrain/frontier_art_profile.gd','lighting_source_sha256':sha(ROOT/'scripts/terrain/frontier_art_profile.gd'),'resolution':[1280,900],'before_after_match':'same camera transform/orthographic size/light/environment per pair; production scene captures remain parent-owned','new_lights':'none in the builder; probe contains the same single directional light prescribed by FrontierArtProfile'},'visual_review':{'opened':True,'findings':'Silhouettes and roof function now differ at ensemble distance; entrances and shutter have real depth, dark plinths contact the ground. No visible missing/cull-flipped parts in front/rear views.','remaining_differences':'Still compact, cleaner and more geometric than the rich painted references. Rear elevations remain restrained. Full service yard, worn ground/rock contacts and lived-in functional groups belong to the parent environment pass. Closed roof interpretation is inferred from cutaway references, not an exact closed-building tracing.','acceptance':'technical and visual candidate review only; no user approval inferred'},'scope_exclusions':['ships','citizen models','Kenney originals','renderer/dressing/preview/test/report edits','global lighting changes','imports/commits/pushes'],'branch':'task/grafikreferenzen-20261101, intentional continuation of the unintegrated graphics branch'}
    (HERE/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    print(json.dumps({'manifest':rel(HERE/'manifest.json'),'builder_sha256':sha(builder),'geometry':qa['passed'],'regression':22,'opened_native_views':len(views)}))
if __name__=='__main__':main()

"""Finalize measured ship metadata; never modifies any GLB or source mesh."""
from pathlib import Path
import json,hashlib,struct
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
ASSETS=['cutlass_01','buccaneer_01']
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return str(Path(p).relative_to(ROOT)).replace('\\','/')
def main():
    rt=read(QA/'roundtrip.json');rows=[]
    for asset in ASSETS:
        r=read(QA/(asset+'_manifest.json'));fresh=next(x for x in rt['assets'] if x['asset']==asset)
        assert r['qa_pass'] and fresh['pass'] and not r['qa_errors'] and not r['qa_warnings']
        assert r['export']['sha256']==fresh['glb_sha256']==sha(ROOT/r['export']['path'])
        b=(ROOT/r['export']['path']).read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n])
        assert len(g['meshes'])==1 and len(g['materials'])<=8 and len(g['nodes'])==1 and not g.get('animations') and not g.get('skins') and not g.get('images')
        assert 'KHR_lights_punctual' not in g.get('extensions',{})
        r['roundtrip']=fresh;r['source_raw_qa']=rel(QA/(asset+'_raw.json'));r['views']=read(QA/(asset+'_views.json'))
        suffixes=['front','rear','top','game','random','wire','roundtrip_front','roundtrip_rear','roundtrip_game']
        r['opened_images']=[{'path':rel(QA/(asset+'_'+v+'.png')),'sha256':sha(QA/(asset+'_'+v+'.png'))} for v in suffixes]
        r['warning_acceptance']='Only roundtrip format-attribute seam duplicate vertices may remain in raw import report. New source is closed and error/warning-free; no z-fight, floating, degenerate, inconsistent or inverted geometry. No expensive checks skipped. UV intentionally absent for solid colors.'
        rows.append(r)
    result={'schema':'sternenbuergerchen.pass04_ships.v1','task':'docs/tasks/ART_2026_11_01_pass04.md','status':'new illustration-led simplified model candidates; parent owns native Godot integration and user visual acceptance',
        'blender':'5.2.3 LTS','generator':rel(HERE/'generator/build_ships.py'),'generator_sha256':sha(HERE/'generator/build_ships.py'),'assets':rows,
        'normalization':'Cutlass total length16Blender-metres, Buccaneer11; deliberately stylized scene normalization, NOT canonical Star Citizen dimensions. Uniform whole-asset scaling includes undercarriage; BBox XY center, lowest footZ0, Godot+Zfront.',
        'geometry_provenance':'Every exported mesh is newly constructed by the retained generator after viewing the assigned local image pairs. No high-poly OBJ, old material candidate or generic Kenney ship mesh is imported or relabeled.',
        'reference_pair_consistency':{'cutlass':'Both views refer to this single mesh: separate aft pods, angled cargo hull, forward endplates, lowered cockpit, dorsal twin turret and closed center ramp.',
            'buccaneer':'Both views refer to this single mesh: large dark front pod inlets, narrower petalled rear nozzles, narrow pointed cockpit, swept short wings and dorsal cannon. Front/rear details are coordinated rather than generated independently.'},
        'visual_review':{'opened':True,'method':'front/rear/overview-distance, top, random-part and true wire images; fresh GLB front/rear/game images; original four targets opened first',
            'improvements':'Broad distinctive silhouettes and ivory/petrol zones; few ochre fields; thick structural connections, visible inset nozzle rings and supported static landing feet.',
            'remaining_differences':'More faceted and cleaner than the painted target art; panel scuffs, small pipes, tiny cutouts and most tertiary details omitted. Canopy and pod cowl contours are simplified. Added original static landing supports are not shown in flying image targets and are not a canonical gear recreation. No animated deployment, flight, weapons or interior.'},
        'integration_interface':{'exports':'Assets/curated/frontier_illustrated_20261101/ships_pass04/{cutlass_01,buccaneer_01}.glb','static_meshes_per_asset':1,'materials_max':8,'runtime_scale_suggested':.22,'front_godot':'+Z','pivot':'BBox XY-center, groundZ0','collision_navigation_lights':False},
        'not_claimed':['canonical Star Citizen scale','official game mesh provenance','new geometry derived from old defective OBJ material studies','native Godot verification performed by this subtask','user visual approval','flight/weapon/vehicle mechanics','general performance or release acceptance']}
    (HERE/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'manifest':rel(HERE/'manifest.json'),'assets':[{'asset':r['asset'],'triangles':r['triangles'],'dimensions':r['dimensions_blender_m'],'sha256':r['export']['sha256']} for r in rows]},indent=2))
if __name__=='__main__':main()

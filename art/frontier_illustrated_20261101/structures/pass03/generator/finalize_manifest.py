"""Finalize static candidate evidence without modifying sources or exports."""
from pathlib import Path
import json,hashlib,struct
HERE=Path(__file__).resolve().parents[1];ROOT=HERE.parents[3];QA=HERE/'qa'
ASSETS=['habitat_cutaway_01','freihafen_hall_01']
def read(p):return json.loads(Path(p).read_text(encoding='utf-8'))
def sha(p):return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def rel(p):return str(Path(p).relative_to(ROOT)).replace('\\','/')
def main():
    roundtrip=read(QA/'roundtrip.json');rows=[]
    refs=['docs/reports/assets/grafik-2026-11-01/references/current/01_rostgrenze_cutaway.png','docs/reports/assets/grafik-2026-11-01/references/current/02_freihafen_distribution_center.png']
    for asset in ASSETS:
        r=read(QA/(asset+'_manifest.json'));rt=next(x for x in roundtrip['assets'] if x['asset']==asset)
        assert r['qa_pass'] and rt['pass'] and not r['qa_errors']
        p=ROOT/r['export']['path'];assert sha(p)==rt['glb_sha256']==r['export']['sha256']
        b=p.read_bytes();n=struct.unpack_from('<I',b,12)[0];g=json.loads(b[20:20+n]);assert len(g['meshes'])==1 and len(g['materials'])<=8
        assert not g.get('animations') and not g.get('skins') and not g.get('images') and len(g['nodes'])==1
        assert not any(k in g.get('extensions',{}) for k in ['KHR_lights_punctual'])
        r['raw_qa_report']=rel(QA/(asset+'_raw.json'));r['roundtrip']=rt;r['views']=read(QA/(asset+'_views.json'))
        r['opened_images']=[{'path':rel(QA/(asset+'_'+s+'.png')),'sha256':sha(QA/(asset+'_'+s+'.png'))} for s in ['front','rear','top','game','random','wire','roundtrip_front','roundtrip_game']]
        r['warning_acceptance']={'hidden_back_to_back_faces':'Accepted exact abutments of repeated closed Kenney wall modules and inherited module-internal mounting caps. They are hidden contacts, not visible z-fighting; raw pair names/counts retained.',
            'duplicate_source_vertices':'Display-table and clipped factory-frame mounting edges deliberately split after source seam welding to preserve separate shells at source nonmanifold contacts; no loose/floating geometry. Duplicate positions retained rather than inventing a full boolean redesign.',
            'open_boundaries':'Some Kenney display/console and frame-shell source boundaries are inherited or remain at split hidden mounting contacts. Profile game checks them numerically; no watertight-print claim.',
            'roundtrip_attribute_seams':'Fresh GLB import additionally retains normal/material seam copies; positions, bounds and per-material triangle counts match source exactly. No import repair.',
            'uv':'Untextured constant-color materials deliberately have no UVs.'}
        rows.append(r)
        if r['asset']=='habitat_cutaway_01':
            r['functional']['functional_zones']=['sleep: two actual Kenney bed-single bases with fitted blankets/headboards and locker','storage: six shelf cases and two actual Kenney container-wide canisters','work: supported bench, wall tool board and vise','stay: actual Kenney table-display without display ship, two chairs and actual Kenney computer']
        else:
            r['functional']['human_scale']='factory-derived opening about5.3m clear width/3.6m high; office doorway0.83m wide; desk0.85m above floor; lower office roof2.97m'
    sources={}
    for r in rows:
        for item in r['kenney_geometry_reuse']:
            path=item['source'];assert sha(ROOT/path)==item['source_sha256']
            rec=sources.setdefault(path,{'path':path,'sha256':item['source_sha256'],'pack':item['pack'],'license':item['license'],'license_path':item['license_path'],'license_sha256':item['license_sha256'],'usages':[],'modifications':[], 'original_file_unchanged':True})
            usage=next((u for u in rec['usages'] if u['asset']==r['asset']),None)
            if usage is None:usage={'asset':r['asset'],'instances':[],'retained_objects':[]};rec['usages'].append(usage)
            usage['instances'].append(item['instance']);usage['retained_objects']=sorted(set(usage['retained_objects']+item['retained_objects']))
            for op in item['operations']:
                if op not in rec['modifications']:rec['modifications'].append(op)
            if item['frame_cut'] and 'retain actual jamb/header regions; omit closed leaf and lower sill; cap derivative cuts' not in rec['modifications']:
                rec['modifications'].append('retain actual jamb/header regions; omit closed leaf and lower sill; cap derivative cuts')
            if item['omitted_objects'] and item['omitted_objects'] not in rec['modifications']:rec['modifications'].append(item['omitted_objects'])
    prior=[]
    for name in ['habitat_01','workshop_01','service_unit_01']:
        p=ROOT/'Assets/curated/frontier_illustrated_20261101/structures'/(name+'.glb');prior.append({'path':rel(p),'sha256':sha(p),'status':'existing Pass02 structure retained; not overwritten by this generator'})
    support=[]
    for pack in ['space_station','factory']:
        atlas=ROOT/'Assets/curated/kenney'/pack/'models/Textures/colormap.png'
        if atlas.exists():support.append({'path':rel(atlas),'sha256':sha(atlas),'license':'Kenney CC0','role':'original atlas sampled to identify source color fields; replaced by constant target palette, not embedded in derivative GLBs'})
    result={'schema':'sternenbuergerchen.pass03_structures.v1','task':'docs/tasks/ART_2026_11_01_pass03.md','status':'separate Kenney-based cutaway/hall assembly candidates; parent task owns native Godot integration and acceptance',
        'blender':'5.2.3 LTS','generator':rel(HERE/'generator/build_cutaways.py'),'generator_sha256':sha(HERE/'generator/build_cutaways.py'),
        'references':[{'path':x,'sha256':sha(ROOT/x),'status':'current user-supplied visual reference; image labels are not gameplay rules'} for x in refs],
        'assets':rows,'kenney_sources':list(sources.values()),'kenney_supporting_files':support,'retained_previous_exports':prior,
        'earlier_procedural_study':{'path':'art/frontier_illustrated_20261101/structures/pass03/studies/procedural_r01','status':'local ignored unapproved study; sources/generator/rawQA/GLBs preserved before Kenney steering; no longer current candidate'},
        'native_interface':{'habitat_cutaway_01':{'preview_plane':[8.3,6.2],'runtime_scale':.35},'freihafen_hall_01':{'preview_plane':[13.2,6.2],'runtime_scale':.35},'front_godot':'+Z','pivot':'full BBox XY center / feet-floorZ0','collision_navigation_lights':False},
        'visual_review':{'opened':True,'readable_forms':'Habitat has distinct Kenney beds/locker, shelf cases/canisters, bench/tools/vise and Kenney display table/chairs/terminal. Hall has a supported factory-derived open portal/lift, two loaded racks, grouped cargo, clear loading aisle and attached lower office with Kenney console/window/tank.',
            'views':'Source front42deg/rear38deg/top, overview-height34.2857m at50deg, random and wire. Fresh GLB front/game views also opened.',
            'limits':'Intentional roof/front/right cutaway does not represent an enclosed weatherproof building. High rear/left walls hide contents from reverse cameras by design. Whole-asset full-world overview makes small props secondary; parent native close views judge final reading. Workbench is geometry/look review, not final PBR/native lighting evidence.'},
        'not_claimed':['user visual approval','interior gameplay','freight economy','navigation/collision authoring','campaign/editor migration','native Godot check performed by this generator','general performance or release acceptance']}
    (HERE/'manifest.json').write_text(json.dumps(result,indent=2),encoding='utf-8')
    print(json.dumps({'manifest':rel(HERE/'manifest.json'),'assets':[{'asset':r['asset'],'triangles':r['geometry']['triangles'],'sha256':r['export']['sha256']} for r in rows]},indent=2))
if __name__=='__main__':main()

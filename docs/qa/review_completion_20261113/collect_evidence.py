"""Index the latest accepted runs; preserve failed attempts in the evidence ZIP."""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

QA = Path(__file__).resolve().parent
ROOT = QA.parents[2]
LABELS = {
    'final_backoff_ship':'Ausweichen bei geänderter Schiffsfläche und Fortsetzung beider Ziele',
    'final_formation_occupied':'Besetzte Formationsziele und echte Hex-Interaktion',
    'final_rng':'Würfelgrenzen und gespeicherte Zufallsfolgen',
    'final_maps':'Alle 14 Missions- und 3 Basiskarten',
    'final_legacy_hex':'Legacy-Migration und atomare Owner-Grenzen',
    'final_authentic_legacy':'Echter alter Spielstand: Continue â†’ Hex-Save â†’ Continue',
    'final_home_save':'Normaler Spielstart, Speicherfehler und kurzer Retry',
    'final_active_continue':'Echte Reise, Einsatzsave, Continue und Rückkehr',
    'final_command_save':'Rundumsicherung und gespeicherte Bewegungsbefehle',
    'final_base_clearance':'Basiswege: Betten und geparkte Schiffe',
    'final_ux':'Bedienung, Fokus, Ausstieg und Namensänderung',
    'final_graphics':'Personenpaletten, Assetquellen und importierte Bounds',
    'final_base_projection':'Schmale Basisdarstellung ohne Bewegungsverzug',
    'final_autosave':'Autosave-Grenzen und Fehlerwiederholung',
    'final_root_checkpoint':'Root-Checkpoint-Transaktion',
    'final_movement_save':'Bewegungs- und Reservierungsfortsetzung',
    'final_network':'Hostautorität und echte ENet-Kommandos',
    'final_door':'Hex-Türen, Sicht und Bewegung',
    'final_connected':'Verbundenes GO und Hostantwort',
    'final_parallel':'Parallele Truppinteraktionen und Abbruch',
    'final_station_connected':'Verbundene Stationsroute',
    'final_station_route':'Verbundene Stationsroute mit AA, Tür, Computer und Fracht',
    'final_combat':'Hex-Kampf, Schablonen und Würfelautorität',
    'final_hex_use':'Lokale Hexinteraktionen, Reichweitengrenzen und Fortsetzung',
    'final_hex_surface':'Hexböden, Rampenhöhen und Figurenauflage',
    'final_hex_surface_capture':'Native Hexlinien auf Hügeln, Rampen und Kenney-Böden',
    'hex_surface_after':'Native Hexlinien auf Hügeln, Rampen und Kenney-Böden',
    'final_spawn':'Autoritative Hexaufnahme authored Stationsgruppen',
    'final_hex_enet':'Hex-Host und Replikat über echtes ENet',
    'final_five_sorties':'Fünf tatsächliche Kampagnenausflüge',
    'final_campaign':'Kampagnenabschluss und alte Save-Nachbarn',
    'final_campaign_chain':'Freigabefolge aller fünf Kampagnenaufträge',
    'maps_after':'Native Kartenansichten nach vollständigem Aufbau',
    'personnel_after':'Native Ansichten aller 46 Personen',
    'graphics_after':'Native Basis-, Personen- und Sternkartenansichten',
    'ui_after':'Native Appfußleiste, Reichweite und Ausstiegsdialog',
    'final_job_briefing':'Alle fünf Auftragsorte aus autoritativen Reisedaten',
    'final_station_visual':'Anschlüsse modularer Boden- und Wandstücke',
    'station_after':'Native Stations-, Landepad- und Sandboxansichten',
    'final_station_capture':'Native Stations-, Landepad- und Sandboxansichten',
    'final_regional_shadow':'Native Kappen, Klippen und Rampenschatten',
    'final_checkpoint_numbers':'Exakte Zahlenwerte über die JSON-Savegrenze',
    'final_actor':'Actor-Checkpoint-Transaktion',
    'final_actor_batch':'Atomare Actor-Batches',
    'final_actor_vital':'Gesundheit und Actor-Checkpoint',
    'final_lifecycle':'Stabile Missions- und Bewegungslebenszyklen',
    'final_station_restore':'Stationssave mit frischem Korridorindex',
    'final_deployment':'Deployment und tatsächliche Ankunft',
    'final_transport':'Transportzustände nach Hexmigration',
    'final_smart_mobile':'Kompakter Ortsbaum, Auftragsregeln und Auswahl',
    'final_starmap':'Kompakter Ortsbaum, Auftragsregeln und Auswahl',
    'final_menu_icons':'Vorhandene Ausrüstungsicons in den Menüs',
    'final_smart_mobile_capture':'Native kompakte Sternkarte und farbige Auftragsansicht',
    'starmap_after':'Native Sternkarte und Smart Mobile bei 720p und 1080p',
    'final_remote_inspection':'Orts-/Orbitansicht ohne Reise und autoritativer FoW',
    'remote_inspection_after':'Native unbekannte Orts- und Orbitansichten',
    'final_ship_access':'Echter Schiffsaccess, Teilankunft und Boarding',
    'final_cliff_visual':'Statische Bruchstein-Klippen und unveränderte Hexgeometrie',
    'final_station_layout':'Stationwinkel, reale Hexhülle und unverändertes Lagerhaus',
    'final_cliff_station':'Bruchsteinklippen, Stationsachsen und gebundene Geometriekosten',
    'final_shared_team':'Sechs echte ENet-Peers, gemeinsame Teams und Rejoin',
    'final_shared_team_legacy':'PvP-Seitenwahl und gemeinsame Koop-Fireteams',
    'final_world_multiplayer':'Parallele Karten und unabhängige Multiplayeransichten',
    'final_shared_team_multimap':'Parallele Karten und unabhängige Multiplayeransichten',
    'final_editor_wall_gate':'Mauer und Tor in einem Zug mit gemeinsamem Undo und Save',
    'final_map_preparation':'Vollständige Kartenvorbereitung unter unverändertem Speicherlimit',
    'final_grid_cache':'Statischer Cache ohne doppelte Live-Rasterdaten; Sicht und Türen erhalten',
    'final_station_building':'Bündige Wände, passende Türblätter und dekorative Kiesel',
    'final_advance_styles':'Vorhandene taktische Bewegungsstile',
    'final_take_doctrine':'Bestehende Nehmen-Befehle und taktische Regeln',
    'final_lobby_layout':'Bedienbare Multiplayer-Lobby bei kleiner Auflösung',
    'station_shadow_after':'Native Schattenvergleiche bei gleicher Stationskamera',
    'final_hex_foundation':'Hexgrundlagen und präziser Marker-Dateiroundtrip',
    'station_ensembles_after':'Native Ansichten der kleinen Station und gedrehter Außenensembles',
    'final_station_nature':'Unregelmäßige Felsgruppen mit erhaltenen Wegen und Blockerfakten',
    'final_visible_projection':'Teambezogene Sichtprojektion und verborgene Einheiten',
    'final_snapshot_contract':'Bestehender Netzwerk-Snapshotvertrag',
    'final_fog_overlay':'Erkundungsnebel und bestehende Renderer-Updates',
    'final_building_material':'18 Gebäude mit geteilten Materialien ohne Instanzparameter-Limit',
    'final_recruit_transport':'Angeworbene Personen, tatsächliche Schiffsbesatzung und strenge Speicherprüfung',
    'diagnostic_post_benit_continue':'Echter gespeicherter Benit-Stand: zwei weitere Ausflüge und Wiederaufnahme',
    'final_occupied_goal':'Belegtes Hexziel ohne Vollkartensuche, Freigabe und gespeicherter Bewegungsauftrag',
}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--cases', nargs='+', required=True)
    parser.add_argument('--product-commit', default='HEAD', help='Verified implementation commit; retain it when rebuilding a later documentation commit.')
    parser.add_argument('--campaign-chain-prefix', help='Partial run with three proved home returns; close it only with the exact saved-file Continue run.')
    args = parser.parse_args()
    checks = []
    for case in args.cases:
        reports = sorted((QA/case).glob('*/report.json'), key=lambda p: p.stat().st_mtime_ns)
        if not reports:
            raise RuntimeError('No result for '+case)
        path = reports[-1]
        record = json.loads(path.read_text(encoding='utf-8'))
        if not record['passed'] or record['assertions'] < 1 or record['failures'] or record['errors'] or not all(record['guards'].values()):
            raise RuntimeError('Latest run is not accepted: '+str(path))
        checks.append(dict(name=LABELS.get(case,case), case=case, status='bestanden', assertions=record['assertions'],
                           run_id=record['run_id'], report=path.relative_to(ROOT).as_posix(),
                           source_snapshot=record['source_snapshot'],
                           renderer=record['renderer'], seconds=record['elapsed_seconds']))
    metadata = json.loads((QA/'completion_content.json').read_text(encoding='utf-8'))
    if args.campaign_chain_prefix:
        if any(item['case'] == 'final_five_sorties' for item in checks):
            raise RuntimeError('Do not count a partial Five run as accepted')
        continuation = next(item for item in checks if item['case'] == 'diagnostic_post_benit_continue')
        prefix_path = (ROOT/args.campaign_chain_prefix).resolve()
        if not prefix_path.is_relative_to(QA): raise RuntimeError('Prefix must be owned QA evidence')
        prefix = json.loads(prefix_path.read_text(encoding='utf-8'))
        prefix_log = prefix_path.with_name('output.log').read_text(encoding='utf-8')
        seed = QA/'post_benit_source/checkpoint_v1.json'
        seed_sha = hashlib.sha256(seed.read_bytes()).hexdigest()
        seed_data = json.loads(seed.read_text(encoding='utf-8'))
        import re
        milestones = dict(re.findall(r'^MILESTONE_FILE (\w+) sha256=([0-9a-f]{64}) ', prefix_log, re.M))
        jobs = ['satellite_recovery','outpost_recovery','benit_delivery']
        if prefix['errors'] or not all(prefix['guards'].values()) or prefix['failures'] != 1 or 'CAMPAIGN_INTRO_LOOP returns=3' not in prefix_log:
            raise RuntimeError('Prefix lacks exactly three genuine guarded home returns')
        if set(milestones) != set(jobs) or milestones['benit_delivery'] != seed_sha:
            raise RuntimeError('Continue seed is not the exact third actual milestone')
        payload = seed_data.get('payload', seed_data)
        if any(payload['campaign']['jobs'][job]['status'] != 'completed' for job in jobs):
            raise RuntimeError('Third actual file lacks completed prefix jobs')
        continuation_log = (ROOT/continuation['report']).with_name('output.log').read_text(encoding='utf-8')
        if not re.search(r'CAMPAIGN_POST_BENIT_CONTINUE returns=2 passed=\d+ failed=0', continuation_log):
            raise RuntimeError('Exact Continue did not complete both remaining home returns')
        metadata['campaign_sequence'] = {'scope':'Drei echte Einsätze mit geschriebenen Heimständen, anschließend zwei weitere Einsätze per normalem Continue derselben Datei. Kein neuer vollständiger Fünferlauf in einem Prozess.',
            'prefix_report':prefix_path.relative_to(ROOT).as_posix(),'prefix_accepted_as_whole':False,'prefix_assertions_excluded':prefix['assertions'],
            'prefix_returns':3,'checkpoint_sha256':seed_sha,'continuation_report':continuation['report'],'continuation_returns':2,
            'prefix_milestone_sha256':milestones}
    preparation = next((item for item in checks if item['case'] == 'final_map_preparation'), None)
    if preparation:
        log = (ROOT/preparation['report']).with_name('output.log').read_text(encoding='utf-8')
        measurements = [json.loads(line.removeprefix('MAP_PREPARATION ')) for line in log.splitlines() if line.startswith('MAP_PREPARATION ')]
        full = {row['map']: row for row in measurements if row['mode'] == 'whole_map_resource_prefill'}
        metadata['map_preparation_measurements'] = measurements
        labels = [('res://maps/satellite_crash_site.json', 'Satellit'), ('res://maps/trade_outpost.json', 'Handel'), ('res://maps/fortified_outpost.json', 'Festung')]
        payloads = ' · '.join(label+': '+f'{full[path]["state"]["retained_payload_bytes"]/1_000_000:.2f}'.replace('.', ',')+' MB' for path,label in labels)
        for area in metadata.get('areas', []):
            if area['id'] == 'architecture':
                area['evidence'] = ('Der gezielte Rastercache-Test besteht nach nachgewiesenem Fehler 12 Prüfungen. '
                    f'Alle 17 tatsächlichen Karten-/Basisstarts bestehen weitere {preparation["assertions"]} Prüfungen. '
                    'Die drei großen Karten bereiten alle Abschnitte innerhalb des unveränderten 256-MiB-Limits vor '
                    'und übergeben den Cache erfolgreich an eine neue Ansicht. Gemessene Nutzdaten: '+payloads+'.')
    inventories = [QA/'graphics_inventory.json', ROOT/'docs/qa/starmap_mobile_20261113/ui_gallery.json']
    gallery_entries = 0
    gallery_files = set()
    for inventory in inventories:
        for asset in json.loads(inventory.read_text(encoding='utf-8'))['assets']:
            gallery_entries += 1
            for stage in ['reference', 'before', 'after']:
                record = asset.get(stage, {})
                if not record.get('path') and stage != 'after' and record.get('unavailable_reason'):
                    continue
                path = (ROOT/record.get('path', '')).resolve()
                if not path.is_relative_to(ROOT) or not path.is_file():
                    raise RuntimeError(f'Missing gallery image: {asset["id"]}/{stage}')
                if hashlib.sha256(path.read_bytes()).hexdigest() != record.get('sha256'):
                    raise RuntimeError(f'Gallery image hash differs: {asset["id"]}/{stage}')
                gallery_files.add(path)
    metadata.update(assertions=sum(item['assertions'] for item in checks), checks=checks,
                    gallery_entries=gallery_entries, gallery_unique_images=len(gallery_files),
                    product_commit=subprocess.check_output(['git','rev-parse','--verify',args.product_commit+'^{commit}'],cwd=ROOT,text=True).strip())
    (QA/'summary.json').write_text(json.dumps(metadata,ensure_ascii=False,indent=2),encoding='utf-8')
    # Every attempt's logs and hashes stay inspectable, including RED and harness
    # failures. Native images remain separate, source-linked gallery artifacts.
    evidence = []
    for name in ['report.json','output.log','engine.log','capture_manifest.json']:
        evidence.extend(QA.rglob(name))
    with zipfile.ZipFile(QA/'regression_evidence.zip','w',compression=zipfile.ZIP_DEFLATED,compresslevel=9) as archive:
        for path in sorted(set(evidence)):
            archive.write(path,path.relative_to(ROOT).as_posix())
        for path in [QA/'summary.json', QA/'final_plan.json', QA/'GRAPHICS_REVIEW.md', QA/'kenney_usage_catalog.json', *inventories,
                     *sorted((QA/'legacy_source_pair').glob('*.json')),
                     *sorted((QA/'return_source_pair').glob('*.json')),
                     *sorted((QA/'post_benit_source').glob('*.json')),
                     *sorted((ROOT/'docs/qa/starmap_mobile_20261113/references').glob('*.json')),
                     *sorted((ROOT/'docs/qa/starmap_mobile_20261113/references').glob('*prompt.txt'))]:
            archive.write(path,path.relative_to(ROOT).as_posix())
        for directory in [ROOT/'docs/qa/hex_surface_design_20261113/references', ROOT/'Assets/curated/mission_illustrations_20261113']:
            for path in sorted(directory.iterdir()):
                if path.suffix in ['.json', '.txt', '.md']:
                    archive.write(path,path.relative_to(ROOT).as_posix())
        for path in sorted(QA.glob('station_*migration.json')):
            archive.write(path,path.relative_to(ROOT).as_posix())
        for path in sorted(QA.glob('frontier_*migration.json')):
            archive.write(path,path.relative_to(ROOT).as_posix())
        archive.write(QA/'station_pipe_removal.json', (QA/'station_pipe_removal.json').relative_to(ROOT).as_posix())
        archive.write(QA/'station_nature_clusters.json', (QA/'station_nature_clusters.json').relative_to(ROOT).as_posix())
    digest = hashlib.sha256((QA/'regression_evidence.zip').read_bytes()).hexdigest()
    print(json.dumps({'accepted_runs':len(checks),'assertions':metadata['assertions'],'evidence_sha256':digest}))


if __name__ == '__main__':
    main()

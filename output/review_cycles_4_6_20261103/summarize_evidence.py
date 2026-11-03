"""Read-only audit of raw reports and pinned sources; writes the result index."""
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent


def assertion_counts(case):
    lines = Path(case['log']).read_text(encoding='utf-8').splitlines()
    found = []
    for line in lines:
        match = re.search(r'=== RESULTS:\s*(\d+) passed,\s*(\d+) failed', line)
        match = match or re.search(r'RESULT\s+passed=(\d+)\s+failed=(\d+)', line)
        if match:
            found.append((int(match[1]), int(match[2])))
        match = re.search(r'ALL (\d+) TESTS PASSED|TASK_1157 PASS \((\d+) checks\)', line)
        if match:
            found.append((int(match[1] or match[2]), 0))
        if '{' in line:
            try:
                data = json.loads(line[line.index('{'):])
            except json.JSONDecodeError:
                continue
            if isinstance(data, dict) and 'passed' in data and 'failed' in data:
                found.append((int(data['passed']), int(data['failed'])))
    if found:
        return {'passed': found[-1][0], 'failed': found[-1][1]}
    assert 'isolation_canary' in case['name'], f'Unparsed assertions: {case["name"]}'
    return {'passed': 0, 'failed': 0, 'kind': 'isolation_canary'}


def main():
    report_path, = (OUT / 'final_suite').glob('*/report.json')
    report = json.loads(report_path.read_text())
    assert report['summary'] == {'selected': 85, 'passed': 84, 'failed': 1}
    failed = [c for c in report['checks'] if not c['passed']]
    assert [c['name'] for c in failed] == ['task_839_release_firefight_world_label_declutter']
    assert failed[0]['exit_code'] == 1 and failed[0]['error_count'] == 2
    baseline = json.loads((OUT / 'roster_baseline.json').read_text())
    snapshot = json.loads((OUT / 'final_source_snapshot.json').read_text())
    for f, expected in snapshot['files_sha256'].items():
        assert hashlib.sha256((ROOT / f).read_bytes()).hexdigest() == expected, f
        committed = subprocess.check_output(['git', 'show', snapshot['source_commit'] + ':' + f], cwd=ROOT)
        assert hashlib.sha256(committed).hexdigest() == expected, f
    history = []
    all_cases = []
    for path in sorted(OUT.glob('**/report.json')):
        data = json.loads(path.read_text())
        history.append({'report': str(path.relative_to(ROOT)).replace('\\', '/'), **data['summary']})
        for case in data['checks']:
            assert case['isolation_verified'] and not case['timed_out'], case['name']
            assert case['roster_before'] == baseline['state'] == case['roster_after']
            all_cases.append(case)
    assert len({c['user_dir'] for c in all_cases}) == len(all_cases)
    checks = [{**{k: c[k] for k in ['name', 'passed', 'exit_code', 'error_count', 'isolation_verified', 'log']},
               'assertions': assertion_counts(c)} for c in report['checks']]
    total = {k: sum(c['assertions'][k] for c in checks) for k in ['passed', 'failed']}
    fresh = [c for c in checks if c['name'].startswith('review46_20261103_')]
    assert len(fresh) == 4 and sum(c['assertions']['passed'] for c in fresh) == 173
    current = Path(baseline['roster_path'])
    raw = current.read_bytes()
    state = {'sha256': hashlib.sha256(raw).hexdigest(), 'length': len(raw), 'mtime_ns': current.stat().st_mtime_ns}
    assert state == baseline['state']
    summary = {'schema': 'sternenbuergerchen.review46.v1', 'base_commit': '21bacf0f2f3268cf058f1c5e52381fce4e4b1792',
               'tested_source_commit': snapshot['source_commit'], 'source_fingerprints': snapshot,
               'rounds': 3, 'confirmed_fixes': 4, 'new_regressions': {'gates': 4, 'assertions': 173},
               'final_gates': report['summary'], 'final_assertions': total,
               'known_baseline_failure': {'name': failed[0]['name'], 'assertions': assertion_counts(failed[0]),
                                          'original_report': 'task839_original_main_baseline/20261103T044215Z-3a1681af/report.json',
                                          'changed_no_assertions': True},
               'hpa_operations_per_8_hits': {'sides': [128, 256], 'materialized_before': [131072, 524288], 'materialized_after': [0, 0]},
               'task1188_paired_headless_p99_usec': {'before': 3370, 'after': 4904, 'budget': 8000, 'frames_each': 8696,
                                                   'limitation': 'One pair; measured overhead, no native FPS or isolated causal estimate.'},
               'protected_roster': state, 'isolated_check_runs': len(all_cases), 'all_user_dirs_unique': True,
               'history': history, 'checks': checks}
    smoke_reports = list((OUT / 'main_smoke').glob('*/report.json'))
    if smoke_reports:
        smoke_path, = smoke_reports
        smoke = json.loads(smoke_path.read_text())
        assert smoke['summary'] == {'selected': 5, 'passed': 5, 'failed': 0}
        smoke_counts = [assertion_counts(c) for c in smoke['checks']]
        assert sum(c['passed'] for c in smoke_counts) == 173
        assert sum(c['failed'] for c in smoke_counts) == 0
        summary['main_smoke'] = {'report': str(smoke_path.relative_to(ROOT)).replace('\\', '/'),
                                 'gates': smoke['summary'], 'assertions': 173,
                                 'context': json.loads((OUT / 'main_smoke_context.json').read_text())}
    (OUT / 'verification_summary.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print(json.dumps({'gates': report['summary'], 'assertions': total, 'new_assertions': 173,
                      'isolated_check_runs': len(all_cases), 'source_hashes': len(snapshot['files_sha256'])}))


if __name__ == '__main__':
    main()

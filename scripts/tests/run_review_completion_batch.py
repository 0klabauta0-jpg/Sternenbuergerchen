"""Run independent private Godot checks serially, preserving each result."""
import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--plan', required=True)
    parser.add_argument('--source-snapshot', required=True)
    args = parser.parse_args()
    plan = json.loads(Path(args.plan).read_text(encoding='utf-8'))
    outcomes = []
    for case in plan:
        command = [sys.executable, str(ROOT/'scripts/tests/run_review_completion_20261113.py'),
                   '--case', case['case'], '--script', 'res://scripts/tests/'+case['script'],
                   '--marker', case['marker'], '--timeout', str(case.get('timeout', 180)),
                   '--source-snapshot', args.source_snapshot]
        if case.get('native'):
            command.append('--native')
        print('START '+case['case'], flush=True)
        code = subprocess.run(command, cwd=ROOT).returncode
        outcomes.append({'case': case['case'], 'exit_code': code})
        print('FINISH '+case['case']+' exit='+str(code), flush=True)
    print(json.dumps({'batch': outcomes}), flush=True)
    return int(any(item['exit_code'] for item in outcomes))


if __name__ == '__main__':
    sys.exit(main())

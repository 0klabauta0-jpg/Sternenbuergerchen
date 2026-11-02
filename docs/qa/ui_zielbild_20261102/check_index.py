"""Check frozen evidence against staged Git blob bytes, without changing pins."""
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
QA = Path(__file__).resolve().parent
snapshot = json.loads((QA / 'source_snapshot.json').read_text(encoding='utf-8'))
failures = []
for entry in snapshot['files']:
    result = subprocess.run(['git', 'show', ':' + entry['path']], cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if result.returncode or hashlib.sha256(result.stdout).hexdigest() != entry['sha256']:
        failures.append(entry['path'])
proof = {'passed': not failures, 'scope': 'Selected frozen source, original target images and native evidence match staged Git blob bytes; no repinning or engine execution.',
         'checked_files': len(snapshot['files']), 'failures': failures,
         'snapshot_sha256': hashlib.sha256((QA / 'source_snapshot.json').read_bytes()).hexdigest()}
(QA / 'INDEX_PROOF.json').write_text(json.dumps(proof, indent=2) + '\n', encoding='utf-8', newline='\n')
print(json.dumps(proof, indent=2))
raise SystemExit(0 if proof['passed'] else 1)

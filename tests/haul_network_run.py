"""Two real product processes; no normal career files or interactive windows."""
from pathlib import Path
import json
import subprocess
import tempfile
import time
import sys

root = Path(__file__).resolve().parents[1]
engine = r'C:\Users\bjoer\AppData\Local\Programs\Godot\Godot_v4.6.2-stable_win64_console.exe'
out = Path(tempfile.mkdtemp(prefix='sternen-haul-network-'))
args = [engine, '--headless', '--path', str(root), '--script', 'tests/haul_network_probe.gd', '--', '--out='+str(out)]
if '--websocket' in sys.argv:
    args.append('--websocket')
processes = []
streams = []
try:
    for role in ['host', 'client']:
        if role == 'client':
            end = time.monotonic()+15
            while not (out/'ready.json').exists():
                if processes[0].poll() is not None or time.monotonic()>end:
                    raise RuntimeError('Host not ready: '+str(out))
                time.sleep(.1)
        stream = (out/(role+'.log')).open('wb'); streams.append(stream)
        processes.append(subprocess.Popen(args+(['--host'] if role=='host' else []), stdout=stream, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW))
    code = processes[0].wait(timeout=70)
    result = json.loads((out/'host.json').read_text(encoding='utf-8'))
    assert code == 0 and result['ok'], (result, str(out))
    assert json.loads((out/'client.json').read_text(encoding='utf-8'))['ok']
    for stream in streams:
        stream.flush()
    for log in out.glob('*.log'):
        assert 'SCRIPT ERROR' not in log.read_text(encoding='utf-8'), str(log)
    print('HAUL_NETWORK_PASS', 'websocket='+str('--websocket' in sys.argv), out)
finally:
    for process in processes:
        if process.poll() is None:
            process.terminate(); process.wait(timeout=5)
    for stream in streams:
        stream.close()

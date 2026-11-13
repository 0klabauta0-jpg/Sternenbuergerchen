"""Exercise the timeout against a real launcher and child on Windows."""
import ctypes
import json
from pathlib import Path
import subprocess
import sys
import uuid
from probe_process import run

out = Path(__file__).resolve().parent / "local_runs" / ("timeout_" + uuid.uuid4().hex)
out.mkdir(parents=True)
child_code = "import time; time.sleep(60)"
parent_code = "import subprocess,sys,time; p=subprocess.Popen([sys.executable,'-c',sys.argv[1]]); print(p.pid,flush=True); time.sleep(60)"
with (out / "process.log").open("wb") as log:
    code = run([sys.executable, "-c", parent_code, child_code], env=None, log=log, timeout=2)
pid = int((out / "process.log").read_text().strip())
kernel = ctypes.WinDLL("kernel32", use_last_error=True)
kernel.OpenProcess.restype = ctypes.c_void_p
kernel.OpenProcess.argtypes = [ctypes.c_ulong, ctypes.c_int, ctypes.c_ulong]
kernel.GetExitCodeProcess.argtypes = [ctypes.c_void_p, ctypes.POINTER(ctypes.c_ulong)]
kernel.CloseHandle.argtypes = [ctypes.c_void_p]
handle = kernel.OpenProcess(0x1000, False, pid)
active = False
if handle:
    value = ctypes.c_ulong()
    if not kernel.GetExitCodeProcess(handle, ctypes.byref(value)):
        raise ctypes.WinError(ctypes.get_last_error())
    active = value.value == 259
    kernel.CloseHandle(handle)
result = {"timeout_returned": code == "timeout", "child_pid": pid, "child_still_active": active,
          "passed": code == "timeout" and not active}
(out / "summary.json").write_text(json.dumps(result, indent=2), encoding="utf-8")
print(json.dumps(result))
if not result["passed"]:
    subprocess.run(["taskkill", "/PID", str(pid), "/T", "/F"], check=False)
    sys.exit(1)

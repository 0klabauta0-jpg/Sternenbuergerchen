"""Bound the console launcher together with its native child process."""
import os
import subprocess
import hashlib


def fingerprint(path):
    return {str(p.relative_to(path)): [hashlib.sha256(p.read_bytes()).hexdigest(), p.stat().st_mtime_ns]
            for p in path.rglob("*") if p.is_file()} if path.exists() else {}


def errors(text):
    return [line for line in text.splitlines() if any(token in line for token in
            ("ERROR:", "SCRIPT ERROR:", "leaked", "Leak", "still in use at exit"))]


def run(args, *, env, log, timeout):
    process = subprocess.Popen(args, env=env, stdout=log, stderr=subprocess.STDOUT)
    try:
        return process.wait(timeout=timeout)
    except subprocess.TimeoutExpired:
        if os.name == "nt":
            subprocess.run(["taskkill", "/PID", str(process.pid), "/T", "/F"],
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                           timeout=20, check=False)
        else:
            process.kill()
        process.wait(timeout=20)
        return "timeout"

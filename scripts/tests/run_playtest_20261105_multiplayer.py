"""Root-run native two-process source multiplayer proof; never uses a release EXE.

Each process receives a separate overlay, user:// guard and canary. Normal
MainMenu CLI adapters enter the product lobby. Cleanup targets only Popen-owned
PIDs, first WM_CLOSE, then a documented deadline fallback. No gameplay patches.
"""
from __future__ import annotations

import argparse
import ctypes
from ctypes import wintypes
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import socket
import struct
import subprocess
import time
import uuid

from run_review2_isolated import ANSI, ERROR, check_roster, create_overlay


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def pins(root: Path) -> dict[str, str]:
    files = [root / "project.godot"]
    for folder, patterns in {"scripts": ("*.gd",), "data": ("*.json",),
                             "maps": ("*.json",), "scenes": ("*.tscn",),
                             "shaders": ("*.gdshader",)}.items():
        for pattern in patterns:
            files.extend((root / folder).rglob(pattern))
    return {p.relative_to(root).as_posix(): sha(p) for p in sorted(set(files))}


def load_json(path: Path) -> dict:
    try:
        value = json.loads(path.read_text(encoding="utf-8-sig"))
        return value if isinstance(value, dict) else {}
    except (OSError, ValueError):
        return {}


def png_dimensions(path: Path) -> list[int]:
    try:
        with path.open("rb") as stream:
            header = stream.read(24)
        if header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
            return []
        return list(struct.unpack(">II", header[16:24]))
    except (OSError, struct.error):
        return []


def owned_windows(pid: int) -> list[dict]:
    if os.name != "nt":
        return []
    user32 = ctypes.windll.user32
    result = []
    callback_type = ctypes.WINFUNCTYPE(wintypes.BOOL, wintypes.HWND, wintypes.LPARAM)
    user32.GetWindowThreadProcessId.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.DWORD)]
    user32.GetWindowRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
    user32.GetClientRect.argtypes = [wintypes.HWND, ctypes.POINTER(wintypes.RECT)]
    user32.IsWindowVisible.argtypes = [wintypes.HWND]
    user32.IsIconic.argtypes = [wintypes.HWND]
    user32.GetWindowTextW.argtypes = [wintypes.HWND, wintypes.LPWSTR, ctypes.c_int]
    user32.EnumWindows.argtypes = [callback_type, wintypes.LPARAM]

    class MonitorInfo(ctypes.Structure):
        _fields_ = [("cbSize", wintypes.DWORD), ("rcMonitor", wintypes.RECT),
                    ("rcWork", wintypes.RECT), ("dwFlags", wintypes.DWORD)]

    user32.MonitorFromWindow.argtypes = [wintypes.HWND, wintypes.DWORD]
    user32.MonitorFromWindow.restype = wintypes.HANDLE
    user32.GetMonitorInfoW.argtypes = [wintypes.HANDLE, ctypes.POINTER(MonitorInfo)]
    user32.GetMonitorInfoW.restype = wintypes.BOOL

    def visit(hwnd, _param):
        process_id = wintypes.DWORD()
        user32.GetWindowThreadProcessId(hwnd, ctypes.byref(process_id))
        if process_id.value != pid or not user32.IsWindowVisible(hwnd):
            return True
        outer, client = wintypes.RECT(), wintypes.RECT()
        user32.GetWindowRect(hwnd, ctypes.byref(outer))
        user32.GetClientRect(hwnd, ctypes.byref(client))
        if client.right < 320 or client.bottom < 200:
            return True
        info = MonitorInfo()
        info.cbSize = ctypes.sizeof(info)
        monitor = user32.MonitorFromWindow(hwnd, 2)
        user32.GetMonitorInfoW(monitor, ctypes.byref(info))
        title = ctypes.create_unicode_buffer(512)
        user32.GetWindowTextW(hwnd, title, 512)
        bounds = [outer.left, outer.top, outer.right, outer.bottom]
        monitor_bounds = [info.rcMonitor.left, info.rcMonitor.top, info.rcMonitor.right, info.rcMonitor.bottom]
        result.append({"hwnd": int(hwnd), "pid": pid, "title": title.value,
                       "outer_bounds": bounds, "client_size": [client.right, client.bottom],
                       "monitor_bounds": monitor_bounds, "minimized": bool(user32.IsIconic(hwnd)),
                       "covers_monitor": bounds[0] <= monitor_bounds[0] and bounds[1] <= monitor_bounds[1]
                       and bounds[2] >= monitor_bounds[2] and bounds[3] >= monitor_bounds[3],
                       "overscan_pixels": [monitor_bounds[0] - bounds[0], monitor_bounds[1] - bounds[1],
                                           bounds[2] - monitor_bounds[2], bounds[3] - monitor_bounds[3]]})
        return True

    user32.EnumWindows(callback_type(visit), 0)
    return sorted(result, key=lambda item: item["client_size"][0] * item["client_size"][1], reverse=True)


def cleanup(processes: dict[str, subprocess.Popen], grace: float = 8.0, users: dict | None = None) -> dict:
    actions = {}
    if users:
        # Retire client first through its normal Disconnect action; leave the
        # host alive while the client's final network packets/audio drain.
        for role in ("client", "host"):
            process = processes.get(role)
            if process is None or process.poll() is not None:
                continue
            request = Path(users[role]["path"]) / "qa_mp_quit_request"
            request.write_text("normal_disconnect_then_quit\n", encoding="utf-8")
            end = time.monotonic() + grace * 0.5
            while process.poll() is None and time.monotonic() < end:
                time.sleep(0.1)
    for role, process in processes.items():
        if process.poll() is not None:
            actions[role] = {"pid": process.pid, "mode": "normal_probe_exit" if users else "already_exited", "exit_code": process.returncode}
            continue
        windows = owned_windows(process.pid)
        if os.name == "nt":
            for window in windows:
                ctypes.windll.user32.PostMessageW(wintypes.HWND(window["hwnd"]), 0x0010, 0, 0)
        actions[role] = {"pid": process.pid, "mode": "wm_close_requested", "owned_windows": windows}
    deadline = time.monotonic() + grace
    while time.monotonic() < deadline and any(p.poll() is None for p in processes.values()):
        time.sleep(0.1)
    for role, process in processes.items():
        if process.poll() is None:
            # Explicitly scoped to this exact Popen child, never name/global PID scans.
            process.terminate()
            actions[role]["mode"] = "owned_pid_terminate_after_quit_grace"
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                actions[role]["mode"] = "owned_pid_kill_after_terminate_deadline"
                process.wait(timeout=3)
        actions[role]["exit_code"] = process.returncode
    return actions


def verify_trace(trace: dict, expected_map_hash: str) -> dict:
    session = trace.get("session", {})
    return {
        "active_mission": bool(trace.get("active_mission", False)),
        "stage": str(trace.get("stage", "")),
        "connected_count": int(session.get("connected_count", 0)),
        "ready_count": int(session.get("ready_count", 0)),
        "peer_id": int(session.get("local_peer_id", 0)),
        "map_matches": session.get("map_manifest", {}).get("map_hash", "") == expected_map_hash,
        "local_map_state": session.get("map_transfer", {}).get("state", ""),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", default=str(Path(__file__).resolve().parents[2]))
    parser.add_argument("--baseline", default="output/playtest_20261105/roster_baseline.json")
    parser.add_argument("--output", default="output/playtest_20261105/multiplayer_pair")
    parser.add_argument("--timeout", type=float, default=180.0)
    parser.add_argument("--port", type=int, default=28747)
    parser.add_argument("--resolution", default="3440x1440")
    parser.add_argument("--screen", type=int, default=0)
    parser.add_argument("--mode", choices=("entry", "drop"), default="entry")
    parser.add_argument("--map", default="maps/Ground_Mission01_32x32.json")
    args = parser.parse_args()
    if os.name != "nt":
        parser.error("Native fullscreen/window verification currently requires Windows")
    if not 30 <= args.timeout <= 240:
        parser.error("--timeout must be between 30 and 240 seconds")
    if not 0 <= args.port <= 65535:
        parser.error("--port must be between 0 (free local port) and 65535")
    if not re.fullmatch(r"[1-9][0-9]*x[1-9][0-9]*", args.resolution):
        parser.error("--resolution must be WIDTHxHEIGHT")
    root = Path(args.project).resolve()
    baseline_path = Path(args.baseline)
    baseline_path = baseline_path if baseline_path.is_absolute() else root / baseline_path
    baseline = load_json(baseline_path)
    if not baseline:
        raise RuntimeError("Missing valid protected roster baseline")
    engine_path = Path(shutil.which(args.godot) or args.godot).resolve()
    if not engine_path.is_file():
        raise RuntimeError("Godot engine not found")
    if "console" in engine_path.stem.lower():
        raise RuntimeError("Native two-window proof requires the direct GUI Godot executable, not the console launcher/wrapper")
    map_path = (root / args.map).resolve()
    if not map_path.is_relative_to(root / "maps") or not map_path.is_file():
        raise RuntimeError("Map must be an existing source-project maps file")
    output = Path(args.output)
    output = output if output.is_absolute() else root / output
    run_id = datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ") + "-" + uuid.uuid4().hex[:8]
    output = output / run_id
    output.mkdir(parents=True, exist_ok=False)
    report = {"schema": "sternenbuergerchen.source_multiplayer_pair.v1", "run_id": run_id,
              "mode": args.mode, "gate": "fail", "uses_release_exe": False,
              "headless": False, "fullscreen_requested": True,
              "native_gui_engine": True, "rendering_method_requested": "forward_plus", "rendering_driver_requested": "vulkan",
              "resolution_requested": args.resolution, "screen_requested": args.screen,
              "source_project": str(root), "output": str(output), "engine": str(engine_path),
              "harness_sha256": sha(Path(__file__).resolve()),
              "overlay_helper_sha256": sha(Path(__file__).resolve().with_name("run_review2_isolated.py")),
              "maximum_owned_runtime_seconds": args.timeout,
              "processes": {}, "traces": {}, "user_data": {}, "checks": {}, "failures": []}
    processes, streams, before_pins = {}, {}, {}
    started = time.monotonic()
    # Reserve 15 seconds for WM_CLOSE and the exact-owned-PID deadline fallback.
    deadline = started + args.timeout - 15.0
    map_text_hash = hashlib.sha256(map_path.read_text(encoding="utf-8-sig").encode("utf-8")).hexdigest()
    report["map"] = {"path": str(map_path), "raw_sha256": sha(map_path), "text_sha256": map_text_hash}
    try:
        report["roster_before"] = check_roster(baseline)
        version = subprocess.run([str(engine_path), "--version"], capture_output=True, text=True, encoding="utf-8", errors="replace", timeout=10, check=False)
        report["engine_version"] = version.stdout.strip()
        report["engine_sha256"] = sha(engine_path)
        if version.returncode != 0 or not report["engine_version"].startswith("4.6.2"):
            raise RuntimeError("This source proof requires the verified Godot 4.6.2 engine")
        before_pins = pins(root)
        (output / "source_pins_before.json").write_text(json.dumps(before_pins, indent=2), encoding="utf-8")
        with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
            probe.bind(("0.0.0.0", args.port))
            port = probe.getsockname()[1]
        report["port"] = port
        overlays = {}
        for role in ("host", "client"):
            project, app_name = create_overlay(root, run_id + "-" + role)
            user_dir = Path(os.environ["APPDATA"]) / "Godot/app_userdata" / app_name
            if user_dir.exists():
                raise RuntimeError("Refusing non-fresh user directory")
            # Persist only the normal display preference in this fresh private
            # QA profile; MainMenu deliberately applies its saved settings.
            user_dir.mkdir(parents=True)
            settings = user_dir / "sternenbuergerchen_settings.cfg"
            settings.write_text('[display]\nwindow_mode="fullscreen"\nresolution_preset="1920x1080"\n', encoding="utf-8")
            config = project / "project.godot"
            value = config.read_text(encoding="utf-8")
            value = value.replace('Review2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\n', 'Review2Isolation="*res://scripts/tests/review2_isolated_user_guard.gd"\nPlaytestNativeProbe="*res://scripts/tests/playtest_20261105_multiplayer_native_probe.gd"\n', 1)
            config.write_text(value, encoding="utf-8")
            overlays[role] = project
            report["user_data"][role] = {"path": str(user_dir), "project": str(project), "app_name": app_name}

        def launch(role: str) -> None:
            trace = output / (role + "_trace.json")
            log = output / (role + ".log")
            stdio = output / (role + "_stdio.log")
            user_args = ["--release-multiplayer-host" if role == "host" else "--release-multiplayer-join",
                         f"--release-multiplayer-port={port}", f"--release-multiplayer-trace={trace}"]
            user_args += [f"--qa-mp-probe={output / (role + '_display.json')}", f"--qa-mp-resolution={args.resolution}"]
            user_args += ["--release-multiplayer-auto-start"] if role == "host" else ["--release-multiplayer-address=127.0.0.1"]
            if args.mode == "drop":
                user_args.append("--release-multiplayer-drop-decision")
            argv = [str(engine_path), "--path", str(overlays[role]), "--fullscreen", "--resolution", args.resolution,
                    "--screen", str(args.screen), "--rendering-method", "forward_plus", "--rendering-driver", "vulkan",
                    "--log-file", str(log), "--", *user_args]
            env = dict(os.environ, SB_REVIEW2_USER_DIR=report["user_data"][role]["path"])
            streams[role] = stdio.open("w", encoding="utf-8")
            process = subprocess.Popen(argv, cwd=str(overlays[role]), env=env, stdin=subprocess.DEVNULL,
                                       stdout=streams[role], stderr=subprocess.STDOUT)
            processes[role] = process
            report["processes"][role] = {"pid": process.pid, "argv": argv, "log": str(log), "stdio": str(stdio), "trace": str(trace)}
            print(f"MULTIPLAYER_PAIR_LAUNCHED {role} pid={process.pid} port={port}", flush=True)

        launch("host")
        host_deadline = min(deadline, time.monotonic() + 60)
        while time.monotonic() < host_deadline:
            host_trace = load_json(output / "host_trace.json")
            if host_trace.get("session", {}).get("connection_state") == "hosting":
                break
            if processes["host"].poll() is not None:
                raise RuntimeError("Host exited before hosting")
            time.sleep(0.2)
        else:
            raise TimeoutError("Host did not reach hosting before its deadline")
        launch("client")
        previous_stage = ""
        while time.monotonic() < deadline:
            traces = {role: load_json(output / (role + "_trace.json")) for role in processes}
            checks = {role: verify_trace(trace, map_text_hash) for role, trace in traces.items()}
            report["traces"], report["trace_checks"] = traces, checks
            stage = " | ".join(f"{role}:{value['stage']} peers={value['connected_count']} ready={value['ready_count']}" for role, value in checks.items())
            if stage != previous_stage:
                print("MULTIPLAYER_PAIR_STATE " + stage, flush=True)
                previous_stage = stage
            connected = len(checks) == 2 and all(value["active_mission"] and value["connected_count"] == 2 and value["ready_count"] == 2 for value in checks.values())
            report["checks"]["connection_and_active_mission"] = connected
            entry_ok = connected and all(value["map_matches"] for value in checks.values())
            peer_ids = [value["peer_id"] for value in checks.values()]
            entry_ok = entry_ok and 1 in peer_ids and len(set(peer_ids)) == 2 and min(peer_ids) > 0
            mode_ok = all(value["stage"] == "mission_started" for value in checks.values())
            if connected and not all(value["map_matches"] for value in checks.values()):
                raise RuntimeError("Both peers reached mission but pinned GM01 manifest hash is missing or mismatched; shared-map acceptance is not proven")
            if args.mode == "drop" and entry_ok:
                decisions = [trace.get("drop_decision", {}) for trace in traces.values()]
                deployed = [set(value.get("deployed_unit_ids", [])) for value in decisions]
                mode_ok = all(value.get("stage") == "first_decision_accepted" and not value.get("embarked_unit_ids", []) for value in decisions)
                mode_ok = mode_ok and bool(deployed[0]) and deployed[0] == deployed[1]
            if entry_ok and mode_ok:
                report["checks"]["network_converged"] = True
                break
            if any(process.poll() is not None for process in processes.values()):
                raise RuntimeError("Owned process exited before multiplayer gate")
            time.sleep(0.25)
        else:
            raise TimeoutError("Two-process session did not converge within bounded run")
        for role, data in report["user_data"].items():
            (Path(data["path"]) / "qa_mp_capture_request").write_text("capture_native_mission\n", encoding="utf-8")
        capture_deadline = min(deadline, time.monotonic() + 8)
        while time.monotonic() < capture_deadline:
            if all(load_json(output / (role + "_display.json")).get("captured") and (output / (role + "_display_mission.png")).is_file() for role in processes):
                break
            time.sleep(0.1)
        report["native_display"] = {role: load_json(output / (role + "_display.json")) for role in processes}
        report["windows"] = {role: owned_windows(process.pid) for role, process in processes.items()}
        requested = list(map(int, args.resolution.split("x")))
        report["checks"]["native_capture_verified"] = len(report["native_display"]) == 2 and all(
            display.get("captured") and display.get("mode") in (3, 4)
            and display.get("window_size") == requested and display.get("time_scale") == 1.0
            and (output / (role + "_display_mission.png")).is_file()
            and (output / (role + "_display_mission.png")).stat().st_size > 0
            and png_dimensions(output / (role + "_display_mission.png")) == requested
            for role, display in report["native_display"].items())
        # Godot's Windows borderless-fullscreen HWND can overscan the monitor by
        # two pixels. Require complete coverage and a tight recorded bound;
        # the independent engine-mode/render-buffer/PNG gate remains exact.
        report["checks"]["native_fullscreen"] = len(report["windows"]) == 2 and all(any(
            window["covers_monitor"] and not window["minimized"]
            and all(0 <= value <= 4 for value in window["overscan_pixels"])
            for window in windows) for windows in report["windows"].values())
    except Exception as error:
        report["failures"].append(f"{type(error).__name__}: {error}")
    finally:
        report["session_wall_seconds"] = round(time.monotonic() - started, 3)
        report["cleanup"] = cleanup(processes, users=report.get("user_data"))
        for stream in streams.values():
            stream.close()
        report["checks"]["normal_owned_exit"] = len(processes) == 2 and all(action["exit_code"] == 0 and action["mode"] in ("already_exited", "normal_probe_exit", "wm_close_requested") for action in report["cleanup"].values())
        for role, data in report["user_data"].items():
            canary = load_json(Path(data["path"]) / "review2_isolation_canary.json")
            data["canary"] = canary
            data["verified"] = str(canary.get("user_dir", "")).replace("\\", "/").rstrip("/").lower() == data["path"].replace("\\", "/").rstrip("/").lower() and canary.get("project") == data["app_name"]
        report["checks"]["isolated_private_users"] = len(report["user_data"]) == 2 and all(data["verified"] for data in report["user_data"].values()) and len({data["path"] for data in report["user_data"].values()}) == 2
        report["diagnostics"] = {}
        for role in processes:
            combined = "\n".join((output / (role + suffix)).read_text(encoding="utf-8-sig", errors="replace") for suffix in (".log", "_stdio.log") if (output / (role + suffix)).is_file())
            clean = ANSI.sub("", combined)
            report["diagnostics"][role] = {"error_count": len(ERROR.findall(clean)), "renderer_lines": [line for line in clean.splitlines() if any(token in line for token in ("Vulkan", "OpenGL", "D3D12", "Rendering"))][:8]}
        report["checks"]["no_engine_diagnostics"] = len(processes) == 2 and all(data["error_count"] == 0 for data in report["diagnostics"].values())
        try:
            report["roster_after"] = check_roster(baseline)
            report["checks"]["protected_roster_unchanged"] = report.get("roster_before") == report["roster_after"]
        except Exception as error:
            report["failures"].append(str(error))
            report["checks"]["protected_roster_unchanged"] = False
        after_pins = pins(root)
        drift = [name for name in sorted(set(before_pins) | set(after_pins)) if before_pins.get(name) != after_pins.get(name)]
        report["source_pin_count"], report["source_drift"] = len(before_pins), drift
        report["checks"]["source_pins_stable"] = bool(before_pins) and not drift
        report["checks"]["engine_hash_stable"] = report.get("engine_sha256") == sha(engine_path)
        report["total_wall_seconds"] = round(time.monotonic() - started, 3)
        report["limitations"] = ["One Windows machine, two source processes over loopback; no LAN/WAN/multi-machine proof.", "Identical pinned GM01 only; no remote map payload transfer or build mismatch handshake proven.", "Native bounds establish fullscreen geometry; screenshots and human visual acceptance remain separate.", "Drop mode drives existing command adapters; no actor/position/HP/timer/loadout/authority patches."]
        report["gate"] = "pass" if not report["failures"] and report["checks"] and all(report["checks"].values()) else "fail"
        (output / "report.json").write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
        print("MULTIPLAYER_PAIR_" + report["gate"].upper(), flush=True)
        print("Report: " + str(output / "report.json"), flush=True)
    return 0 if report["gate"] == "pass" else 1


if __name__ == "__main__":
    raise SystemExit(main())

"""Run this dedicated visual QA script on a separate Windows desktop."""
import ctypes
from ctypes import wintypes
import os
from pathlib import Path
import subprocess
import sys
import uuid


def main() -> int:
    project_dir = Path(__file__).resolve().parent
    desktop_name = "TankerRender_" + uuid.uuid4().hex
    user32 = ctypes.WinDLL("user32", use_last_error=True)
    user32.CreateDesktopW.argtypes = (
        wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.LPVOID,
        wintypes.DWORD, wintypes.DWORD, wintypes.LPVOID,
    )
    user32.CreateDesktopW.restype = wintypes.HANDLE
    user32.CloseDesktop.argtypes = (wintypes.HANDLE,)
    desktop = user32.CreateDesktopW(desktop_name, None, None, 0, 0x10000000, None)
    if not desktop:
        raise ctypes.WinError(ctypes.get_last_error())

    try:
        startup = subprocess.STARTUPINFO()
        startup.lpDesktop = desktop_name
        startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
        startup.wShowWindow = subprocess.SW_HIDE
        profile = project_dir / "render_profile"
        profile.mkdir(exist_ok=True)
        environment = os.environ.copy()
        environment["APPDATA"] = str(profile)
        return subprocess.run(
            [
                sys.argv[1], "--path", str(project_dir),
                "--log-file", str(project_dir / "capture_engine.log"),
                "--resolution", "64x64", "--script", "res://capture.gd",
            ],
            check=False, cwd=project_dir, env=environment,
            startupinfo=startup, timeout=40,
        ).returncode
    finally:
        user32.CloseDesktop(desktop)


if __name__ == "__main__":
    sys.exit(main())

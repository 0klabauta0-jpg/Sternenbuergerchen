import ctypes, os, subprocess, sys, uuid
from ctypes import wintypes

user32 = ctypes.WinDLL('user32', use_last_error=True)
user32.CreateDesktopW.argtypes = (wintypes.LPCWSTR, wintypes.LPCWSTR, wintypes.LPVOID, wintypes.DWORD, wintypes.DWORD, wintypes.LPVOID)
user32.CreateDesktopW.restype = wintypes.HANDLE
user32.CloseDesktop.argtypes = (wintypes.HANDLE,)
name = 'CodexRender_' + uuid.uuid4().hex
desktop = user32.CreateDesktopW(name, None, None, 0, 0x10000000, None)
if not desktop:
    raise ctypes.WinError(ctypes.get_last_error())
si = subprocess.STARTUPINFO()
si.lpDesktop = name
si.dwFlags |= subprocess.STARTF_USESHOWWINDOW
si.wShowWindow = subprocess.SW_HIDE
env = os.environ.copy()
env['APPDATA'] = os.path.abspath('output/hidden_visual_profile')
env['POLISA_TEST_PROFILE'] = env['APPDATA']
os.makedirs(env['APPDATA'], exist_ok=True)
args = ['C:/Users/bjoer/AppData/Local/Microsoft/WinGet/Links/godot_console.exe', '--path', '.', '--rendering-method', 'gl_compatibility', '--resolution', '1280x720', '--script', sys.argv[1]]
try:
    p = subprocess.run(args, startupinfo=si, env=env, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, timeout=300)
    print(p.stdout)
    sys.exit(p.returncode)
finally:
    user32.CloseDesktop(desktop)

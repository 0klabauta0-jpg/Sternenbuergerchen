param(
    [string]$Script='',
    [string]$Executable='',
    [string]$SourceRoot='',
    [string]$ProjectPath='',
    [string]$MainPack='',
    [string]$EvidenceRoot='',
    [string]$ProfileRoot='',
    [Parameter(Mandatory=$true)][string]$Label,
    [int]$TimeoutSeconds=180
)
$ErrorActionPreference = 'Stop'
if (-not $SourceRoot) { $SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot '../../../..')).Path }
$projectRoot = (Resolve-Path -LiteralPath $SourceRoot).Path
if (-not $ProjectPath) { $ProjectPath = $projectRoot }
if (-not $EvidenceRoot) { $EvidenceRoot = Join-Path $projectRoot 'docs/qa/campaign_replace_crash_20261110/raw' }
if (-not $ProfileRoot) { $ProfileRoot = Join-Path $projectRoot 'output/campaign_replace_crash_20261110/profiles' }
$profile = Join-Path $ProfileRoot $Label
New-Item -ItemType Directory -Path $evidenceRoot,$profile -Force | Out-Null
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.Threading;
public static class HiddenGodotParent {
 [StructLayout(LayoutKind.Sequential)] struct Point {public int x;public int y;}
 [StructLayout(LayoutKind.Sequential)] struct Msg {public IntPtr hwnd;public uint message;public UIntPtr wParam;public IntPtr lParam;public uint time;public Point pt;public uint priv;}
 [DllImport("user32.dll",CharSet=CharSet.Unicode,SetLastError=true)] static extern IntPtr CreateWindowEx(uint ex,string cls,string title,uint style,int x,int y,int w,int h,IntPtr parent,IntPtr menu,IntPtr instance,IntPtr param);
 [DllImport("user32.dll")] static extern bool DestroyWindow(IntPtr h);
 [DllImport("user32.dll")] static extern bool PeekMessage(out Msg m,IntPtr h,uint min,uint max,uint remove);
 [DllImport("user32.dll")] static extern bool TranslateMessage(ref Msg m);
 [DllImport("user32.dll")] static extern IntPtr DispatchMessage(ref Msg m);
 [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
 [DllImport("kernel32.dll")] public static extern uint SetErrorMode(uint mode);
 static Thread thread;static volatile bool stop;static IntPtr handle;static Exception failure;
 public static IntPtr Start() {
  var ready=new ManualResetEventSlim(false);
  thread=new Thread(()=>{try {
   handle=CreateWindowEx(0x08000080,"STATIC","Hidden Godot GPU probe",0x86000000,-32000,-32000,1280,720,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero,IntPtr.Zero);
   if(handle==IntPtr.Zero)throw new Exception("CreateWindowEx failed: "+Marshal.GetLastWin32Error());
   ready.Set();
   while(!stop){Msg m;while(PeekMessage(out m,IntPtr.Zero,0,0,1)){TranslateMessage(ref m);DispatchMessage(ref m);}Thread.Sleep(2);}
  }catch(Exception e){failure=e;ready.Set();}finally{if(handle!=IntPtr.Zero)DestroyWindow(handle);}});
  thread.IsBackground=true;thread.SetApartmentState(ApartmentState.STA);thread.Start();ready.Wait();
  if(failure!=null)throw failure;return handle;
 }
 public static void Stop(){stop=true;if(thread!=null)thread.Join(3000);}
}
'@
$parentHandle = [HiddenGodotParent]::Start()
$oldErrorMode = [HiddenGodotParent]::SetErrorMode(0x8003)
try {
    if ([HiddenGodotParent]::IsWindowVisible($parentHandle)) { throw 'GPU host must stay hidden' }
    $info=[System.Diagnostics.ProcessStartInfo]::new()
    $info.FileName=if($Executable){$Executable}else{(Get-Command godot_console.exe).Source}
    $info.WorkingDirectory=if($Executable){Split-Path -Parent $Executable}else{$ProjectPath}
    $info.UseShellExecute=$false
    $info.CreateNoWindow=$true
    $info.WindowStyle=[System.Diagnostics.ProcessWindowStyle]::Hidden
    $info.RedirectStandardOutput=$true
    $info.RedirectStandardError=$true
    $info.Environment['APPDATA']=$profile
    if($MainPack){$info.Environment['PACKAGE_PROBE_ROOT']=$ProjectPath}
    $arguments=@('--display-driver','windows','--rendering-driver','d3d12','--rendering-method','forward_plus','--audio-driver','Dummy','--single-window','--resolution','1280x720','--wid',$parentHandle.ToInt64().ToString())
    if($Executable){$arguments+=@('--quit-after','240','--','--release-singleplayer')}
    else {
        $arguments+=@('--path',$ProjectPath)
        if($MainPack){$arguments+=@('--main-pack',$MainPack)}
        $arguments+=@('--script',$Script,'--','continue-chapter','1x')
    }
    foreach($argument in $arguments) {$info.ArgumentList.Add($argument)}
    $process=[System.Diagnostics.Process]::Start($info)
    try {$process.PriorityClass=[System.Diagnostics.ProcessPriorityClass]::BelowNormal}catch{}
    $stdout=$process.StandardOutput.ReadToEndAsync()
    $stderr=$process.StandardError.ReadToEndAsync()
    $finished=$process.WaitForExit($TimeoutSeconds*1000)
    if(-not $finished){$process.Kill($true);$process.WaitForExit()}
    $log=$stdout.GetAwaiter().GetResult()+$stderr.GetAwaiter().GetResult()
    [System.IO.File]::WriteAllText((Join-Path $evidenceRoot ($Label+'.log')),$log)
    $result=[ordered]@{label=$Label;exit_code=$(if($finished){$process.ExitCode}else{-1});errors=[regex]::Matches($log,'(?m)^(?:SCRIPT ERROR|ERROR:|FAIL:)').Count;warnings=[regex]::Matches($log,'(?m)^WARNING:').Count;hidden_parent_visible=[HiddenGodotParent]::IsWindowVisible($parentHandle);profile=$profile;arguments=@($info.ArgumentList)}
    $result|ConvertTo-Json -Depth 4|Set-Content -LiteralPath (Join-Path $evidenceRoot ($Label+'.json')) -Encoding utf8
    $process.Dispose()
    Write-Output ($result|ConvertTo-Json -Depth 4 -Compress)
    if ($result.exit_code -ne 0 -or $result.errors -ne 0 -or $result.hidden_parent_visible) {exit 1}
} finally {
    [void][HiddenGodotParent]::SetErrorMode($oldErrorMode)
    [HiddenGodotParent]::Stop()
}

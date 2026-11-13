param([int]$OwnerPid)
Add-Type -Namespace ReviewSession -Name Power -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("kernel32.dll", SetLastError = true)]
public static extern uint SetThreadExecutionState(uint flags);
'@
$ErrorActionPreference = 'Stop'
try {
    while (Get-Process -Id $OwnerPid -ErrorAction SilentlyContinue) {
        $result = [ReviewSession.Power]::SetThreadExecutionState([uint32]2147483649)
        if ($result -eq 0) { throw 'SetThreadExecutionState failed' }
        Set-Content -LiteralPath (Join-Path $PSScriptRoot 'keep_awake_status.json') -Value (@{
            process_id = $PID
            owner_process_id = $OwnerPid
            system_required = $true
            heartbeat_utc = [DateTime]::UtcNow.ToString('o')
        } | ConvertTo-Json)
        Start-Sleep -Seconds 30
    }
} finally {
    [void][ReviewSession.Power]::SetThreadExecutionState([uint32]2147483648)
}

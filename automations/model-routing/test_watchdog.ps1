<#
  Offline liveness watchdog tests for watchdog.ps1 (Spec 0012, updated 17/11/26).
  Run: powershell -NoProfile -ExecutionPolicy Bypass -File automations/model-routing/test_watchdog.ps1
  Exit 0 = all pass, 1 = any failure.
#>
$ErrorActionPreference = 'Stop'
. (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'watchdog.ps1')

$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("wd-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $Tmp | Out-Null
$Repo = Join-Path $Tmp 'repo'
New-Item -ItemType Directory -Path $Repo | Out-Null
& git -C $Repo init -q 2>$null
$script:Failures = 0

function Start-Fake([string]$Script) {
    $f = Join-Path $Tmp ("fake-" + [guid]::NewGuid().ToString('N').Substring(0, 6) + ".ps1")
    Set-Content -Path $f -Value $Script -Encoding UTF8
    $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$f`"" -PassThru -WindowStyle Hidden
    $null = $p.Handle
    return $p
}
function Check([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name :: $Detail"; $script:Failures++ }
}
function Alive([int]$Id) { return [bool](Get-Process -Id $Id -ErrorAction SilentlyContinue) }
function Gone([string]$Pattern) {
    for ($i = 0; $i -lt 20; $i++) {
        $left = @(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $PID -and ([string]$_.CommandLine) -match $Pattern })
        if ($left.Count -eq 0) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

try {
    # 1. Silent process, no log, no CPU, no workspace edits -> stalled after DeadAfterSec.
    $p = Start-Fake 'Start-Sleep 600'
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -LogFile (Join-Path $Tmp 'none.log') -PollSec 1
    Check 'idle process is stalled' ($r.outcome -eq 'stalled' -and $r.reason -match 'no liveness') "$($r.outcome) $($r.reason)"
    Start-Sleep 1; Check 'idle process is killed' (-not (Alive $p.Id)) "pid $($p.Id) alive"

    # 2. Sleeping child does NOT fake liveness -> tree dies on DeadAfterSec.
    $marker = "wdchild" + (Get-Random)
    $p = Start-Fake "Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''$marker''; Start-Sleep 600`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 4 -PollSec 1 -StartupGraceSec 1
    Check 'sleeping child stalls after dead_after_sec' ($r.outcome -eq 'stalled') "$($r.outcome) $($r.reason)"
    Check 'sleeping child tree killed' (Gone $marker) 'child left alive'

    # 3. MCP server and startup-window server are ignored for liveness, then killed on stall.
    $p = Start-Fake "Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''fake-mcp-server''; while(`$true){`$k++}`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -PollSec 1 -StartupGraceSec 0
    Check 'busy MCP child ignored for liveness' ($r.outcome -eq 'stalled') "$($r.outcome) $($r.reason)"
    Check 'MCP child killed too' (Gone 'fake-mcp-server') 'left alive'

    $p = Start-Fake "Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''fake-seq-thinking''; while(`$true){`$k++}`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -PollSec 1 -StartupGraceSec 10
    Check 'startup-window server ignored' ($r.outcome -eq 'stalled') "$($r.outcome) $($r.reason)"
    Check 'startup-window server killed' (Gone 'fake-seq-thinking') 'left alive'

    # 4. Log writes alone keep a run alive past DeadAfterSec and finish cleanly.
    $log = Join-Path $Tmp 'busy.log'
    $p = Start-Fake "for (`$i = 0; `$i -lt 6; `$i++) { Add-Content -Path '$log' -Value `$i; Start-Sleep 1 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -LogFile $log -PollSec 1
    Check 'log activity keeps process alive across 6s (>3s dead_after)' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    # 5. Rewriting the same workspace file OR writing new files in non-git dir counts as liveness.
    $f = Join-Path $Repo 'work.txt'
    $p = Start-Fake "for (`$i = 0; `$i -lt 6; `$i++) { Set-Content -Path '$f' -Value `$i; Start-Sleep 1 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -WorkDir $Repo -PollSec 1
    Check 'git workspace edits keep process alive' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    $Plain = Join-Path $Tmp 'plain'
    New-Item -ItemType Directory -Path $Plain | Out-Null
    $p = Start-Fake "for (`$i = 0; `$i -lt 6; `$i++) { Set-Content -Path (Join-Path '$Plain' (`"b`$i.json`")) -Value `$i; Start-Sleep 1 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -DeadAfterSec 3 -ProgressDir $Plain -PollSec 1
    Check 'non-git ProgressDir writes keep process alive' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    # 6. Hard ceiling (MaxRunSec) kills even an active run.
    $p = Start-Fake "while (`$true) { Add-Content -Path '$log' -Value (Get-Date); Start-Sleep -Milliseconds 500 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -MaxRunSec 4 -DeadAfterSec 30 -LogFile $log -PollSec 1
    Check 'hard ceiling kills active run' ($r.outcome -eq 'timeout' -and $r.reason -match 'max ceiling') "$($r.outcome) $($r.reason)"
    Start-Sleep 1; Check 'ceiling-killed process gone' (-not (Alive $p.Id)) "pid $($p.Id) alive"
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

if ($script:Failures -gt 0) { Write-Host "$($script:Failures) failure(s)"; exit 1 }
Write-Host 'ALL PASS'
exit 0

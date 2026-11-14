<#
  Offline tests for watchdog.ps1 (no agy, no network). Fake "agy" processes are plain
  PowerShell children. Run: powershell -NoProfile -ExecutionPolicy Bypass -File automations/model-routing/test_watchdog.ps1
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
# taskkill returns before the tree is gone; wait up to 10 s for the pattern to disappear.
function Gone([string]$Pattern) {
    for ($i = 0; $i -lt 20; $i++) {
        $left = @(Get-CimInstance Win32_Process | Where-Object { $_.ProcessId -ne $PID -and ([string]$_.CommandLine) -match $Pattern })
        if ($left.Count -eq 0) { return $true }
        Start-Sleep -Milliseconds 500
    }
    return $false
}

try {
    # 1. Silent process, no log, no children -> stalled on log idle, and killed.
    $p = Start-Fake 'Start-Sleep 600'
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile (Join-Path $Tmp 'none.log') -LogIdleSec 3 -PollSec 1
    Check 'idle process is stalled' ($r.outcome -eq 'stalled' -and $r.reason -match 'log idle') "$($r.outcome) $($r.reason)"
    Start-Sleep 1; Check 'idle process is killed' (-not (Alive $p.Id)) "pid $($p.Id) alive"

    # 2. A long-running command is work, until ChildMaxSec; then the whole tree dies.
    $marker = "wdchild" + (Get-Random)
    $p = Start-Fake "Start-Sleep 2; Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''$marker''; Start-Sleep 600`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile '' -LogIdleSec 4 -ChildMaxSec 8 -PollSec 1 -StartupGraceSec 1
    Check 'busy child blocks idle stall, then ChildMaxSec stalls' ($r.outcome -eq 'stalled' -and $r.reason -match 'command has run over') "$($r.outcome) $($r.reason)"
    Check 'child tree killed with parent' (Gone $marker) 'child left alive'

    # 3. A child whose command line says mcp is not work: idle stall still fires.
    $p = Start-Fake "Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''fake-mcp-server''; Start-Sleep 600`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile '' -LogIdleSec 3 -ChildMaxSec 60 -PollSec 1 -StartupGraceSec 0
    Check 'MCP child ignored' ($r.outcome -eq 'stalled' -and $r.reason -match 'log idle') "$($r.outcome) $($r.reason)"
    Check 'MCP child killed too' (Gone 'fake-mcp-server') 'left alive'

    # 3b. A server started in agy's startup window, with no "mcp" in its command line
    #     (sequential-thinking, 24/09/26), is infrastructure: idle stall still fires.
    $p = Start-Fake "Start-Process powershell -ArgumentList '-NoProfile -Command `"`$x=''fake-seq-thinking''; Start-Sleep 600`"' -WindowStyle Hidden; Start-Sleep 600"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile '' -LogIdleSec 4 -ChildMaxSec 60 -PollSec 1 -StartupGraceSec 10
    Check 'startup-window server ignored' ($r.outcome -eq 'stalled' -and $r.reason -match 'log idle') "$($r.outcome) $($r.reason)"
    Check 'startup-window server killed' (Gone 'fake-seq-thinking') 'left alive'

    # 4. Log keeps moving but the workspace never changes -> no-progress stall (executor).
    $log = Join-Path $Tmp 'busy.log'
    $p = Start-Fake "while (`$true) { Add-Content -Path '$log' -Value (Get-Date); Start-Sleep -Milliseconds 500 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile $log -LogIdleSec 30 -WorkDir $Repo -NoProgressSec 4 -PollSec 1
    Check 'chatty log without file changes is stalled' ($r.outcome -eq 'stalled' -and $r.reason -match 'no workspace change') "$($r.outcome) $($r.reason)"

    # 5. Rewriting the SAME file counts as progress; a process that finishes returns 'exited'.
    $f = Join-Path $Repo 'work.txt'
    $p = Start-Fake "for (`$i = 0; `$i -lt 8; `$i++) { Set-Content -Path '$f' -Value `$i; Add-Content -Path '$log' -Value `$i; Start-Sleep 1 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile $log -LogIdleSec 30 -WorkDir $Repo -NoProgressSec 3 -PollSec 1
    Check 'steady edits to one file are progress; clean exit' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    # 5b. Outside a git worktree (13/10/26: a Drive client folder was killed as "no workspace
    #     change" while it was writing a new file every few minutes): new files are progress.
    $Plain = Join-Path $Tmp 'plain'
    New-Item -ItemType Directory -Path $Plain | Out-Null
    $p = Start-Fake "for (`$i = 0; `$i -lt 8; `$i++) { Set-Content -Path (Join-Path '$Plain' (`"b`$i.json`")) -Value `$i; Add-Content -Path '$log' -Value `$i; Start-Sleep 1 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile $log -LogIdleSec 30 -WorkDir $Plain -NoProgressSec 3 -PollSec 1
    Check 'non-git dir: new files are progress; clean exit' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    # 5c. ...and a non-git dir that never changes still stalls.
    $p = Start-Fake "while (`$true) { Add-Content -Path '$log' -Value (Get-Date); Start-Sleep -Milliseconds 500 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 60 -LogFile $log -LogIdleSec 30 -WorkDir $Plain -NoProgressSec 4 -PollSec 1
    Check 'non-git dir without changes is stalled' ($r.outcome -eq 'stalled' -and $r.reason -match 'no workspace change') "$($r.outcome) $($r.reason)"

    # 6. Total timeout still applies to a busy run, and kills it.
    $p = Start-Fake "while (`$true) { Add-Content -Path '$log' -Value (Get-Date); Start-Sleep -Milliseconds 500 }"
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 4 -LogFile $log -LogIdleSec 30 -PollSec 1
    Check 'total timeout' ($r.outcome -eq 'timeout') "$($r.outcome) $($r.reason)"
    Start-Sleep 1; Check 'timed-out process killed' (-not (Alive $p.Id)) "pid $($p.Id) alive"
}
finally {
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

if ($script:Failures -gt 0) { Write-Host "$script:Failures failure(s)"; exit 1 }
Write-Host 'ALL PASS'
exit 0

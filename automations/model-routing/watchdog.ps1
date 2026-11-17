<#
  Liveness watchdog for agy runs, dot-sourced by agy-route.ps1 (Spec 0012, 17/11/26).

  Replaces fixed wall-clock kills (child_max_sec 900, log_idle_sec 300) with liveness
  tracking. A long test suite, ffmpeg render, or hyperframes compile runs safely as
  long as ANY liveness signal moves within DeadAfterSec (600s default), up to the
  4-hour MaxRunSec (14400s) hard safety ceiling:
    1. AgyLog write: LogFile size or LastWriteTimeUtc advances.
    2. Process CPU work: parent or non-MCP busy descendant process CPU advances (>0.05s).
    3. Workspace progress: edited/new file timestamp under WorkDir/ProgressDir advances.

  MCP servers and startup-window servers (within StartupGraceSec) are excluded from the
  child-work filter so an idle background MCP server never fakes liveness for a frozen agent.
#>

function Get-DescendantProcesses {
    param([int]$RootId)
    $all = @(Get-CimInstance Win32_Process -ErrorAction SilentlyContinue)
    $out = @()
    $frontier = @($RootId)
    while ($frontier.Count -gt 0) {
        $next = @()
        foreach ($id in $frontier) {
            foreach ($c in $all) {
                if ($c.ParentProcessId -eq $id -and $c.ProcessId -ne $id) { $out += $c; $next += $c.ProcessId }
            }
        }
        $frontier = $next
    }
    return $out
}

function Get-BusyChildren {
    param([int]$RootId, [datetime]$InfraBefore = [datetime]::MinValue)
    return @(Get-DescendantProcesses -RootId $RootId | Where-Object {
        $cl = [string]$_.CommandLine
        $_.Name -ne 'conhost.exe' -and
        $cl -notmatch '(?i)mcp|modelcontextprotocol' -and
        (-not $_.CreationDate -or $_.CreationDate -ge $InfraBefore)
    })
}

function Get-WorkspaceProgressStamp {
    param([string]$Dir)
    if (-not $Dir -or -not (Test-Path $Dir)) { return '' }
    try {
        $eap = $ErrorActionPreference
        $ErrorActionPreference = 'SilentlyContinue'
        $null = & git -C $Dir rev-parse --is-inside-work-tree 2>$null
        $isRepo = ($LASTEXITCODE -eq 0)
        $ErrorActionPreference = $eap
        if (-not $isRepo) {
            $files = @(Get-ChildItem -LiteralPath $Dir -File -Recurse -Force -ErrorAction SilentlyContinue)
            $newestFs = 0
            foreach ($f in $files) { if ($f.LastWriteTimeUtc.Ticks -gt $newestFs) { $newestFs = $f.LastWriteTimeUtc.Ticks } }
            return "fs|$($files.Count)|$newestFs"
        }
        $lines = @(& git -C $Dir status --porcelain -uall 2>$null)
        $newest = 0
        foreach ($l in $lines) {
            if ($l.Length -lt 4) { continue }
            $rel = $l.Substring(3).Trim('"')
            if ($rel -match ' -> ') { $rel = ($rel -split ' -> ')[-1] }
            $full = Join-Path $Dir $rel
            if (Test-Path -LiteralPath $full -PathType Leaf) {
                $t = (Get-Item -LiteralPath $full).LastWriteTimeUtc.Ticks
                if ($t -gt $newest) { $newest = $t }
            }
        }
        return (($lines -join "`n") + "|$newest")
    } catch { return '' }
}

function Stop-ProcessTree {
    param([int]$RootId)
    & taskkill.exe /T /F /PID $RootId 2>&1 | Out-Null
}

function Wait-ProcessWithWatchdog {
    <#  Returns @{ outcome = 'exited' | 'timeout' | 'stalled'; reason = <text> }  #>
    param(
        [Parameter(Mandatory = $true)] [System.Diagnostics.Process]$Process,
        [int]$TotalTimeoutSec = 14400,
        [int]$MaxRunSec = 14400,
        [int]$DeadAfterSec = 600,
        [string]$LogFile = '',
        [string]$WorkDir = '',
        [string]$ProgressDir = '',
        [int]$PollSec = 30,
        [int]$StartupGraceSec = 30,
        [scriptblock]$Log = { param($m) }
    )
    $start = Get-Date
    $ceiling = [Math]::Min($TotalTimeoutSec, $MaxRunSec)
    $infraBefore = $Process.StartTime.AddSeconds($StartupGraceSec)
    $lastAlive = $start
    $lastReason = 'startup'

    $prevLogLen = -1L
    $prevLogTicks = 0L
    $perPidCpu = @{}
    $watchDir = if ($ProgressDir) { $ProgressDir } else { $WorkDir }
    $stamp = if ($watchDir) { Get-WorkspaceProgressStamp -Dir $watchDir } else { '' }

    # Seed baseline CPU for the root process so idle launch ticks alone do not look like work later
    try {
        $rp = Get-Process -Id $Process.Id -ErrorAction SilentlyContinue
        if ($rp) { $perPidCpu[$Process.Id] = [double]$rp.TotalProcessorTime.TotalSeconds }
    } catch { }

    while ($true) {
        if ($Process.WaitForExit($PollSec * 1000)) { return @{ outcome = 'exited'; reason = '' } }
        $now = Get-Date
        $elapsed = ($now - $start).TotalSeconds

        if ($elapsed -ge $ceiling) {
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'timeout'; reason = "max ceiling ${ceiling}s reached" }
        }

        $aliveThisSample = $false
        $busy = @(Get-BusyChildren -RootId $Process.Id -InfraBefore $infraBefore)

        # Signal 1: -agy.log file size or mtime advanced
        if ($LogFile -and (Test-Path -LiteralPath $LogFile)) {
            $item = Get-Item -LiteralPath $LogFile -ErrorAction SilentlyContinue
            if ($item) {
                $len = [long]$item.Length
                $ticks = [long]$item.LastWriteTimeUtc.Ticks
                if ($len -ne $prevLogLen -or $ticks -ne $prevLogTicks) {
                    $prevLogLen = $len
                    $prevLogTicks = $ticks
                    $aliveThisSample = $true
                    $lastReason = 'log'
                }
            }
        }

        # Signal 2: CPU delta > 0.05s across parent + non-MCP busy descendants
        $checkIds = @([int]$Process.Id)
        foreach ($b in $busy) { if ($b.ProcessId -and ($checkIds -notcontains [int]$b.ProcessId)) { $checkIds += [int]$b.ProcessId } }
        $totalCpuDelta = 0.0
        foreach ($cid in $checkIds) {
            $proc = Get-Process -Id $cid -ErrorAction SilentlyContinue
            if (-not $proc) { continue }
            $cpuNow = 0.0
            try { $cpuNow = [double]$proc.TotalProcessorTime.TotalSeconds } catch { continue }
            $prevCpu = if ($perPidCpu.ContainsKey($cid)) { [double]$perPidCpu[$cid] } else { 0.0 }
            $delta = $cpuNow - $prevCpu
            $perPidCpu[$cid] = $cpuNow
            if ($delta -gt 0.05) { $totalCpuDelta += $delta }
        }
        if ($totalCpuDelta -gt 0.05) {
            $aliveThisSample = $true
            $lastReason = 'cpu'
        }

        # Signal 3: Workspace / progress dir change
        if ($watchDir) {
            $s = Get-WorkspaceProgressStamp -Dir $watchDir
            if ($s -ne $stamp) {
                $stamp = $s
                $aliveThisSample = $true
                $lastReason = 'workspace'
            }
        }

        if ($aliveThisSample) { $lastAlive = $now }
        $deadFor = ($now - $lastAlive).TotalSeconds

        if ($deadFor -ge $DeadAfterSec) {
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'stalled'; reason = ("no liveness for {0:N0}s (dead_after={1}s, last={2})" -f $deadFor, $DeadAfterSec, $lastReason) }
        }
        & $Log ("  watchdog: t+{0:N0}s dead_idle={1:N0}s/{2}s cpu_d={3:N2}s busy_children={4} last={5}" -f $elapsed, $deadFor, $DeadAfterSec, $totalCpuDelta, $busy.Count, $lastReason)
    }
}

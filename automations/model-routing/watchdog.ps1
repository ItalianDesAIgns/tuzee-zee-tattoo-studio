<#
  Stall watchdog for agy runs, dot-sourced by agy-route.ps1.

  Why (Rasta, 24/09/26): two executor runs in two days sat for 15+ minutes with no output and
  were found only because a human asked. A total timeout alone (30 min) is too slow to catch a
  hang, and a check that depends on the Architect remembering to arm it is not enforcement.
  This polls the running agy process and kills it when it stops making progress.

  A run is STALLED when no command is running under agy (MCP servers excluded) and either
    - agy's own log has not been written for LogIdleSec (hung on a model call or a tool), or
    - (executor only) the workspace has not changed for NoProgressSec (thinking in circles).
  A command running under agy counts as work, but only up to ChildMaxSec: a child that runs
  longer than that is itself treated as the stall (a hung pip-audit inside preflight, 23/09/26).

  Limit: the workspace check reads `git status`, so edits made by another agent in the same
  tree at the same time look like progress. The log and child checks still hold. Outside a git
  worktree it falls back to the newest file write under the directory; pass a narrow
  -ProgressDir to agy-route.ps1 so that scan stays cheap on a large folder.
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
    # MCP servers live for the whole run and are not work; conhost is plumbing. agy starts its
    # MCP servers in its first seconds, and not every one says "mcp" on its command line
    # (@modelcontextprotocol/server-sequential-thinking does not; found live 24/09/26, when it
    # masked idleness and would have tripped ChildMaxSec on a healthy run). So anything born in
    # the startup window counts as infrastructure, as does anything naming MCP.
    param([int]$RootId, [datetime]$InfraBefore = [datetime]::MinValue)
    return @(Get-DescendantProcesses -RootId $RootId | Where-Object {
        $cl = [string]$_.CommandLine
        $_.Name -ne 'conhost.exe' -and
        $cl -notmatch '(?i)mcp|modelcontextprotocol' -and
        (-not $_.CreationDate -or $_.CreationDate -ge $InfraBefore)
    })
}

function Get-WorkspaceProgressStamp {
    # Changes whenever a file is created, deleted or rewritten, including a second edit to a
    # file that git already shows as modified (the porcelain text alone would not change).
    param([string]$Dir)
    if (-not $Dir -or -not (Test-Path $Dir)) { return '' }
    try {
        # Not a git worktree (a client folder on Drive, 13/10/26): git status prints nothing, so
        # the stamp never changed and a healthy run was killed as "no workspace change". Fall
        # back to the newest file write anywhere under the directory, plus the file count.
        # PS 5.1 with ErrorActionPreference=Stop turns git's "fatal: not a git repository" on
        # stderr into a terminating error even with 2>$null, so relax it for this one probe.
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
    # Process.Kill() leaves children alive (a preflight started by agy kept running after its
    # parent died). taskkill /T takes the whole tree.
    & taskkill.exe /T /F /PID $RootId 2>&1 | Out-Null
}

function Wait-ProcessWithWatchdog {
    <#  Returns @{ outcome = 'exited' | 'timeout' | 'stalled'; reason = <text> }  #>
    param(
        [Parameter(Mandatory = $true)] [System.Diagnostics.Process]$Process,
        [int]$TotalTimeoutSec = 1800,
        [string]$LogFile = '',
        [int]$LogIdleSec = 300,
        [string]$WorkDir = '',
        [int]$NoProgressSec = 0,          # 0 = workspace check off (read-only roles)
        [int]$ChildMaxSec = 900,
        [int]$PollSec = 15,
        [int]$StartupGraceSec = 30,
        [scriptblock]$Log = { param($m) }
    )
    $start = Get-Date
    $infraBefore = $Process.StartTime.AddSeconds($StartupGraceSec)
    $lastProgress = Get-Date
    $stamp = ''
    if ($NoProgressSec -gt 0) { $stamp = Get-WorkspaceProgressStamp -Dir $WorkDir }

    while ($true) {
        if ($Process.WaitForExit($PollSec * 1000)) { return @{ outcome = 'exited'; reason = '' } }
        $now = Get-Date
        $elapsed = ($now - $start).TotalSeconds

        if ($elapsed -ge $TotalTimeoutSec) {
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'timeout'; reason = "total timeout ${TotalTimeoutSec}s reached" }
        }

        $busy = @(Get-BusyChildren -RootId $Process.Id -InfraBefore $infraBefore)
        $oldest = $null
        foreach ($b in $busy) { if ($b.CreationDate -and (-not $oldest -or $b.CreationDate -lt $oldest.CreationDate)) { $oldest = $b } }
        if ($oldest -and (($now - $oldest.CreationDate).TotalSeconds -ge $ChildMaxSec)) {
            $cl = [string]$oldest.CommandLine
            $cl = $cl.Substring(0, [Math]::Min(160, $cl.Length))
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'stalled'; reason = "a command has run over ${ChildMaxSec}s: $cl" }
        }

        if ($NoProgressSec -gt 0) {
            $s = Get-WorkspaceProgressStamp -Dir $WorkDir
            if ($s -ne $stamp) { $stamp = $s; $lastProgress = $now }
        }
        # A running command is work: it resets the no-progress clock (a 10 min preflight must
        # not trip it the moment it ends). ChildMaxSec above bounds a hung command.
        if ($busy.Count -gt 0) { $lastProgress = $now; continue }

        if ($LogFile -and (Test-Path -LiteralPath $LogFile)) {
            $idle = ($now - (Get-Item -LiteralPath $LogFile).LastWriteTime).TotalSeconds
        } else {
            $idle = $elapsed    # no log yet: idle since launch
        }
        if ($idle -ge $LogIdleSec) {
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'stalled'; reason = ("agy log idle {0:N0}s with no command running" -f $idle) }
        }
        if ($NoProgressSec -gt 0 -and (($now - $lastProgress).TotalSeconds -ge $NoProgressSec)) {
            Stop-ProcessTree -RootId $Process.Id
            return @{ outcome = 'stalled'; reason = "no workspace change for ${NoProgressSec}s with no command running" }
        }
        & $Log ("  watchdog: t+{0:N0}s log_idle={1:N0}s busy_children={2}" -f $elapsed, $idle, $busy.Count)
    }
}

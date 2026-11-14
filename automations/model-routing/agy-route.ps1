<#
.SYNOPSIS
  Model router for the Antigravity CLI (agy). Resolves a model from role + policy + runtime
  state, invokes agy non-interactively, and emits exactly one JSON object on stdout.

.DESCRIPTION
  Task 0018. Windows PowerShell 5.1 only (A7: pwsh 7+ is not installed on this machine).
  Emits ONE JSON object on stdout and nothing else; all human-readable output goes to the log.

  Design decisions this implements (Architect review 2, 27/07/26):
    D1  two-tier MCP health check - free static config read every run, live probe rate-limited
    D2  role-differentiated permissions - executor skips prompts, verifier/scout stay read-only
    D3  fail-closed quota matcher - inferred signals only, unknown failures never blacklist
    D4  spec passed BY REFERENCE - cmd line caps at 8191 chars, specs are far larger

  Phase E findings that shape the error model:
    A14 Start-Process with a SINGLE quoted argument string; -ArgumentList as an array does not
        quote elements containing spaces in PS 5.1 and silently mangles the prompt.
        $p.Handle must be read before WaitForExit or $p.ExitCode comes back empty.
    A15 CORRECTED 27/07/26 - the original reading was wrong and cost the verifier rung.
        Permissions are WORKSPACE-SCOPED, not write-scoped: a read INSIDE --add-dir is
        allowed, the same read OUTSIDE it is auto-denied, and command execution is denied
        outright. So the read-only rung was not "free", it was mute - it could not read a
        spec outside WorkDir and could not run a single test. See D5 and defects 5-7.
    A16 An auto-denied run still exits 0. EXIT CODE ALONE IS NOT A SUCCESS SIGNAL.

.EXAMPLE
  .\agy-route.ps1 -Role executor -Spec <abs path of a spec in this repo>
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('architect', 'executor', 'verifier', 'scout')]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [string]$Spec,

    [string]$Model,
    [string]$WorkDir = $PWD.Path,
    # Where the stall watchdog looks for file changes (defaults to WorkDir). Use a narrow folder
    # when WorkDir is large and not a git repo, e.g. the output folder of a cataloguing job.
    [string]$ProgressDir = '',
    [switch]$DryRun,
    [int]$TimeoutSec = 1800,
    [switch]$RefreshQuota
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- exit codes
$EXIT_OK            = 0
$EXIT_EXHAUSTED     = 10   # every agy candidate spent/blocked -> LOCAL FALLBACK AUTHORISED
$EXIT_AUTH          = 20
$EXIT_AGY_ERROR     = 30   # agy invocation error, or MCP unhealthy
$EXIT_POLICY        = 40
$EXIT_SPEC          = 50
$EXIT_TIMEOUT       = 60

# ---------------------------------------------------------------- paths
$Root        = Split-Path -Parent $MyInvocation.MyCommand.Path
$PolicyPath  = Join-Path $Root 'policy.json'
$WorkingDir  = Join-Path $Root 'working'
$StatePath   = Join-Path $WorkingDir 'state.json'
$LogDir      = Join-Path $WorkingDir 'logs'
$AgyExe      = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe'

# Stall watchdog (24/09/26): kills a run that stops making progress. See watchdog.ps1.
. (Join-Path $Root 'watchdog.ps1')

foreach ($d in @($WorkingDir, $LogDir)) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

$StartedUtc = (Get-Date).ToUniversalTime()
# 13/10/26: + process id, so two runs started in the same second no longer collide on one log file
$Stamp      = '{0}-{1}' -f $StartedUtc.ToString('yyyyMMddTHHmmssZ'), $PID
$Stopwatch  = [Diagnostics.Stopwatch]::StartNew()

$script:LogPath      = Join-Path $LogDir ("{0}-{1}-init.log" -f $Stamp, $Role)
$script:ResponsePath = ''
$script:Attempts     = @()
$script:LogsPruned   = 0

function Write-Log {
    param([string]$Message)
    $line = "{0}  {1}" -f (Get-Date).ToUniversalTime().ToString('HH:mm:ss'), $Message
    Add-Content -Path $script:LogPath -Value $line -Encoding UTF8
}

# stdout purity (spec 5.4 item 8): this is the ONLY thing that ever writes to stdout.
function Emit-AndExit {
    param(
        [string]$ModelUsed = '',
        [string]$Pool      = '',
        [string]$Reason,
        [int]$Code
    )
    $Stopwatch.Stop()
    $respChars = 0
    if ($script:ResponsePath -and (Test-Path $script:ResponsePath)) {
        $c = Get-Content $script:ResponsePath -Raw
        if ($c) { $respChars = $c.Length }
    }
    $payload = [ordered]@{
        role            = $Role
        model_used      = $ModelUsed
        pool            = $Pool
        decision_reason = $Reason
        attempts        = @($script:Attempts)
        spec            = $Spec
        work_dir        = $WorkDir
        started_utc     = $StartedUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
        duration_s      = [math]::Round($Stopwatch.Elapsed.TotalSeconds, 1)
        log             = $script:LogPath
        response_path   = $script:ResponsePath
        response_chars  = $respChars
        logs_pruned     = $script:LogsPruned
        exit_code       = $Code
    }
    Write-Log "EXIT $Code - $Reason"
    # ONE line, ONE object. PS 5.1 pipes multi-line JSON into ConvertFrom-Json line-by-line and
    # mangles it, so -Compress is what makes `... | ConvertFrom-Json` (T7) work for the couriers.
    $json = $payload | ConvertTo-Json -Depth 6 -Compress
    # Write-Output, NOT [Console]::Out.Write - the latter writes to the console handle and
    # bypasses the PowerShell pipeline, so `... | ConvertFrom-Json` and `$x = & script` both
    # come back empty. Write-Output reaches the success stream AND process stdout.
    Write-Output $json
    exit $Code
}

function Get-Prop($obj, $name, $default) {
    if ($null -ne $obj -and $obj.PSObject.Properties.Name -contains $name) { return $obj.$name }
    return $default
}

# Backstop. Set-StrictMode turns a missing property into a TERMINATING error, which would
# otherwise kill the script with a PowerShell error record, no JSON on stdout, and
# $LASTEXITCODE = 0 - i.e. a hard crash that a courier reads as success. Found by testing a
# policy.json with a role missing its 'preference' key. Nothing may exit 0 except Emit-AndExit.
trap {
    $msg = $_.Exception.Message
    try { Write-Log "UNHANDLED: $msg" } catch { }
    Emit-AndExit -Reason "unhandled error (config or script fault): $msg" -Code $EXIT_POLICY
}

# ---------------------------------------------------------------- load policy
if (-not (Test-Path $PolicyPath)) {
    Emit-AndExit -Reason "policy.json not found at $PolicyPath" -Code $EXIT_POLICY
}
try {
    $Policy = Get-Content $PolicyPath -Raw | ConvertFrom-Json
} catch {
    Emit-AndExit -Reason "policy.json is not valid JSON: $($_.Exception.Message)" -Code $EXIT_POLICY
}
foreach ($req in @('roles', 'thresholds', 'health_probe', 'quota_signals')) {
    if (-not ($Policy.PSObject.Properties.Name -contains $req)) {
        Emit-AndExit -Reason "policy.json is missing the required '$req' section" -Code $EXIT_POLICY
    }
}
if (-not ($Policy.roles.PSObject.Properties.Name -contains $Role)) {
    Emit-AndExit -Reason "policy.json defines no role '$Role'" -Code $EXIT_POLICY
}
$RoleCfg = $Policy.roles.$Role
# Get-Prop, not $RoleCfg.preference: under StrictMode a missing key throws a terminating
# error before this validation can report it cleanly.
if (@(Get-Prop $RoleCfg 'preference' @()).Count -eq 0) {
    Emit-AndExit -Reason "role '$Role' has a missing or empty preference chain" -Code $EXIT_POLICY
}

# real log path, now that the role resolved
$script:LogPath = Join-Path $LogDir ("{0}-{1}.log" -f $Stamp, $Role)
Write-Log "agy-route start | role=$Role spec=$Spec workdir=$WorkDir timeout=${TimeoutSec}s dryrun=$($DryRun.IsPresent)"

# ---------------------------------------------------------------- spec validation (5.4 item 1)
if (-not (Test-Path $Spec)) {
    Emit-AndExit -Reason "spec not found: $Spec" -Code $EXIT_SPEC
}
$SpecItem = Get-Item $Spec
$Spec = $SpecItem.FullName
if ($SpecItem.Length -eq 0) {
    Emit-AndExit -Reason "spec is empty (0 bytes): $Spec" -Code $EXIT_SPEC
}
if (-not (Test-Path $WorkDir)) {
    Emit-AndExit -Reason "work dir not found: $WorkDir" -Code $EXIT_SPEC
}
$WorkDir = (Get-Item $WorkDir).FullName

# ---------------------------------------------------------------- state
function Read-State {
    if (Test-Path $StatePath) {
        try { return (Get-Content $StatePath -Raw | ConvertFrom-Json) } catch {
            Write-Log "state.json unreadable, starting fresh: $($_.Exception.Message)"
        }
    }
    return [pscustomobject]@{
        schema             = 1
        quota              = [pscustomobject]@{ P2 = $null; P3 = $null; observed_utc = $null }
        current_model      = [pscustomobject]@{}
        consecutive_fails  = [pscustomobject]@{}
        last_decision      = ''
        blacklist          = @()
        p3_calls           = @()
        last_probe_ok_utc  = $null
    }
}
function Save-State($s) {
    $s | ConvertTo-Json -Depth 8 | Set-Content -Path $StatePath -Encoding UTF8
}
$State = Read-State

$NowUtc = $StartedUtc

# blacklist: drop expired entries
$activeBl = @()
foreach ($b in @(Get-Prop $State 'blacklist' @())) {
    if ($null -eq $b) { continue }
    $exp = Get-Prop $b 'expires_utc' $null
    if ($exp -and ([datetime]::Parse($exp, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind) -gt $NowUtc)) {
        $activeBl += $b
    }
}
$State.blacklist = $activeBl

# P3 budget window
$p3Window = [double](Get-Prop $Policy.thresholds 'p3_window_hours' 5)
$p3Max    = [int](Get-Prop $Policy.thresholds 'p3_max_calls_per_window' 3)
$p3Recent = @()
foreach ($c in @(Get-Prop $State 'p3_calls' @())) {
    if ($null -eq $c) { continue }
    try {
        $t = [datetime]::Parse($c, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
        if ($t -gt $NowUtc.AddHours(-$p3Window)) { $p3Recent += $c }
    } catch { }
}
$State.p3_calls = $p3Recent
$P3Spent = @($p3Recent).Count
Write-Log "P3 budget: $P3Spent/$p3Max used in the last ${p3Window}h"

if ($RefreshQuota) {
    Write-Log "-RefreshQuota requested. A5 is FALSE: quota is not obtainable non-interactively."
    Write-Log "Run 'agy' interactively and use /quota, then paste both pool percentages into state.json."
}

# ---------------------------------------------------------------- log retention (prune on startup)
function Invoke-LogPruning {
    param($LoggingCfg)

    $enabled = [bool](Get-Prop $LoggingCfg 'enabled' $true)
    if (-not $enabled) {
        Write-Log "Log pruning disabled by policy."
        return
    }

    $retentionDays = [int](Get-Prop $LoggingCfg 'retention_days' 14)
    $maxFiles      = [int](Get-Prop $LoggingCfg 'max_files' 200)

    if (-not (Test-Path $LogDir)) { return }

    try {
        $cutoff = (Get-Date).ToUniversalTime().AddDays(-$retentionDays)
        $files = @(Get-ChildItem -Path $LogDir -File -ErrorAction SilentlyContinue)

        $prunedCount = 0

        # 1. Prune files older than retention_days (excluding current run's log & response file)
        foreach ($f in $files) {
            if ($null -eq $f) { continue }
            if ($f.FullName -eq $script:LogPath -or ($script:ResponsePath -and $f.FullName -eq $script:ResponsePath)) {
                continue
            }
            if ($f.LastWriteTimeUtc -lt $cutoff) {
                try {
                    Remove-Item -Path $f.FullName -Force -ErrorAction Stop
                    $prunedCount++
                } catch {
                    Write-Log "Pruning error removing $($f.Name): $($_.Exception.Message)"
                }
            }
        }

        $script:LogsPruned = $prunedCount

        # 2. If remaining count exceeds max_files, delete oldest first
        $remaining = @(Get-ChildItem -Path $LogDir -File -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -ne $script:LogPath -and (-not $script:ResponsePath -or $_.FullName -ne $script:ResponsePath) } |
            Sort-Object LastWriteTimeUtc)

        if ($remaining.Length -gt $maxFiles) {
            $excess = $remaining.Length - $maxFiles
            for ($i = 0; $i -lt $excess; $i++) {
                try {
                    Remove-Item -Path $remaining[$i].FullName -Force -ErrorAction Stop
                    $prunedCount++
                } catch {
                    Write-Log "Pruning error removing $($remaining[$i].Name): $($_.Exception.Message)"
                }
            }
        }

        $script:LogsPruned = $prunedCount
        if ($prunedCount -gt 0) {
            Write-Log "Log pruning complete: $prunedCount files removed (retention=${retentionDays}d, maxFiles=$maxFiles)."
        }
    } catch {
        Write-Log "Log pruning encountered a non-fatal error: $($_.Exception.Message)"
    }
}

$loggingCfg = Get-Prop $Policy 'logging' $null
Invoke-LogPruning -LoggingCfg $loggingCfg

# ---------------------------------------------------------------- D1 tier 1: static MCP health (free)
function Test-McpConfigStatic {
    $hp = $Policy.health_probe
    $cfgPath = [Environment]::ExpandEnvironmentVariables((Get-Prop $hp 'mcp_config_path' ''))
    if (-not $cfgPath -or -not (Test-Path $cfgPath)) {
        Write-Log "MCP static check: no config at '$cfgPath' - treated as healthy (agy regenerates an empty one)."
        return $null
    }
    try {
        $cfg = Get-Content $cfgPath -Raw | ConvertFrom-Json
    } catch {
        return "mcp_config.json is unparseable: $($_.Exception.Message)"
    }
    if (-not ($cfg.PSObject.Properties.Name -contains 'mcpServers')) { return $null }
    $deny  = @(Get-Prop $hp 'mcp_denylist_servers' @())
    $denyC = @(Get-Prop $hp 'mcp_denylist_command_substrings' @())
    foreach ($srv in $cfg.mcpServers.PSObject.Properties) {
        if ($deny -contains $srv.Name) {
            return "mcp_config.json contains the known-hanging server '$($srv.Name)'. It gates the whole agent, not just print mode (A12/A13). Remove the entry."
        }
        # NOTE: only the command/args shape is inspected. Values are never logged - this file sits beside credentials.
        $cmdText = ''
        try {
            $c = Get-Prop $srv.Value 'command' ''
            $a = @(Get-Prop $srv.Value 'args' @())
            $cmdText = ("{0} {1}" -f $c, ($a -join ' '))
        } catch { }
        foreach ($sub in $denyC) {
            if ($cmdText -and $cmdText.ToLower().Contains($sub.ToLower())) {
                return "mcp_config.json server '$($srv.Name)' uses '$sub', the remote-proxy pattern that hangs agy initialisation (A13). Remove or fix it."
            }
        }
    }
    return $null
}

# ---------------------------------------------------------------- agy invocation
function Invoke-Agy {
    <#  Returns a hashtable: exit_code, stdout, stderr, timed_out, signal  #>
    param(
        [string]$Prompt,
        [string]$ModelId,
        [int]$PrintTimeoutSec,
        [bool]$SkipPermissions,
        [string]$AgyLogFile,
        [switch]$NoAddDir,
        [int]$NoProgressSec = 0
    )
    if (-not (Test-Path $AgyExe)) {
        return @{ exit_code = -1; stdout = ''; stderr = "agy.exe not found at $AgyExe"; timed_out = $false; signal = 'error' }
    }

    # A14: ONE quoted argument string. An array does not quote spaces in PS 5.1.
    $sb = New-Object System.Text.StringBuilder
    [void]$sb.Append('--print "').Append(($Prompt -replace '"', '\"')).Append('"')
    [void]$sb.Append(' --model ').Append($ModelId)
    [void]$sb.Append(' --print-timeout ').Append($PrintTimeoutSec).Append('s')
    if (-not $NoAddDir) { [void]$sb.Append(' --add-dir "').Append($WorkDir).Append('"') }
    if ($SkipPermissions) { [void]$sb.Append(' --dangerously-skip-permissions') }
    if ($AgyLogFile) { [void]$sb.Append(' --log-file "').Append($AgyLogFile).Append('"') }
    $argString = $sb.ToString()

    $o = [System.IO.Path]::GetTempFileName()
    $e = [System.IO.Path]::GetTempFileName()
    Write-Log "  invoke: agy $argString"

    $timedOut = $false
    $stalledReason = ''
    $code = -1
    try {
        $p = Start-Process -FilePath $AgyExe -ArgumentList $argString -NoNewWindow -PassThru `
             -RedirectStandardOutput $o -RedirectStandardError $e
        $null = $p.Handle    # A14: required or ExitCode is empty after exit
        # agy's --print-timeout should fire first; the watchdog is the backstop for that AND
        # kills a run that stalls long before it (24/09/26: two runs sat 15+ min doing nothing).
        $wd = Get-Prop $Policy 'watchdog' $null
        $w = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec ($PrintTimeoutSec + 30) `
                -LogFile $AgyLogFile -WorkDir ($(if ($ProgressDir) { $ProgressDir } else { $WorkDir })) -NoProgressSec $NoProgressSec `
                -LogIdleSec ([int](Get-Prop $wd 'log_idle_sec' 300)) `
                -ChildMaxSec ([int](Get-Prop $wd 'child_max_sec' 900)) `
                -PollSec ([int](Get-Prop $wd 'poll_sec' 30)) `
                -Log { param($m) Write-Log $m }
        if ($w.outcome -eq 'exited') {
            $code = $p.ExitCode
        } elseif ($w.outcome -eq 'timeout') {
            $timedOut = $true
        } else {
            $stalledReason = $w.reason
            Write-Log "  STALLED: $stalledReason - process tree killed"
        }
    } catch {
        Remove-Item $o, $e -ErrorAction SilentlyContinue
        return @{ exit_code = -1; stdout = ''; stderr = "launch failed: $($_.Exception.Message)"; timed_out = $false; signal = 'error' }
    }

    $out = ''; $err = ''
    if (Test-Path $o) { $t = Get-Content $o -Raw; if ($t) { $out = $t } }
    if (Test-Path $e) { $t = Get-Content $e -Raw; if ($t) { $err = $t } }
    Remove-Item $o, $e -ErrorAction SilentlyContinue

    # Defect 7 (27/07/26): a tool denied MID-RUN truncates the answer but still exits 0 with
    # non-empty stdout, so "exit 0 + some output" is NOT success - one preamble sentence
    # defeats it. Two verifier runs were reported as successes having delivered no verdict at
    # all. The stderr marker below only fires when output is ENTIRELY empty (the A10 case),
    # which is why that rule looked sufficient. agy's own log is the authoritative record and
    # the router already captures it, so read it.
    $deniedTool = ''
    if ($AgyLogFile -and (Test-Path $AgyLogFile)) {
        try {
            $agyLogText = Get-Content $AgyLogFile -Raw -ErrorAction Stop
            if ($agyLogText) {
                $m = [regex]::Match($agyLogText, 'soft-denying tool confirmation "([^"]+)"')
                if ($m.Success)                        { $deniedTool = $m.Groups[1].Value }
                elseif ($agyLogText -match 'approved=false') { $deniedTool = 'unknown' }
            }
        } catch { }
    }

    # ---- signal classification (D3, fail-closed) --------------------------------
    $qs   = $Policy.quota_signals
    $both = "$out`n$err"
    $signal = 'none'

    if ($stalledReason) {
        $signal = 'stalled'
    }
    elseif ($timedOut) {
        $signal = 'timeout'
    }
    elseif ($code -ne 0) {
        $signal = 'error'
        foreach ($pat in @(Get-Prop $qs 'auth_patterns' @())) {
            if ($both -match [regex]::Escape($pat)) { $signal = 'auth'; break }
        }
        if ($signal -eq 'error') {
            foreach ($pat in @(Get-Prop $qs 'exhaustion_patterns' @())) {
                if ($both -cmatch [regex]::Escape($pat)) { $signal = 'quota'; break }
            }
        }
        if ($signal -eq 'error') {
            # 13/10/26: a retired model id is a config error, not a run failure; try the next rung
            foreach ($pat in @(Get-Prop $qs 'invalid_model_patterns' @())) {
                if ($both -match [regex]::Escape($pat)) { $signal = 'invalid_model'; break }
            }
        }
    }
    else {
        # A16: exit 0 does NOT mean success. Assert on the output.
        $marker = Get-Prop $qs 'denied_no_output_marker' 'no output produced'
        if ($err -and $err.Contains($marker)) {
            $signal = 'denied'
        } elseif ($deniedTool) {
            # truncated mid-run by a denied tool - output exists but the work did not finish
            $signal = 'denied'
        } elseif (-not $out -or $out.Trim().Length -eq 0) {
            $signal = 'empty'
        } else {
            # a quota signal can still ride along on a zero exit
            foreach ($pat in @(Get-Prop $qs 'exhaustion_patterns' @())) {
                if ($both -cmatch [regex]::Escape($pat)) { $signal = 'quota'; break }
            }
        }
    }

    if ($signal -eq 'quota') {
        Write-Log "QUOTA_SIGNAL_FIRST_OBSERVED >>>"
        Write-Log "  model : $ModelId"
        Write-Log "  stderr: $err"
        Write-Log "  stdout: $out"
        Write-Log "<<< A6 was UNVERIFIED and inferred from binary strings. This is a real observation - record it in DISCOVERY.md."
    }

    return @{ exit_code = $code; stdout = $out; stderr = $err; timed_out = $timedOut; signal = $signal; denied_tool = $deniedTool; stalled_reason = $stalledReason }
}

function Get-QuotaResetHours {
    # Parses agy's "Resets in 1h2m3s" (any of h/m/s) and returns hours + a 5-minute margin; else -Default.
    param([string]$Text, [double]$Default)
    $m = [regex]::Match([string]$Text, 'Resets in ((?:\d+h)?(?:\d+m)?(?:\d+s)?)')
    if (-not $m.Success -or -not $m.Groups[1].Value) { return $Default }
    $s = 0.0
    foreach ($p in [regex]::Matches($m.Groups[1].Value, '(\d+)([hms])')) {
        $n = [double]$p.Groups[1].Value
        switch ($p.Groups[2].Value) { 'h' { $s += $n * 3600 } 'm' { $s += $n * 60 } 's' { $s += $n } }
    }
    if ($s -le 0) { return $Default }
    return [math]::Round(($s + 300) / 3600, 3)
}

# ---------------------------------------------------------------- prompt templates (D4: by reference)
function Get-Prompt {
    param([string]$ForRole)
    # 24/09/26 (Rasta): agy auto-loads AGENTS.md as a rule file but cuts it at 24 KB (its log
    # warns "truncated by 7476 bytes"), so the tail of the repo rules never reached the model.
    # Reading it with the file tool gets the whole file. {1} is the workspace.
    $ReadRulesFirst = "First read {1}\AGENTS.md in full with your file-read tool; the copy loaded automatically as a rule file is truncated, so do not rely on it. "
    switch ($ForRole) {
        'verifier' {
            return ($ReadRulesFirst + "You are an independent VERIFIER. Read the task specification at {0}. " +
                    "Inspect the work in {1} and check it against that spec's acceptance criteria. " +
                    "Reply with PASS or FAIL on the first line, then the evidence you checked. " +
                    "Do NOT fix, edit, or create anything - report only.") -f $Spec, $WorkDir
        }
        'scout' {
            return ($ReadRulesFirst + "You are a SCOUT. Read the task specification at {0}. " +
                    "Search {1} and report only what you find - file paths, matches, and a short summary. " +
                    "Do NOT modify anything.") -f $Spec, $WorkDir
        }
        default {
            return ($ReadRulesFirst + "Then read the task specification at {0} and execute it fully in the workspace at {1}. " +
                    "The spec is authoritative; follow it exactly and do not ask clarifying questions. " +
                    "Write the deliverable files early so progress is visible on disk. While working, run only the tests the spec names; " +
                    "run the repo-wide preflight at most once, at the end, never as a baseline before you start. " +
                    "When finished, summarise what you changed.") -f $Spec, $WorkDir
        }
    }
}

# ---------------------------------------------------------------- candidate resolution
function Test-Blacklisted($poolId, $modelId) {
    foreach ($b in @($State.blacklist)) {
        if ((Get-Prop $b 'model' '') -eq $modelId) { return $true }
    }
    return $false
}

# Derived from policy.json, never hardcoded: opus_roles lists the roles ALLOWED to reach Opus,
# so every other role is banned. A hardcoded role list here would contradict the policy file,
# which DoD item 8 forbids.
$OpusAllowed = @(Get-Prop $Policy 'opus_roles' @('architect'))
$OpusBanned  = @($Policy.roles.PSObject.Properties.Name | Where-Object { $OpusAllowed -notcontains $_ })

function Resolve-Candidates {
    $out = @()
    $i = 0
    foreach ($c in @($RoleCfg.preference)) {
        $i++
        $poolKey = Get-Prop $c 'pool' ''
        $modelId = Get-Prop $c 'model' ''
        $escOnly = [bool](Get-Prop $c 'escalate_only' $false)
        $rationed = [bool](Get-Prop $c 'rationed' $false)
        $skipReason = ''

        # Hard rule: Opus is never selected for executor or scout, in data or by fallback.
        if ($OpusBanned -contains $Role -and $modelId -like '*opus*') {
            $skipReason = 'opus-banned-for-role'
        }
        elseif ($escOnly) {
            $skipReason = 'escalate-only (reachable via -Model)'
        }
        elseif (Test-Blacklisted $poolKey $modelId) {
            $skipReason = 'blacklisted'
        }
        elseif ($poolKey -eq 'P3' -and $P3Spent -ge $p3Max) {
            $skipReason = "p3-budget-spent ($P3Spent/$p3Max in ${p3Window}h)"
        }

        $out += [pscustomobject]@{
            Order = $i; Pool = $poolKey; Model = $modelId
            Rationed = $rationed; SkipReason = $skipReason
        }
    }
    return $out
}

$Candidates = Resolve-Candidates
foreach ($c in $Candidates) {
    if ($c.SkipReason) { Write-Log "  candidate $($c.Order): $($c.Model) [$($c.Pool)] SKIPPED - $($c.SkipReason)" }
    else               { Write-Log "  candidate $($c.Order): $($c.Model) [$($c.Pool)] eligible" }
}

# explicit -Model override bypasses policy AND the P3 budget - and must say so (5.2)
$Overridden = $false
if ($Model) {
    $Overridden = $true
    $ovPool = 'P2'
    if ($Model -like '*claude*' -or $Model -like '*gpt*') { $ovPool = 'P3' }
    if ($OpusBanned -contains $Role -and $Model -like '*opus*') {
        Emit-AndExit -Reason "hard rule: Opus is never selected for role '$Role', not even via -Model" -Code $EXIT_POLICY
    }
    $Candidates = @([pscustomobject]@{ Order = 1; Pool = $ovPool; Model = $Model; Rationed = $false; SkipReason = '' })
    Write-Log "-Model override: $Model [$ovPool]. Bypasses policy order and the P3 budget deliberately."
}

$Eligible = @($Candidates | Where-Object { -not $_.SkipReason })

# verifier_must_differ_from_executor: cross-family verification is the whole reason two
# allowances exist, so a verifier on the same pool as the executor that produced the work is
# a weaker check. Reorder rather than exclude - a same-pool verification still beats none -
# but say so in decision_reason when it could not be honoured.
$CrossFamilyNote = ''
if ($Role -eq 'verifier' -and [bool](Get-Prop $Policy 'verifier_must_differ_from_executor' $false)) {
    $lastExecPool = Get-Prop $State 'last_executor_pool' ''
    if ($lastExecPool -and $Eligible.Count -gt 0) {
        $differing = @($Eligible | Where-Object { $_.Pool -ne $lastExecPool })
        $same      = @($Eligible | Where-Object { $_.Pool -eq $lastExecPool })
        if ($differing.Count -gt 0) {
            $Eligible = @($differing + $same)
            $CrossFamilyNote = " (cross-family: preferred a pool other than the executor's '$lastExecPool')"
        } else {
            $CrossFamilyNote = " (WARNING: verifier_must_differ_from_executor could not be honoured - every remaining candidate shares the executor's pool '$lastExecPool')"
        }
        Write-Log "cross-family check: last executor pool='$lastExecPool'$CrossFamilyNote"
    }
}

if ($Eligible.Count -eq 0) {
    $why = "every candidate for role '$Role' is blacklisted, budget-blocked or escalate-only"
    if ($RoleCfg.local_fallback) {
        Emit-AndExit -Reason "$why - LOCAL FALLBACK AUTHORISED (finish on Claude Sonnet 5 in Claude Code; never Opus)" -Code $EXIT_EXHAUSTED
    }
    Emit-AndExit -Reason "$why - and this role has no local fallback (a drained verifier reports and stops)" -Code $EXIT_EXHAUSTED
}

$First  = $Eligible[0]
$Reason = "policy: first eligible candidate for '$Role'$CrossFamilyNote"
if ($Overridden) { $Reason = "-Model override (bypassed policy order and P3 budget)" }
elseif ($First.Order -gt 1) {
    # Only report rungs that were genuinely SKIPPED. A rung can also sit earlier in the policy
    # order yet be passed over by the cross-family reorder, which is not the same thing -
    # reporting it as "unavailable" with a blank cause would be a lie in the machine contract.
    $skippedList = @($Candidates | Where-Object { $_.Order -lt $First.Order -and $_.SkipReason } |
                     ForEach-Object { "$($_.Model)=$($_.SkipReason)" })
    if ($skippedList.Count -gt 0) {
        $Reason = "fell back to candidate $($First.Order) ($($First.Model)); earlier rungs unavailable: $($skippedList -join '; ')$CrossFamilyNote"
    } else {
        $Reason = "chose candidate $($First.Order) ($($First.Model)) over earlier rungs$CrossFamilyNote"
    }
}

# ---------------------------------------------------------------- dry run (5.4 item 3)
# policy.json's dry_run_default is honoured: set it true to make every run a dry run without
# touching call sites. -DryRun on the command line still forces it on.
if ((-not $DryRun) -and [bool](Get-Prop $Policy 'dry_run_default' $false)) {
    Write-Log "dry_run_default=true in policy.json - forcing dry run"
    $DryRun = $true
}
if ($DryRun) {
    Emit-AndExit -ModelUsed $First.Model -Pool $(if ($First.Pool -eq 'P3') { 'claude' } else { 'gemini' }) `
                 -Reason "DRY RUN - no agy call made. $Reason" -Code $EXIT_OK
}

# ---------------------------------------------------------------- D1 tier 1 (static, free)
$staticProblem = Test-McpConfigStatic
if ($staticProblem) {
    Write-Log "MCP static check FAILED: $staticProblem"
    Emit-AndExit -Reason "pre-flight MCP health failed (static, no agy call made): $staticProblem" -Code $EXIT_AGY_ERROR
}
Write-Log "MCP static check passed (no denylisted servers present)."

# ---------------------------------------------------------------- D1 tier 2 (live, rate-limited)
$hp = $Policy.health_probe
$ttlMin = [double](Get-Prop $hp 'probe_ttl_min' 60)
$needProbe = $true
$lastOk = Get-Prop $State 'last_probe_ok_utc' $null
if ($lastOk) {
    try {
        $t = [datetime]::Parse($lastOk, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::RoundtripKind)
        if ($t -gt $NowUtc.AddMinutes(-$ttlMin)) {
            $needProbe = $false
            Write-Log "Live probe skipped: last success $lastOk is inside the ${ttlMin}min TTL. Costs no quota."
        }
    } catch { }
}
if ($needProbe) {
    $probeModel = Get-Prop $hp 'model' 'gemini-3.6-flash-low'
    $probeTo    = [int](Get-Prop $hp 'timeout_sec' 20)
    $probeTries = [int](Get-Prop $hp 'retries' 1)
    $probeOk = $false
    for ($try = 0; $try -le $probeTries; $try++) {
        Write-Log "Live MCP probe (attempt $($try + 1)) on $probeModel, ${probeTo}s"
        $pr = Invoke-Agy -Prompt (Get-Prop $hp 'prompt' 'Reply with exactly the two characters OK and nothing else.') `
                         -ModelId $probeModel -PrintTimeoutSec $probeTo -SkipPermissions $false -AgyLogFile '' -NoAddDir
        if ($pr.signal -eq 'none') { $probeOk = $true; break }
        Write-Log "  probe attempt failed: signal=$($pr.signal) exit=$($pr.exit_code) stderr=$($pr.stderr)"
    }
    if (-not $probeOk) {
        Emit-AndExit -Reason "pre-flight MCP health probe failed - agy is not answering. Aborting before burning the run timeout." -Code $EXIT_AGY_ERROR
    }
    $State.last_probe_ok_utc = $NowUtc.ToString('yyyy-MM-ddTHH:mm:ssZ')
    Write-Log "Live probe OK."
}

# ---------------------------------------------------------------- the routed call
$skipPerms = [bool](Get-Prop $RoleCfg 'skip_permissions' $false)
Write-Log "D2 permissions for '$Role': skip_permissions=$skipPerms"

# D5 (27/07/26): the read-only roles are no longer read-only by construction. To verify
# anything behavioural a verifier must RUN the code, and agy has no sandboxed-execution path
# in headless mode (--sandbox denies command execution outright), so permissions.allow now
# grants read_file(*) + command(*). write_file stays denied - the file tool is still blocked -
# but a shell command can write. Containment therefore moves here, where it can still be
# enforced: snapshot the workspace before a read-only role runs, compare after, and fail the
# run if anything changed. Detection, not prevention - and infinitely better than the prose
# in a prompt that D2 rightly refused to rely on.
function Get-WorkspaceFingerprint {
    if (-not $WorkDir -or -not (Test-Path $WorkDir)) { return $null }
    try {
        $porcelain = & git -C $WorkDir status --porcelain 2>$null
        if ($LASTEXITCODE -ne 0) { return $null }   # not a git worktree - no cheap fingerprint
        return (($porcelain | Out-String).Trim())
    } catch { return $null }
}

$PreRunFingerprint = $null
if (-not $skipPerms) {
    $PreRunFingerprint = Get-WorkspaceFingerprint
    if ($null -eq $PreRunFingerprint) {
        Write-Log "containment: '$WorkDir' is not a git worktree, so no before/after fingerprint is possible. A write by this read-only role would NOT be detected."
    } else {
        Write-Log "containment: workspace fingerprint captured for read-only role '$Role'."
    }
}

$prompt = Get-Prompt $Role
$script:ResponsePath = Join-Path $LogDir ("{0}-{1}-response.txt" -f $Stamp, $Role)

# 5.4 item 6: quota exhaustion retries the NEXT candidate exactly once. Nothing else retries.
$maxAttempts = 2
$attemptNo = 0
$idx = 0
$finalModel = ''
$finalPool  = ''

while ($attemptNo -lt $maxAttempts -and $idx -lt $Eligible.Count) {
    $cand = $Eligible[$idx]
    $attemptNo++
    $poolName = 'gemini'
    if ($cand.Pool -eq 'P3') { $poolName = 'claude' }

    Write-Log "ATTEMPT $attemptNo -> $($cand.Model) [$($cand.Pool)]"
    $agyLog = Join-Path $LogDir ("{0}-{1}-{2}-agy.log" -f $Stamp, $Role, $cand.Model)

    $noProgress = 0
    if ($Role -eq 'executor') { $noProgress = [int](Get-Prop (Get-Prop $Policy 'watchdog' $null) 'executor_no_progress_sec' 900) }
    $r = Invoke-Agy -Prompt $prompt -ModelId $cand.Model -PrintTimeoutSec $TimeoutSec `
                    -SkipPermissions $skipPerms -AgyLogFile $agyLog -NoProgressSec $noProgress

    $script:Attempts += [ordered]@{ model = $cand.Model; exit_code = $r.exit_code; signal = $r.signal }

    if ($cand.Pool -eq 'P3') {
        $State.p3_calls = @($State.p3_calls) + @($NowUtc.ToString('yyyy-MM-ddTHH:mm:ssZ'))
        $P3Spent++
        Write-Log "  P3 call recorded ($P3Spent/$p3Max)"
    }

    switch ($r.signal) {
        'none' {
            Set-Content -Path $script:ResponsePath -Value $r.stdout -Encoding UTF8

            # Containment (D5): a read-only role that changed the workspace has done the one
            # thing it must never do - a verifier that repairs what it judges destroys the only
            # independent signal in the process. Fail the run loudly; never report it as work done.
            if (-not $skipPerms -and $null -ne $PreRunFingerprint) {
                $postRun = Get-WorkspaceFingerprint
                if ($null -ne $postRun -and $postRun -ne $PreRunFingerprint) {
                    Write-Log "CONTAINMENT BREACH >>> role '$Role' modified the workspace."
                    Write-Log "  before: $PreRunFingerprint"
                    Write-Log "  after : $postRun"
                    Save-State $State
                    Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "CONTAINMENT BREACH: read-only role '$Role' modified the workspace during its run (git status differs before/after). Its output must NOT be treated as an independent judgement. See the log for the before/after diff." -Code $EXIT_AGY_ERROR
                }
            }

            # S5.5: a verifier owes an explicit PASS or FAIL. Anything else is prose, not a
            # verdict, and reporting exit 0 for it is precisely the failure this router exists
            # to prevent. Fail closed - a wrongly-formatted verdict is cheap to re-run; a
            # verification that silently never happened is not.
            if ($Role -eq 'verifier') {
                # Look for a VERDICT LINE, not literally line 1. Models open with a markdown
                # rule or a heading and put "**FAIL**" on line 3, which is still a verdict
                # plainly delivered. Strip leading markdown, then require the line to BEGIN
                # with PASS or FAIL - so a "| 1 | ... | PASS |" table row does not count.
                $verdict = ''
                foreach ($line in ($r.stdout -split "`r?`n")) {
                    $t = ($line.Trim() -replace '^[\*_#>\s\-]+', '') -replace '[\*_`\s]+$', ''
                    if ($t -cmatch '^(PASS|FAIL)\b') { $verdict = $Matches[1]; break }
                }
                if (-not $verdict) {
                    Save-State $State
                    Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "verifier returned no verdict - no line in the response begins with PASS or FAIL, so no independent check was delivered (S5.5). Response: $script:ResponsePath" -Code $EXIT_AGY_ERROR
                }
                Write-Log "verifier verdict: $verdict"
            }

            $finalModel = $cand.Model; $finalPool = $poolName
            $State.last_decision = $Reason
            # feeds verifier_must_differ_from_executor on the next verifier run
            if ($Role -eq 'executor') {
                $State | Add-Member -NotePropertyName 'last_executor_pool' -NotePropertyValue $cand.Pool -Force
            }
            Save-State $State
            Emit-AndExit -ModelUsed $finalModel -Pool $finalPool -Reason $Reason -Code $EXIT_OK
        }
        'quota' {
            # D3: the ONLY signal that blacklists and retries.
            $resetH = $p3Window
            if ($cand.Pool -eq 'P2') { $resetH = 51 }
            # 13/10/26: agy states the real reset ("Resets in 26m42s"); honour it (+5 min margin) instead of the
            # 51h worst case, which blocked a model for two days over a 27-minute window.
            $resetH = Get-QuotaResetHours -Text "$($r.stderr) $($r.stdout)" -Default $resetH
            $State.blacklist = @($State.blacklist) + @([pscustomobject]@{
                model = $cand.Model; pool = $cand.Pool
                expires_utc = $NowUtc.AddHours($resetH).ToString('yyyy-MM-ddTHH:mm:ssZ')
                reason = 'quota exhaustion signal observed'
            })
            Write-Log "  quota signal -> blacklisted $($cand.Model) until +${resetH}h; retrying the next candidate once."
            $Reason = "quota exhaustion on $($cand.Model); retried next candidate once"
            $idx++
            continue
        }
        'invalid_model' {
            # 13/10/26: agy rejected the model id (retired). Config error, not a run: no blacklist, does not use
            # up the one quota retry, move to the next rung. Fix policy.json so this stops appearing.
            Write-Log "  INVALID MODEL: agy does not recognise '$($cand.Model)' - skipped; update policy.json to an id from 'agy models'."
            $attemptNo--
            $idx++
            continue
        }
        'auth' {
            Save-State $State
            Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "authentication failure - no keyring session. Launch 'agy' and confirm it signs in as italiandesaigns@gmail.com." -Code $EXIT_AUTH
        }
        'timeout' {
            Save-State $State
            Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "timed out after ${TimeoutSec}s and was killed" -Code $EXIT_TIMEOUT
        }
        'stalled' {
            Save-State $State
            Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "STALLED and killed by the watchdog: $($r.stalled_reason). Not quota, no blacklist, no retry. Check the agy log and the working tree before re-running." -Code $EXIT_TIMEOUT
        }
        'denied' {
            Save-State $State
            $whichTool = 'a tool'
            if ($r.denied_tool) { $whichTool = "the '$($r.denied_tool)' tool" }
            Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "$whichTool was auto-denied in headless mode, so the run was cut short and its output is NOT a completed answer. Role '$Role' runs without --dangerously-skip-permissions; if it legitimately needs this tool, add a rule under permissions.allow in agy's settings.json (see D5). Never read a denied run as a success." -Code $EXIT_AGY_ERROR
        }
        default {
            # A6 is UNVERIFIED: an unrecognised failure is NEVER treated as quota. No blacklist, no retry.
            Save-State $State
            $tail = ''
            if ($r.stderr) { $tail = ($r.stderr -split "`n" | Select-Object -First 3) -join ' ' }
            Emit-AndExit -ModelUsed $cand.Model -Pool $poolName -Reason "agy error (exit $($r.exit_code), signal '$($r.signal)') - not treated as quota because A6 is unverified, so no blacklist and no retry. $tail" -Code $EXIT_AGY_ERROR
        }
    }
}

Save-State $State
if ($RoleCfg.local_fallback) {
    Emit-AndExit -Reason "every agy candidate for '$Role' is exhausted or budget-blocked - LOCAL FALLBACK AUTHORISED (Claude Sonnet 5 in Claude Code; never Opus)" -Code $EXIT_EXHAUSTED
}
Emit-AndExit -Reason "every agy candidate for '$Role' is exhausted or budget-blocked, and this role has no local fallback" -Code $EXIT_EXHAUSTED

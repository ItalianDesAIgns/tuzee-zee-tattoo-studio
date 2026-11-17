<#
  Spec 0012 offline tests: liveness CPU tracking, policy schema, and AcceptanceCmd block/guards.
  Run: powershell -NoProfile -ExecutionPolicy Bypass -File automations/model-routing/test_liveness.ps1
  Exit 0 = all pass, 1 = any failure.
#>
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $Root 'watchdog.ps1')

$src = Join-Path $Root 'agy-route.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($src, [ref]$null, [ref]$null)
foreach ($name in 'Write-Log', 'Test-AcceptanceCommandSafe', 'Invoke-AcceptanceBlock') {
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
    if ($fn.Count -ne 1) { Write-Host "FAIL: $name not found once"; exit 1 }
    Invoke-Expression $fn[0].Extent.Text
}
$script:LogPath = Join-Path ([IO.Path]::GetTempPath()) ("live-test-" + $PID + ".log")

$Tmp = Join-Path ([IO.Path]::GetTempPath()) ("live-test-tmp-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
New-Item -ItemType Directory -Path $Tmp | Out-Null
$script:Failures = 0

function Check([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name :: $Detail"; $script:Failures++ }
}

try {
    # 1. Policy schema aligns with Spec 0012
    $pol = Get-Content (Join-Path $Root 'policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Check 'policy watchdog.dead_after_sec is 600' ([int]$pol.watchdog.dead_after_sec -eq 600) "got $($pol.watchdog.dead_after_sec)"
    Check 'policy watchdog.max_run_sec is 14400' ([int]$pol.watchdog.max_run_sec -eq 14400) "got $($pol.watchdog.max_run_sec)"
    Check 'policy removes legacy child_max_sec' ($null -eq $pol.watchdog.PSObject.Properties['child_max_sec']) 'child_max_sec still set'
    Check 'policy removes legacy log_idle_sec' ($null -eq $pol.watchdog.PSObject.Properties['log_idle_sec']) 'log_idle_sec still set'
    Check 'policy health_probe.timeout_sec >= 120' ([int]$pol.health_probe.timeout_sec -ge 120) "got $($pol.health_probe.timeout_sec)"

    # 2. CPU-busy child (zero log, zero file writes) survives past DeadAfterSec=3s and exits cleanly after ~6s
    $f = Join-Path $Tmp 'cpu-worker.ps1'
    $scriptBody = @'
$child = Start-Process powershell -ArgumentList '-NoProfile -Command "$sw=[Diagnostics.Stopwatch]::StartNew(); $x=0; while($sw.Elapsed.TotalSeconds -lt 6){$x++}"' -PassThru -WindowStyle Hidden
$child.WaitForExit()
exit 0
'@
    Set-Content -Path $f -Value $scriptBody -Encoding UTF8
    $p = Start-Process powershell -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$f`"" -PassThru -WindowStyle Hidden
    $null = $p.Handle
    $r = Wait-ProcessWithWatchdog -Process $p -TotalTimeoutSec 30 -MaxRunSec 30 -DeadAfterSec 3 -PollSec 1 -StartupGraceSec 0
    Check 'CPU-busy child with zero log/file writes survives > dead_after_sec' ($r.outcome -eq 'exited') "$($r.outcome) $($r.reason)"

    # 3. Acceptance command safety guard blocks --live / --publish-live / git push / publish.py --main
    Check 'rejects --live flag' ($null -ne (Test-AcceptanceCommandSafe -Commands @('python run.py --live'))) 'allowed --live'
    Check 'rejects --publish-live' ($null -ne (Test-AcceptanceCommandSafe -Commands @('python post.py --publish-live'))) 'allowed --publish-live'
    Check 'rejects git push' ($null -ne (Test-AcceptanceCommandSafe -Commands @('git push origin main'))) 'allowed git push'
    Check 'rejects publish.py --main' ($null -ne (Test-AcceptanceCommandSafe -Commands @('python .agents/scripts/publish.py --main'))) 'allowed publish.py --main'
    Check 'allows safe verification command' ($null -eq (Test-AcceptanceCommandSafe -Commands @('python -m pytest -q', 'pnpm test'))) 'rejected safe command'

    # 4. Invoke-AcceptanceBlock returns ok=true on passing command, ok=false on failing command
    $okRes = Invoke-AcceptanceBlock -Commands @('Write-Output ok') -Dir $Tmp
    Check 'Invoke-AcceptanceBlock passes zero exit' ($okRes.ok -eq $true -and $okRes.exit_code -eq 0) "exit=$($okRes.exit_code)"
    $failRes = Invoke-AcceptanceBlock -Commands @('exit 3') -Dir $Tmp
    Check 'Invoke-AcceptanceBlock fails non-zero exit' ($failRes.ok -eq $false -and $failRes.exit_code -eq 3) "ok=$($failRes.ok) exit=$($failRes.exit_code)"

    # 5. Live CLI check of agy-route.ps1 refusing unsafe AcceptanceCmd with exit 70 (no agy invoked)
    $specTmp = Join-Path $Tmp 'spec.md'
    Set-Content -Path $specTmp -Value '# Test Spec' -Encoding UTF8
    $eap = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    $null = & powershell -NoProfile -ExecutionPolicy Bypass -File $src -Role executor -Spec $specTmp -WorkDir $Root -AcceptanceCmd 'git push origin main' -DryRun 2>$null
    $routeExit = $LASTEXITCODE
    $ErrorActionPreference = $eap
    Check 'agy-route refuses unsafe AcceptanceCmd with exit 70' ($routeExit -eq 70) "got exit $routeExit"
}
finally {
    Remove-Item $script:LogPath -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $Tmp -ErrorAction SilentlyContinue
}

if ($script:Failures -gt 0) { Write-Host "$($script:Failures) failure(s)"; exit 1 }
Write-Host 'ALL PASS'
exit 0

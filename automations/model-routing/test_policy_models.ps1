<#
  Live tests (needs agy signed in; costs no quota: agy rejects a bad id before any model call).
  1. Every model id in policy.json (role ladders + health probe) is one agy currently offers ('agy models').
  2. Invoke-Agy classifies a retired id as signal 'invalid_model' (so the router skips to the next rung).
  3. The id set from 'agy models' equals models.known.json (the model-catalog watch, spec 0008). A difference FAILS
     and says what to do. -KnownPath points the check at another snapshot (used to plant a failure).
  Run: powershell -NoProfile -ExecutionPolicy Bypass -File automations/model-routing/test_policy_models.ps1
  Exit 0 = all pass, 1 = any failure.
#>
param([string]$KnownPath = '')
$ErrorActionPreference = 'Stop'
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$AgyExe = Join-Path $env:LOCALAPPDATA 'agy\bin\agy.exe'
$script:Failures = 0
function Check([string]$Name, [bool]$Ok, [string]$Detail) {
    if ($Ok) { Write-Host "PASS  $Name" } else { Write-Host "FAIL  $Name :: $Detail"; $script:Failures++ }
}

$Policy = Get-Content (Join-Path $Root 'policy.json') -Raw -Encoding UTF8 | ConvertFrom-Json

# ---- 1. policy ids vs agy models
$ErrorActionPreference = 'Continue'   # PS 5.1 turns agy's stderr progress line into a terminating error
$listed = @(& $AgyExe models 2>$null | ForEach-Object { ($_ -split "`t")[0].Trim() } | Where-Object { $_ -match '^[a-z0-9.-]+$' })
$ErrorActionPreference = 'Stop'
Check 'agy models returns a list' ($listed.Count -gt 0) 'no model ids parsed from agy models'
$ids = @($Policy.health_probe.model)
foreach ($r in $Policy.roles.PSObject.Properties) { $ids += @($r.Value.preference | ForEach-Object { $_.model }) }
foreach ($id in ($ids | Sort-Object -Unique)) {
    Check "policy model '$id' is offered by agy" ($listed -contains $id) ("agy offers: " + ($listed -join ', '))
}

# ---- 3. catalog equals snapshot (model-catalog watch)
if (-not $KnownPath) { $KnownPath = Join-Path $Root 'models.known.json' }
$knownOk = Test-Path $KnownPath
Check 'models.known.json is readable' $knownOk "missing: $KnownPath"
if ($knownOk) {
    $known = @((Get-Content $KnownPath -Raw -Encoding UTF8 | ConvertFrom-Json).models)
    $live = @($listed | Sort-Object -Unique)
    $added = @($live | Where-Object { $known -notcontains $_ })
    $removed = @($known | Where-Object { $live -notcontains $_ })
    $same = ($added.Count -eq 0 -and $removed.Count -eq 0)
    $detail = "added: [" + ($added -join ', ') + "] removed: [" + ($removed -join ', ') + "]. " +
        "agy's model list changed. Re-read https://antigravity.google/docs/models/ and the new model's card, decide the ladders (MODEL-ROUTING.md section 6), " +
        "update policy.json + MODEL-ROUTING.md + models.known.json in agency-os, copy to every repo, run the daily brief's drift check."
    Check 'agy models equals models.known.json' $same $detail
}

# ---- 2. retired id -> invalid_model
$src = Join-Path $Root 'agy-route.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($src, [ref]$null, [ref]$null)
foreach ($name in 'Write-Log', 'Get-Prop', 'Invoke-Agy') {
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
    if ($fn.Count -ne 1) { Write-Host "FAIL  function $name not found once"; exit 1 }
    Invoke-Expression $fn[0].Extent.Text
}
. (Join-Path $Root 'watchdog.ps1')
$script:LogPath = Join-Path ([IO.Path]::GetTempPath()) ("policy-models-test-" + $PID + ".log")
$WorkDir = [IO.Path]::GetTempPath(); $ProgressDir = ''
$r = Invoke-Agy -Prompt 'Reply OK' -ModelId 'gemini-3.7-flash-high' -PrintTimeoutSec 60 -SkipPermissions $false -AgyLogFile '' -NoAddDir
Check "retired id 'gemini-3.7-flash-high' -> signal invalid_model" ($r.signal -eq 'invalid_model') "got signal '$($r.signal)', exit $($r.exit_code), stderr: $($r.stderr)"
Remove-Item $script:LogPath -ErrorAction SilentlyContinue

if ($script:Failures) { Write-Host "$($script:Failures) FAILED"; exit 1 }
Write-Host 'ALL PASS'; exit 0

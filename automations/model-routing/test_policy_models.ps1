<#
  Live tests (needs agy signed in; costs no quota: agy rejects a bad id before any model call).
  1. Every model id in policy.json (role ladders + health probe) is one agy currently offers ('agy models').
  2. Invoke-Agy classifies a retired id as signal 'invalid_model' (so the router skips to the next rung).
  Run: powershell -NoProfile -ExecutionPolicy Bypass -File automations/model-routing/test_policy_models.ps1
  Exit 0 = all pass, 1 = any failure.
#>
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

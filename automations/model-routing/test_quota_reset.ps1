# Tests Get-QuotaResetHours in agy-route.ps1: the quota blacklist must honour agy's "Resets in ..." text.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File test_quota_reset.ps1   (exit 0 = all pass)
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'agy-route.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($src, [ref]$null, [ref]$null)
$fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq 'Get-QuotaResetHours' }, $true)
if ($fn.Count -ne 1) { Write-Host 'FAIL: Get-QuotaResetHours not found exactly once'; exit 1 }
Invoke-Expression $fn[0].Extent.Text

$fail = 0
function Check($name, $got, $want) {
    if ([math]::Abs($got - $want) -lt 0.001) { Write-Host "PASS $name ($got)" }
    else { Write-Host "FAIL $name : got $got, want $want"; $script:fail++ }
}
$agy = 'error: Individual quota reached. Please upgrade your subscription to increase your limits. Resets in 26m42s. (response may be truncated)'
Check 'real agy message 26m42s' (Get-QuotaResetHours -Text $agy -Default 51) ([math]::Round((26*60 + 42 + 300) / 3600, 3))
Check 'hours minutes seconds'   (Get-QuotaResetHours -Text 'Resets in 4h10m5s.' -Default 51) ([math]::Round((4*3600 + 600 + 5 + 300) / 3600, 3))
Check 'hours only'              (Get-QuotaResetHours -Text 'Resets in 2h' -Default 51) ([math]::Round((7200 + 300) / 3600, 3))
Check 'no reset text -> default' (Get-QuotaResetHours -Text 'RESOURCE_EXHAUSTED (code 429)' -Default 51) 51
Check 'empty text -> default'   (Get-QuotaResetHours -Text '' -Default 5) 5
Check 'bare "Resets in" -> default' (Get-QuotaResetHours -Text 'Resets in soon' -Default 51) 51
if ($fail) { Write-Host "$fail FAILED"; exit 1 }
Write-Host 'ALL PASS'; exit 0

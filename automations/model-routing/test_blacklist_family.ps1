# Tests the quota blacklist in agy-route.ps1: it works per model FAMILY (id without its thinking-level suffix).
# An exhausted Argon must leave Hydrogen and Flash eligible, and must also skip the other Argon levels.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File test_blacklist_family.ps1   (exit 0 = all pass)
$ErrorActionPreference = 'Stop'
$src = Join-Path $PSScriptRoot 'agy-route.ps1'
$ast = [System.Management.Automation.Language.Parser]::ParseFile($src, [ref]$null, [ref]$null)
foreach ($name in 'Get-Prop', 'Get-ModelFamily', 'Test-Blacklisted') {
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }, $true)
    if ($fn.Count -ne 1) { Write-Host "FAIL: $name not found exactly once"; exit 1 }
    Invoke-Expression $fn[0].Extent.Text
}
$fail = 0
function Check($name, $got, $want) {
    if ($got -eq $want) { Write-Host "PASS $name" } else { Write-Host "FAIL $name : got $got, want $want"; $script:fail++ }
}
$State = [pscustomobject]@{ blacklist = @([pscustomobject]@{ model = 'gemini-4-argon-medium'; pool = 'P2'; expires_utc = '2099-01-01T00:00:00Z' }) }
Check 'family strips level'              (Get-ModelFamily 'gemini-4-hydrogen-xhigh') 'gemini-4-hydrogen'
Check 'flash family keeps version dots'  (Get-ModelFamily 'gemini-3.8-flash-low') 'gemini-3.8-flash'
Check 'exact exhausted id blocked'       (Test-Blacklisted 'P2' 'gemini-4-argon-medium') $true
Check 'same family other level blocked'  (Test-Blacklisted 'P2' 'gemini-4-argon-high') $true
Check 'Hydrogen stays eligible'          (Test-Blacklisted 'P2' 'gemini-4-hydrogen-medium') $false
Check 'Hydrogen high stays eligible'     (Test-Blacklisted 'P2' 'gemini-4-hydrogen-high') $false
Check 'Flash stays eligible'             (Test-Blacklisted 'P2' 'gemini-3.8-flash-high') $false
Check 'Claude stays eligible'            (Test-Blacklisted 'P3' 'claude-sonnet-5-5-medium') $false
$State = [pscustomobject]@{ blacklist = @() }
Check 'empty blacklist blocks nothing'   (Test-Blacklisted 'P2' 'gemini-4-argon-medium') $false
if ($fail) { Write-Host "$fail FAILED"; exit 1 }
Write-Host 'ALL PASS'; exit 0

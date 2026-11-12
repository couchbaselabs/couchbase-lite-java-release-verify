<#  run_tests_windows.ps1
    Usage:
      powershell -ExecutionPolicy Bypass -File .\run_tests_windows.ps1 -Version 4.1.3 [-Artifact couchbase-lite-java-ee]
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $Version,
  [string] $Artifact = "couchbase-lite-java-ee"
)

# Step 2: Run Java tests
Write-Host "Step 2: Running Java verification tests..." -ForegroundColor Yellow
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$testDir = Join-Path $scriptDir "java-tests"

Push-Location $testDir
try {
$gradlewCmd = ".\gradlew.bat"
if (-not (Test-Path $gradlewCmd)) {
    throw "Gradle wrapper not found at $gradlewCmd"
}

& $gradlewCmd clean test --no-daemon -PcblVersion="$Version" -PcblArtifact="$Artifact"

if ($LASTEXITCODE -ne 0) {
    throw "Gradle tests failed with exit code $LASTEXITCODE"
}

Write-Host ""
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Verification completed successfully!" -ForegroundColor Green
Write-Host "======================================" -ForegroundColor Cyan
Write-Host "Test results: $testDir\build\reports\tests\test\index.html"
}
finally {
Pop-Location
}
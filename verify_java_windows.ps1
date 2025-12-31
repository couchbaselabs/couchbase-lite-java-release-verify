<#  verify_download.ps1
    Usage:
      powershell -ExecutionPolicy Bypass -File .\verify_download.ps1 -Version 3.2.1
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory = $true)]
  [string] $Version
)

$ErrorActionPreference = 'Stop'

$CENTRAL_BASE = "https://repo1.maven.org/maven2"
$EE_BASE      = "https://mobile.maven.couchbase.com/maven2/dev"
$GROUP_PATH   = "com/couchbase/lite"

$COMMUNITY  = @("couchbase-lite-java")
$ENTERPRISE = @("couchbase-lite-java-ee")

function New-TempDir {
  $base = [System.IO.Path]::GetTempPath()
  $name = "cbl-downloads-" + [System.Guid]::NewGuid().ToString("N")
  $dir  = Join-Path $base $name
  New-Item -ItemType Directory -Path $dir | Out-Null
  return $dir
}

function Download-WithRetry {
  param(
    [Parameter(Mandatory = $true)][string] $Uri,
    [Parameter(Mandatory = $true)][string] $OutFile,
    [int] $MaxAttempts = 4,
    [int] $DelaySeconds = 2
  )

  for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
    try {
      Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
      $fi = Get-Item -LiteralPath $OutFile
      if ($fi.Length -le 0) { throw "Downloaded file is empty: $OutFile" }
      return
    } catch {
      if ($attempt -eq $MaxAttempts) { throw }
      Start-Sleep -Seconds $DelaySeconds
    }
  }
}

function Download-One {
  param(
    [Parameter(Mandatory = $true)][string] $RepoBase,
    [Parameter(Mandatory = $true)][string] $Artifact,
    [Parameter(Mandatory = $true)][string] $Version,
    [Parameter(Mandatory = $true)][string] $Dest
  )

  New-Item -ItemType Directory -Force -Path $Dest | Out-Null

  $base = "$RepoBase/$GROUP_PATH/$Artifact/$Version"
  $jar  = "$Artifact-$Version.jar"
  $pom  = "$Artifact-$Version.pom"

  $jarUrl = "$base/$jar"
  $pomUrl = "$base/$pom"

  $jarPath = Join-Path $Dest $jar
  $pomPath = Join-Path $Dest $pom

  Download-WithRetry -Uri $jarUrl -OutFile $jarPath
  Download-WithRetry -Uri $pomUrl -OutFile $pomPath

  if (-not (Test-Path -LiteralPath $jarPath) -or ((Get-Item $jarPath).Length -le 0)) { throw "Missing/empty: $jarPath" }
  if (-not (Test-Path -LiteralPath $pomPath) -or ((Get-Item $pomPath).Length -le 0)) { throw "Missing/empty: $pomPath" }
}

$workDir = New-TempDir
$outDir  = Join-Path $workDir "cbl-downloads"

try {
  foreach ($a in $COMMUNITY) {
    Download-One -RepoBase $CENTRAL_BASE -Artifact $a -Version $Version -Dest (Join-Path $outDir "community")
  }

  foreach ($a in $ENTERPRISE) {
    Download-One -RepoBase $EE_BASE -Artifact $a -Version $Version -Dest (Join-Path $outDir "enterprise")
  }

  Write-Host "OK: all artifacts downloaded for version $Version (temp dir will be deleted): $outDir"
}
finally {
  if (Test-Path -LiteralPath $workDir) {
    Remove-Item -LiteralPath $workDir -Recurse -Force
  }
}

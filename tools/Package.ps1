param([string]$OutputDirectory)
$ErrorActionPreference = 'Stop'
$addonRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
. (Join-Path $PSScriptRoot 'SourceFiles.ps1')
$dist = Join-Path $addonRoot 'dist'
if ($OutputDirectory) { $dist=[IO.Path]::GetFullPath($OutputDirectory) }
$toc = Get-Content -LiteralPath (Join-Path $addonRoot 'EndCapper.toc')
$versionLine = @($toc | Where-Object { $_ -match '^## Version: ' })
if ($versionLine.Count -ne 1) { throw 'Expected one TOC version' }
$version = ($versionLine[0] -replace '^## Version: ', '').Trim()
if ($version -notmatch '^\d+\.\d+\.\d+(?:-[A-Za-z0-9.]+)?$') { throw "Invalid version: $version" }

$runtime = @(Get-EndCapperRuntimeFiles)
$files = @(Get-EndCapperPackageFiles)
foreach ($file in $files) {
    $null=Resolve-EndCapperSource $addonRoot $file
}
foreach ($line in $toc) {
    $reference = $line.Trim()
    if ($reference -and -not $reference.StartsWith('#') -and $runtime -notcontains $reference) {
        throw "TOC load reference missing from runtime manifest: $reference"
    }
}
foreach ($document in @('README.md','CHANGELOG.md')) {
    if (-not (Get-Content -LiteralPath (Join-Path $addonRoot $document) -Raw).Contains($version)) {
        throw "$document does not identify release $version"
    }
}
New-Item -ItemType Directory -Force -Path $dist | Out-Null
# Create a fresh ZIP directly from the allowlist, without duplicating textures.
$stageRoot = Join-Path $dist ('.stage-' + [Guid]::NewGuid().ToString('N'))
$archive = Join-Path $dist "EndCapper-$version.zip"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
try {
    New-Item -ItemType Directory -Path $stageRoot | Out-Null
    $candidate = Join-Path $stageRoot 'candidate.zip'
    $outputZip = [IO.Compression.ZipFile]::Open($candidate, [IO.Compression.ZipArchiveMode]::Create)
    try {
        foreach ($file in $files) {
            # Use portable ZIP separators even under Windows PowerShell/.NET.
            [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($outputZip, (Resolve-EndCapperSource $addonRoot $file), "EndCapper/$file", [IO.Compression.CompressionLevel]::Optimal) | Out-Null
        }
    } finally { $outputZip.Dispose() }
    $zip = [IO.Compression.ZipFile]::OpenRead($candidate)
    try {
        $expected = @($files | ForEach-Object { "EndCapper/$_" })
        $names = @($zip.Entries | ForEach-Object { $_.FullName })
        if ($names.Count -ne $expected.Count -or @(Compare-Object $expected $names).Count -ne 0) {
            throw 'Archive does not exactly match the release manifest'
        }
        foreach ($entry in $zip.Entries) {
            $relative = $entry.FullName.Replace('\','/').Substring('EndCapper/'.Length)
            $stream = $entry.Open()
            $sha = [Security.Cryptography.SHA256]::Create()
            try {
                $hash = [BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')
                if ($hash -ne (Get-FileHash -LiteralPath (Resolve-EndCapperSource $addonRoot $relative) -Algorithm SHA256).Hash) {
                    throw "Archive/source mismatch: $relative"
                }
            } finally { $stream.Dispose(); $sha.Dispose() }
        }
    } finally { $zip.Dispose() }
    Move-Item -LiteralPath $candidate -Destination $archive -Force
    Write-Output "Package verified: $archive ($($files.Count) files; exact manifest and SHA-256 match)"
} finally {
    # Verify containment before recursively removing this build's staging directory.
    $resolvedStage = [IO.Path]::GetFullPath($stageRoot)
    $distPrefix = [IO.Path]::GetFullPath($dist).TrimEnd('\') + '\'
    if (-not $resolvedStage.StartsWith($distPrefix, [StringComparison]::OrdinalIgnoreCase) -or
        [IO.Path]::GetFileName($resolvedStage) -notmatch '^\.stage-[a-f0-9]{32}$') { throw 'Unsafe staging cleanup path' }
    if (Test-Path -LiteralPath $resolvedStage) {
        $items = @((Get-Item -LiteralPath $resolvedStage -Force)) + @(Get-ChildItem -LiteralPath $resolvedStage -Recurse -Force)
        if (@($items | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint }).Count) {
            throw 'Refusing recursive cleanup of staging with reparse points'
        }
        Remove-Item -LiteralPath $resolvedStage -Recurse -Force
    }
}

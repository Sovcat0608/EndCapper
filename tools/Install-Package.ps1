param([Parameter(Mandatory)][string]$Archive,[Parameter(Mandatory)][string]$BackupRoot,[Parameter(Mandatory)][string]$Target)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$sourceRoot=[IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
. (Join-Path $PSScriptRoot 'SourceFiles.ps1')
$targetRoot=[IO.Path]::GetFullPath($Target).TrimEnd('\')+'\'
if(-not(Test-Path -LiteralPath (Join-Path $targetRoot 'EndCapper.toc'))){throw 'Expected existing EndCapper installation'}
$backup=Join-Path ([IO.Path]::GetFullPath($BackupRoot)) ('install-before-moonwell-'+[Guid]::NewGuid().ToString('N'))
$zip=[IO.Compression.ZipFile]::OpenRead([IO.Path]::GetFullPath($Archive))
$records=@();$changes=@()
try {
    $missing=[System.Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
    foreach($file in Get-EndCapperPackageFiles){$null=$missing.Add("EndCapper/$file")}
    foreach($entry in $zip.Entries){
        if(-not $missing.Remove($entry.FullName)){throw "Unexpected or duplicate archive entry: $($entry.FullName)"}
    }
    if($missing.Count){throw "Missing package entries: $($missing -join ', ')"}
    foreach($entry in $zip.Entries){
        $rel=$entry.FullName.Substring('EndCapper/'.Length)
        $dest=[IO.Path]::GetFullPath((Join-Path $targetRoot $rel))
        if(-not $dest.StartsWith($targetRoot,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe archive path'}
        $src=Resolve-EndCapperSource $sourceRoot $rel
        $expected=(Get-FileHash -LiteralPath $src -Algorithm SHA256).Hash
        $sha=[Security.Cryptography.SHA256]::Create();$stream=$entry.Open()
        try {$archiveHash=[BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-','')}finally{$stream.Dispose();$sha.Dispose()}
        if($archiveHash -ne $expected){throw "Package differs from source: $rel"}
        $old=if(Test-Path -LiteralPath $dest){(Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash}else{$null}
        $record=[PSCustomObject]@{File=$rel;Source=$src;Destination=$dest;Expected=$expected;Previous=$old}
        $records+=$record
        if($old -ne $expected){$changes+=$record}
    }
}finally{$zip.Dispose()}
New-Item -ItemType Directory -Path $backup -Force | Out-Null
foreach($record in $changes){
    if($record.Previous){$prior=Join-Path $backup $record.File;New-Item -ItemType Directory -Path (Split-Path $prior -Parent) -Force | Out-Null;Copy-Item -LiteralPath $record.Destination -Destination $prior}
}
$changes | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backup 'changed-files.json')
foreach($record in $changes){New-Item -ItemType Directory -Path (Split-Path $record.Destination -Parent) -Force | Out-Null;Copy-Item -LiteralPath $record.Source -Destination $record.Destination -Force}
foreach($record in $records){if((Get-FileHash -LiteralPath $record.Destination -Algorithm SHA256).Hash -ne $record.Expected){throw "Installed hash mismatch: $($record.File)"}}
Write-Output "Installed $($changes.Count) changed files; verified $($records.Count) package files. Backup: $backup. SavedVariables untouched."

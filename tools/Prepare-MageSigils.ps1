param(
    [string]$Source = (Join-Path $PSScriptRoot '../../EndCapper/concepts/frost-fire-mages/sigils/Coldsnap-v3.png')
)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$cache=Join-Path $PSScriptRoot 'cache/mage-sigils'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$sourceBitmap=[Drawing.Bitmap]::new([IO.Path]::GetFullPath($Source))
function Write-Raw($bitmap,$path) {
    $rect=[Drawing.Rectangle]::new(0,0,$bitmap.Width,$bitmap.Height)
    $data=$bitmap.LockBits($rect,[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $bytes=[byte[]]::new($bitmap.Width*$bitmap.Height*4)
        for($row=0;$row -lt $bitmap.Height;$row++) {
            [Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($data.Scan0,$row*$data.Stride),$bytes,$row*$bitmap.Width*4,$bitmap.Width*4)
        }
        [IO.File]::WriteAllBytes($path,$bytes)
    } finally { $bitmap.UnlockBits($data) }
}
Write-Raw $sourceBitmap (Join-Path $cache 'Coldsnap.bgra')
@{width=$sourceBitmap.Width;height=$sourceBitmap.Height;source=[IO.Path]::GetFullPath($Source);sha256=(Get-FileHash -LiteralPath $Source).Hash} | ConvertTo-Json | Set-Content (Join-Path $cache 'source.json')
$sourceBitmap.Dispose()

# Restore the approved painted Combustion sources without redrawing their glyphs.
# Their existing PNG alpha already leaves the spaces between strokes transparent.
$concept=Join-Path $PSScriptRoot '../../EndCapper/concepts/frost-fire-mages/sigils'
$combustion=@{}
foreach($item in @(@('seal','Combustion-Seal-v2.png'),@('flame','Combustion-Flame-v3-transparent.png'))) {
    $file=Join-Path $concept $item[1]
    $bitmap=[Drawing.Bitmap]::new([IO.Path]::GetFullPath($file))
    try {
        Write-Raw $bitmap (Join-Path $cache ($item[0]+'.bgra'))
        $combustion[$item[0]]=@{width=$bitmap.Width;height=$bitmap.Height;source=[IO.Path]::GetFullPath($file);sha256=(Get-FileHash -LiteralPath $file).Hash}
    } finally { $bitmap.Dispose() }
}
$combustion | ConvertTo-Json -Depth 4 | Set-Content (Join-Path $cache 'combustion-source.json')
& node (Join-Path $PSScriptRoot 'Build-MageSigils.cjs')
if($LASTEXITCODE -ne 0){throw 'Sigil build failed'}

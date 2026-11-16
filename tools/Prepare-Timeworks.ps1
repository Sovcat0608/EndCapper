param([string]$SourceDirectory=(Join-Path $PSScriptRoot '../../EndCapper/concepts/timekeeper-timelost'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$cache=Join-Path $PSScriptRoot 'cache/timeworks'
New-Item -ItemType Directory -Force -Path $cache | Out-Null
$records=@()
foreach($item in @(@('Timekeeper','Timekeeper-v1.png'),@('Timelost','Timelost-v1.png'),@('Recess','layers/Timelost-gearless-v1.png'),@('Gears','layers/Timelost-gears-v2.png'))) {
    $source=[IO.Path]::GetFullPath((Join-Path $SourceDirectory $item[1]))
    $image=[Drawing.Bitmap]::new($source)
    try {
        $data=$image.LockBits([Drawing.Rectangle]::new(0,0,$image.Width,$image.Height),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $pixels=[byte[]]::new($image.Width*$image.Height*4)
            for($y=0;$y -lt $image.Height;$y++) { [Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($data.Scan0,$y*$data.Stride),$pixels,$y*$image.Width*4,$image.Width*4) }
            [IO.File]::WriteAllBytes((Join-Path $cache ($item[0]+'.bgra')),$pixels)
        } finally {$image.UnlockBits($data)}
        $records+=@{name=$item[0];width=$image.Width;height=$image.Height;source=$source;sha256=(Get-FileHash -LiteralPath $source).Hash}
    } finally {$image.Dispose()}
}
$records | ConvertTo-Json | Set-Content (Join-Path $cache 'sources.json')
& node (Join-Path $PSScriptRoot 'Build-Timeworks.cjs')
if($LASTEXITCODE -ne 0){throw 'Timeworks preparation failed'}
& node (Join-Path $PSScriptRoot 'Build-TimeGlyphs.cjs')
if($LASTEXITCODE -ne 0){throw 'Timeworks glyph preparation failed'}

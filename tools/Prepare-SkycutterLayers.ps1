param([Parameter(Mandatory)][string]$SourceDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$root=Split-Path $PSScriptRoot -Parent
foreach($name in @('SkycutterIsland','SkycutterBoat')) {
    $source=[Drawing.Bitmap]::new((Join-Path $SourceDirectory "$name-v1.png"))
    $target=[Drawing.Bitmap]::new(1024,1024,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        if($source.Width -ne 1536 -or $source.Height -ne 1024){throw 'Expected registered 1536x1024 layers'}
        $g=[Drawing.Graphics]::FromImage($target)
        try {
            $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
            $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.DrawImage($source,0,0,1024,1024)
        } finally {$g.Dispose()}
        $bits=$target.LockBits([Drawing.Rectangle]::new(0,0,1024,1024),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $data=[byte[]]::new(1024*1024*4)
            [Runtime.InteropServices.Marshal]::Copy($bits.Scan0,$data,0,$data.Length)
        } finally {$target.UnlockBits($bits)}
    } finally {$source.Dispose();$target.Dispose()}
    $header=[byte[]]::new(18);$header[2]=2;$header[16]=32;$header[17]=40
    [BitConverter]::GetBytes([uint16]1024).CopyTo($header,12)
    [BitConverter]::GetBytes([uint16]1024).CopyTo($header,14)
    $output=if($name -eq 'SkycutterIsland'){Join-Path $root 'Media/Skycutter.tga'}else{Join-Path $SourceDirectory 'SkycutterBoat.tga'}
    [IO.File]::WriteAllBytes($output,[byte[]]($header+$data))
    $bottom=-1
    for($y=0;$y -lt 1024;$y++){
        $count=0
        for($x=0;$x -lt 1024;$x++){if($data[3+($y*1024+$x)*4] -ge 200){$count++}}
        if($count -ge 12){$bottom=$y}
    }
    "$name baseline=$bottom/1024"
}
node (Join-Path $PSScriptRoot 'Build-SkycutterMipmaps.cjs') (Join-Path $SourceDirectory 'SkycutterBoat.tga')
if($LASTEXITCODE -ne 0){throw 'Boat mipmap encoding failed'}

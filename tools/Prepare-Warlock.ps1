param([Parameter(Mandatory)][string]$SourceDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$media=Join-Path (Split-Path $PSScriptRoot -Parent) 'Media'
$sources=@{Hexbound='Hexbound-v1.png'; Soulbound='SoulboundBase-v1.png'; SoulboundCrystal='SoulboundCrystal-v1.png'}
foreach($name in $sources.Keys){
    $size=if($name -eq 'SoulboundCrystal'){256}else{512}
    $source=[Drawing.Bitmap]::FromFile((Join-Path $SourceDirectory $sources[$name]))
    $target=[Drawing.Bitmap]::new($size,$size,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $g=[Drawing.Graphics]::FromImage($target)
        $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
        $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($source,0,0,$size,$size)
        $g.Dispose()
        $bits=$target.LockBits([Drawing.Rectangle]::new(0,0,$size,$size),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $data=[byte[]]::new($size*$size*4)
            [Runtime.InteropServices.Marshal]::Copy($bits.Scan0,$data,0,$data.Length)
        } finally {$target.UnlockBits($bits)}
    } finally {$target.Dispose(); $source.Dispose()}
    $header=[byte[]]::new(18)
    $header[2]=2; $header[16]=32; $header[17]=40
    [BitConverter]::GetBytes([uint16]$size).CopyTo($header,12)
    [BitConverter]::GetBytes([uint16]$size).CopyTo($header,14)
    [IO.File]::WriteAllBytes((Join-Path $media "$name.tga"),[byte[]]($header+$data))
    $bottom=-1
    for($y=0;$y -lt $size;$y++){
        $count=0
        for($x=0;$x -lt $size;$x++){if($data[3+($y*$size+$x)*4] -ge 200){$count++}}
        if($count -ge 6){$bottom=$y}
    }
    "$name $size x $size; baseline $bottom/$size"
}

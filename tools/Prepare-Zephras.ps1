param([Parameter(Mandatory)][string]$SourceDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$source=[Drawing.Bitmap]::FromFile((Join-Path $SourceDirectory 'Zephras-Isle-Sisters-v1.png'))
try {
    if($source.Width -ne 2172 -or $source.Height -ne 724){throw 'Expected approved 2172x724 sheet'}
    for($y=0;$y -lt $source.Height;$y++){
        if($source.GetPixel(1086,$y).A -ne 0){throw 'Split line is not transparent'}
    }
    $index=0
    foreach($name in @('Zephyr','Skycutter')) {
        $part=$source.Clone([Drawing.Rectangle]::new(1086*$index,0,1086,724),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $target=[Drawing.Bitmap]::new(1024,1024,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $part.Save((Join-Path $SourceDirectory "$name-v1.png"),[Drawing.Imaging.ImageFormat]::Png)
            $g=[Drawing.Graphics]::FromImage($target)
            try {
                $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
                $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.DrawImage($part,0,0,1024,1024)
            } finally {$g.Dispose()}
            $bits=$target.LockBits([Drawing.Rectangle]::new(0,0,1024,1024),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $data=[byte[]]::new(1024*1024*4)
                [Runtime.InteropServices.Marshal]::Copy($bits.Scan0,$data,0,$data.Length)
            } finally {$target.UnlockBits($bits)}
        } finally {$part.Dispose();$target.Dispose()}
        $header=[byte[]]::new(18);$header[2]=2;$header[16]=32;$header[17]=40
        [BitConverter]::GetBytes([uint16]1024).CopyTo($header,12)
        [BitConverter]::GetBytes([uint16]1024).CopyTo($header,14)
        $media=Join-Path (Split-Path $PSScriptRoot -Parent) "Media/$name.tga"
        [IO.File]::WriteAllBytes($media,[byte[]]($header+$data))
        $bottom=-1
        for($y=0;$y -lt 1024;$y++){
            $count=0
            for($x=0;$x -lt 1024;$x++){if($data[3+($y*1024+$x)*4] -ge 200){$count++}}
            if($count -ge 12){$bottom=$y}
        }
        "$name baseline=$bottom/1024; source=1086x724; runtime=1024x1024, displayed=225x150"
        $index++
    }
} finally {$source.Dispose()}

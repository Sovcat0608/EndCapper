param([Parameter(Mandatory)][string]$SourceDirectory)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$source=[Drawing.Bitmap]::FromFile((Join-Path $SourceDirectory 'Sylvanas-sisters-v1.png'))
try {
    if($source.Width -ne 1774 -or $source.Height -ne 887){throw 'Expected approved 1774x887 sheet'}
    for($y=0;$y -lt 887;$y++){
        # The generated empty gap contains a few alpha-1 pixels; preserve them.
        if($source.GetPixel(887,$y).A -gt 2){throw 'Split line intersects visible artwork'}
    }
    $index=0
    foreach($name in @('Banshee','HighGeneral')) {
        $part=$source.Clone([Drawing.Rectangle]::new(887*$index,0,887,887),[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $target=[Drawing.Bitmap]::new(512,512,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $part.Save((Join-Path $SourceDirectory "$name-v1.png"),[Drawing.Imaging.ImageFormat]::Png)
            $g=[Drawing.Graphics]::FromImage($target)
            try {
                $g.CompositingMode=[Drawing.Drawing2D.CompositingMode]::SourceCopy
                $g.InterpolationMode=[Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $g.DrawImage($part,0,0,512,512)
            } finally {$g.Dispose()}
            $target.Save((Join-Path $SourceDirectory "$name-runtime-preview.png"),[Drawing.Imaging.ImageFormat]::Png)
            $bits=$target.LockBits([Drawing.Rectangle]::new(0,0,512,512),[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $data=[byte[]]::new(512*512*4)
                [Runtime.InteropServices.Marshal]::Copy($bits.Scan0,$data,0,$data.Length)
            } finally {$target.UnlockBits($bits)}
        } finally {$part.Dispose();$target.Dispose()}
        $header=[byte[]]::new(18);$header[2]=2;$header[16]=32;$header[17]=40
        [BitConverter]::GetBytes([uint16]512).CopyTo($header,12)
        [BitConverter]::GetBytes([uint16]512).CopyTo($header,14)
        [IO.File]::WriteAllBytes((Join-Path (Split-Path $PSScriptRoot -Parent) "Media/$name.tga"),[byte[]]($header+$data))
        $bottom=-1
        for($y=0;$y -lt 512;$y++){
            $count=0
            for($x=0;$x -lt 512;$x++){if($data[3+($y*512+$x)*4] -ge 200){$count++}}
            if($count -ge 6){$bottom=$y}
        }
        "$name baseline=$bottom/512; source=887x887; runtime=512x512; display=150x150"
        $index++
    }
} finally {$source.Dispose()}

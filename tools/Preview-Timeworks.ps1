$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
function Read-Tga([string]$path) {
 $b=[IO.File]::ReadAllBytes($path);$w=[BitConverter]::ToUInt16($b,12);$h=[BitConverter]::ToUInt16($b,14)
 $im=[Drawing.Bitmap]::new($w,$h);$d=$im.LockBits([Drawing.Rectangle]::new(0,0,$w,$h),[Drawing.Imaging.ImageLockMode]::WriteOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
 try {for($y=0;$y -lt $h;$y++){[Runtime.InteropServices.Marshal]::Copy($b,18+$y*$w*4,[IntPtr]::Add($d.Scan0,$y*$d.Stride),$w*4)}} finally {$im.UnlockBits($d)}
 return $im
}
$cache=Join-Path $PSScriptRoot 'cache/timeworks'
$out=Join-Path $PSScriptRoot '../../EndCapper/concepts/timekeeper-timelost/layers'
$back=Read-Tga "$cache/TimelostBackdrop.tga";$front=Read-Tga "$cache/TimelostFront.tga"
$canvas=[Drawing.Bitmap]::new(2172,724);$g=[Drawing.Graphics]::FromImage($canvas);$g.Clear([Drawing.Color]::FromArgb(255,32,35,40));$g.InterpolationMode='HighQualityBicubic'
$specs=@(@(866,298,144,32,1),@(818,413,114,24,-1),@(914,440,128,28,1))
for($phase=0;$phase -lt 2;$phase++) {
 $g.DrawImage($back,$phase*1086,0,1086,724)
 for($i=0;$i -lt 3;$i++) {
  $im=Read-Tga "$cache/TimelostGear$($i+1).tga";$s=$specs[$i];$state=$g.Save()
  $g.TranslateTransform($phase*1086+$s[0],$s[1]);$g.RotateTransform($phase*7*360/$s[3]*$s[4]);$g.DrawImage($im,[single](-$s[2]/2),[single](-$s[2]/2),[single]$s[2],[single]$s[2]);$g.Restore($state);$im.Dispose()
 }
 $g.DrawImage($front,$phase*1086,0,1086,724)
}
$g.Dispose();$canvas.Save("$out/Timelost-layer-preview.png",[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();$back.Dispose();$front.Dispose()
$im=Read-Tga (Join-Path $PSScriptRoot '../Media/TimekeeperSandAtlasCAS.tga');$im.Save("$out/Timekeeper-sand-preview.png",[Drawing.Imaging.ImageFormat]::Png);$im.Dispose()
$source=[Drawing.Bitmap]::new((Join-Path $out '../Timekeeper-v1.png'))
$atlas=Read-Tga (Join-Path $PSScriptRoot '../Media/TimekeeperSandAtlasCAS.tga')
$canvas=[Drawing.Bitmap]::new(1086,724);$g=[Drawing.Graphics]::FromImage($canvas);$g.Clear([Drawing.Color]::FromArgb(255,32,35,40));$g.DrawImage($source,0,0,1086,724)
$g.DrawImage($atlas,[Drawing.Rectangle]::new(300,380,184,208),[Drawing.Rectangle]::new(3,3,122,122),[Drawing.GraphicsUnit]::Pixel)
$g.Dispose();$canvas.Save("$out/Timekeeper-composite-preview.png",[Drawing.Imaging.ImageFormat]::Png);$canvas.Dispose();$source.Dispose();$atlas.Dispose()

param([string]$SourceDirectory = (Join-Path $PSScriptRoot '../../EndCapper/concepts/frost-fire-mages'))
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Drawing
$output=Join-Path $PSScriptRoot 'cache/mage-books'
New-Item -ItemType Directory -Force -Path $output | Out-Null
$records=@()
foreach($sheet in @(,@('Books-pair-v6.png','Book'))) {
    $image=[System.Drawing.Bitmap]::new((Join-Path $SourceDirectory $sheet[0]))
    try {
        $width=[int]($image.Width/2)
        for($side=0;$side -lt 2;$side++) {
            $name=@('Frostbound','Emberbound')[$side]+$sheet[1]
            $crop=$image.Clone([System.Drawing.Rectangle]::new($side*$width,0,$width,$image.Height),[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
            try {
                $crop.Save((Join-Path $output "$name.png"),[System.Drawing.Imaging.ImageFormat]::Png)
                $data=$crop.LockBits([System.Drawing.Rectangle]::new(0,0,$width,$crop.Height),[System.Drawing.Imaging.ImageLockMode]::ReadOnly,[System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                try {
                    $pixels=[byte[]]::new($width*$crop.Height*4)
                    for($y=0;$y -lt $crop.Height;$y++) {
                        [Runtime.InteropServices.Marshal]::Copy([IntPtr]::Add($data.Scan0,$y*$data.Stride),$pixels,$y*$width*4,$width*4)
                    }
                    [IO.File]::WriteAllBytes((Join-Path $output "$name.bgra"),$pixels)
                } finally {$crop.UnlockBits($data)}
                $records+=@{name=$name;width=$width;height=$crop.Height;source=$sheet[0];sha256=(Get-FileHash -LiteralPath (Join-Path $SourceDirectory $sheet[0])).Hash}
            } finally {$crop.Dispose()}
        }
    } finally {$image.Dispose()}
}
$records | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $output 'sources.json')
if($BasesOnly){& node (Join-Path $PSScriptRoot 'Build-MageBooks.cjs') --bases-only}
else {& node (Join-Path $PSScriptRoot 'Build-MageBooks.cjs')}
if($LASTEXITCODE -ne 0){throw 'Mage asset preparation failed'}

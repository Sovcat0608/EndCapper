param([string]$SourceDirectory = (Join-Path $PSScriptRoot '../../EndCapper/concepts/rogue-sisters'))
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$cache = Join-Path $PSScriptRoot 'cache/rogue'
New-Item -ItemType Directory -Force -Path $cache | Out-Null

function Export-Pixels($file, $name, $x, $width, $height, [switch]$Mirror) {
    $original = [Drawing.Bitmap]::new((Join-Path $SourceDirectory $file))
    try {
        if ($original.Width -lt ($x+$width) -or $original.Height -ne $height) { throw "Unexpected source geometry for $file" }
        if ($Mirror) { $original.RotateFlip([Drawing.RotateFlipType]::RotateNoneFlipX) }
        $rect = [Drawing.Rectangle]::new($x,0,$width,$height)
        $data = $original.LockBits($rect,[Drawing.Imaging.ImageLockMode]::ReadOnly,[Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $bytes = [byte[]]::new($width*$height*4)
            for ($row=0; $row -lt $height; $row++) {
                $address = [IntPtr]::Add($data.Scan0,$row*$data.Stride)
                [Runtime.InteropServices.Marshal]::Copy($address,$bytes,$row*$width*4,$width*4)
            }
            [IO.File]::WriteAllBytes((Join-Path $cache "$name.bgra"),$bytes)
        } finally { $original.UnlockBits($data) }
    } finally { $original.Dispose() }
}

$review = 'armor-baselines-review-v2'
foreach ($name in @('Gloomfang','Venomveil','GloomfangDagger','VenomveilDagger')) {
    # Mirror the artwork source, keeping native effects in the original cap coordinates.
    Export-Pixels "$review/$name.png" $name 0 1086 724 -Mirror
}
node (Join-Path $PSScriptRoot 'Build-Rogue.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Rogue artwork conversion failed' }

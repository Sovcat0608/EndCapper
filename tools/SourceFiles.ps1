# Player-only allowlist shared by packaging and installation.
function Get-EndCapperRuntimeFiles {
    @('EndCapper.toc', 'Model.lua', 'Layouts.lua', 'Clipping.lua', 'NativeSmoke.xml', 'NativeSmoke.lua', 'Glyphs.lua', 'Liquid.lua', 'Arcane.lua', 'Skycutter.lua', 'MageBooks.lua', 'MageSigils.lua', 'Molten.lua', 'Frost.lua', 'Moonwell.lua', 'Halos.lua', 'Effects.lua', 'Core.lua', 'Options.lua')
}

function Get-EndCapperPackageFiles {
    $files = (Get-EndCapperRuntimeFiles) + @('README.md', 'LICENSE', 'CHANGELOG.md')
    foreach($name in @('ColdsnapDetails','ColdsnapPupilAtlas','ColdsnapFlowAtlas','CombustionSeal','CombustionFlameAtlas')) {$files += "Media/$name.tga"}
    foreach($name in @('Frostbound','Emberbound')) {
        foreach($size in @(192,288,384,480,576,768,887)) {
            foreach($suffix in @('CAS','Emission','Bloom')) {$files += "Media/${name}Book${suffix}Size$size.tga"}
        }
    }
    foreach($name in @('Seraph','Sanctum','Umbra','Eclipse')) {$files += "Media/$name.tga"}
    foreach($name in @('Undead','Lordaeron')) {$files += "Media/$name.tga"}
    $files += @('Media/KirinTor.tga','Media/EcapLogo.tga')
    $files += @('Media/Banshee.tga','Media/HighGeneral.tga')
    $files += @('Media/Zephyr.tga','Media/Skycutter.tga','Media/SkycutterBoatStaticProbe.tga')
    foreach($source in (Get-Content -LiteralPath (Join-Path $PSScriptRoot 'artwork-cas.json') -Raw | ConvertFrom-Json)) {
        $files += ($source -replace '\.(tga|blp)$','CAS.$1')
    }
    foreach($size in @(192,288,384,480,576,768,960)) {$files += "Media/SkycutterBoatSize$size.tga"}
    foreach($size in @(192,288,384,480,576,768,960)) {$files += "Media/SkycutterBoatCASSize$size.tga"}
    $files += 'THIRD-PARTY-CAS.txt'
    foreach($name in @('ArcaneCrystal','ArcaneSigil','SoulboundCrystal','SoulboundCrystalEmission')) {
        foreach($size in @(64,96,128,192,256)) {$files += @("Media/${name}CASSize$size.tga","Media/${name}Size$size.tga")}
    }
    $files += @('Media/Cryptgate.tga','Media/Plaguewell.tga','Media/CryptgateLiquidAtlas.tga','Media/PlaguewellLiquidAtlas.tga')
    foreach($name in @('Hexbound','Soulbound')) {
        foreach($suffix in @('','Emission','Bloom')) {$files += "Media/$name$suffix.tga"}
    }
    $files += @('Media/SoulboundCrystal.blp','Media/SoulboundCrystalEmission.blp')
    foreach($name in @('FrostmourneHilt','FrostmourneBlade','FrostmourneHiltIce','FrostmourneBladeIce')) {$files += "Media/$name.tga"}
    foreach($name in @('WorgenBlack','WorgenWhite')) {$files += "Media/$name.tga"}
    foreach($name in @('SeraphHalo','UmbraHalo','ArcaneCrystal','ArcaneSigil')) {$files += "Media/$name.blp"}
    foreach($name in @('Moonwell','MoonwellGlyphs','MoonwellMoon','MoonwellWater','MoonwellBounce')) { $files += "Media/$name.tga" }
    foreach ($art in @('Moonbough','VerdantRoot','LunarRelic','StormhornTotem','Felwing','FelwingGlyphAtlas','VioletSpire','Cinderforged','Cindermaw','CinderforgedEmission','CinderforgedBloom','CindermawEmission','CindermawBloom','Rimeforged','Rimeguard','RimeforgedRunes','RimeforgedRunesBloom','RimeforgedIce','RimeforgedIceBloom','RimeguardRunes','RimeguardRunesBloom','RimeguardIce','RimeguardIceBloom','RimeguardEyes','RimeguardEyesBloom')) {
        $files += "Media/$art.tga"
    }
    # Static bases use originals; animated layers retain CAS. Comparison variants stay build-only.
    $originalArtwork=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'artwork-cas.json') -Raw | ConvertFrom-Json)
    $baselineArtwork=@(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'baseline-artwork.json') -Raw | ConvertFrom-Json)
    $baselineCAS=@($baselineArtwork | ForEach-Object { $_ -replace '\.(tga|blp)$','CAS.$1' })
    return @($files | Where-Object {
        ($originalArtwork -notcontains $_ -or $baselineArtwork -contains $_) -and
        $baselineCAS -notcontains $_ -and
        $_ -notmatch '^Media/(SkycutterBoat|ArcaneCrystal|ArcaneSigil|SoulboundCrystal|SoulboundCrystalEmission)Size\d+\.tga$' -and
        $_ -notmatch '^Media/(ArcaneCrystal|ArcaneSigil|SoulboundCrystal|SoulboundCrystalEmission)\.blp$'
    })
}

function Resolve-EndCapperSource([string]$Root,[string]$Relative) {
    $local=Join-Path $Root $Relative
    if(Test-Path -LiteralPath $local -PathType Leaf){return $local}
    $map=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'external-media.json') -Raw | ConvertFrom-Json
    $property=$map.PSObject.Properties[$Relative.Replace('\','/')]
    if(-not $property -or -not(Test-Path -LiteralPath $property.Value -PathType Leaf)){throw "Missing source: $Relative"}
    return [string]$property.Value
}

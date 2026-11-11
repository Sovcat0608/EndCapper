# Player-only allowlist shared by packaging and installation.
function Get-EndCapperRuntimeFiles {
    @('EndCapper.toc', 'Model.lua', 'Layouts.lua', 'Clipping.lua', 'NativeSmoke.xml', 'NativeSmoke.lua', 'Glyphs.lua', 'Liquid.lua', 'Arcane.lua', 'Molten.lua', 'Frost.lua', 'Moonwell.lua', 'Halos.lua', 'Effects.lua', 'Core.lua', 'Options.lua')
}

function Get-EndCapperPackageFiles {
    $files = (Get-EndCapperRuntimeFiles) + @('README.md', 'LICENSE', 'CHANGELOG.md')
    foreach($name in @('Seraph','Sanctum','Umbra','Eclipse')) {$files += "Media/$name.tga"}
    foreach($name in @('Undead','Lordaeron')) {$files += "Media/$name.tga"}
    $files += @('Media/KirinTor.tga','Media/EcapLogo.tga')
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
    return $files
}

function Resolve-EndCapperSource([string]$Root,[string]$Relative) {
    $local=Join-Path $Root $Relative
    if(Test-Path -LiteralPath $local -PathType Leaf){return $local}
    $map=Get-Content -LiteralPath (Join-Path $PSScriptRoot 'external-media.json') -Raw | ConvertFrom-Json
    $property=$map.PSObject.Properties[$Relative.Replace('\','/')]
    if(-not $property -or -not(Test-Path -LiteralPath $property.Value -PathType Leaf)){throw "Missing source: $Relative"}
    return [string]$property.Value
}

local _, E = ...
E.schemaVersion = 34
-- Approved multi-art bake from applied 2026-11-10 save; see docs/rebake-rc14.md.
E.UndeadArtworks={skull=true,lordaeron=true}
E.WorgenArtworks={wolf=true,whiteWorgen=true}
E.FrostmourneArtworks={frostmourneHilt=true,frostmourneBlade=true}
E.PriestArtworks={seraph="Seraph",sanctum="Sanctum",umbra="Umbra",eclipse="Eclipse"}
E.HaloArtworks={seraph="SeraphHalo",umbra="UmbraHalo"}
E.PriestEffectPairs={seraph={"holyGlow","sunRays"},sanctum={"holyGlow","sunRays"},
    umbra={"voidGlow","voidSmoke"},eclipse={"voidGlow","voidSmoke"}}
-- Approved multi-art calibration, 2026-11-10 13:27:45 UTC save.
-- Coordinates remain artwork-relative and mirror normally on either cap.
E.SkullEffect = {nativeEffect="amberFlow", trailSize=89, trailAngle=107, trailX=-30, trailY=-1, trailOpacity=26,effectLayer="front"}
-- Approved Shadowfang LEFT / Snowfang RIGHT effect bake, 2026-11-10 21:07:49 UTC.
-- Only native calibration is baked; preserve personal artwork/placement overrides.
E.WolfEffect = {nativeEffect="coldFlame", trailSize=100, trailAngle=-113, trailX=-98, trailY=28, trailOpacity=64,effectLayer="front"}
E.EffectProfiles = {skull=E.SkullEffect, wolf=E.WolfEffect}
E.EffectProfiles.whiteWorgen={nativeEffect="amberFlow",trailSize=100,trailAngle=113,trailX=34,trailY=17,trailOpacity=27,effectLayer="front"}
E.EffectProfiles.lordaeron={nativeEffect="amberFlow",trailSize=157,trailAngle=-180,trailX=34,trailY=-29,trailOpacity=6,effectLayer="front"}
-- Approved Seraph/Umbra LEFT calibration from the same save.
-- Offsets stay artwork-relative and mirror normally on either cap.
E.EffectProfiles.seraph={nativeEffect="holyGlow",trailSize=171,trailAngle=90,trailX=-33,trailY=30,trailOpacity=11,effectLayer="back"}
E.EffectProfiles.umbra={nativeEffect="voidGlow",trailSize=150,trailAngle=90,trailX=-39,trailY=39,trailOpacity=30,effectLayer="back"}
-- Approved Sanctum/Eclipse LEFT calibration from the same save.
E.EffectProfiles.sanctum={nativeEffect="holyGlow",trailSize=149,trailAngle=90,trailX=-41,trailY=-7,trailOpacity=6,effectLayer="back"}
E.EffectProfiles.eclipse={nativeEffect="voidGlow",trailSize=104,trailAngle=90,trailX=-45,trailY=27,trailOpacity=30,effectLayer="front"}
-- Moonwell LEFT calibration; base glow unchanged.
E.EffectProfiles.moonwell={nativeEffect="moonwellGlow",trailSize=200,trailAngle=90,trailX=-16,trailY=5,trailOpacity=67,effectLayer="front"}
E.devArtworks = {wolf=true, moonbough=true, verdantRoot=true, lunarRelic=true, stormhornTotem=true, felwing=true, violetSpire=true, cinderforged=true, cindermaw=true}
E.MoltenArtworks = {cinderforged="Cinderforged",cindermaw="Cindermaw"}
E.FrostArtworks = {rimeforged="Rimeforged",rimeguard="Rimeguard"}
E.devArtworks.moonwell=true
E.devArtworks.skull=true
E.devArtworks.lordaeron=true
E.devArtworks.whiteWorgen=true
-- Baked from the left Frosthilt and right Frostblade calibration.
for art in pairs(E.FrostmourneArtworks) do E.devArtworks[art]=true end
E.EffectProfiles.frostmourneHilt={nativeEffect="frostGlow",trailSize=110,trailAngle=90,
    trailX=60,trailY=-36,trailOpacity=55,effectLayer="front"}
E.EffectProfiles.frostmourneBlade={nativeEffect="frostGlow",trailSize=110,trailAngle=90,
    trailX=-51,trailY=-34,trailOpacity=37,effectLayer="front"}
for art in pairs(E.PriestEffectPairs) do E.devArtworks[art]=true end
for art in pairs(E.FrostArtworks) do
    E.devArtworks[art]=true
end
-- Approved LEFT calibration for both frost designs, 2026-11-10.
E.EffectProfiles.rimeforged={nativeEffect="coldFlame",trailSize=176,trailAngle=171,trailX=-150,trailY=-5,trailOpacity=26,effectLayer="front"}
E.EffectProfiles.rimeguard={nativeEffect="coldFlame",trailSize=93,trailAngle=129,trailX=-89,trailY=15,trailOpacity=65,effectLayer="front"}
-- Cinderforged retained; Cindermaw approved LEFT calibration, 2026-11-10.
-- Geometry mirrors with artwork; personal cap placement is not a default.
E.EffectProfiles.cinderforged={nativeEffect="fireGlow",trailSize=164,trailAngle=90,trailX=-37,trailY=-21,trailOpacity=43,effectLayer="front"}
E.EffectProfiles.cindermaw={nativeEffect="fireGlow",trailSize=124,trailAngle=90,trailX=3,trailY=-45,trailOpacity=32,effectLayer="front"}
-- Approved on both caps in the 2026-11-09 09:41:38 applied save.
E.ArcaneSealSize = 153 -- Percentage of RC6 geometry; retain existing saved percentages.
E.EffectProfiles.violetSpire = {nativeEffect="arcaneGlow",trailSize=150,trailAngle=90,trailX=-23,trailY=14,trailOpacity=61,effectLayer="front"}
-- A separate profile keeps the sister's saved tuning independent of the spire.
E.EffectProfiles.kirinTor={}
for key,value in pairs(E.EffectProfiles.violetSpire) do E.EffectProfiles.kirinTor[key]=value end
E.devArtworks.kirinTor=true
-- Moonbough LEFT / Lunar RIGHT calibration, 2026-11-10; Verdant retained.
-- Offsets remain centre-relative and mirror with artwork; preserve saved overrides.
E.EffectProfiles.moonbough = {nativeEffect="moonlight",moonlight=true,trailSize=200,trailAngle=0,trailX=-48,trailY=-15,trailOpacity=40,effectLayer="front"}
E.EffectProfiles.verdantRoot = {nativeEffect="moonlight",moonlight=true,trailSize=182,trailAngle=0,trailX=-42,trailY=-17,trailOpacity=65}
E.EffectProfiles.lunarRelic = {nativeEffect="moonlight",moonlight=true,trailSize=186,trailAngle=0,trailX=-44,trailY=-7,trailOpacity=39,effectLayer="front"}
-- User-calibrated right cap, flipped (2026-11-09). Both totem effects render together.
E.EffectProfiles.stormhornTotem = {nativeEffect="blueGlow",trailSize=200,trailAngle=90,trailX=43,trailY=9,trailOpacity=100}
-- User-calibrated right cap, flipped (2026-11-09). Flat storage stays Glow;
-- new selections use Dripping alongside the independent registered glyph pulse.
E.EffectProfiles.felwing = {nativeEffect="felGlow",trailSize=175,trailAngle=90,trailX=60,trailY=16,trailOpacity=20}
E.effectChoices = {{id="moonlight",name="Moonlight glow"},{id="faerieFire",name="Faerie Fire"},{id="blueGlow",name="Blue Glow"},{id="broadFlame",name="Broad Blue Flame"},{id="felGlow",name="Fel Green Glow"},{id="felDrip",name="Fel Green Dripping"},{id="coldFlame",name="Cold flame"},{id="arcaneGlow",name="Arcane Glow"}}
E.effectChoices[#E.effectChoices+1]={id="fireGlow",name="Fire Glow"}
E.effectChoices[#E.effectChoices+1]={id="fireFlame",name="Fire"}
E.effectChoices[#E.effectChoices+1]={id="frostEnchant",name="Frost Form"}
E.effectChoices[#E.effectChoices+1]={id="moonwellGlow",name="Azure Glow"}
E.effectChoices[#E.effectChoices+1]={id="waterRipple",name="Water Ripples"}
E.effectChoices[#E.effectChoices+1]={id="holyGlow",name="Large Holy Glow"}
E.effectChoices[#E.effectChoices+1]={id="sunRays",name="Divine Radiance"}
E.effectChoices[#E.effectChoices+1]={id="voidGlow",name="Large Void Glow"}
E.effectChoices[#E.effectChoices+1]={id="voidSmoke",name="Void Smoke"}
E.effectChoices[#E.effectChoices+1]={id="amberFlow",name="Amber Flow"}
E.effectChoices[#E.effectChoices+1]={id="rotFog",name="Rot Fog"}
E.effectChoices[#E.effectChoices+1]={id="kirinSeal",name="Kirin Tor Seal"}
E.effectChoices[#E.effectChoices+1]={id="worgenGloom",name="Gloom"}
E.effectChoices[#E.effectChoices+1]={id="frostGlow",name="Blue Frost Glow"}
E.effectChoices[#E.effectChoices+1]={id="frostMist",name="Icy Mist"}
local thirdEffect = {frostmourneHilt = "coldFlame"}
local function alternateEffect(art)
    if E.FrostmourneArtworks[art] then return "frostMist" end
    if E.WorgenArtworks[art] then return "worgenGloom" end
    if art=="kirinTor" then return "kirinSeal" end
    if E.UndeadArtworks[art] then return "rotFog" end
    if E.PriestEffectPairs[art] then return E.PriestEffectPairs[art][2] end
    if art=="moonwell" then return "waterRipple" end
    if E.FrostArtworks[art] then return "frostEnchant" end
    if E.MoltenArtworks[art] then return "fireFlame" end
    if art=="stormhornTotem" then return "broadFlame" end
    if art=="felwing" then return "felDrip" end
    if art=="verdantRoot" then return "faerieFire" end
end
local function usesSeparateTuning(art, id)
    return id ~= nil and (id == alternateEffect(art) or id == thirdEffect[art])
end
function E.CanSelectEffect(art, id)
    local alternate=alternateEffect(art)
    return usesSeparateTuning(art,id) or (alternate~=nil and id==E.EffectProfiles[art].nativeEffect)
end
function E.GetEffectDefaults(art, id)
    local profile=E.EffectProfiles[art] or E.SkullEffect
    if art=="frostmourneHilt" and id=="coldFlame" then
        return {nativeEffect="coldFlame",trailSize=50,trailAngle=-162,
            trailX=-36,trailY=17,trailOpacity=98,effectLayer="front"}
    end
    if E.FrostmourneArtworks[art] and id=="frostMist" then
        local hilt=art=="frostmourneHilt"
        return {nativeEffect="frostMist",trailSize=130,trailAngle=90,
            trailX=hilt and 12 or -12,trailY=hilt and -74 or -101,trailOpacity=1,effectLayer="front"}
    end
    if art=="wolf" and id=="worgenGloom" then
        return {nativeEffect="worgenGloom",trailSize=90,trailAngle=-91,trailX=10,trailY=-91,trailOpacity=100,effectLayer="front"}
    end
    if art=="whiteWorgen" and id=="worgenGloom" then
        return {nativeEffect="worgenGloom",trailSize=91,trailAngle=-91,trailX=2,trailY=-79,trailOpacity=100,effectLayer="front"}
    end
    if art=="kirinTor" and id=="kirinSeal" then
        return {nativeEffect="kirinSeal",trailSize=100,trailAngle=90,trailX=-23,trailY=30,trailOpacity=75,effectLayer="front"}
    end
    if art=="skull" and id=="rotFog" then
        return {nativeEffect="rotFog",trailSize=91,trailAngle=90,trailX=-9,trailY=-73,trailOpacity=3,effectLayer="front"}
    end
    if art=="lordaeron" and id=="rotFog" then
        return {nativeEffect="rotFog",trailSize=89,trailAngle=90,trailX=12,trailY=-69,trailOpacity=3,effectLayer="front"}
    end
    if art=="sanctum" and id=="sunRays" then
        return {nativeEffect="sunRays",trailSize=150,trailAngle=-66,trailX=-40,trailY=-51,trailOpacity=1,effectLayer="front"}
    end
    if art=="eclipse" and id=="voidSmoke" then
        return {nativeEffect="voidSmoke",trailSize=200,trailAngle=18,trailX=65,trailY=-70,trailOpacity=18,effectLayer="front"}
    end
    if art=="seraph" and id=="sunRays" then
        -- Latest applied LEFT calibration, 2026-11-10 00:45:34 UTC.
        -- Replaces the earlier bake that left a bright radiance above a fresh right cap.
        return {nativeEffect="sunRays",trailSize=150,trailAngle=-66,trailX=-40,trailY=-51,trailOpacity=4,effectLayer="front"}
    end
    if art=="umbra" and id=="voidSmoke" then
        return {nativeEffect="voidSmoke",trailSize=200,trailAngle=39,trailX=76,trailY=-128,trailOpacity=20,effectLayer="front"}
    end
    if art=="moonwell" and id=="waterRipple" then
        return {nativeEffect="waterRipple",trailSize=59,trailAngle=90,trailX=-14,trailY=-20,trailOpacity=45,effectLayer="front"}
    end
    if art=="rimeforged" and id=="frostEnchant" then
        return {nativeEffect="frostEnchant",trailSize=200,trailAngle=-91,trailX=-39,trailY=72,trailOpacity=5,effectLayer="front"}
    end
    if art=="rimeguard" and id=="frostEnchant" then
        return {nativeEffect="frostEnchant",trailSize=180,trailAngle=-87,trailX=-30,trailY=43,trailOpacity=8,effectLayer="front"}
    end
    if art=="cinderforged" and id=="fireFlame" then
        return {nativeEffect="fireFlame",trailSize=156,trailAngle=172,trailX=-43,trailY=-10,trailOpacity=30,effectLayer="front"}
    end
    if art=="cindermaw" and id=="fireFlame" then
        return {nativeEffect="fireFlame",trailSize=150,trailAngle=180,trailX=-28,trailY=-10,trailOpacity=35,effectLayer="front"}
    end
    if art=="stormhornTotem" and id=="broadFlame" then
        return {nativeEffect="broadFlame",trailSize=70,trailAngle=90,trailX=44,trailY=54,trailOpacity=100,effectLayer="back"}
    end
    if art=="felwing" and id=="felDrip" then
        return {nativeEffect="felDrip",trailSize=100,trailAngle=90,trailX=67,trailY=-2,trailOpacity=43}
    end
    if id~="faerieFire" or not E.CanSelectEffect(art,id) then return profile end
    return {nativeEffect="faerieFire",moonlight=true,trailSize=100,trailAngle=90,
        trailX=0,trailY=0,trailOpacity=65}
end
function E.SelectedEffect(config)
    local tuning=config.devEffects and config.devEffects[config.art]
    if tuning and usesSeparateTuning(config.art,tuning.selectedEffect) then return tuning.selectedEffect end
    if config.art=="felwing" and (not tuning or tuning.selectedEffect~="felGlow") then return "felDrip" end
    return (E.EffectProfiles[config.art] or E.SkullEffect).nativeEffect
end
E.artworks = {
    { id = "skull", name = "Undead", path = "Interface\\AddOns\\EndCapper\\Media\\Undead.tga", width=225, height=150 },
    { id = "lordaeron", name = "Lordaeron", path = "Interface\\AddOns\\EndCapper\\Media\\Lordaeron.tga", width=225, height=150 },
    { id = "wolf", name = "Shadowfang", path = "Interface\\AddOns\\EndCapper\\Media\\WorgenBlack.tga", width=200, height=100 },
    { id = "whiteWorgen", name = "Snowfang", path = "Interface\\AddOns\\EndCapper\\Media\\WorgenWhite.tga", width=200, height=100 },
    { id = "moonbough", name = "Moonbough", path = "Interface\\AddOns\\EndCapper\\Media\\Moonbough.tga", width=225, height=150 },
    { id = "verdantRoot", name = "Verdant", path = "Interface\\AddOns\\EndCapper\\Media\\VerdantRoot.tga", width=225, height=150 },
    { id = "lunarRelic", name = "Lunar", path = "Interface\\AddOns\\EndCapper\\Media\\LunarRelic.tga", width=225, height=150 },
    { id = "stormhornTotem", name = "Stormhorn", path = "Interface\\AddOns\\EndCapper\\Media\\StormhornTotem.tga", width=225, height=150 },
    { id = "felwing", name = "Felwing", path = "Interface\\AddOns\\EndCapper\\Media\\Felwing.tga", width=225, height=150 },
    { id = "violetSpire", name = "Violetspire", path = "Interface\\AddOns\\EndCapper\\Media\\VioletSpire.tga", width=225, height=150 },
    { id = "kirinTor", name = "Kirin Tor", path = "Interface\\AddOns\\EndCapper\\Media\\KirinTor.tga", width=225, height=150 },
    { id = "cinderforged", name = "Cinderforged", path = "Interface\\AddOns\\EndCapper\\Media\\Cinderforged.tga", width=225, height=150 },
    { id = "cindermaw", name = "Cindermaw", path = "Interface\\AddOns\\EndCapper\\Media\\Cindermaw.tga", width=225, height=150 },
    { id = "rimeforged", name = "Rimeforged", path = "Interface\\AddOns\\EndCapper\\Media\\Rimeforged.tga", width=225, height=150 },
    { id = "rimeguard", name = "Rimeguard", path = "Interface\\AddOns\\EndCapper\\Media\\Rimeguard.tga", width=225, height=150 },
    { id = "moonwell", name = "Moonwell", path = "Interface\\AddOns\\EndCapper\\Media\\Moonwell.tga", width=225, height=150 },
    { id = "seraph", name = "Seraph", path = "Interface\\AddOns\\EndCapper\\Media\\Seraph.tga", width=225, height=150 },
    { id = "sanctum", name = "Sanctum", path = "Interface\\AddOns\\EndCapper\\Media\\Sanctum.tga", width=225, height=150 },
    { id = "umbra", name = "Umbra", path = "Interface\\AddOns\\EndCapper\\Media\\Umbra.tga", width=225, height=150 },
    { id = "eclipse", name = "Eclipse", path = "Interface\\AddOns\\EndCapper\\Media\\Eclipse.tga", width=225, height=150 },
    { id = "frostmourneHilt", name = "Frosthilt", path = "Interface\\AddOns\\EndCapper\\Media\\FrostmourneHilt.tga", overlay="Interface\\AddOns\\EndCapper\\Media\\FrostmourneHiltIce.tga", width=300, height=120 },
    { id = "frostmourneBlade", name = "Frostblade", path = "Interface\\AddOns\\EndCapper\\Media\\FrostmourneBlade.tga", overlay="Interface\\AddOns\\EndCapper\\Media\\FrostmourneBladeIce.tga", width=300, height=120 },
    { id = "default", name = "Default" },
    { id = "hidden", name = "Hidden" },
}
E.artworkByID = {}
for _, artwork in ipairs(E.artworks) do E.artworkByID[artwork.id] = artwork end
-- Chooser rows are also the authoritative sister relationships.
E.ArtworkPairs={{"skull","lordaeron"},{"wolf","whiteWorgen"},{"moonbough","lunarRelic"},
    {"verdantRoot","moonwell"},{"stormhornTotem"},{"felwing"},
    {"violetSpire","kirinTor"},{"cinderforged","cindermaw"},{"rimeforged","rimeguard"},
    {"seraph","sanctum"},{"umbra","eclipse"},{"frostmourneHilt","frostmourneBlade"},{"default","hidden"}}
E.PairByArt={}
for _,row in ipairs(E.ArtworkPairs) do
    for _,art in ipairs(row) do E.PairByArt[art]=row end
end
-- Saved flip remains the actual texture/effect mirror state for compatibility.
-- The UI checkbox reverses this artwork's default facing on the selected side.
function E.DefaultMirror(art, side)
    if E.FrostmourneArtworks[art] then return side==(art=="frostmourneHilt" and "right" or "left") end
    if art=="whiteWorgen" then return side=="left" end
    if art=="skull" then return side=="left" end
    if art=="lordaeron" then return side=="right" end
    if E.PriestArtworks[art] then return side=="left" end
    local profile=E.EffectProfiles[art]
    if not profile then return false end
    return side==((profile.moonlight or art=="moonwell" or art=="violetSpire" or art=="kirinTor" or E.MoltenArtworks[art] or E.FrostArtworks[art]) and "left" or "right")
end
function E.FlipChecked(config, side)
    return (config.flip==true) ~= E.DefaultMirror(config.art,side)
end
function E.SelectArtwork(config, art, side)
    if not E.artworkByID[art] then return end
    local reverse=E.FlipChecked(config,side)
    config.art=art
    config.flip=reverse ~= E.DefaultMirror(art,side)
end
local function number(value, fallback, low, high)
    if type(value) ~= "number" or value ~= value then return fallback end
    return math.max(low, math.min(high, value))
end
local function separationInitialized(pair)
    if pair.separationInitialized~=nil then return pair.separationInitialized==true end
    -- Preserve existing configured gaps, including a linked zero. An unused
    -- old unlinked zero is the historical default, not a chosen spacing.
    return type(pair.separation)=="number" and (pair.linked==true or pair.separation>0)
end
E.devEffectFields = {
    {"trailSize", "Effect size (%)", 50, 200},
    {"trailAngle", "Effect angle (degrees)", -180, 180},
    {"trailX", "Origin X: backward / forward", -150, 150},
    {"trailY", "Origin Y: up / down", -150, 150},
    {"trailOpacity", "Effect opacity (%)", 0, 100},
}
E.HaloFields={{"size","Halo size (%)",25,250},{"x","Halo X from artwork centre",-150,150},
    {"y","Halo Y from artwork centre",-150,150},{"opacity","Halo opacity (%)",0,100},
    {"period","Seconds per revolution",8,120}}
E.HaloDefaults={
    seraph={size=125,x=-40,y=31,opacity=100,period=40,reverse=false},
    umbra={size=132,x=-41,y=30,opacity=100,period=40,reverse=false},
}
local function normalizeHalo(value,art)
    value=type(value)=="table" and value or {}
    local defaults=E.HaloDefaults[art]
    local result={reverse=value.reverse==true}
    for _,spec in ipairs(E.HaloFields) do result[spec[1]]=number(value[spec[1]],defaults[spec[1]],spec[3],spec[4]) end
    return result
end
function E.GetHaloConfig(config)
    if not E.HaloArtworks[config.art] then return nil end
    return normalizeHalo(config.halos and config.halos[config.art],config.art)
end
function E.SetHalo(config,key,value)
    if not E.devMode or not E.HaloArtworks[config.art] then return end
    local known=key=="reverse"
    for _,spec in ipairs(E.HaloFields) do if spec[1]==key then known=true end end
    if not known then return end
    config.halos=config.halos or {}
    local tuning=E.GetHaloConfig(config);tuning[key]=value
    config.halos[config.art]=normalizeHalo(tuning,config.art)
end
function E.ResetHalo(config)
    if not E.devMode or not E.HaloArtworks[config.art] then return end
    config.halos=config.halos or {};config.halos[config.art]=normalizeHalo(nil,config.art)
end
local function normalizeEffect(value, defaults)
    value = type(value)=="table" and value or {}
    local result = {}
    for _, spec in ipairs(E.devEffectFields) do
        local key=spec[1]; result[key]=number(value[key], defaults[key], spec[3], spec[4])
    end
    return result
end
local function normalizeDevArtwork(value, art)
    value=type(value)=="table" and value or {}
    -- Old flat Cold flame calibration belongs to the removed blue trail.
    -- New records always carry one of these two selected-effect identifiers.
    if E.UndeadArtworks[art] and value.selectedEffect~="amberFlow" and value.selectedEffect~="rotFog" then value={} end
    -- The old Wind/Sparks geometry is retired. Start replacement effects at
    -- their own defaults while preserving all artwork/placement settings.
    if art=="stormhornTotem" and value.selectedEffect~="blueGlow" and value.selectedEffect~="broadFlame" and value.selectedEffect~="cloud" then value={} end
    local result=normalizeEffect(value,E.EffectProfiles[art])
    if art=="violetSpire" then result.sealSize=number(value.sealSize,E.ArcaneSealSize,25,250) end
    local alternate=alternateEffect(art)
    if alternate then
        -- Retire Moonbeam and its calibration; do not apply beam geometry to Faerie Fire.
        local selected=value.selectedEffect
        if (alternate=="faerieFire" and selected=="moonbeam")
            or (art=="stormhornTotem" and value.selectedEffect=="cloud")
            or (art=="felwing" and value.selectedEffect~="felGlow") then
            selected=alternate
        end
        result.selectedEffect=usesSeparateTuning(art,selected) and selected or E.EffectProfiles[art].nativeEffect
        for _, id in ipairs({alternate,thirdEffect[art]}) do
            if type(value[id])=="table" then result[id]=normalizeEffect(value[id],E.GetEffectDefaults(art,id)) end
        end
    end
    return result
end
function E.GetEffectConfig(config, effectID)
    local result = {}
    for k,v in pairs(config) do result[k]=v end
    result.trailSpeed=nil -- Discard obsolete tuning from older versions.
    local seal=config.devEffects and config.devEffects.violetSpire
    result.sealSize=config.art=="violetSpire" and number(seal and seal.sealSize,E.ArcaneSealSize,25,250) or nil
    local selected=E.CanSelectEffect(config.art,effectID) and effectID or E.SelectedEffect(config)
    local profile=E.GetEffectDefaults(config.art,selected)
    local override=E.devArtworks[config.art] and config.devEffects and config.devEffects[config.art]
    if usesSeparateTuning(config.art,selected) then override=override and override[selected] end
    for k,v in pairs(normalizeEffect(override,profile)) do result[k]=v end
    result.nativeEffect=profile.nativeEffect
    result.moonlight=profile.moonlight==true
    local layers=config.effectLayers and config.effectLayers[config.art]
    local layer=layers and layers[selected]
    result.effectLayer=(layer=="front" or layer=="back") and layer or (profile.effectLayer or "front")
    if E.PriestArtworks[config.art] and not E.PriestEffectPairs[config.art] then
        result.nativeEffect=nil;result.nativeSmoke=false;result.moonlight=false
    end
    return result
end
function E.SelectEffect(config, id)
    if not E.devMode or not E.CanSelectEffect(config.art,id) then return end
    config.devEffects=config.devEffects or {}
    local tuning=normalizeDevArtwork(config.devEffects[config.art],config.art)
    tuning.selectedEffect=id
    config.devEffects[config.art]=tuning
end
function E.SetDevEffect(config, key, value)
    if not E.devMode or not E.devArtworks[config.art] then return end
    local known=false
    for _, spec in ipairs(E.devEffectFields) do if spec[1]==key then known=true; break end end
    if not known then return end
    config.devEffects=config.devEffects or {}
    local selected=E.SelectedEffect(config)
    local profile=E.GetEffectDefaults(config.art,selected)
    local artwork=normalizeDevArtwork(config.devEffects[config.art],config.art)
    local separate=usesSeparateTuning(config.art,selected)
    local tuning=separate and normalizeEffect(artwork[selected],profile) or artwork
    tuning[key]=value
    if separate then artwork[selected]=normalizeEffect(tuning,profile) end
    config.devEffects[config.art]=normalizeDevArtwork(artwork,config.art)
end
function E.SetSealSize(config,value)
    if not E.devMode or config.art~="violetSpire" then return end
    config.devEffects=config.devEffects or {}
    local tuning=normalizeDevArtwork(config.devEffects.violetSpire,"violetSpire")
    tuning.sealSize=number(value,E.ArcaneSealSize,25,250)
    config.devEffects.violetSpire=tuning
end
function E.ResetDevEffect(config)
    if not E.devMode or not E.devArtworks[config.art] then return end
    local defaults=E.GetEffectDefaults(config.art,E.SelectedEffect(config))
    for _, spec in ipairs(E.devEffectFields) do E.SetDevEffect(config,spec[1],defaults[spec[1]]) end
    E.SetEffectLayer(config,defaults.effectLayer or "front")
    if config.art=="violetSpire" then E.SetSealSize(config,E.ArcaneSealSize) end
end
function E.SetEffectLayer(config, layer)
    if not E.EffectProfiles[config.art] or (layer~="front" and layer~="back") then return end
    config.effectLayers=config.effectLayers or {}
    config.effectLayers[config.art]=config.effectLayers[config.art] or {}
    config.effectLayers[config.art][E.SelectedEffect(config)]=layer
end
function E.NormalizeSide(value, side)
    value = type(value) == "table" and value or {}
    local art = value.art
    if not E.artworkByID[art] then art = "skull" end
    local flip = value.flip
    if type(flip) ~= "boolean" then flip = E.DefaultMirror(art,side) end
    local devEffects={}
    if type(value.devEffects)=="table" then
        for id in pairs(E.devArtworks) do
            if type(value.devEffects[id])=="table" then
                devEffects[id]=normalizeDevArtwork(value.devEffects[id],id)
            end
        end
    end
    local effectLayers={}
    if type(value.effectLayers)=="table" then
        for id,profile in pairs(E.EffectProfiles) do
            local source=value.effectLayers[id]
            if type(source)=="table" then
                local layers={}
                for effect,layer in pairs(source) do
                    if (effect==profile.nativeEffect or E.CanSelectEffect(id,effect)) and (layer=="front" or layer=="back") then layers[effect]=layer end
                end
                -- Whitefang now uses the same amber trail asset as Undead.
                -- Numeric tuning stays flat; transfer only its old layer key.
                -- A valid explicit amber layer wins, and inputs are never mutated.
                if id=="whiteWorgen" and not layers.amberFlow and
                    (source.coldFlame=="front" or source.coldFlame=="back") then
                    layers.amberFlow=source.coldFlame
                end
                effectLayers[id]=layers
            end
        end
    end
    local halos={}
    if type(value.halos)=="table" then
        for id in pairs(E.HaloArtworks) do if type(value.halos[id])=="table" then halos[id]=normalizeHalo(value.halos[id],id) end end
    end
    return E.GetEffectConfig({ art = art, flip = flip, size = number(value.size, 100, 50, 200),
        x = number(value.x, 0, -200, 200), y = number(value.y, 0, -200, 200),
        frameBottom=value.frameBottom~=false,artBottom=value.artBottom~=false,
        frameX=type(value.frameX)=="number" and number(value.frameX,0,-10000,10000) or nil,
        effects = true, nativeSmoke = true, devEffects=devEffects, effectLayers=effectLayers,halos=halos })
end
function E.Normalize(value)
    value = type(value) == "table" and value or {}
    local result = { version = E.schemaVersion, left = E.NormalizeSide(value.left, "left"), right = E.NormalizeSide(value.right, "right") }
    if type(value.version)~="number" or value.version<14 then
        -- Adopt the requested front glow once, including previously saved back layers.
        -- Later developer choices remain editable and persist normally.
        for _,side in ipairs({"left","right"}) do
            local c=result[side]
            c.effectLayers.violetSpire=c.effectLayers.violetSpire or {}
            c.effectLayers.violetSpire.arcaneGlow="front"
            result[side]=E.GetEffectConfig(c)
        end
    end
    local p=type(value.pair)=="table" and value.pair or {}
    local art=E.PairByArt[p.art] and p.art or result.left.art
    -- Default and Hidden are utility choices, not sisters.
    local row=E.PairByArt[art]
    result.pair={linked=p.linked==true,art=row[1]=="default" and art or row[1],
        swapped=p.swapped==true,flip=p.flip==true,size=number(p.size,100,50,200),
        x=number(p.x,0,-200,200),y=number(p.y,0,-200,200),
        separation=number(p.separation,0,0,2000),artBottom=p.artBottom~=false,
        separationInitialized=separationInitialized(p),
        centerX=type(p.centerX)=="number" and number(p.centerX,0,-10000,10000) or nil}
    if p.linked and (p.art=="moonbough" or p.art=="lunarRelic") and result.left.art==result.right.art then
        -- Old releases treated these as standalone clones. Retain the left art
        -- while adopting its newly declared sister on the right.
        result.pair.swapped=result.left.art=="lunarRelic"
    end
    if p.linked and p.art=="violetSpire" and result.left.art=="violetSpire" and result.right.art=="violetSpire" then
        -- The former standalone clone now has a sister. Keep the left spire.
        result.pair.swapped=false
    end
    if p.linked and p.art=="wolf" and result.left.art=="wolf" and result.right.art=="wolf" then
        -- Replace the old linked clone with the new sister, keeping black left.
        result.pair.swapped=false
    end
    if result.pair.linked then E.SyncPair(result) end
    result.positionProfiles={}
    if type(value.positionProfiles)=="table" then
        local count=0
        for key,profile in pairs(value.positionProfiles) do
            if type(key)=="string" and #key<=512 and type(profile)=="table" and count<128 then
                result.positionProfiles[key]=E.NormalizePosition(profile);count=count+1
            end
        end
    end
    return result
end
E.SidePositionFields={"size","x","y","frameBottom","artBottom","frameX"}
E.PairPositionFields={"linked","size","x","y","separation","separationInitialized","centerX","artBottom"}
function E.NormalizePosition(value)
    local result={pair={}}
    for _,side in ipairs({"left","right"}) do
        local normalized=E.NormalizeSide(value[side],side);result[side]={}
        for _,key in ipairs(E.SidePositionFields) do result[side][key]=normalized[key] end
    end
    local p=type(value.pair)=="table" and value.pair or {}
    result.pair={linked=p.linked==true,size=number(p.size,100,50,200),
        x=number(p.x,0,-200,200),y=number(p.y,0,-200,200),
        separation=number(p.separation,0,0,2000),artBottom=p.artBottom~=false,
        separationInitialized=separationInitialized(p),
        centerX=type(p.centerX)=="number" and number(p.centerX,0,-10000,10000) or nil}
    return result
end
function E.CapturePosition(db)
    return E.NormalizePosition(db)
end
function E.RestorePosition(db,profile)
    profile=E.NormalizePosition(profile)
    for _,side in ipairs({"left","right"}) do
        for _,key in ipairs(E.SidePositionFields) do db[side][key]=profile[side][key] end
    end
    for _,key in ipairs(E.PairPositionFields) do db.pair[key]=profile.pair[key] end
    E.SyncPair(db)
end
function E.SyncPair(db)
    local p=db.pair
    if not p or not p.linked then return end
    local row=E.PairByArt[p.art] or E.PairByArt.skull
    local left,right=row[1],row[2] or row[1]
    if p.art=="default" or p.art=="hidden" then left,right=p.art,p.art end
    if p.swapped then left,right=right,left end
    for _,side in ipairs({"left","right"}) do
        local c=db[side];c.art=side=="left" and left or right
        c.flip=p.flip ~= E.DefaultMirror(c.art,side)
        -- Pair X and separation position native frames. Art stays centred on
        -- its own draggable frame, with the existing crop-relative Y.
        c.size=p.size;c.x=0;c.y=p.y;c.artBottom=p.artBottom
        if p.centerX then c.frameX=p.centerX+p.x+E.PairFrameOffset(c,side,p.separation) end
        db[side]=E.GetEffectConfig(c)
    end
end
function E.PairFrameOffset(config,side,gap,halfWidth)
    -- Default width follows the art-sized drag box. The renderer supplies
    -- actual native widths/effective scales once those frames are available.
    if not halfWidth then
        local art=E.artworkByID[config.art]
        halfWidth=(art and art.width or 154)*config.size/200
    end
    return (side=="left" and -1 or 1)*(halfWidth+gap/2)
end
function E.LinkPair(db,side,enabled)
    if enabled and not db.pair.linked then
        local c=db[side];local row=E.PairByArt[c.art]
        db.pair.art=row[1]=="default" and c.art or row[1]
        db.pair.swapped=row[2]~=nil and row[1]~="default" and ((c.art==row[2]) ~= (side=="right")) or false
        db.pair.flip=E.FlipChecked(c,side)
        db.pair.size=c.size;db.pair.x=c.x;db.pair.y=c.y
        db.pair.artBottom=c.artBottom
        db.pair.centerX=nil
    end
    db.pair.linked=enabled==true;E.SyncPair(db)
    if db.pair.linked and not db.pair.separationInitialized then E.ResetPairSeparation(db);E.SyncPair(db) end
end
function E.ResetPairSeparation(db)
    -- The runtime supplies native geometry; 600 is an approximation only
    -- when frame positions are not available yet.
    db.pair.separation=number(E.GetDefaultPairSeparation and E.GetDefaultPairSeparation(db),600,0,2000)
    db.pair.separationInitialized=true
end
function E.SelectPair(db,art)
    local row=E.PairByArt[art];if not row then return end
    db.pair.art=row[1]=="default" and art or row[1]
    E.SyncPair(db)
end
function E.SnapToBottom(db,side)
    if db.pair.linked then
        db.pair.y=0;db.pair.artBottom=true
        db.left.frameBottom=true;db.right.frameBottom=true;E.SyncPair(db)
    else
        db[side].y=0;db[side].frameBottom=true;db[side].artBottom=true
    end
end
function E.UV(coords, flip)
    if not flip then return unpack(coords) end
    return coords[5], coords[6], coords[7], coords[8], coords[1], coords[2], coords[3], coords[4]
end
function E.Config()
    return E.draft or EndCapperDB
end
local function sameSettings(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not sameSettings(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
local function editableSettings(db,includeEffects)
    local result={pair={linked=db.pair.linked}}
    if db.pair.linked then
        for _,key in ipairs({"art","swapped","flip","size","x","y","separation","artBottom"}) do result.pair[key]=db.pair[key] end
    end
    for _,side in ipairs({"left","right"}) do
        local c=db[side];local settings={effects={}}
        for _,key in ipairs({"art","flip","size","x","y","frameBottom","artBottom"}) do settings[key]=c[key] end
        if not db.pair.linked then settings.frameX=c.frameX end
        -- Compare effective tuning, so returning a slider to its original
        -- default does not count as a change merely because an override exists.
        if includeEffects then for art,profile in pairs(E.EffectProfiles) do
            local config={}
            for k,v in pairs(c) do config[k]=v end
            config.art=art
            local tuning={selected=E.SelectedEffect(config),halo=E.GetHaloConfig(config)}
            for _,choice in ipairs(E.effectChoices) do
                if choice.id==profile.nativeEffect or E.CanSelectEffect(art,choice.id) then
                    local resolved=E.GetEffectConfig(config,choice.id);local fields={layer=resolved.effectLayer,seal=resolved.sealSize}
                    for _,spec in ipairs(E.devEffectFields) do fields[spec[1]]=resolved[spec[1]] end
                    tuning[choice.id]=fields
                end
            end
            settings.effects[art]=tuning
        end end
        result[side]=settings
    end
    return result
end
function E.HasChanges()
    if not E.draft or not EndCapperDB then return false end
    local function normalize(value)
        return E.Normalize({version=value.version,left=value.left,right=value.right,pair=value.pair})
    end
    local draft,saved=normalize(E.draft),normalize(EndCapperDB)
    if not sameSettings(editableSettings(draft,false),editableSettings(saved,false)) then return true end
    return not sameSettings(editableSettings(draft,true),editableSettings(saved,true))
end
function E.Begin()
    if not E.draft then E.draft = E.Normalize(EndCapperDB) end
end
function E.Commit()
    EndCapperDB = E.Normalize(E.Config())
    if E.SavePositionProfile then E.SavePositionProfile() end
    E.draft = nil
end
function E.Cancel()
    E.draft = nil
end

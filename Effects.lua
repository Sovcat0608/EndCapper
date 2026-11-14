local _, E = ...
-- The default native emitter starts at the centre of the full artwork.
E.EffectEmitters = {{u = 0.5, v = 0.5, scale = 1}}

function E.EyeAnchor(eye, width, height, flip)
    return (flip and 1-eye.u or eye.u)*width, -eye.v*height, flip and -1 or 1
end
function E.EffectAnchor(eye, width, height, config)
    local x, y, direction = E.EyeAnchor(eye, width, height, config.flip)
    return x+direction*(config.trailX or 0)*width/150,
        y+(config.trailY or 0)*height/150, direction
end
-- The hilt shows one eye. Register the emitter to its painted centre.
local hiltEye = {u = 0.613, v = 0.812, scale = 1}
local function updateHiltEyeTrail(entry, config)
    local trail = entry.hiltEyeTrail
    if config.art ~= "frostmourneHilt" or not entry.nativeWanted or not E.UpdateNativeSmoke then
        if trail then
            trail.effectsEnabled = false
            trail.nativeWanted = false
            trail.nativeActive = false
            E.StopNativeSmoke(trail)
        end
        return
    end
    if not trail then
        trail = {frame = entry.frame, art = entry.art, emitters = {hiltEye}}
        entry.hiltEyeTrail = trail
    end
    trail.side = entry.side
    trail.alpha = entry.alpha
    trail.effectsEnabled = true
    trail.nativeWanted = true
    trail.nativeActive = E.UpdateNativeSmoke(trail, E.GetEffectConfig(config, "coldFlame"))
end

local function updateWarlockShadow(entry, config)
    local shadow=entry.warlockEffect
    if not E.WarlockArtworks[config.art] or not entry.nativeWanted or not E.UpdateNativeSmoke then
        if shadow then
            shadow.effectsEnabled=false
            shadow.nativeWanted=false
            shadow.nativeActive=false
            E.StopNativeSmoke(shadow)
        end
        return
    end
    if not shadow then
        shadow={frame=entry.frame,art=entry.art}
        entry.warlockEffect=shadow
    end
    shadow.side=entry.side
    shadow.alpha=entry.alpha
    shadow.effectsEnabled=true
    shadow.nativeWanted=true
    shadow.nativeActive=E.UpdateNativeSmoke(shadow,E.GetEffectConfig(config,"shadowGlow"))
end

local function updateMultiEffects(entry, config)
    -- Keep the existing pool field so load callbacks/status retain the same ownership.
    local ids=E.MultiEffects[config.art]
    local wanted={}
    if ids and entry.nativeWanted and E.UpdateNativeSmoke then
        entry.undercityEffects=entry.undercityEffects or {}
        for index,id in ipairs(ids) do
            if index>1 then
                wanted[id]=true
                local effect=entry.undercityEffects[id] or {frame=entry.frame,art=entry.art}
                entry.undercityEffects[id]=effect
                effect.side=entry.side
                effect.alpha=entry.alpha
                effect.effectsEnabled=true
                effect.nativeWanted=true
                effect.nativeActive=E.UpdateNativeSmoke(effect,E.GetEffectConfig(config,id))
            end
        end
    end
    for id,effect in pairs(entry.undercityEffects or {}) do
        if not wanted[id] then
            effect.effectsEnabled=false
            effect.nativeWanted=false
            effect.nativeActive=false
            E.StopNativeSmoke(effect)
        end
    end
end

local function stopCustomEffects(entry)
    if E.StopMageSigils then E.StopMageSigils(entry) end
    if E.StopMageBooks then E.StopMageBooks(entry) end
    if E.StopSkycutter then E.StopSkycutter(entry) end
    if E.StopLiquid then E.StopLiquid(entry) end
    if E.StopHalo then E.StopHalo(entry) end
    if E.StopMoonwell then E.StopMoonwell(entry) end
    if E.StopFrost then E.StopFrost(entry) end
    if E.StopMolten then E.StopMolten(entry) end
    if E.StopArcane then E.StopArcane(entry) end
    if E.StopGlyphs then E.StopGlyphs(entry) end
end
function E.StopEffects(entry)
    stopCustomEffects(entry)
    if E.StopNativeSmoke then E.StopNativeSmoke(entry) end
    if entry.secondaryEffect and E.StopNativeSmoke then E.StopNativeSmoke(entry.secondaryEffect) end
    if entry.hiltEyeTrail and E.StopNativeSmoke then E.StopNativeSmoke(entry.hiltEyeTrail) end
    if entry.warlockEffect and E.StopNativeSmoke then E.StopNativeSmoke(entry.warlockEffect) end
    for _,effect in pairs(entry.undercityEffects or {}) do E.StopNativeSmoke(effect) end
end
local function stopUnusedNative(entry)
    if not E.StopNativeSmoke then return end
    if not entry.nativeWanted then E.StopNativeSmoke(entry) end
    local secondary=entry.secondaryEffect
    if secondary and not secondary.nativeWanted then E.StopNativeSmoke(secondary) end
end
function E.PlayEffects(entry)
    if E.PlayMageBooks then E.PlayMageBooks(entry) end
    if E.PlayMageSigils then E.PlayMageSigils(entry) end
    -- The boat remains visible as static artwork when effects are disabled.
    if E.PlaySkycutter then E.PlaySkycutter(entry) end
    if not entry.effectsEnabled or not entry.frame:IsVisible() then return end
    if E.PlayLiquid then E.PlayLiquid(entry) end
    if E.PlayHalo then E.PlayHalo(entry) end
    if E.PlayMoonwell then E.PlayMoonwell(entry) end
    if E.PlayFrost then E.PlayFrost(entry) end
    if E.PlayMolten then E.PlayMolten(entry) end
    if E.PlayArcane then E.PlayArcane(entry) end
    if E.PlayGlyphs then E.PlayGlyphs(entry) end
    if E.PlayNativeSmoke then E.PlayNativeSmoke(entry) end
    if entry.secondaryEffect and E.PlayNativeSmoke then E.PlayNativeSmoke(entry.secondaryEffect) end
    if entry.hiltEyeTrail and E.PlayNativeSmoke then E.PlayNativeSmoke(entry.hiltEyeTrail) end
    if entry.warlockEffect and E.PlayNativeSmoke then E.PlayNativeSmoke(entry.warlockEffect) end
    for _,effect in pairs(entry.undercityEffects or {}) do E.PlayNativeSmoke(effect) end
end
function E.UpdateEffects(entry, config)
    -- Called only through the out-of-combat Apply path.
    if not entry.effectHooks then
        entry.frame:HookScript("OnHide", function() E.StopEffects(entry) end)
        entry.frame:HookScript("OnShow", function() E.PlayEffects(entry) end)
        entry.effectHooks=true
    end
    -- Reconfigure running models in place. Hiding them for every preview or
    -- load callback interrupts the native particle simulation, even if loaded.
    stopCustomEffects(entry)
    if entry.secondaryEffect then
        entry.secondaryEffect.effectsEnabled=false
        entry.secondaryEffect.nativeWanted=false
    end
    local level=entry.frame:GetFrameLevel()
    if entry.artLayer then entry.artLayer:SetFrameLevel(level+(config.art=="skycutter" and 3 or 2)) end
    entry.effectsEnabled = (E.EffectProfiles[config.art] ~= nil or E.PriestArtworks[config.art]~=nil) and config.effects ~= false
    entry.nativeWanted = entry.effectsEnabled and config.nativeSmoke ~= false
    entry.nativeActive = false
    updateHiltEyeTrail(entry, config)
    updateWarlockShadow(entry, config)
    updateMultiEffects(entry, config)
    if E.UpdateSkycutter then E.UpdateSkycutter(entry,config) end
    if E.UpdateMageBooks then E.UpdateMageBooks(entry,config) end
    if E.UpdateMageSigils then E.UpdateMageSigils(entry,config) end
    if E.UpdateLiquid then E.UpdateLiquid(entry, config) end
    if E.UpdateGlyphs then E.UpdateGlyphs(entry, config) end
    if E.UpdateArcane then E.UpdateArcane(entry, config) end
    if E.UpdateMolten then E.UpdateMolten(entry, config) end
    if E.UpdateFrost then E.UpdateFrost(entry, config) end
    if E.UpdateMoonwell then E.UpdateMoonwell(entry, config) end
    if E.UpdateHalo then E.UpdateHalo(entry,config) end
    for _,key in ipairs({"glyphs","molten","frost","moonwell","halo","liquid"}) do
        local state=entry[key]
        if state and state.enabled then
            E.ClipEffect(entry,config,state.host,level+(key=="halo" and 1 or 3))
        end
    end
    if E.PriestArtworks[config.art] and not E.PriestEffectPairs[config.art] then
        entry.nativeWanted=false
        stopUnusedNative(entry)
        E.PlayEffects(entry);return
    end
    if not entry.effectsEnabled then stopUnusedNative(entry);return end
    if E.MultiEffects[config.art] then
        if E.UpdateNativeSmoke then
            entry.nativeActive=E.UpdateNativeSmoke(entry,E.GetEffectConfig(config,E.MultiEffects[config.art][1]))
        end
        stopUnusedNative(entry)
        E.PlayEffects(entry)
        return
    end
    -- Keep the three hilt models on dedicated scenes as the editor changes selection.
    local primaryConfig = config.art=="frostmourneHilt" and E.GetEffectConfig(config,"frostGlow") or config
    if E.WarlockArtworks[config.art] then primaryConfig=E.GetEffectConfig(config,"felFlame") end
    if E.UpdateNativeSmoke then entry.nativeActive = E.UpdateNativeSmoke(entry, primaryConfig) end
    if (E.WarlockArtworks[config.art] or E.FrostmourneArtworks[config.art] or E.WorgenArtworks[config.art] or E.UndeadArtworks[config.art] or E.PriestEffectPairs[config.art] or config.art=="kirinTor" or config.art=="moonwell" or config.art=="stormhornTotem" or config.art=="felwing" or E.MoltenArtworks[config.art] or E.FrostArtworks[config.art]) and E.UpdateNativeSmoke then
        -- Two independently layered scenes, pooled per cap. The dev radio only
        -- selects which calibration to edit; both effects remain visible.
        local secondary=entry.secondaryEffect or {frame=entry.frame,art=entry.art}
        entry.secondaryEffect=secondary
        secondary.side=entry.side
        secondary.alpha=entry.alpha
        secondary.effectsEnabled=entry.effectsEnabled
        secondary.nativeWanted=entry.nativeWanted
        local other=config.nativeEffect=="blueGlow" and "broadFlame" or "blueGlow"
        if E.WarlockArtworks[config.art] then other="felMagic" end
        if E.FrostmourneArtworks[config.art] then other=primaryConfig.nativeEffect=="frostGlow" and "frostMist" or "frostGlow" end
        if E.UndeadArtworks[config.art] then other=config.nativeEffect=="amberFlow" and "rotFog" or "amberFlow" end
        if E.WorgenArtworks[config.art] then
            local trail=E.EffectProfiles[config.art].nativeEffect
            other=config.nativeEffect==trail and "worgenGloom" or trail
        end
        if config.art=="felwing" then other=config.nativeEffect=="felGlow" and "felDrip" or "felGlow" end
        if E.MoltenArtworks[config.art] then other=config.nativeEffect=="fireGlow" and "fireFlame" or "fireGlow" end
        if E.FrostArtworks[config.art] then other=config.nativeEffect=="coldFlame" and "frostEnchant" or "coldFlame" end
        if config.art=="moonwell" then other=config.nativeEffect=="moonwellGlow" and "waterRipple" or "moonwellGlow" end
        if config.art=="kirinTor" then other=config.nativeEffect=="arcaneGlow" and "kirinSeal" or "arcaneGlow" end
        local priestPair=E.PriestEffectPairs[config.art]
        if priestPair then other=config.nativeEffect==priestPair[1] and priestPair[2] or priestPair[1] end
        secondary.nativeActive=E.UpdateNativeSmoke(secondary,E.GetEffectConfig(config,other))
    end
    stopUnusedNative(entry)
    E.PlayEffects(entry)
end

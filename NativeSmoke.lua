local _, E = ...
-- NativeSmoke names remain internal for compatibility.
-- Emitter coordinates were inspected in the model data; see docs/native-smoke.md.
E.NativeEffectProfiles = {
    -- Skywall ground vortex: soft swirl textures, 5–9.3 second rotations.
    -- Zephras alternative, independently tunable beside Gentle Whirlwind.
    skyWind={fileID=460839,name="Skywall Swirl",emitterX=0,emitterY=0.0007514954,emitterZ=1.0117073059,
        modelScale=0.018,cameraElevation=35,animation=0,opacity=0.8,centered=true,naturalEdges=true},
    -- Sylvanas: existing inspected native assets, independent IDs for each eye.
    rangerBloom={fileID=166034,name="Luminance Bloom",emitterX=0,emitterY=0,emitterZ=0,
        modelScale=2,opacity=0.8,centered=true},
    -- Black dungeon fog: alpha-blended smoke surfaces, authored RGB 9/255.
    -- Centre its measured bounds; retain the fixed viewport for vertical tuning.
    bansheeCloud={fileID=1713498,name="Black Dungeon Fog",emitterX=11.0514602661,emitterY=-14.9769515991,emitterZ=34.8938217163,
        modelScale=0.015,animation=0,opacity=0.8,centered=true,fixedViewport=true},
    blueEyeLeft={fileID=165995,name="Left Blue Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,
        modelScale=0.5,opacity=0.8,centered=true},
    blueEyeRight={fileID=165995,name="Right Blue Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,
        modelScale=0.5,opacity=0.8,centered=true},
    redEyeLeft={fileID=166011,name="Left Red Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,
        modelScale=0.5,opacity=0.8,centered=true},
    redEyeRight={fileID=166011,name="Right Red Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,
        modelScale=0.5,opacity=0.8,centered=true},
    -- Skywall updraft: 5.3/6.7-second rotations and a 2.1-second UV scroll,
    -- with constant mesh opacity. Stand keeps the persistent ambient wind.
    rangerWind={fileID=445680,name="Gentle Whirlwind",emitterX=-0.0001710653,emitterY=-0.0011721849,emitterZ=2.3160927296,
        modelScale=0.55,animation=0,opacity=0.8,centered=true},
    -- Keep saved tuning keys; replace the original ground fog models.
    -- Rot Fog matches Undead; BlueRadiationFog inspected in Forever 1.60.1.70888.
    greenGroundFog={fileID=166280,name="Rot Fog",emitterX=0,emitterY=0,emitterZ=0,
        modelScale=0.22,animation=158,opacity=0.8,centered=true},
    eerieGroundFog={fileID=165743,name="Blue Mist",emitterX=-0.0377854258,emitterY=0.0422529913,emitterZ=0,
        modelScale=0.22,animation=158,opacity=0.8,centered=true},
    -- Flame-only animated mesh lies in Y/Z; view along X like the Kirin Tor seal.
    candleFlame={fileID=1958358,name="Candle Flame",emitterX=0,emitterY=0,emitterZ=-0.0319035314,
        modelScale=0.22,cameraAxis="X",animation=0,opacity=0.8,centered=true},
    -- Separate keys/scenes let each eye retain independent tuning despite sharing a model.
    amberEyeLeft={fileID=166033,name="Left Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,opacity=0.8,centered=true},
    amberEyeRight={fileID=166033,name="Right Eye Trail",emitterX=-0.1388888955,emitterY=0,emitterZ=0,opacity=0.8,centered=true},
    -- Existing inspected yellowglow_high particles, scaled for the lantern.
    lampGlow={fileID=166034,name="Amber Lamp Glow",emitterX=0,emitterY=0,emitterZ=0,
        modelScale=1,animation=0,opacity=0.8,centered=true},
    -- Target-build particle data inspected for the warlock sisters.
    felFlame={fileID=166003,name="Fel Flame",emitterX=-0.1388888955,emitterY=0,emitterZ=0,
        opacity=0.8,centered=true},
    felMagic={fileID=166072,name="Fel Casting",emitterX=0,emitterY=-0.0012143453,emitterZ=-0.0384081602,
        modelScale=0.65,opacity=0.8,centered=true},
    shadowGlow={fileID=166009,name="Shadow Glow",emitterX=0,emitterY=0,emitterZ=0,
        opacity=0.8,centered=true},
    -- Target-build ColdBreath: small, slow, origin-centred white mist particles.
    -- Enlarged for the ice edge; separate from Frost Form's mesh and blue flames.
    frostMist={fileID=165412,name="Icy Mist",emitterX=0,emitterY=0,emitterZ=0,
        modelScale=4,opacity=0.8,centered=true},
    -- BlueGlow Medium, same inspected native source as Azure Glow, separate tuning.
    frostGlow={fileID=165998,name="Blue Frost Glow",emitterX=0,emitterY=0,emitterZ=0,
        modelScale=1,opacity=0.8,centered=true},
    -- BlackRadiationFog: compact blue-gray/violet particles, static emitter.
    -- Looping Hold158; inspected target-build data in docs/worgen-sisters.md.
    worgenGloom={fileID=165686,name="Gloom",emitterX=-0.0377854258,emitterY=0.0422529913,emitterZ=0,
        modelScale=0.22,animation=158,opacity=0.8,centered=true},
    -- Native Dalaran Eye; its luminous eye texture matches the Kirin Tor seal.
    -- Mesh lies in Y/Z, so view from X instead of the particle-only Y camera.
    kirinSeal={fileID=243044,name="Kirin Tor Seal",emitterX=0,emitterY=0,emitterZ=0,modelScale=0.65,cameraAxis="X",opacity=0.8,centered=true},
    -- YellowFlame Low: additive amber/yellow particles with a one-second flow.
    amberFlow={fileID=166033,name="Amber Flow",emitterX=-0.1388888955,emitterY=0,emitterZ=0,opacity=0.8,centered=true},
    -- GreenRadiationFog: native green particles, static origin, looping Hold.
    rotFog={fileID=166280,name="Rot Fog",emitterX=0,emitterY=0,emitterZ=0,modelScale=0.22,animation=158,opacity=0.8,centered=true},
    -- Inspected native assets; size/position/opacity are provisional for testing.
    holyGlow={fileID=166034,name="Large Holy Glow",emitterX=0,emitterY=0,emitterZ=0,modelScale=2,opacity=0.8,centered=true},
    -- Stable saved key; Divine Star's looping hold plus animated golden particles.
    sunRays={fileID=610642,name="Divine Radiance",emitterX=0.0232977532,emitterY=0.0576375052,emitterZ=0.0206381083,modelScale=1.5,animation=158,opacity=0.8,centered=true},
    voidGlow={fileID=166009,name="Large Void Glow",emitterX=0,emitterY=0,emitterZ=0,modelScale=2,opacity=0.8,centered=true},
    -- Purple smoke flare: compensate its dominant rising-smoke emitter in all axes.
    voidSmoke={fileID=166907,name="Void Smoke",emitterX=-0.0003013768,emitterY=-0.0055674450,emitterZ=0.1358658969,modelScale=0.18,opacity=0.8,centered=true},
    -- Stable saved key; BlueGlow Medium is particle-only with its emitter at origin.
    moonwellGlow={fileID=165998,name="Azure Glow",emitterX=0,emitterY=0,emitterZ=0,modelScale=1,opacity=0.8,centered=true},
    -- Ground-plane ripple, viewed from above to match the painted water ellipse.
    waterRipple={fileID=657698,name="Water Ripples",emitterX=0,emitterY=0,emitterZ=0,modelScale=0.04,cameraElevation=18,opacity=0.8,centered=true},
    -- Stable saved key; Frost Form's measured particle origin, scaled for the cap.
    frostEnchant = {fileID=166209, name="Frost Form", emitterX=0, emitterY=0.0116675766, emitterZ=-0.1641135812,
        modelScale=0.45, opacity=0.8, centered=true},
    fireGlow = {fileID=166012, name="Fire Glow", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    -- RedFlame Low: moving orange/red fire particles; compensate actual origin.
    fireFlame = {fileID=166011, name="Fire", emitterX=-0.1388888955, emitterZ=0, opacity=0.8, centered=true},
    -- PurpleGlow High: compact violet particles, inspected emitter at 0/0/0.
    arcaneGlow = {fileID=166009, name="Arcane Glow", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    felGlow = {fileID=166004, name="Fel Green Glow", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    -- Native PoisonDrip: green/yellow falling particles; origin is the emitter,
    -- not the highly asymmetric animation bounds. See docs/felwing.md.
    felDrip = {fileID=166007, name="Fel Green Dripping", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    blueGlow = {fileID=165997, name="Blue Glow", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    -- Broad ground-fire base; reduce the large world effect to end-cap scale.
    broadFlame = {fileID=165598, name="Broad Blue Flame", emitterX=0, emitterZ=0,
        modelScale=0.15, opacity=0.8, centered=true},
    coldFlame = {fileID=165995, name="Cold flame", emitterX=-0.1388888955, emitterZ=0, opacity=0.8},
    soulfrost = {fileID=166026, name="Soulfrost", emitterX=0, emitterZ=0, opacity=0.65},
    moonlight = {fileID=166032, name="Moonlight glow", emitterX=0, emitterZ=0, opacity=0.8, centered=true},
    -- FaerieFire_NoGlow: animated geometry without the extra particle halo.
    -- Anchor the midpoint of its inspected animated bounds, including depth.
    faerieFire = {fileID=166062, name="Faerie Fire", emitterX=-0.1370388716,
        emitterY=-0.0742775947, emitterZ=0.3270530477, opacity=0.8, centered=true},
}
function E.StopNativeSmoke(entry)
    local state = entry.nativeSmoke
    if not state then return end
    for _, slot in ipairs(state.slots) do slot.scene:Hide() end
end
local function fail(entry, reason, timedOut)
    entry.nativeSmoke.status = "unavailable"
    entry.nativeSmoke.reason = reason
    entry.nativeSmoke.timedOut = timedOut == true
    entry.nativeActive = false
    E.StopNativeSmoke(entry)
end
local function loaded(state)
    local profile=E.NativeEffectProfiles[state.profileID]
    for _, slot in ipairs(state.slots) do
        if not slot.actor:IsLoaded() then return false end
        if profile and slot.actor.GetModelFileID and slot.actor:GetModelFileID()~=profile.fileID then return false end
    end
    return #state.slots == 1
end
local function requestRefresh(entry)
    if not entry.effectsEnabled or not entry.nativeWanted or not entry.frame:IsVisible() then return end
    if InCombatLockdown() then E.pending=true;return end
    -- Apply reads the current draft/saved configuration, never a stale snapshot.
    E.Schedule(entry.side)
end
local function watchLoad(entry,state,slot,profile)
    local generation=state.generation
    slot.needsAnimation=true
    slot.notifiedGeneration=nil
    slot.actor.endCapperOnModelLoaded=function()
        if entry.nativeSmoke~=state or state.generation~=generation or slot.notifiedGeneration==generation then return end
        if state.status=="unavailable" and not state.timedOut then return end
        if not slot.actor:IsLoaded() then return end
        if slot.actor.GetModelFileID and slot.actor:GetModelFileID()~=profile.fileID then return end
        slot.notifiedGeneration=generation
        slot.needsAnimation=true
        state.loadDirty=true
        -- The event can fire during SetModelByFileID, after an optimistic
        -- IsLoaded result, or after the bounded poll window has expired.
        -- Defer geometry/alpha/animation to the normal safe Apply path.
        requestRefresh(entry)
    end
end
local function poll(entry)
    local state = entry.nativeSmoke
    if not state or state.status ~= "loading" or state.polling then return end
    state.polling = true
    local generation = state.generation
    C_Timer.After(0.75, function()
        if generation ~= state.generation then return end
        state.polling = false
        if state.status ~= "loading" or not entry.effectsEnabled or not entry.nativeWanted then return end
        if not entry.frame:IsVisible() then return end
        if InCombatLockdown() then E.pending = true; return end
        state.attempts = state.attempts + 1
        local ok, ready = pcall(loaded, state)
        if not ok then fail(entry, "model readiness check failed")
        elseif ready then state.status = "ready"; state.reason=nil; state.timedOut=false
        elseif state.attempts >= 8 then
            if state.retries < 1 then
                -- One extra loading window for cold caches/slow storage. Keep
                -- the requested model intact; restarting it can delay loading.
                state.retries=state.retries+1; state.attempts=0
                poll(entry); return
            end
            fail(entry, "model did not load within twelve visible seconds", true)
        else poll(entry); return end
        E.Schedule(entry.side)
    end)
end
function E.PlayNativeSmoke(entry)
    local state = entry.nativeSmoke
    if not state or not entry.effectsEnabled or not entry.nativeWanted or not entry.frame:IsVisible() then return end
    if state.loadDirty then requestRefresh(entry);return end
    if state.status == "unavailable" then
        -- A late model can become ready after the bounded polling has ended.
        -- OnShow requests the normal Apply path so alpha/visibility are refreshed.
        if state.timedOut then
            if InCombatLockdown() then E.pending=true; return end
            local ok,ready=pcall(loaded,state)
            if ok and ready then E.Schedule(entry.side) end
        end
        return
    end
    for _, slot in ipairs(state.slots) do slot.scene:Show() end
    if state.status == "loading" then poll(entry) end
end
local function create(entry)
    local state = {slots = {}, status = "loading", attempts = 0, retries = 0, generation = 0}
    entry.nativeSmoke = state
    for _, eye in ipairs(entry.emitters or E.EffectEmitters) do
        local scene = CreateFrame("ModelScene", nil, entry.frame)
        local slot = {scene = scene, eye = eye}
        table.insert(state.slots, slot)
        scene:Hide(); scene:SetAlpha(0); scene:EnableMouse(false)
        -- Particle viewports intentionally overlap within a cap and across
        -- caps. Opt in before loading; visible artwork bounds are much smaller
        -- than these scenes. See Blizzard ModelSceneMixin:OnLoad.
        if scene.SetAllowOverlappedModels then scene:SetAllowOverlappedModels(true) end
        scene:SetFrameLevel(entry.frame:GetFrameLevel()+1)
        scene:SetDrawLayer("OVERLAY")
        scene:SetCameraNearClip(0.01); scene:SetCameraFarClip(100)
        -- Triple viewport and world span together: same flame size, more room
        -- before particles reach the ModelScene render boundary.
        scene:SetCameraFieldOfView(2*math.atan(6/(2*8)))
        scene:SetLightAmbientColor(1,1,1); scene:SetLightDiffuseColor(0,0,0)
        local actor = scene:CreateActor(nil, "EndCapperSmokeActorTemplate")
        slot.actor = actor
        if not actor or not actor.IsLoaded then error("native actor API unavailable") end
        actor:SetScale(1); actor:SetPitch(0); actor:SetYaw(0); actor:SetRoll(0); actor:Show()
    end
    return state
end
function E.UpdateNativeSmoke(entry, config)
    if not entry.nativeWanted then return false end
    if InCombatLockdown() then E.pending = true; return false end
    local id = E.NativeEffectProfiles[config.nativeEffect] and config.nativeEffect or "coldFlame"
    local p = E.NativeEffectProfiles[id]
    local opacity = (config.trailOpacity or 100)/100
    local ok, result = pcall(function()
        local state = entry.nativeSmoke or create(entry)
        if state.profileID ~= id then
            -- Reuse the same scenes/actors and invalidate callbacks for the old selection.
            state.profileID = id
            state.generation = state.generation+1
            state.status, state.reason, state.attempts, state.polling = "loading", nil, 0, false
            state.retries=0; state.timedOut=false
            state.loadDirty=false
            for _, slot in ipairs(state.slots) do
                slot.scene:Hide(); slot.scene:SetAlpha(0)
                watchLoad(entry,state,slot,p)
                slot.actor:ClearModel()
                if not slot.actor:SetModelByFileID(p.fileID) then error("client rejected model " .. p.fileID) end
            end
        end
        -- Consume a notification even when this Apply cannot recover a failed
        -- model, so Play cannot queue an unbounded sequence of zero-time work.
        state.loadDirty=false
        if state.status=="unavailable" and not state.timedOut then E.StopNativeSmoke(entry);return false end
        local ready=loaded(state)
        if state.status=="unavailable" and not ready then E.StopNativeSmoke(entry);return false end
        if ready then
            state.status="ready"; state.reason=nil; state.timedOut=false
        elseif state.status=="ready" then
            -- A recycled actor can lose readiness after reporting a cached
            -- model ready. Resume bounded polling without reloading that model.
            state.status="loading";state.attempts=0;state.retries=0
            for _,slot in ipairs(state.slots) do slot.needsAnimation=true end
        end
        local width, height = entry.art:GetSize()
        local angle = math.rad(config.trailAngle or 14)
        local sine, cosine = math.sin(angle), math.cos(angle)
        for _, slot in ipairs(state.slots) do
            local frontLevel=(config.art=="violetSpire" or config.art=="soulbound" or config.art=="skycutter") and 4 or 3
            slot.scene:SetFrameLevel(entry.frame:GetFrameLevel()+(config.effectLayer=="back" and 1 or frontLevel))
            -- Reset pooled scenes to native colour unless this profile opts out.
            if slot.scene.SetDesaturation then
                slot.scene:SetDesaturation(p.desaturation or 0)
            end
            local x, y, direction = E.EffectAnchor(slot.eye, width, height, config)
            local artScale = (width/150)*slot.eye.scale
            local viewport = 288*artScale*(config.trailSize or 100)/100
            local pixelsPerUnit = viewport/6
            -- Roll the camera instead of trusting each asset's world-space particles
            -- to follow actor pitch. Reverse the viewing side for a true mirrored view.
            local rx, rz, ux, uz = direction*sine, direction*cosine, -cosine, sine
            slot.scene:SetCameraPosition(0, -direction*8, 0)
            slot.scene:SetCameraOrientationByAxisVectors(0,direction,0, rx,0,rz, ux,0,uz)
            if p.cameraAxis=="X" then
                slot.scene:SetCameraPosition(-direction*8,0,0)
                slot.scene:SetCameraOrientationByAxisVectors(direction,0,0,
                    0,-direction*sine,direction*cosine,0,cosine,sine)
            end
            if p.cameraElevation then
                local elevation=math.rad(p.cameraElevation)
                local se,ce=math.sin(elevation),math.cos(elevation)
                slot.scene:SetCameraPosition(0,-direction*8*ce,8*se)
                slot.scene:SetCameraOrientationByAxisVectors(0,direction*ce,-se,
                    direction*sine,se*cosine,direction*ce*cosine,
                    -cosine,direction*se*sine,ce*sine)
            end
            local biasX, biasY = direction*0.5, 0.15
            -- Symmetric models get a genuinely centred viewport. Preserve the
            -- approved flame's asymmetric render room and calibration.
            if p.centered then biasX,biasY=0,0 end
            slot.cropVisible=E.CropNativeEffect(entry,config,slot.scene,viewport,
                x+biasX*pixelsPerUnit,y+biasY*pixelsPerUnit,p)
            -- Put the inspected origin on the chosen point and camera depth plane.
            local modelScale=p.modelScale or 1
            slot.actor:SetScale(modelScale)
            slot.actor:SetPosition(-p.emitterX*modelScale-biasX*rx-biasY*ux, -(p.emitterY or 0)*modelScale,
                -p.emitterZ*modelScale-biasX*rz-biasY*uz)
            if ready and slot.needsAnimation then
                slot.actor:SetAnimation(p.animation or 0,0,1,0)
                slot.actor:Show()
                slot.needsAnimation=false
            end
        end
        for _, slot in ipairs(state.slots) do
            slot.scene:SetAlpha(state.status == "ready" and slot.cropVisible and entry.alpha*p.opacity*opacity or 0)
        end
        E.PlayNativeSmoke(entry)
        return state.status == "ready"
    end)
    if not ok then
        if entry.nativeSmoke then fail(entry, tostring(result)) end
        return false
    end
    return result
end
local function nativeStatus(entry)
    if not entry then return "end cap not attached" end
    if not entry.effectsEnabled then return "artwork effects off" end
    if not entry.nativeWanted then return "native effects disabled" end
    local state = entry.nativeSmoke
    if not state then return "not initialized" end
    local p = E.NativeEffectProfiles[state.profileID]
    if state.status == "ready" then
        local scene=state.slots[1] and state.slots[1].scene
        local overlap="unavailable"
        if scene and scene.GetAllowOverlappedModels then
            overlap=scene:GetAllowOverlappedModels() and "on" or "off"
        end
        return p.name .. " loaded (" .. p.fileID .. "; overlap=" .. overlap .. ")"
    end
    if state.status == "loading" then return "loading native effect; no texture fallback" end
    return "native effect hidden: " .. (state.reason or "native model unavailable")
end
function E.NativeSmokeStatus(entry)
    local status=nativeStatus(entry)
    for _,effect in pairs(entry and entry.undercityEffects or {}) do
        if effect.effectsEnabled then status=status .. "; " .. nativeStatus(effect) end
    end
    if entry and entry.warlockEffect and entry.warlockEffect.effectsEnabled then
        status=status .. "; " .. nativeStatus(entry.warlockEffect)
    end
    if entry and entry.secondaryEffect and entry.secondaryEffect.effectsEnabled then
        status=status .. "; " .. nativeStatus(entry.secondaryEffect)
    end
    if entry and entry.hiltEyeTrail and entry.hiltEyeTrail.effectsEnabled then
        status=status .. "; eye trail: " .. nativeStatus(entry.hiltEyeTrail)
    end
    return status
end

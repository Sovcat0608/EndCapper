local _, E = ...
-- Visible basal edges measured in the runtime textures, top to bottom.
-- These are horizontal cutoffs, not masks of the full artwork silhouette.
E.EffectBaselines = {
    frostmourneHilt=467/512, frostmourneBlade=467/512,
    skull=498/512, lordaeron=498/512, wolf=496/512, whiteWorgen=492/512,
    moonbough=475/512, verdantRoot=464/512, lunarRelic=491/512,
    stormhornTotem=497/512, felwing=468/512, violetSpire=493/512, kirinTor=492/512,
    cinderforged=466/512, cindermaw=466/512,
    rimeforged=466/512, rimeguard=466/512, moonwell=465/512,
    seraph=467/512, sanctum=476/512, umbra=468/512, eclipse=476/512,
}

function E.UpdateEffectClip(entry, config, clip, level)
    local baseline=E.EffectBaselines[config.art]
    if not baseline or not clip.SetClipsChildren then return false end
    local width,height=entry.art:GetSize()
    clip:EnableMouse(false)
    clip:SetFrameLevel(level)
    clip:SetClipsChildren(true)
    -- Far beyond every supported effect viewport/offset/rotation. Only the
    -- bottom intersects visible effects; no screen coordinates or OnUpdate.
    clip:SetSize(math.max(4096,width*32),math.max(4096,height*32))
    clip:ClearAllPoints()
    clip:SetPoint("BOTTOM",entry.art,"TOP",0,-height*baseline)
    return true
end

function E.ClipEffect(entry, config, frame, level)
    -- Texture hosts only. Native ModelScenes use their own viewport below:
    -- generic SetClipsChildren makes overlapping particle layers disappear.
    local clip=frame.endCapperClip
    if not clip and E.EffectBaselines[config.art] and
        entry.frame.SetClipsChildren and frame.SetParent then
        clip=CreateFrame("Frame",nil,entry.frame)
        frame.endCapperClip=clip
        frame:SetParent(clip)
    end
    if clip then E.UpdateEffectClip(entry,config,clip,level) end
    frame:SetFrameLevel(level)
end

function E.CropNativeEffect(entry, config, scene, viewport, centreX, centreY)
    local baseline=E.EffectBaselines[config.art]
    local _,height=entry.art:GetSize()
    local bottom,visible=0,true
    if baseline and scene.SetViewTranslation then
        -- All coordinates are relative to artwork TOP. Moving the artwork/cap
        -- moves the boundary with it without screen queries or OnUpdate.
        bottom=math.max(0,viewport/2-centreY-height*baseline)
        if bottom>=viewport then
            -- Keep a valid viewport; the caller hides fully cropped particles.
            bottom,visible=0,false
        end
    end
    -- Insets alter the camera but do not cut off particle pixels. The actual
    -- scene rectangle must end at the baseline. Its top/left/right stay fixed.
    -- Missing translation support safely retains the original uncropped view.
    scene:SetSize(viewport,viewport-bottom)
    scene:ClearAllPoints()
    scene:SetPoint("CENTER",entry.art,"TOPLEFT",centreX,centreY+bottom/2)
    if scene.SetViewInsets then scene:SetViewInsets(0,0,0,0) end
    -- Preserve the six-unit span at distance eight and the calibrated centre
    -- while rendering into the shortened rectangle (confirmed live in RC13).
    scene:SetCameraFieldOfView(2*math.atan(3*(viewport-bottom)/(8*viewport)))
    if scene.SetViewTranslation then scene:SetViewTranslation(0,-bottom/2) end
    return visible
end

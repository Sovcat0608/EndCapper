local _, E = ...
-- Art-registered layers. Native glow calibration never moves these textures.
local media="Interface\\AddOns\\EndCapper\\Media\\"
local uv={0,0,0,1,1,0,1,1}
function E.StopArcane(entry)
    local s=entry.arcane
    if not s then return end
    -- Read the clock only at lifecycle boundaries, never once per render frame.
    if s.startedAt then
        s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%24
        s.startedAt=nil
    end
    s.motionGroup:Stop(); s.pulseGroup:Stop(); s.rotationGroup:Stop(); s.host:Hide()
end
function E.PlayArcane(entry)
    local s=entry.arcane
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    s.motionGroup:Play(false,s.elapsed%6)
    s.pulseGroup:Play(false,s.elapsed%4)
    if s.hasSeal then s.rotationGroup:Play(false,s.elapsed%24) end
end
function E.UpdateArcane(entry,config)
    local s=entry.arcane
    if (config.art~="violetSpire" and config.art~="soulbound") or config.effects==false then
        if s then s.enabled=false; E.StopArcane(entry) end
        return
    end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame)
        host:EnableMouse(false)
        -- The crystal is artwork. Only its emission and the seal are clipped;
        -- this stationary child stays independent of the floating textures.
        local effectsHost=CreateFrame("Frame",nil,host)
        effectsHost:EnableMouse(false)
        local function texture(name,blend,layer,parent)
            local t=(parent or host):CreateTexture(nil,"OVERLAY",nil,layer)
            t:SetTexture(media..name..".blp","CLAMP","CLAMP","TRILINEAR")
            if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
            if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
            t:SetBlendMode(blend)
            t:SetPoint("CENTER",host,"CENTER",0,0)
            return t
        end
        local crystal=texture("ArcaneCrystal","BLEND",1)
        local emission=texture("ArcaneCrystal","ADD",2,effectsHost)
        local sigil=texture("ArcaneSigil","ADD",3,effectsHost); sigil:SetAlpha(0.65)
        local group=sigil:CreateAnimationGroup(); group:SetLooping("REPEAT")
        local rotation=group:CreateAnimation("Rotation")
        rotation:SetDuration(24); rotation:SetOrder(1); rotation:SetSmoothing("NONE")
        rotation:SetOrigin("CENTER",0,0)
        -- One native timeline targets both textures, keeping emission registered.
        -- Explicit return legs close the loop without a positional jump.
        local motion=host:CreateAnimationGroup(); motion:SetLooping("REPEAT")
        local translations={}
        for order=1,2 do
            for _,target in ipairs({crystal,emission}) do
                local a=motion:CreateAnimation("Translation")
                a:SetTarget(target); a:SetDuration(3); a:SetOrder(order); a:SetSmoothing("IN_OUT")
                translations[#translations+1]={animation=a,direction=order==1 and 1 or -1}
            end
        end
        local pulse=emission:CreateAnimationGroup(); pulse:SetLooping("REPEAT")
        for order=1,2 do
            local a=pulse:CreateAnimation("Alpha")
            a:SetFromAlpha(order==1 and 0.08 or 0.38); a:SetToAlpha(order==1 and 0.38 or 0.08)
            a:SetDuration(2); a:SetOrder(order); a:SetSmoothing("IN_OUT")
        end
        emission:SetAlpha(0.08)
        s={host=host,effectsHost=effectsHost,crystal=crystal,emission=emission,sigil=sigil,
            rotationGroup=group,rotation=rotation,motionGroup=motion,pulseGroup=pulse,
            translations=translations,elapsed=0}
        entry.arcane=s
    end
    s.enabled=true; s.art=entry.art
    local soulbound=config.art=="soulbound"
    s.hasSeal=not soulbound
    s.crystal:SetTexture(media..(soulbound and "SoulboundCrystal" or "ArcaneCrystal")..".blp","CLAMP","CLAMP","TRILINEAR")
    s.emission:SetTexture(media..(soulbound and "SoulboundCrystalEmission" or "ArcaneCrystal")..".blp","CLAMP","CLAMP","TRILINEAR")
    if s.hasSeal then s.sigil:Show() else s.sigil:Hide() end
    local width,height=entry.art:GetSize(); s.height=height
    local anchorU=soulbound and 0.30 or 0.345
    s.x=(config.flip and 1-anchorU or anchorU)*width
    s.y=-(soulbound and 0.175 or 0.405)*height
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+3)
    E.UpdateEffectClip(entry,config,s.effectsHost,entry.frame:GetFrameLevel()+3)
    s.host:SetAlpha(entry.alpha); s.host:SetSize(height*0.4,height*0.4)
    s.host:ClearAllPoints()
    s.host:SetPoint("CENTER",s.art,"TOPLEFT",s.x,s.y)
    local amplitude=height*0.012
    s.crystal:SetPoint("CENTER",s.host,"CENTER",0,-amplitude)
    s.emission:SetPoint("CENTER",s.host,"CENTER",0,-amplitude)
    for _,t in ipairs(s.translations) do t.animation:SetOffset(0,t.direction*2*amplitude) end
    local crystalWidth=height*(soulbound and 0.44 or 0.4)
    local crystalHeight=height*(soulbound and 0.32 or 0.4)
    s.crystal:SetSize(crystalWidth,crystalHeight)
    s.emission:SetSize(crystalWidth,crystalHeight)
    -- 100% is the approved rc.6 size; centre and rotation stay independent.
    local sealSize=height*0.525*(config.sealSize or E.ArcaneSealSize)/100
    s.sigil:SetSize(sealSize,sealSize)
    s.crystal:SetTexCoord(E.UV(uv,config.flip))
    s.emission:SetTexCoord(E.UV(uv,config.flip))
    s.sigil:SetTexCoord(E.UV(uv,config.flip))
    s.rotation:SetDegrees(config.flip and 360 or -360)
    E.PlayArcane(entry)
end

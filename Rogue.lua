local _, E = ...
local media="Interface\\AddOns\\EndCapper\\Media\\"
local daggerSizes={192,288,384,576,768,1086}
-- Neutral to low, low to high, high to neutral. Both transforms use
-- the same native clock and easing so their turning points coincide.
local hoverLegs={{1.5,"OUT",0,-1},{3,"IN_OUT",-1,1},{1.5,"IN",1,0}}

function E.GetDaggerHoverFraction(s)
    local elapsed=s.motion.GetElapsed and s.motion:GetElapsed() or s.elapsed+GetTime()-s.startedAt
    local phase=elapsed%6
    for i,leg in ipairs(hoverLegs) do
        if phase<leg[1] then
            local translation=s.translations[i]
            local t=phase/leg[1]
            local progress=translation.GetSmoothProgress and translation:GetSmoothProgress() or nil
            if progress==nil then
                if i==1 then progress=1-(1-t)^2
                elseif i==3 then progress=t*t
                else progress=t*t*(3-2*t) end
            end
            return leg[3]+(leg[4]-leg[3])*progress
        end
        phase=phase-leg[1]
    end
end
local function textureHost(parent)
    local host=CreateFrame("Frame",nil,parent)
    host:EnableMouse(false)
    host:Hide()
    local texture=host:CreateTexture(nil,"ARTWORK")
    return host,texture
end

local function backingSize(content)
    local size=1
    while size<content do size=size*2 end
    return size
end

local function textureSize(entry,width,sizes)
    local scale=entry.frame.GetEffectiveScale and entry.frame:GetEffectiveScale()
    local screenHeight
    if GetPhysicalScreenSize then _,screenHeight=GetPhysicalScreenSize() end
    if scale and scale>0 and screenHeight and screenHeight>0 then
        local pixels=width*scale*screenHeight/768
        for _,size in ipairs(sizes) do if size>=pixels then return size end end
    end
    return sizes[#sizes]
end

local function disableTextureSnapping(texture)
    if texture.SetSnapToPixelGrid then texture:SetSnapToPixelGrid(false) end
    if texture.SetTexelSnappingBias then texture:SetTexelSnappingBias(0) end
end

local function place(t,host,path,width,height,u,v,flip)
    t:SetTexture(path)
    t:SetTexCoord(E.UV({0,0,0,v,u,0,u,v},flip))
    t:SetSize(width,height)
    t:ClearAllPoints()
    t:SetPoint("CENTER",host,"CENTER")
end

local function stopHover(s)
    if s.startedAt then
        s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%6
        s.startedAt=nil
        s.motion:Stop()
    end
end

function E.StopRogue(entry)
    local s=entry.rogue
    if not s then return end
    stopHover(s)
    s.daggerHost:Hide()
end

function E.PlayRogue(entry)
    local s=entry.rogue
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.daggerHost:Show()
    if s.animate and not s.startedAt then
        s.startedAt=GetTime()
        s.motion:Play(false,s.elapsed%6)
    end
end

function E.UpdateRogue(entry,config)
    local name=E.RogueArtworks[config.art]
    local s=entry.rogue
    if not name then
        if s then s.enabled=false;E.StopRogue(entry) end
        return
    end
    if not s then
        local daggerHost,dagger=textureHost(entry.frame)
        disableTextureSnapping(dagger)
        local motion=daggerHost:CreateAnimationGroup()
        motion:SetLooping("REPEAT")
        local translations={}
        local topDegrees=entry.side=="left" and -1 or 1
        for order,spec in ipairs(hoverLegs) do
            local move=motion:CreateAnimation("Translation")
            move:SetDuration(spec[1])
            move:SetOrder(order)
            move:SetSmoothing(spec[2])
            translations[order]=move
            local turn=motion:CreateAnimation("Rotation")
            turn:SetTarget(dagger)
            turn:SetOrigin("CENTER",0,0)
            turn:SetDuration(spec[1])
            turn:SetOrder(order)
            turn:SetSmoothing(spec[2])
            turn:SetDegrees(topDegrees*(spec[4]-spec[3]))
        end
        s={daggerHost=daggerHost,dagger=dagger,motion=motion,translations=translations,topDegrees=topDegrees}
        entry.rogue=s
    end
    if s.art~=config.art then
        stopHover(s)
        s.elapsed=hoverLegs[1][1] -- Start at the bottom of the float.
    end
    s.art=config.art
    s.enabled=true
    s.animate=config.effects~=false
    if not s.animate then stopHover(s) end

    local width,height=entry.art:GetSize()
    local level=entry.frame:GetFrameLevel()
    local flip=config.flip
    local daggerWidth,daggerHeight=width*.88,height*.88
    local size=textureSize(entry,daggerWidth*E.ArtworkLayerScale(config,"art:dagger",E.RogueDaggerSize),daggerSizes)
    local contentHeight=size*2/3
    local amplitude=s.animate and (daggerHeight*.012+2) or 0
    if amplitude~=s.hoverAmplitude then
        stopHover(s)
        s.hoverAmplitude=amplitude
        for i,spec in ipairs(hoverLegs) do
            s.translations[i]:SetOffset(0,amplitude*(spec[4]-spec[3]))
        end
    end
    local daggerU=config.art=="gloomfang" and .24 or .71
    s.daggerHost:SetSize(daggerWidth,daggerHeight)
    s.daggerHost:SetFrameLevel(level+4)
    s.daggerHost:SetAlpha(entry.alpha)
    s.daggerHost:ClearAllPoints()
    s.daggerHost:SetPoint("CENTER",entry.art,"TOPLEFT",(flip and 1-daggerU or daggerU)*width,-.375*height)
    local daggerFlip=E.LayerFacing(config,"art:dagger")
    local scale=E.RogueDaggerSize/100
    place(s.dagger,s.daggerHost,media..name.."DaggerCASSize"..size..".tga",daggerWidth*scale,daggerHeight*scale,
        size/backingSize(size),contentHeight/backingSize(contentHeight),daggerFlip)

    E.PlayRogue(entry)
end

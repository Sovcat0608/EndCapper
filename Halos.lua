local _,E=...
local media="Interface\\AddOns\\EndCapper\\Media\\"
local uv={0,0,0,1,1,0,1,1}
function E.StopHalo(entry)
    local s=entry.halo;if not s then return end
    if s.startedAt then
        s.phase=(s.phase+math.max(0,GetTime()-s.startedAt)/s.period)%1;s.startedAt=nil
    end
    s.group:Stop();s.host:Hide()
end
function E.PlayHalo(entry)
    local s=entry.halo
    if not s or not s.enabled or not entry.effectsEnabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime();s.group:Play(false,s.phase*s.period)
end
function E.UpdateHalo(entry,config)
    local s=entry.halo
    E.StopHalo(entry)
    local tuning=E.GetHaloConfig(config)
    if not tuning or config.effects==false then if s then s.enabled=false end;return end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame);host:EnableMouse(false)
        local texture=host:CreateTexture(nil,"ARTWORK")
        texture:SetBlendMode("BLEND");texture:SetPoint("CENTER",host,"CENTER",0,0)
        local group=texture:CreateAnimationGroup();group:SetLooping("REPEAT")
        local rotation=group:CreateAnimation("Rotation")
        rotation:SetOrder(1);rotation:SetSmoothing("NONE");rotation:SetOrigin("CENTER",0,0)
        s={host=host,texture=texture,group=group,rotation=rotation,phase=0,period=40}
        entry.halo=s
    end
    -- Keep angular phase when changing speed/direction, independent of artwork placement.
    local direction=(config.flip and 1 or -1)*(tuning.reverse and -1 or 1)
    if s.direction and s.direction~=direction then s.phase=(-s.phase)%1 end
    if s.art~=config.art then s.phase=0 end
    s.art=config.art;s.direction=direction;s.period=tuning.period;s.enabled=true
    local width,height=entry.art:GetSize()
    local diameter=height*0.62*tuning.size/100
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+1)
    s.host:SetSize(diameter,diameter);s.host:SetAlpha(entry.alpha*tuning.opacity/100)
    s.host:ClearAllPoints()
    s.host:SetPoint("CENTER",entry.art,"CENTER",(config.flip and -1 or 1)*tuning.x*width/150,tuning.y*height/150)
    -- Stored mip levels reduce shimmer when the detailed ring is scaled down.
    s.texture:SetTexture(E.ArtworkTexture(media..E.HaloArtworks[config.art]..".blp"),"CLAMP","CLAMP","TRILINEAR")
    if s.texture.SetSnapToPixelGrid then s.texture:SetSnapToPixelGrid(false) end
    if s.texture.SetTexelSnappingBias then s.texture:SetTexelSnappingBias(0) end
    s.texture:SetSize(diameter,diameter);s.texture:SetTexCoord(E.UV(uv,config.flip))
    s.rotation:SetDuration(s.period);s.rotation:SetDegrees(direction*360)
    E.PlayHalo(entry)
end

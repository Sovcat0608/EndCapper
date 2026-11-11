local _,E=...
local media="Interface\\AddOns\\EndCapper\\Media\\Moonwell"
local uv={0,0,0,1,1,0,1,1}
-- Four source-registered planes. Water and reflected light share phase/period.
function E.StopMoonwell(entry)
    local s=entry.moonwell
    if not s then return end
    if s.startedAt then s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%60;s.startedAt=nil end
    for _,layer in ipairs(s.layers) do layer.group:Stop() end
    s.host:Hide()
end
function E.PlayMoonwell(entry)
    local s=entry.moonwell
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    for _,layer in ipairs(s.layers) do layer.group:Play(false,s.elapsed%layer.period) end
end
function E.UpdateMoonwell(entry,config)
    local s=entry.moonwell
    if config.art~="moonwell" or config.effects==false then
        if s then s.enabled=false;E.StopMoonwell(entry) end
        return
    end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame);host:EnableMouse(false)
        s={host=host,layers={},elapsed=0};entry.moonwell=s
        for _,spec in ipairs({{"Bounce",5,.04,.34},{"Glyphs",4,.08,.62},{"Moon",6,.08,.62},{"Water",5,.08,.62}}) do
            local t=host:CreateTexture(nil,"OVERLAY",nil,1)
            t:SetTexture(media..spec[1]..".tga");t:SetBlendMode("ADD");t:SetPoint("CENTER",host,"CENTER",0,0);t:SetAlpha(spec[3])
            local group=t:CreateAnimationGroup();group:SetLooping("REPEAT")
            for order=1,2 do
                local a=group:CreateAnimation("Alpha");a:SetFromAlpha(order==1 and spec[3] or spec[4]);a:SetToAlpha(order==1 and spec[4] or spec[3])
                a:SetDuration(spec[2]/2);a:SetOrder(order);a:SetSmoothing("IN_OUT")
            end
            s.layers[#s.layers+1]={texture=t,group=group,kind=spec[1],period=spec[2]}
        end
    end
    s.enabled=true
    local w,h=entry.art:GetSize()
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+3);s.host:SetAlpha(entry.alpha);s.host:SetSize(w,h)
    s.host:ClearAllPoints();s.host:SetPoint("CENTER",entry.art,"CENTER",0,0)
    for _,layer in ipairs(s.layers) do layer.texture:SetSize(w,h);layer.texture:SetTexCoord(E.UV(uv,config.flip));layer.texture:Show() end
    E.PlayMoonwell(entry)
end

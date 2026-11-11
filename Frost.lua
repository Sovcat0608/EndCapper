local _, E = ...
local media="Interface\\AddOns\\EndCapper\\Media\\"
local uv={0,0,0,1,1,0,1,1}
-- Runes, ice and eyes use separate native Alpha cycles, with delayed bloom.
-- Their least common period is 12s; preserve phase at lifecycle boundaries only.
function E.StopFrost(entry)
    local s=entry.frost
    if not s then return end
    if s.startedAt then s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%12; s.startedAt=nil end
    for _,layer in ipairs(s.layers) do layer.group:Stop() end
    s.host:Hide()
end
function E.PlayFrost(entry)
    local s=entry.frost
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    for _,layer in ipairs(s.layers) do
        if layer.enabled then layer.group:Play(false,(s.elapsed-layer.lag)%layer.period) end
    end
end
function E.UpdateFrost(entry,config)
    local name=E.FrostArtworks[config.art]
    local s=entry.frost
    if not name or config.effects==false then
        if s then s.enabled=false; E.StopFrost(entry) end
        return
    end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame); host:EnableMouse(false)
        s={host=host,layers={},elapsed=0}; entry.frost=s
        for _,spec in ipairs({{"Runes",4},{"Ice",6},{"Eyes",3}}) do
            for _,bloom in ipairs({true,false}) do
                local t=host:CreateTexture(nil,"OVERLAY",nil,bloom and 1 or 2)
                t:SetBlendMode("ADD");t:SetPoint("CENTER",host,"CENTER",0,0);t:SetAlpha(0.08)
                local group=t:CreateAnimationGroup();group:SetLooping("REPEAT")
                local high=bloom and 0.50 or 0.65
                for order=1,2 do
                    local a=group:CreateAnimation("Alpha")
                    a:SetFromAlpha(order==1 and 0.08 or high);a:SetToAlpha(order==1 and high or 0.08)
                    a:SetDuration(spec[2]/2);a:SetOrder(order);a:SetSmoothing("IN_OUT")
                end
                s.layers[#s.layers+1]={texture=t,group=group,kind=spec[1],suffix=spec[1]..(bloom and "Bloom" or ""),period=spec[2],lag=bloom and 0.3 or 0}
            end
        end
    end
    s.enabled=true
    local width,height=entry.art:GetSize()
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+3);s.host:SetAlpha(entry.alpha);s.host:SetSize(width,height)
    s.host:ClearAllPoints();s.host:SetPoint("CENTER",entry.art,"CENTER",0,0)
    for _,layer in ipairs(s.layers) do
        layer.enabled=layer.kind~="Eyes" or config.art=="rimeguard"
        if layer.enabled then
            layer.texture:SetTexture(media..name..layer.suffix..".tga")
            layer.texture:SetSize(width,height);layer.texture:SetTexCoord(E.UV(uv,config.flip));layer.texture:Show()
        else layer.group:Stop();layer.texture:Hide() end
    end
    E.PlayFrost(entry)
end

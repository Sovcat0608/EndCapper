local _, E = ...
-- Full-canvas textures remain registered to the art; native model tuning is separate.
local media="Interface\\AddOns\\EndCapper\\Media\\"
local uv={0,0,0,1,1,0,1,1}
local period=4
function E.StopMolten(entry)
    local s=entry.molten
    if not s then return end
    if s.startedAt then
        s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%period
        s.startedAt=nil
    end
    for _,layer in ipairs(s.layers) do layer.group:Stop() end
    s.host:Hide()
end
function E.PlayMolten(entry)
    local s=entry.molten
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    for _,layer in ipairs(s.layers) do layer.group:Play(false,(s.elapsed-layer.lag)%period) end
end
function E.UpdateMolten(entry,config)
    local name=E.MoltenArtworks[config.art] or E.WarlockArtworks[config.art]
    local s=entry.molten
    if not name or config.effects==false then
        if s then s.enabled=false; E.StopMolten(entry) end
        return
    end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame); host:EnableMouse(false)
        s={host=host,layers={},elapsed=0}; entry.molten=s
        for i,spec in ipairs({{"Bloom",0.08,0.62,0.3},{"Emission",0.12,0.72,0}}) do
            local t=host:CreateTexture(nil,"OVERLAY",nil,i)
            t:SetBlendMode("ADD"); t:SetPoint("CENTER",host,"CENTER",0,0); t:SetAlpha(spec[2])
            local group=t:CreateAnimationGroup(); group:SetLooping("REPEAT")
            for order=1,2 do
                local a=group:CreateAnimation("Alpha")
                a:SetFromAlpha(order==1 and spec[2] or spec[3]); a:SetToAlpha(order==1 and spec[3] or spec[2])
                a:SetDuration(period/2); a:SetOrder(order); a:SetSmoothing("IN_OUT")
            end
            s.layers[i]={texture=t,group=group,suffix=spec[1],lag=spec[4]}
        end
    end
    s.enabled=true
    local width,height=entry.art:GetSize()
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+3)
    s.host:SetAlpha(entry.alpha); s.host:SetSize(width,height)
    s.host:ClearAllPoints(); s.host:SetPoint("CENTER",entry.art,"CENTER",0,0)
    for _,layer in ipairs(s.layers) do
        layer.texture:SetTexture(media..name..layer.suffix..".tga")
        layer.texture:SetSize(width,height); layer.texture:SetTexCoord(E.UV(uv,config.flip))
    end
    E.PlayMolten(entry)
end

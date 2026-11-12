local _, E = ...
local prefix="Interface\\AddOns\\EndCapper\\Media\\"
local path=prefix.."SkycutterBoatStaticProbe.tga"
local uv={0,0,0,1,1,0,1,1}
-- Content dimensions and power-of-two backing sizes; no runtime mip filtering.
local sizes={{192,128,256,128},{288,192,512,256},{384,256,512,256},
    {480,320,512,512},{576,384,1024,512},{768,512,1024,512},{960,640,1024,1024}}
local function selectTexture(entry,width,height)
    local scale=entry.frame.GetEffectiveScale and entry.frame:GetEffectiveScale()
    local _,screenHeight
    if GetPhysicalScreenSize then _,screenHeight=GetPhysicalScreenSize() end
    if not scale or scale<=0 or not screenHeight or screenHeight<=0 then return E.ArtworkTexture(path),uv,"baseline" end
    -- Same pixel/UI conversion used by Blizzard PixelUtil, without rounding motion.
    local pixelWidth,pixelHeight=width*scale*screenHeight/768,height*scale*screenHeight/768
    for _,size in ipairs(sizes) do
        local w,h,tw,th=unpack(size)
        if w>=pixelWidth and h>=pixelHeight then
            local u,v=w/tw,h/th
            return prefix.."SkycutterBoat".."CASSize"..w..".tga",{0,0,0,v,u,0,u,v},w.."x"..h.." CAS"
        end
    end
    return E.ArtworkTexture(path),uv,"baseline"
end
local function capturePhase(s)
    if s.startedAt then
        s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%42
        s.startedAt=nil
    end
end

function E.StopSkycutter(entry)
    local s=entry.skycutter
    if not s then return end
    capturePhase(s)
    s.motion:Stop();s.rock:Stop()
    s.boat:Hide();s.host:Hide()
end

function E.PlaySkycutter(entry)
    local s=entry.skycutter
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show();s.boat:Show()
    if not s.animate then
        capturePhase(s)
        s.motion:Stop();s.rock:Stop()
        return
    end
    if s.startedAt then return end
    s.startedAt=GetTime()
    s.starts=s.starts+1
    s.motion:Play(false,s.elapsed%6)
    s.rock:Play(false,s.elapsed%7)
end

function E.UpdateSkycutter(entry,config)
    local s=entry.skycutter
    if config.art~="skycutter" then
        if s then s.enabled=false;E.StopSkycutter(entry) end
        return
    end
    if not s then
        -- Independent native timelines: frame hover and texture rocking.
        local host=CreateFrame("Frame",nil,entry.frame)
        host:EnableMouse(false);host:Hide()
        local boat=host:CreateTexture(nil,"ARTWORK",nil,0)
        if boat.SetSnapToPixelGrid then boat:SetSnapToPixelGrid(false) end
        if boat.SetTexelSnappingBias then boat:SetTexelSnappingBias(0) end
        local motion=host:CreateAnimationGroup();motion:SetLooping("REPEAT")
        local translations={}
        for order=1,2 do
            local a=motion:CreateAnimation("Translation")
            a:SetDuration(3);a:SetOrder(order);a:SetSmoothing("IN_OUT")
            translations[order]=a
        end
        local rock=boat:CreateAnimationGroup();rock:SetLooping("REPEAT")
        local rotations={}
        -- Start at neutral, ease into each extreme, cross neutral without a stop.
        for order,leg in ipairs({{1.75,"OUT",3},{3.5,"IN_OUT",-6},{1.75,"IN",3}}) do
            local a=rock:CreateAnimation("Rotation")
            a:SetDuration(leg[1]);a:SetOrder(order);a:SetSmoothing(leg[2]);a:SetOrigin("CENTER",0,0)
            rotations[order]={animation=a,degrees=leg[3]}
        end
        s={host=host,boat=boat,motion=motion,translations=translations,rock=rock,rotations=rotations,elapsed=0,starts=0,updates=0}
        entry.skycutter=s
    end
    s.enabled=true;s.animate=config.effects~=false
    for _,leg in ipairs(s.rotations) do leg.animation:SetDegrees(leg.degrees*(config.flip and -1 or 1)) end
    s.updates=s.updates+1
    local width,height=entry.art:GetSize()
    local texture,coords,size=selectTexture(entry,width,height)
    s.textureSize=size
    -- Plain TGA sampling; resizing selects a prepared image, not an animation tick.
    s.boat:SetTexture(texture)
    local amplitude=s.animate and height*0.012 or 0
    s.translations[1]:SetOffset(0,amplitude*2)
    s.translations[2]:SetOffset(0,-amplitude*2)
    s.host:SetFrameLevel(entry.frame:GetFrameLevel()+2)
    s.host:SetSize(width,height)
    s.host:ClearAllPoints()
    s.host:SetPoint("CENTER",entry.art,"CENTER",0,-amplitude)
    s.boat:SetSize(width,height)
    s.boat:SetAlpha(entry.alpha)
    s.boat:SetTexCoord(E.UV(coords,config.flip))
    s.boat:ClearAllPoints()
    s.boat:SetPoint("CENTER",s.host,"CENTER",0,0)
    E.PlaySkycutter(entry)
end

-- Read-only, session-only diagnostics. Native loop repetitions are not restarts.
function E.SkycutterHoverStatus(entry)
    local s=entry and entry.skycutter
    if not s then return "Skycutter not loaded" end
    local running=s.startedAt~=nil
    local age=running and string.format("%.1fs",math.max(0,GetTime()-s.startedAt)) or "stopped"
    return string.format("Skycutter hover: restarts=%d, updates=%d, current run=%s, texture=%s",
        math.max(0,s.starts-1),s.updates,age,s.textureSize or "baseline")
end

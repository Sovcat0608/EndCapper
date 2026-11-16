local _,E=...
local media="Interface\\AddOns\\EndCapper\\Media\\"
local gearSpecs={{866,298,144,32,1},{818,413,114,24,-1},{914,440,128,28,1}}
local sizes={64,96,128,192,256}
local function texture(host)
    local t=host:CreateTexture(nil,"ARTWORK")
    t:SetBlendMode("BLEND")
    if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    return t
end
local function host(parent)
    local f=CreateFrame("Frame",nil,parent);f:EnableMouse(false);f:Hide();return f
end
local function drawSand(s)
    local cursor=(s.elapsed%2)/2*32
    local index=math.floor(cursor);local mix=cursor-index
    for i,t in ipairs(s.sand) do
        local frame=(index+i-1)%32
        local x,y=frame%8,math.floor(frame/8)
        local l,r=(x+3/128)/8,(x+1-3/128)/8
        local top,bottom=(y+3/128)/4,(y+1-3/128)/4
        t:SetTexCoord(E.UV({l,top,l,bottom,r,top,r,bottom},s.flip))
        t:SetAlpha(i==1 and 1-mix or mix)
    end
end
local function sizeFor(entry,width)
    local scale=entry.frame.GetEffectiveScale and entry.frame:GetEffectiveScale()
    local _,screenHeight
    if GetPhysicalScreenSize then _,screenHeight=GetPhysicalScreenSize() end
    if scale and scale>0 and screenHeight and screenHeight>0 then
        local pixels=width*scale*screenHeight/768
        for _,size in ipairs(sizes) do if size>=pixels then return size end end
    end
    return 256
end
function E.StopTimeworks(entry)
    local s=entry.timeworks;if not s then return end
    if s.startedAt then s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%672;s.startedAt=nil end
    s.middle:SetScript("OnUpdate",nil);s.middle:Hide();s.frontHost:Hide()
    if s.glyphHost then s.glyphHost:Hide();for _,layer in ipairs(s.glyphs) do layer.group:Stop() end end
    for _,g in ipairs(s.gears or {}) do g.group:Stop() end
end
function E.PlayTimeworks(entry)
    local s=entry.timeworks
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    local starting=s.animate and not s.startedAt
    if s.animate and s.glyphHost then
        s.glyphHost:Show()
        if starting then for _,layer in ipairs(s.glyphs) do layer.group:Play(false,(s.elapsed-layer.lag)%6) end end
    end
    if s.art=="timelost" then
        s.middle:Show();s.frontHost:Show()
        if s.animate and not s.startedAt then
            s.startedAt=GetTime()
            for i,g in ipairs(s.gears) do g.group:Play(false,s.elapsed%gearSpecs[i][4]) end
        end
    elseif s.animate then
        s.middle:Show()
        if not s.startedAt then s.startedAt=GetTime() end
        s.middle:SetScript("OnUpdate",s.tick)
    end
end
function E.UpdateTimeworks(entry,config)
    local s=entry.timeworks
    if not E.TimeArtworks[config.art] then
        if s then s.enabled=false;E.StopTimeworks(entry) end;return
    end
    if not s then
        s={middle=host(entry.frame),frontHost=host(entry.frame),elapsed=0}
        entry.timeworks=s
        s.tick=function()
            -- Elapsed time, rather than frame count, handles stalls and keeps
            -- both crossfade textures on the same continuous two-second loop.
            local phase=s.elapsed
            s.elapsed=(phase+math.max(0,GetTime()-(s.startedAt or GetTime())))%672
            drawSand(s);s.elapsed=phase
        end
    end
    E.StopTimeworks(entry)
    if s.art~=config.art then s.elapsed=0 end
    s.art=config.art;s.enabled=true;s.animate=config.effects~=false;s.flip=config.flip==true
    local width,height=entry.art:GetSize();local level=entry.frame:GetFrameLevel()
    if not s.glyphHost then
        s.glyphHost=host(entry.frame);s.glyphs={}
        for _,spec in ipairs({{"Bloom",.04,.35,.35},{"Emission",.12,.65,0}}) do
            local t=texture(s.glyphHost);t:SetBlendMode("ADD");t:SetAlpha(spec[2])
            local group=t:CreateAnimationGroup();group:SetLooping("REPEAT")
            for order=1,2 do
                local a=group:CreateAnimation("Alpha");a:SetOrder(order);a:SetDuration(3);a:SetSmoothing("IN_OUT")
                a:SetFromAlpha(order==1 and spec[2] or spec[3]);a:SetToAlpha(order==1 and spec[3] or spec[2])
            end
            s.glyphs[#s.glyphs+1]={texture=t,group=group,lag=spec[4],suffix=spec[1]}
        end
    end
    s.glyphHost:SetFrameLevel(level+5);s.glyphHost:SetAlpha(entry.alpha);s.glyphHost:SetSize(width,height)
    s.glyphHost:ClearAllPoints();s.glyphHost:SetPoint("CENTER",entry.art,"CENTER",0,0)
    for _,layer in ipairs(s.glyphs) do
        layer.texture:SetTexture(media..(config.art=="timekeeper" and "Timekeeper" or "Timelost").."Glyph"..layer.suffix.."CAS.tga")
        layer.texture:SetSize(width,height);layer.texture:ClearAllPoints();layer.texture:SetPoint("CENTER",s.glyphHost,"CENTER",0,0)
        layer.texture:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},s.flip));layer.texture:Show()
    end
    s.middle:SetFrameLevel(level+3);s.frontHost:SetFrameLevel(level+4)
    for _,f in ipairs({s.middle,s.frontHost}) do
        f:SetSize(width,height);f:SetAlpha(entry.alpha);f:ClearAllPoints();f:SetPoint("CENTER",entry.art,"CENTER",0,0)
    end
    for _,g in ipairs(s.gears or {}) do g.texture:Hide() end
    for _,t in ipairs(s.sand or {}) do t:Hide() end
    if config.art=="timelost" then
        if not s.front then
            s.front=texture(s.frontHost);s.front:SetTexture(media.."TimelostFront.tga")
            s.gears={}
            for i,spec in ipairs(gearSpecs) do
                local t=texture(s.middle);local group=t:CreateAnimationGroup();group:SetLooping("REPEAT")
                local rotation=group:CreateAnimation("Rotation");rotation:SetOrder(1);rotation:SetOrigin("CENTER",0,0)
                rotation:SetDuration(spec[4]);rotation:SetSmoothing("NONE")
                s.gears[i]={texture=t,group=group,rotation=rotation}
            end
        end
        s.front:SetSize(width,height);s.front:ClearAllPoints();s.front:SetPoint("CENTER",s.frontHost,"CENTER",0,0)
        s.front:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},s.flip));s.front:Show()
        for i,spec in ipairs(gearSpecs) do
            local g=s.gears[i];local diameter=width*spec[3]/1086;local size=sizeFor(entry,diameter)
            local backing=1;while backing<size do backing=backing*2 end;local u=size/backing
            g.texture:SetTexture(media.."TimelostGear"..i.."CASSize"..size..".tga")
            g.texture:SetSize(diameter,diameter);g.texture:ClearAllPoints()
            g.texture:SetPoint("CENTER",entry.art,"TOPLEFT",width*(s.flip and 1-spec[1]/1086 or spec[1]/1086),-height*spec[2]/724)
            g.texture:SetTexCoord(E.UV({0,0,0,u,u,0,u,u},s.flip));g.texture:Show()
            g.rotation:SetDegrees(360*spec[5]*(s.flip and -1 or 1))
        end
    else
        if not s.sand then s.sand={texture(s.middle),texture(s.middle)} end
        for _,t in ipairs(s.sand) do
            t:SetTexture(media.."TimekeeperSandAtlasCAS.tga");t:SetSize(width*184/1086,height*208/724)
            t:ClearAllPoints();t:SetPoint("CENTER",entry.art,"TOPLEFT",width*(s.flip and 1-392/1086 or 392/1086),-height*484/724);t:Show()
        end
        drawSand(s)
    end
    E.PlayTimeworks(entry)
end

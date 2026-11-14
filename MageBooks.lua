local _,E=...
local prefix="Interface\\AddOns\\EndCapper\\Media\\"
local sizes={192,288,384,480,576,768,887}
local function textureSize(entry,width)
    local scale=entry.frame.GetEffectiveScale and entry.frame:GetEffectiveScale()
    local _,screenHeight
    if GetPhysicalScreenSize then _,screenHeight=GetPhysicalScreenSize() end
    local chosen=887
    if scale and scale>0 and screenHeight and screenHeight>0 then
        local pixels=width*scale*screenHeight/768
        for _,size in ipairs(sizes) do if size>=pixels then chosen=size;break end end
    end
    local backing=1
    while backing<chosen do backing=backing*2 end
    local uv=chosen/backing
    return chosen,{0,0,0,uv,uv,0,uv,uv}
end
local function capturePhase(s)
    if s.startedAt then s.elapsed=(s.elapsed+math.max(0,GetTime()-s.startedAt))%60;s.startedAt=nil end
end
local function texture(host,layer)
    local t=host:CreateTexture(nil,layer,nil,0)
    if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    return t
end
local function host(parent)
    local f=CreateFrame("Frame",nil,parent);f:EnableMouse(false);f:Hide();return f
end
local function hover(frame)
    local group=frame:CreateAnimationGroup();group:SetLooping("REPEAT")
    local legs={}
    for order=1,2 do
        local a=group:CreateAnimation("Translation");a:SetOrder(order);a:SetDuration(3);a:SetSmoothing("IN_OUT");legs[order]=a
    end
    return {group=group,legs=legs}
end
local function emission(frame,period)
    local layers={}
    for i,suffix in ipairs({"Emission","Bloom"}) do
        local t=texture(frame,"OVERLAY");t:SetBlendMode("ADD")
        local group=t:CreateAnimationGroup();group:SetLooping("REPEAT")
        local low,high=0.08,i==1 and 0.48 or 0.30
        for order=1,2 do
            local a=group:CreateAnimation("Alpha");a:SetOrder(order);a:SetDuration(period/2);a:SetSmoothing("IN_OUT")
            a:SetFromAlpha(order==1 and low or high);a:SetToAlpha(order==1 and high or low)
        end
        layers[i]={texture=t,group=group,suffix=suffix,period=period}
    end
    return layers
end
local function register(t,frame,width,height,coords,flip,path)
    t:SetTexture(path);t:SetSize(width,height);t:SetTexCoord(E.UV(coords,flip))
    t:ClearAllPoints();t:SetPoint("CENTER",frame,"CENTER",0,0);t:Show()
end
function E.StopMageBooks(entry)
    local s=entry.mageBooks;if not s then return end
    capturePhase(s)
    for _,motion in ipairs(s.motions) do motion.group:Stop() end
    for _,layer in ipairs(s.bookLayers) do layer.group:Stop() end
    s.bookHost:Hide();s.bookGlowHost:Hide()
end
function E.PlayMageBooks(entry)
    local s=entry.mageBooks;if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.bookHost:Show()
    if not s.animate then
        capturePhase(s)
        for _,motion in ipairs(s.motions) do motion.group:Stop() end
        s.bookGlowHost:Hide();return
    end
    s.bookGlowHost:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    for _,motion in ipairs(s.motions) do motion.group:Play(false,s.elapsed%6) end
    for _,layer in ipairs(s.bookLayers) do layer.group:Play(false,s.elapsed%layer.period) end
end
function E.UpdateMageBooks(entry,config)
    local name=E.MageArtworks[config.art];local s=entry.mageBooks
    if not name then if s then s.enabled=false;E.StopMageBooks(entry) end;return end
    if not s then
        local bookHost,bookGlowHost=host(entry.frame),host(entry.frame)
        s={bookHost=bookHost,bookGlowHost=bookGlowHost,
            book=texture(bookHost,"ARTWORK"),motions={hover(bookHost),hover(bookGlowHost)},
            bookLayers=emission(bookGlowHost,4),elapsed=0}
        entry.mageBooks=s
    end
    -- Preserve phase on size/position/side refresh; each cap owns its timelines.
    E.StopMageBooks(entry)
    s.enabled=true;s.animate=config.effects~=false
    local tuning=E.GetBookConfig(config)
    local bookFlip=(config.flip==true)~=tuning.flip
    local width,height=entry.art:GetSize()
    local bookWidth=width*0.72*tuning.size/100
    local size,coords=textureSize(entry,bookWidth);s.textureSize=size
    local amplitude=s.animate and E.MageBookHoverAmplitude(bookWidth) or 0
    local x=tuning.x*width/225*(config.flip and -1 or 1)
    local y=tuning.y*height/225-amplitude
    local level=entry.frame:GetFrameLevel()
    s.bookHost:SetFrameLevel(level+4);s.bookGlowHost:SetFrameLevel(level+5)
    -- Both layers now belong to the floating book; no retired scroll crop.
    for _,frame in ipairs({s.bookHost,s.bookGlowHost}) do
        frame:SetSize(bookWidth,bookWidth);frame:SetAlpha(entry.alpha)
        frame:ClearAllPoints();frame:SetPoint("CENTER",entry.art,"CENTER",x,y)
    end
    for _,motion in ipairs(s.motions) do motion.legs[1]:SetOffset(0,amplitude*2);motion.legs[2]:SetOffset(0,-amplitude*2) end
    register(s.book,s.bookHost,bookWidth,bookWidth,coords,bookFlip,prefix..name.."BookCASSize"..size..".tga")
    for _,layer in ipairs(s.bookLayers) do register(layer.texture,s.bookGlowHost,bookWidth,bookWidth,coords,bookFlip,prefix..name.."Book"..layer.suffix.."Size"..size..".tga") end
    E.PlayMageBooks(entry)
end

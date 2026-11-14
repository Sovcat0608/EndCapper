local _,E=...
local prefix="Interface\\AddOns\\EndCapper\\Media\\"
local columns,rows,frames,cell,pad=8,4,32,256,4
local function texture(parent)
    local t=parent:CreateTexture(nil,"OVERLAY")
    t:SetBlendMode("ADD")
    if t.SetSnapToPixelGrid then t:SetSnapToPixelGrid(false) end
    if t.SetTexelSnappingBias then t:SetTexelSnappingBias(0) end
    return t
end
local function uv(t,index,flip)
    local x,y=index%columns,math.floor(index/columns)
    local l,r=(x+pad/cell)/columns,(x+1-pad/cell)/columns
    local top,bottom=(y+pad/cell)/rows,(y+1-pad/cell)/rows
    t:SetTexCoord(E.UV({l,top,l,bottom,r,top,r,bottom},flip))
end
local function draw(state,elapsed)
    for i,pair in ipairs(state.atlases) do
        if pair.active then
            -- Curls flow faster than the eye looks around, while sharing a
            -- repeatable elapsed clock. Crossfade adjacent authored RGBA frames.
            local period=state.cycle
            if state.art=="frostbound" then period=period/(i==1 and 2 or 3) end
            local cursor=(elapsed%period)/period*frames
            local index=math.floor(cursor);local mix=cursor-index
            if pair.index~=index or pair.flip~=state.flip then
                uv(pair.a,index,state.flip);uv(pair.b,(index+1)%frames,state.flip)
                pair.index=index;pair.flip=state.flip
            end
            pair.a:SetAlpha(1-mix);pair.b:SetAlpha(mix)
        end
    end
    if state.art=="frostbound" then
        state.base:SetAlpha(0.94+0.04*math.sin(elapsed*2.7)+0.02*math.sin(elapsed*7.3))
    else state.base:SetAlpha(1) end
end
function E.StopMageSigils(entry)
    local s=entry.mageSigils;if not s then return end
    if s.startedAt then s.elapsed=s.elapsed+math.max(0,GetTime()-s.startedAt);s.startedAt=nil end
    s.host:SetScript("OnUpdate",nil);s.rotationGroup:Stop();s.hover:Stop();s.host:Hide()
end
function E.PlayMageSigils(entry)
    local s=entry.mageSigils
    if not s or not s.enabled or not entry.frame:IsVisible() then return end
    s.host:Show()
    if s.startedAt then return end
    s.startedAt=GetTime()
    local book=entry.mageBooks
    local bookTime=book.elapsed+(book.startedAt and math.max(0,GetTime()-book.startedAt) or 0)
    s.hover:Play(false,(bookTime-1)%6)
    if s.art=="emberbound" then s.rotationGroup:Play(false,s.elapsed%s.period) end
    s.host:SetScript("OnUpdate",s.tick)
end
function E.UpdateMageSigils(entry,config)
    local tuning=E.GetSigilConfig(config);local s=entry.mageSigils
    if not tuning or config.effects==false or tuning.opacity==0 or not entry.mageBooks then
        if s then s.enabled=false;E.StopMageSigils(entry) end
        return
    end
    if not s then
        local host=CreateFrame("Frame",nil,entry.frame);host:EnableMouse(false);host:Hide()
        s={host=host,base=texture(host),atlases={},elapsed=0}
        s.hover=host:CreateAnimationGroup();s.hover:SetLooping("REPEAT");s.hoverLegs={}
        for order=1,2 do
            local leg=s.hover:CreateAnimation("Translation");leg:SetOrder(order)
            leg:SetDuration(3);leg:SetSmoothing("IN_OUT");s.hoverLegs[order]=leg
        end
        for i=1,2 do s.atlases[i]={a=texture(host),b=texture(host)} end
        s.rotationGroup=s.base:CreateAnimationGroup();s.rotationGroup:SetLooping("REPEAT")
        s.rotation=s.rotationGroup:CreateAnimation("Rotation");s.rotation:SetOrder(1)
        s.rotation:SetOrigin("CENTER",0,0);s.rotation:SetSmoothing("NONE")
        s.tick=function() draw(s,s.elapsed+math.max(0,GetTime()-s.startedAt)) end
        entry.mageSigils=s
    end
    E.StopMageSigils(entry)
    if s.art~=config.art then s.elapsed=0 end
    s.art=config.art;s.enabled=true;s.cycle=tuning.cycle;s.period=tuning.period
    s.flip=(config.flip==true)~=tuning.flip
    local width,height=entry.art:GetSize()
    local book=E.GetBookConfig(config)
    local bookWidth=width*.72*book.size/100
    local amplitude=bookWidth*.012
    local size=bookWidth*.65*tuning.size/100
    s.host:SetSize(size,size);s.host:SetFrameLevel(entry.frame:GetFrameLevel()+6)
    -- Same registered center/amplitude as the book, independent native motion.
    -- Resuming against its clock keeps the sigil exactly one second behind.
    s.host:ClearAllPoints();s.host:SetPoint("CENTER",entry.art,"CENTER",
        (book.x+tuning.x)*width/225*(config.flip and -1 or 1),(book.y+tuning.y)*height/225-amplitude)
    s.hoverLegs[1]:SetOffset(0,amplitude*2);s.hoverLegs[2]:SetOffset(0,-amplitude*2)
    s.host:SetAlpha(entry.alpha*tuning.opacity/100)
    local function register(t,name,scale)
        local extent=size*(scale or 1)
        t:SetTexture(prefix..name..".tga");t:SetSize(extent,extent)
        t:ClearAllPoints();t:SetPoint("CENTER",s.host,"CENTER",0,0);t:Show()
    end
    register(s.base,s.art=="frostbound" and "ColdsnapDetails" or "CombustionSeal")
    s.base:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},s.flip))
    for i,pair in ipairs(s.atlases) do
        local name=s.art=="frostbound" and (i==1 and "ColdsnapPupilAtlas" or "ColdsnapFlowAtlas")
            or (i==1 and "CombustionFlameAtlas" or nil)
        pair.active=name~=nil;pair.index=nil
        if name then
            local scale=s.art=="emberbound" and 0.9 or 1
            register(pair.a,name,scale);register(pair.b,name,scale)
        else pair.a:Hide();pair.b:Hide() end
    end
    s.rotation:SetDuration(tuning.period);s.rotation:SetDegrees(s.flip and -360 or 360)
    draw(s,s.elapsed);E.PlayMageSigils(entry)
end

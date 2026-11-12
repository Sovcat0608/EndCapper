local addonName, E = ...
E.caps = {}
E.cornerCaps = {}
local events = CreateFrame("Frame")
local function message(text) print("|cffb8e08cEndCapper:|r " .. text) end
E.Message = message

local function frameScreenPosition(frame)
    local x,y=frame:GetCenter()
    if x and y then
        local scale=frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
        return x*scale-(UIParent:GetLeft() or 0),y*scale-(UIParent:GetBottom() or 0)
    end
end

local function capsForMode(mode)
    return mode=="corner" and E.cornerCaps or E.caps
end

local function inward(side)
    return side=="left" and 1 or -1
end

local function halfWidth(side,config)
    local entry=E.caps[side]
    local scale=entry and entry.frame:GetEffectiveScale()/UIParent:GetEffectiveScale() or 1
    return (E.artworkByID[config.art].width or 154)*config.size*scale/200
end

local function defaultPairSpan()
    return math.min(760, UIParent:GetWidth()*0.7)
end

local function defaultCapX(side)
    return (UIParent:GetWidth()-inward(side)*defaultPairSpan())/2
end

function E.GetDefaultPairSeparation(db)
    local gap=defaultPairSpan()-halfWidth("left",db.left)-halfWidth("right",db.right)
    return math.max(0,math.min(2000,math.floor(gap/2+0.5)*2))
end

local function pairCenter(db,leftHalf,rightHalf)
    local pair=db.pair
    if pair.centerX then
        -- Preserve the rendered midpoint of a saved absolute anchor.
        return pair.centerX+pair.x+(rightHalf-leftHalf)/2
    end
    return UIParent:GetWidth()/2+pair.x
end

function E.GetPairOffset(db)
    if not db.pair.centerX then return db.pair.x end
    return pairCenter(db,halfWidth("left",db.left),halfWidth("right",db.right))-UIParent:GetWidth()/2
end

local function capX(side,db)
    if db.pair.linked then
        local leftHalf,rightHalf=halfWidth("left",db.left),halfWidth("right",db.right)
        local distance=(leftHalf+rightHalf+db.pair.separation)/2
        return pairCenter(db,leftHalf,rightHalf)-inward(side)*distance
    end
    return db[side].frameX or defaultCapX(side)
end

function E.GetLinkOffset(db)
    local x1=E.artworkByID[db.left.art].path and capX("left",db) or defaultCapX("left")
    local x2=E.artworkByID[db.right.art].path and capX("right",db) or defaultCapX("right")
    return (x1+x2-UIParent:GetWidth())/2
end

function E.RememberPairPositions(db)
    for _,side in ipairs({"left","right"}) do
        local c=db[side]
        if E.artworkByID[c.art].path then
            if db.mode=="corner" then
                if db.pair.x~=0 then c.frameX=(c.frameX or 0)+db.pair.x end
            else c.frameX=capX(side,db) end
        end
    end
end

local function placeCap(entry,db)
    local frame,c=entry.frame,db[entry.side]
    local scale=UIParent:GetEffectiveScale()/frame:GetEffectiveScale()
    if db.mode=="corner" then
        local anchor=entry.side=="left" and "BOTTOMLEFT" or "BOTTOMRIGHT"
        local x=(c.frameX or 0)+(db.pair.linked and db.pair.x or 0)
        local y=c.frameBottom and 0 or c.frameY or 0
        frame:ClearAllPoints()
        frame:SetPoint(anchor,UIParent,anchor,inward(entry.side)*x*scale,y*scale)
        return
    end
    local x=capX(entry.side,db)
    local bottomCenter=frame:GetHeight()/(2*scale)
    local y=not c.frameBottom and c.frameY or bottomCenter
    frame:ClearAllPoints()
    frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*scale,y*scale)
end

local activeDrag

function E.StopCapDrag()
    if not activeDrag then return end
    activeDrag.handle:SetScript("OnUpdate",nil)
    activeDrag=nil
end

local function updateDrag()
    local drag=activeDrag
    if not drag then return end
    if InCombatLockdown() or E.draft~=drag.db then E.StopCapDrag();return end
    local x,y=GetCursorPosition()
    local scale=UIParent:GetEffectiveScale()
    local dx,dy=math.floor((x-drag.x)/scale+0.5),math.floor((y-drag.y)/scale+0.5)
    if dx==drag.dx and dy==drag.dy then return end
    drag.dx,drag.dy=dx,dy
    drag.move(dx,dy)
end

local function beginDrag(handle,db,move)
    E.StopCapDrag()
    local x,y=GetCursorPosition()
    activeDrag={db=db,handle=handle,x=x,y=y,dx=0,dy=0,move=move}
    handle:SetScript("OnUpdate",updateDrag)
end

local function startCapDrag(entry,handle)
    local db=E.draft
    if InCombatLockdown() or not db or db.mode~=entry.mode or not entry.owned or not handle:IsVisible() then return end
    local linked=db.pair.linked
    local originalCenter=db.pair.centerX
    local originalX=db.pair.x
    local corner=db.mode=="corner"
    local offset=linked and (corner and originalX or E.GetPairOffset(db))
    local caps=capsForMode(db.mode)
    local positions={}
    for side,cap in pairs(caps) do
        if cap.owned and (linked or cap==entry) then
            local cx,cy=frameScreenPosition(cap.frame)
            if not cx then return end
            local c=db[side]
            local x=corner and (c.frameX or 0) or cx
            local y=corner and (c.frameBottom and 0 or c.frameY or 0) or cy
            positions[side]={x=x,y=y,frameX=c.frameX,frameY=c.frameY,frameBottom=c.frameBottom}
        end
    end
    beginDrag(handle,db,function(dx,dy)
        if linked then
            if dx~=0 then E.SetPairOffset(db,offset+dx*(corner and inward(entry.side) or 1))
            else db.pair.x,db.pair.centerX=originalX,originalCenter end
        end
        for side,start in pairs(positions) do
            local c=db[side]
            if not linked then c.frameX=dx~=0 and start.x+dx*(corner and inward(side) or 1) or start.frameX end
            c.frameY=dy~=0 and start.y+dy or start.frameY
            c.frameBottom=dy==0 and start.frameBottom
            placeCap(caps[side],db)
        end
    end)
end

local launcherCollected, launcherOnMinimap

function E.UpdateDragHandles()
    local editing=E.draft and E.panel and E.panel:IsShown() and not InCombatLockdown()
    local mode=editing and E.draft.mode
    for _,caps in ipairs({E.caps,E.cornerCaps}) do
        for _,entry in pairs(caps) do entry.handle:SetShown(mode==entry.mode and entry.owned or false) end
    end
    if E.launcherHandle then E.launcherHandle:SetShown(editing and E.draft.launcher.shown and not launcherCollected or false) end
end

local function colorDragOutline(handle,selected)
    if selected then
        handle:SetBackdropBorderColor(0.35,0.85,1,1)
    else
        handle:SetBackdropBorderColor(0.85,0.68,0.25,0.9)
    end
end

function E.UpdateCapSelection(selectedSide)
    for _,caps in ipairs({E.caps,E.cornerCaps}) do
        for side,entry in pairs(caps) do colorDragOutline(entry.handle,side==selectedSide) end
    end
end

local function createDragHandle(frame,start)
    local handle=CreateFrame("Button",nil,frame,"BackdropTemplate")
    handle:SetAllPoints(frame)
    handle:SetFrameStrata("HIGH")
    handle:SetFrameLevel(frame:GetFrameLevel()+5)
    handle:SetBackdrop({edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=12})
    colorDragOutline(handle,false)
    handle:EnableMouse(true)
    handle:RegisterForDrag("LeftButton")
    handle:SetScript("OnDragStart",function() start(handle) end)
    handle:SetScript("OnDragStop",function()
        if activeDrag and activeDrag.handle==handle then
            updateDrag()
            E.StopCapDrag()
            if E.RefreshOptions then E.RefreshOptions()
            elseif E.UpdateSaveButton then E.UpdateSaveButton() end
        end
    end)
    handle:SetScript("OnHide",function()
        if activeDrag and activeDrag.handle==handle then E.StopCapDrag() end
    end)
    handle:Hide()
    return handle
end

local launcherSize=40
local function keepLauncherOnScreen(position,extent)
    local half=launcherSize*E.launcher:GetEffectiveScale()/UIParent:GetEffectiveScale()/2
    return math.max(half,math.min(extent-half,position))
end

local function placeLauncher(config)
    if launcherCollected then return end
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local x=keepLauncherOnScreen(config.x or width-240,width)
    local y=keepLauncherOnScreen(config.y or height-44,height)
    local scale=UIParent:GetEffectiveScale()/E.launcher:GetEffectiveScale()
    E.launcher:ClearAllPoints()
    E.launcher:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*scale,y*scale)
end

local function startLauncherDrag(handle)
    local db=E.draft
    if InCombatLockdown() or launcherCollected or not db or not db.launcher.shown or not handle:IsVisible() then return end
    local x,y=frameScreenPosition(E.launcher)
    if not x then return end
    local config=db.launcher
    local originalX,originalY=config.x,config.y
    beginDrag(handle,db,function(dx,dy)
        local targetX=keepLauncherOnScreen(x+dx,UIParent:GetWidth())
        local targetY=keepLauncherOnScreen(y+dy,UIParent:GetHeight())
        config.x=targetX~=x and targetX or originalX
        config.y=targetY~=y and targetY or originalY
        placeLauncher(config)
    end)
end

local function updateLauncher(config, oneForAllLoaded)
    if not E.launcher then
        local button=CreateFrame("Button","EndCapperMinimapButton",UIParent)
        button:SetSize(launcherSize,launcherSize)
        button:SetFrameStrata("HIGH")
        button:SetNormalTexture("Interface\\AddOns\\EndCapper\\Media\\EcapLogo.tga")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
        button:SetScript("OnClick",function() E.OpenOptions() end)
        E.launcher=button
        E.launcherHandle=createDragHandle(button,startLauncherDrag)
    end
    if not launcherOnMinimap and Minimap and
        (oneForAllLoaded or C_AddOns and C_AddOns.IsAddOnLoaded("OneForAll")) then
        launcherOnMinimap=true
        E.launcher:SetParent(Minimap)
        -- The collector reparents the button and restores its old anchors when released.
        hooksecurefunc(E.launcher,"SetParent",function(_,parent)
            local wasCollected=launcherCollected
            launcherCollected=parent~=Minimap and parent~=UIParent
            if launcherCollected then
                E.launcherHandle:Hide()
            elseif wasCollected then
                C_Timer.After(0,function()
                    if InCombatLockdown() then return end
                    local current=E.Config().launcher
                    if current.shown then placeLauncher(current) end
                    E.UpdateDragHandles()
                end)
            end
        end)
    end
    if config.shown then placeLauncher(config) end
    E.launcher:SetShown(config.shown)
end

local function updateNativeSelection(entry,suppressed)
    local selection=entry.nativeFrame and entry.nativeFrame.Selection
    if not selection then return end
    local previous=entry.nativeSelection
    if suppressed and not previous then
        entry.nativeSelection={alpha=selection:GetAlpha(),mouse=selection:IsMouseEnabled()}
        -- Blizzard still owns the selection lifecycle and the native anchor.
        selection:SetAlpha(0)
        selection:EnableMouse(false)
    elseif not suppressed and previous then
        selection:SetAlpha(previous.alpha)
        selection:EnableMouse(previous.mouse)
        entry.nativeSelection=nil
    end
end

local function suppressNativeCap(entry,suppress)
    if not entry.native then return end
    if suppress or entry.suppress then
        entry.settingAlpha=true
        entry.native:SetAlpha(suppress and 0 or entry.nativeAlpha)
        entry.settingAlpha=false
    end
    updateNativeSelection(entry,suppress)
    entry.suppress=suppress
end

local function renderCap(entry,db)
    local c=db[entry.side]
    local art=entry.art
    local artwork=E.artworkByID[c.art]
    local flip=E.RenderFlip(c,db.mode)
    entry.owned=db.enabled and artwork.path~=nil
    entry.frame:SetShown(entry.owned)
    art:Hide()
    if entry.artOverlay then entry.artOverlay:Hide() end
    if entry.owned then
        local width,height=artwork.width,artwork.height
        art:SetTexture(E.ArtworkTexture(artwork.path))
        art:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},flip))
        art:SetSize(width*c.size/100,height*c.size/100)
        entry.frame:SetSize(art:GetSize())
        art:SetAlpha(entry.alpha)
        art:ClearAllPoints()
        local offsetY=c.y
        -- The visible drag box is art-sized for custom artwork. Its
        -- lower edge is the zero reference, excluding transparent padding.
        if c.artBottom then
            local baseline=E.EffectBaselines[c.art] or 1
            offsetY=offsetY+height*c.size/100*(baseline-1)
        end
        art:SetPoint("CENTER", entry.frame, "CENTER", c.x, offsetY)
        art:Show()
        if artwork.overlay then
            -- Static foreground artwork shares the base plane, above its
            -- texture but below front native effects. It is not an effect.
            local overlay=entry.artOverlay
            if not overlay then
                overlay=entry.artLayer:CreateTexture(nil,"OVERLAY",nil,7)
                entry.artOverlay=overlay
                overlay:SetBlendMode("BLEND")
            end
            overlay:SetTexture(E.ArtworkTexture(artwork.overlay))
            overlay:SetSize(width*c.size/100,height*c.size/100)
            overlay:SetTexCoord(E.UV({0,0,0,1,1,0,1,1},flip))
            overlay:SetAlpha(entry.alpha)
            overlay:ClearAllPoints()
            overlay:SetPoint("CENTER",art,"CENTER",0,0)
            overlay:Show()
        end
    end
    if entry.owned then placeCap(entry,db) end
    local effect=E.GetEffectConfig(c)
    effect.flip=flip
    if not db.enabled then effect.effects=false end
    E.UpdateEffects(entry,effect)
end

local function bartenderArtModule()
    if Bartender4 and type(Bartender4.GetModule)=="function" then
        return Bartender4:GetModule("BlizzardArt",true)
    end
end

function E.HasBartenderArtBar()
    return bartenderArtModule()~=nil
end

local observedArtModule, bartenderArt

local function writeBartenderAlpha(art,alpha)
    if art.frame:GetAlpha()==alpha then return end
    art.writing=true
    art.frame:SetAlpha(alpha)
    art.writing=false
end

local function updateBartenderArt()
    if InCombatLockdown() then E.pending=true;return end
    local module=bartenderArtModule()
    if module~=observedArtModule then
        observedArtModule=module
        if module and type(module.OnEnable)=="function" then
            hooksecurefunc(module,"OnEnable",function()
                if module==observedArtModule then updateBartenderArt() end
            end)
        end
    end
    local bar=module and module.bar
    if bartenderArt and bartenderArt.frame~=bar then
        if bartenderArt.hidden then writeBartenderAlpha(bartenderArt,bartenderArt.alpha) end
        bartenderArt=nil
    end
    if not bar then return end
    local requested=E.Config().hideBartenderArt
    if not requested and not bartenderArt then return end
    if not bartenderArt then
        local art={frame=bar,alpha=bar:GetAlpha()}
        bartenderArt=art
        hooksecurefunc(bar,"SetAlpha",function(_,alpha)
            if bartenderArt~=art or art.writing then return end
            art.alpha=alpha
            if art.hidden then
                if InCombatLockdown() then E.pending=true
                else writeBartenderAlpha(art,0) end
            end
        end)
        if bar.overlay then
            bar.overlay:HookScript("OnShow",updateBartenderArt)
            bar.overlay:HookScript("OnHide",updateBartenderArt)
        end
    end
    -- The overlay is interactive while Bartender's bars are unlocked.
    local hide=requested and not (bar.overlay and bar.overlay:IsShown())
    local wasHidden=bartenderArt.hidden
    bartenderArt.hidden=hide
    if hide or wasHidden then writeBartenderAlpha(bartenderArt,hide and 0 or bartenderArt.alpha) end
end

function E.Apply(targetSide,targetMode)
    if not E.ready then return end
    if InCombatLockdown() then E.pending=true;return end
    E.pending=false
    if E.ReconcilePositionLayout then
        local allowed,changed=E.ReconcilePositionLayout()
        if not allowed then return end
        if changed then targetSide,targetMode=nil,nil end
    end
    local db=E.Config()
    local endMode=db.mode=="end" and db or db.otherMode
    local cornerMode=db.mode=="corner" and db or db.otherMode
    if endMode.pair.linked and not endMode.pair.separationInitialized then E.ResetPairSeparation(endMode) end
    for side,entry in pairs(E.caps) do
        if not targetSide or side==targetSide then
            if not targetMode or targetMode=="end" then
                suppressNativeCap(entry,endMode.enabled and endMode[side].art~="default")
                renderCap(entry,endMode)
            end
            local corner=E.cornerCaps[side]
            if (not targetMode or targetMode=="corner") and (cornerMode.enabled or corner.owned) then
                renderCap(corner,cornerMode)
            end
        end
    end
    if E.DismissNativeCapSettings then E.DismissNativeCapSettings() end
    updateLauncher(db.launcher)
    updateBartenderArt()
    E.UpdateDragHandles()
end

local scheduledSides = {}
function E.Schedule(side)
    if side == "left" or side == "right" then scheduledSides[side] = true
    else scheduledSides.left, scheduledSides.right = true, true end
    if E.scheduled then return end
    E.scheduled = true
    C_Timer.After(0, function()
        local sides = scheduledSides
        scheduledSides = {}; E.scheduled = false
        if sides.left and sides.right then E.Apply()
        else E.Apply(sides.left and "left" or "right") end
    end)
end

local function createCap(side,mode)
    local frame=CreateFrame("Frame",nil,E.capRoot)
    frame:EnableMouse(false)
    frame:SetFrameLevel(10)
    frame:Hide()
    local artLayer=CreateFrame("Frame",nil,frame)
    artLayer:SetAllPoints(frame);artLayer:EnableMouse(false)
    artLayer:SetFrameLevel(frame:GetFrameLevel()+2)
    local art=artLayer:CreateTexture(nil,"OVERLAY",nil,6)
    local entry={side=side,mode=mode,frame=frame,artLayer=artLayer,art=art,alpha=1}
    entry.handle=createDragHandle(frame,function(handle) startCapDrag(entry,handle) end)
    entry.handle:SetScript("OnMouseDown",function(_,button)
        if button=="LeftButton" and E.SelectCapSide then E.SelectCapSide(side) end
    end)
    return entry
end

local function bindNativeCaps()
    local root = MainActionBar and MainActionBar.EndCaps
    local changed=false
    for side,entry in pairs(E.caps) do
        local cap = root and root[side == "left" and "LeftEndCap" or "RightEndCap"]
        local texture=cap and cap.Texture
        if texture~=entry.native or (texture and cap~=entry.nativeFrame) then
            suppressNativeCap(entry,false)
            entry.nativeFrame=texture and cap or nil
            entry.native=texture
            entry.nativeAlpha=texture and texture:GetAlpha() or nil
            changed=true
            if texture then
                entry.nativeHooks=entry.nativeHooks or setmetatable({}, {__mode="k"})
                if not entry.nativeHooks[texture] then
                    entry.nativeHooks[texture]=true
                    hooksecurefunc(texture,"SetAlpha",function(region,alpha)
                        if entry.native~=region or entry.settingAlpha then return end
                        entry.nativeAlpha=alpha
                        if entry.suppress then E.Schedule(entry.side) end
                    end)
                end
            end
        end
    end
    return changed
end

function E.Attach(onlyIfChanged)
    if not E.ready or InCombatLockdown() then E.pending = true; return end
    local created=not E.capRoot
    if created then
        E.capRoot=CreateFrame("Frame",nil,UIParent)
        if RegisterStateDriver then
            RegisterStateDriver(E.capRoot,"visibility","[petbattle][overridebar][vehicleui] hide; show")
        end
        for _,side in ipairs({"left","right"}) do
            E.caps[side]=createCap(side,"end")
            E.cornerCaps[side]=createCap(side,"corner")
        end
    end
    local changed=bindNativeCaps()
    if created or changed or not onlyIfChanged then E.Apply() end
    if E.AttachOptions and not (E.dialogHooked and E.registryHooked) then E.AttachOptions() end
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("UI_SCALE_CHANGED")
events:RegisterEvent("DISPLAY_SIZE_CHANGED")
events:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
events:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        if type(EndCapperDB) == "table" and type(EndCapperDB.version) == "number" and EndCapperDB.version > E.schemaVersion then
            message("Settings are from a newer version. This version will leave them untouched.")
            return
        end
        EndCapperDB = E.Normalize(EndCapperDB)
        E.ready = true
        SLASH_ENDCAPPER1 = "/endcapper"
        SLASH_ENDCAPPER2 = "/ecap"
        SlashCmdList.ENDCAPPER = function(command)
            local cmd=(command or ""):lower():match("^%s*(.-)%s*$")
            if cmd=="dev" or cmd=="dev on" or cmd=="dev off" then
                if InCombatLockdown() then message("Developer editing is available after combat."); return end
                E.devMode=cmd~="dev off" and (cmd=="dev on" or not E.devMode)
                message(E.devMode and "Developer mode on: artwork effect calibration unlocked." or "Developer mode off. Applied calibration is retained.")
                E.OpenOptions()
            elseif cmd=="hover" then
                local found=false
                for _,mode in ipairs({"end","corner"}) do
                    local caps=capsForMode(mode)
                    for _,side in ipairs({"left","right"}) do
                        local entry=caps and caps[side]
                        if entry and entry.skycutter then
                            message(mode.." / "..side..": "..E.SkycutterHoverStatus(entry))
                            found=true
                        end
                    end
                end
                if not found then message("Skycutter not loaded in either mode.") end
            elseif cmd=="status" then
                local caps=capsForMode(E.Config().mode)
                for _, side in ipairs({"left", "right"}) do
                    message(side .. ": " .. E.NativeSmokeStatus(caps[side]))
                end
            else E.OpenOptions() end
        end
    end
    if not E.ready then return end
    if event=="ADDON_LOADED" and name~=addonName then
        if name=="OneForAll" and E.launcher and not InCombatLockdown() then
            updateLauncher(E.Config().launcher,true)
        end
        E.Attach(name~="Bartender4")
        if name=="Bartender4" and not InCombatLockdown() and E.RefreshOptions then E.RefreshOptions() end
        return
    end
    if event=="PLAYER_LOGOUT" then
        if E.SavePositionProfile then E.SavePositionProfile() end
        return
    end
    if event=="EDIT_MODE_LAYOUTS_UPDATED" or event=="PLAYER_SPECIALIZATION_CHANGED" then
        -- The native manager must finish applying its own anchors first.
        E.Schedule();return
    end
    if event == "PLAYER_REGEN_DISABLED" then
        if E.panel then E.panel:Hide() end
    else
        E.Attach()
    end
end)

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

function E.CaptureNativePairSpacing()
    for _,entry in pairs(E.caps) do
        entry.nativeX,entry.nativeY=frameScreenPosition(entry.nativeFrame)
    end
    local left,right=E.caps.left,E.caps.right
    local x1,x2=left and left.nativeX,right and right.nativeX
    E.nativePairSpan=x1 and x2 and x2>x1 and x2-x1 or nil
end

local function capsForMode(mode)
    return mode=="corner" and E.cornerCaps or E.caps
end

local function inward(side)
    return side=="left" and 1 or -1
end

local function halfWidth(entry,config)
    local artwork=E.artworkByID[config.art]
    local width=artwork.width or entry.nativeFrame:GetWidth()
    return width*config.size/200*entry.frame:GetEffectiveScale()/UIParent:GetEffectiveScale()
end

function E.GetDefaultPairSeparation(db)
    local left,right=E.caps.left,E.caps.right
    if not E.nativePairSpan or not left or not right then return end
    local gap=E.nativePairSpan-halfWidth(left,db.left)-halfWidth(right,db.right)
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
    local left,right=E.caps.left,E.caps.right
    if not left or not right then return db.pair.x end
    return pairCenter(db,halfWidth(left,db.left),halfWidth(right,db.right))-UIParent:GetWidth()/2
end

local function capX(entry,db)
    local left,right=E.caps.left,E.caps.right
    if db.pair.linked and left and right then
        local leftHalf,rightHalf=halfWidth(left,db.left),halfWidth(right,db.right)
        local distance=(leftHalf+rightHalf+db.pair.separation)/2
        return pairCenter(db,leftHalf,rightHalf)+(entry.side=="left" and -distance or distance)
    end
    return db[entry.side].frameX or entry.nativeX
end

function E.GetLinkOffset(db)
    local left,right=E.caps.left,E.caps.right
    if not left or not right then return end
    local x1=E.artworkByID[db.left.art].path and capX(left,db) or left.nativeX
    local x2=E.artworkByID[db.right.art].path and capX(right,db) or right.nativeX
    if x1 and x2 then return (x1+x2-UIParent:GetWidth())/2 end
end

function E.RememberPairPositions(db)
    for side,entry in pairs(capsForMode(db.mode)) do
        local c=db[side]
        if E.artworkByID[c.art].path then
            if db.mode=="corner" then
                if db.pair.x~=0 then c.frameX=(c.frameX or 0)+db.pair.x end
            else c.frameX=capX(entry,db) end
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
    local x=capX(entry,db)
    local y=c.frameBottom and frame:GetHeight()/(2*scale) or c.frameY or entry.nativeY
    frame:ClearAllPoints()
    if x and y then
        frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x*scale,y*scale)
    else
        frame:SetPoint("CENTER",entry.nativeFrame,"CENTER")
    end
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

function E.UpdateDragHandles()
    local editing=E.draft and E.panel and E.panel:IsShown() and not InCombatLockdown()
    local mode=editing and E.draft.mode
    for _,caps in ipairs({E.caps,E.cornerCaps}) do
        for _,entry in pairs(caps) do entry.handle:SetShown(mode==entry.mode and entry.owned or false) end
    end
    if E.launcherHandle then E.launcherHandle:SetShown(editing and E.draft.launcher.shown or false) end
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
    local half=launcherSize/2
    return math.max(half,math.min(extent-half,position))
end

local function placeLauncher(config)
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local x=keepLauncherOnScreen(config.x or width-240,width)
    local y=keepLauncherOnScreen(config.y or height-44,height)
    E.launcher:ClearAllPoints()
    E.launcher:SetPoint("CENTER",UIParent,"BOTTOMLEFT",x,y)
end

local function startLauncherDrag(handle)
    local db=E.draft
    if InCombatLockdown() or not db or not db.launcher.shown or not handle:IsVisible() then return end
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

local function updateLauncher(config)
    if not E.launcher then
        local button=CreateFrame("Button",nil,UIParent)
        button:SetSize(launcherSize,launcherSize)
        button:SetFrameStrata("HIGH")
        button:SetNormalTexture("Interface\\AddOns\\EndCapper\\Media\\EcapLogo.tga")
        button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square","ADD")
        button:SetScript("OnClick",function() E.OpenOptions() end)
        E.launcher=button
        E.launcherHandle=createDragHandle(button,startLauncherDrag)
    end
    if config.shown then placeLauncher(config) end
    E.launcher:SetShown(config.shown)
end

local function updateNativeSelection(entry,suppressed)
    local selection=entry.nativeFrame.Selection
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
        art:SetTexture(artwork.path)
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
            overlay:SetTexture(artwork.overlay)
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

function E.Apply(targetSide,targetMode)
    if not E.ready then return end
    if InCombatLockdown() then E.pending=true;return end
    E.pending=false
    if E.refreshNativePositions then
        E.refreshNativePositions=nil
        E.CaptureNativePairSpacing()
        targetSide,targetMode=nil,nil
    end
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
                local suppress=endMode.enabled and endMode[side].art~="default"
                if suppress or entry.suppress then
                    entry.settingAlpha=true
                    entry.native:SetAlpha(suppress and 0 or entry.alpha)
                    entry.settingAlpha=false
                end
                updateNativeSelection(entry,suppress)
                entry.suppress=suppress
                renderCap(entry,endMode)
            end
            local corner=E.cornerCaps[side]
            if (not targetMode or targetMode=="corner") and (cornerMode.enabled or corner.owned) then
                corner.alpha=entry.alpha
                renderCap(corner,cornerMode)
            end
        end
    end
    if E.DismissNativeCapSettings then E.DismissNativeCapSettings() end
    updateLauncher(db.launcher)
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

local function createCap(side,cap,mode)
    -- Both sets inherit visibility and scale. Their anchors belong to the addon.
    local frame=CreateFrame("Frame",nil,cap)
    frame:EnableMouse(false)
    frame:SetFrameLevel(cap:GetFrameLevel())
    frame:Hide()
    local artLayer=CreateFrame("Frame",nil,frame)
    artLayer:SetAllPoints(frame);artLayer:EnableMouse(false)
    artLayer:SetFrameLevel(frame:GetFrameLevel()+2)
    local art=artLayer:CreateTexture(nil,"OVERLAY",nil,6)
    local native=cap.Texture
    local entry={side=side,mode=mode,frame=frame,nativeFrame=cap,artLayer=artLayer,native=native,art=art,alpha=native:GetAlpha()}
    entry.handle=createDragHandle(frame,function(handle) startCapDrag(entry,handle) end)
    entry.handle:SetScript("OnMouseDown",function(_,button)
        if button=="LeftButton" and E.SelectCapSide then E.SelectCapSide(side) end
    end)
    return entry
end

function E.Attach()
    if not E.ready or InCombatLockdown() then E.pending = true; return end
    local root = MainActionBar and MainActionBar.EndCaps
    if not root then return end
    local attached=false
    for _, side in ipairs({"left", "right"}) do
        local cap = root[side == "left" and "LeftEndCap" or "RightEndCap"]
        if cap and cap.Texture and not E.caps[side] then
            local entry=createCap(side,cap,"end")
            E.caps[side]=entry
            E.cornerCaps[side]=createCap(side,cap,"corner")
            attached=true
            cap:HookScript("OnShow",function()
                if not entry.nativeX then E.refreshNativePositions=true;E.Schedule() end
            end)
            hooksecurefunc(entry.native,"SetAlpha",function(_,alpha)
                if entry.settingAlpha then return end
                entry.alpha=alpha
                if entry.suppress or E.cornerCaps[side].owned then E.Schedule(side) end
            end)
        end
    end
    if attached then E.CaptureNativePairSpacing() end
    E.Apply()
    if E.AttachOptions then E.AttachOptions() end
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
            elseif cmd=="status" then
                local caps=capsForMode(E.Config().mode)
                for _, side in ipairs({"left", "right"}) do
                    message(side .. ": " .. E.NativeSmokeStatus(caps[side]))
                end
            else E.OpenOptions() end
        end
    end
    if not E.ready then return end
    if event=="ADDON_LOADED" and name~=addonName and E.caps.left and E.caps.right then
        if E.AttachOptions and not (E.dialogHooked and E.registryHooked) and not InCombatLockdown() then
            E.AttachOptions()
        end
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
    if event=="UI_SCALE_CHANGED" or event=="DISPLAY_SIZE_CHANGED" then E.refreshNativePositions=true end
    if event == "PLAYER_REGEN_DISABLED" then
        if E.panel then E.panel:Hide() end
    else
        E.Attach()
    end
end)
